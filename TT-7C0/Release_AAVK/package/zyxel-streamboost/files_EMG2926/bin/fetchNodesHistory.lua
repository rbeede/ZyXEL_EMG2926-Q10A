-----------------------------------------------------------
-- CONST
-----------------------------------------------------------
local DB_NAME = "eventdb:events"
local PrecalculatedDB_NAME = "eventdb:perDevicePrecalculated"

-----------------------------------------------------------
-- Name of log saved on redis for debug purpose
-- Delete previous log
-----------------------------------------------------------
local loglist = KEYS[1]
redis.pcall("DEL", loglist)


-----------------------------------------------------------
-- Push log
-----------------------------------------------------------
local function logit(msg)
  redis.pcall("RPUSH", loglist, msg)
end


-----------------------------------------------------------
-- Push pushDeviceData
-----------------------------------------------------------
local function pushDeviceData(stringfyDeviceData)
  redis.pcall("LPUSH", PrecalculatedDB_NAME, stringfyDeviceData)
end


-----------------------------------------------------------
-- Epoch time conversion related functions
-----------------------------------------------------------
local strformat = string.format
local floor = math.floor
local idiv do
	-- Try and use actual integer division when available (Lua 5.3+)
	local idiv_loader, err = (loadstring or load)([[return function(n,d) return n//d end]], "idiv")
	if idiv_loader then
		idiv = idiv_loader()
	else
		idiv = function(n, d)
			return floor(n/d)
		end
	end
end


local mon_lengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
-- Number of days in year until start of month; not corrected for leap years
local months_to_days_cumulative = { 0 }
for i = 2, 12 do
	months_to_days_cumulative [ i ] = months_to_days_cumulative [ i-1 ] + mon_lengths [ i-1 ]
end
-- For Sakamoto's Algorithm (day of week)
local sakamoto = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};

local function is_leap ( y )
	if (y % 4) ~= 0 then
		return false
	elseif (y % 100) ~= 0 then
		return true
	else
		return (y % 400) == 0
	end
end

local function year_length ( y )
	return is_leap ( y ) and 366 or 365
end

local function month_length ( m , y )
	if m == 2 then
		return is_leap ( y ) and 29 or 28
	else
		return mon_lengths [ m ]
	end
end

local function leap_years_since ( year )
	return idiv ( year , 4 ) - idiv ( year , 100 ) + idiv ( year , 400 )
end

local function day_of_year ( day , month , year )
	local yday = months_to_days_cumulative [ month ]
	if month > 2 and is_leap ( year ) then
		yday = yday + 1
	end
	return yday + day
end

local function day_of_week ( day , month , year )
	if month < 3 then
		year = year - 1
	end
	return ( year + leap_years_since ( year ) + sakamoto[month] + day ) % 7 + 1
end

local function borrow ( tens , units , base )
	local frac = tens % 1
	units = units + frac * base
	tens = tens - frac
	return tens , units
end

local function carry ( tens , units , base )
	if units >= base then
		tens  = tens + idiv ( units , base )
		units = units % base
	elseif units < 0 then
		tens  = tens - 1 + idiv ( -units , base )
		units = base - ( -units % base )
	end
	return tens , units
end

-- Modify parameters so they all fit within the "normal" range
local function normalise ( year , month , day , hour , min , sec )
	-- `month` and `day` start from 1, need -1 and +1 so it works modulo
	month , day = month - 1 , day - 1

	-- Convert everything (except seconds) to an integer
	-- by propagating fractional components down.
	year  , month = borrow ( year  , month , 12 )
	-- Carry from month to year first, so we get month length correct in next line around leap years
	year  , month = carry ( year , month , 12 )
	month , day   = borrow ( month , day   , month_length ( floor ( month + 1 ) , year ) )
	day   , hour  = borrow ( day   , hour  , 24 )
	hour  , min   = borrow ( hour  , min   , 60 )
	min   , sec   = borrow ( min   , sec   , 60 )

	-- Propagate out of range values up
	-- e.g. if `min` is 70, `hour` increments by 1 and `min` becomes 10
	-- This has to happen for all columns after borrowing, as lower radixes may be pushed out of range
	min   , sec   = carry ( min   , sec   , 60 ) -- TODO: consider leap seconds?
	hour  , min   = carry ( hour  , min   , 60 )
	day   , hour  = carry ( day   , hour  , 24 )
	-- Ensure `day` is not underflowed
	-- Add a whole year of days at a time, this is later resolved by adding months
	-- TODO[OPTIMIZE]: This could be slow if `day` is far out of range
	while day < 0 do
		year = year - 1
		day  = day + year_length ( year )
	end
	year , month = carry ( year , month , 12 )

	-- TODO[OPTIMIZE]: This could potentially be slow if `day` is very large
	while true do
		local i = month_length ( month + 1 , year )
		if day < i then break end
		day = day - i
		month = month + 1
		if month >= 12 then
			month = 0
			year = year + 1
		end
	end

	-- Now we can place `day` and `month` back in their normal ranges
	-- e.g. month as 1-12 instead of 0-11
	month , day = month + 1 , day + 1

	return year , month , day , hour , min , sec
end

local leap_years_since_1970 = leap_years_since ( 1970 )
local function timestamp ( year , month , day , hour , min , sec )
	year , month , day , hour , min , sec = normalise ( year , month , day , hour , min , sec )

	local days_since_epoch = day_of_year ( day , month , year )
		+ 365 * ( year - 1970 )
		-- Each leap year adds one day
		+ ( leap_years_since ( year - 1 ) - leap_years_since_1970 ) - 1

	return days_since_epoch * (60*60*24)
		+ hour  * (60*60)
		+ min   * 60
		+ sec
end


local timetable_methods = { }

function timetable_methods:unpack ( )
	return assert ( self.year  , "year required" ) ,
		assert ( self.month , "month required" ) ,
		assert ( self.day   , "day required" ) ,
		self.hour or 12 ,
		self.min  or 0 ,
		self.sec  or 0 ,
		self.yday ,
		self.wday
end

function timetable_methods:normalise ( )
	local year , month , day
	year , month , day , self.hour , self.min , self.sec = normalise ( self:unpack ( ) )

	self.day   = day
	self.month = month
	self.year  = year
	self.yday  = day_of_year ( day , month , year )
	self.wday  = day_of_week ( day , month , year )

	return self
end
timetable_methods.normalize = timetable_methods.normalise -- American English

function timetable_methods:timestamp ( )
	return timestamp ( self:unpack ( ) )
end

function timetable_methods:rfc_3339 ( )
	local year , month , day , hour , min , sec = self:unpack ( )
	local sec , msec = borrow ( sec , 0 , 1000 )
	msec = math.floor(msec)
	return strformat ( "%04u-%02u-%02uT%02u:%02u:%02d.%03d" , year , month , day , hour , min , sec , msec )
end

function timetable_methods:date( )
	local year , month , day= self:unpack ( )
	return strformat ( "%04u/%02u/%02u" , year , month , day )
end

function timetable_methods:format ( format_string )
	return strftime ( format_string , self )
end

local timetable_mt

local function coerce_arg ( t )
	if getmetatable ( t ) == timetable_mt then
		return t:timestamp ( )
	end
	return t
end

timetable_mt = {
	__index    = timetable_methods ;
	__tostring = timetable_methods.rfc_3339 ;
	__eq = function ( a , b )
		return a:timestamp ( ) == b:timestamp ( )
	end ;
	__lt = function ( a , b )
		return a:timestamp ( ) < b:timestamp ( )
	end ;
	__sub = function ( a , b )
		return coerce_arg ( a ) - coerce_arg ( b )
	end ;
}

local function cast_timetable ( tm )
	return setmetatable ( tm , timetable_mt )
end

local function new_timetable ( year , month , day , hour , min , sec , yday , wday )
	return cast_timetable {
		year  = year ;
		month = month ;
		day   = day ;
		hour  = hour ;
		min   = min ;
		sec   = sec ;
		yday  = yday ;
		wday  = wday ;
	}
end


local function new_from_timestamp ( ts )
	if type ( ts ) ~= "number" then
		error ( "bad argument #1 to 'new_from_timestamp' (number expected, got " .. type ( ts ) .. ")" , 2 )
	end
	return new_timetable ( 1970 , 1 , 1 , 0 , 0 , ts ):normalise ( )
end

-----------------------------------------------------------
-- Streamboost Event conversion related functions
-----------------------------------------------------------
-- event IDs,  version 1 unless otherwise specified
local event_id_open = 1
local event_id_close = 2
local event_id_milestone = 3
local event_id_classification = 4
local event_id_feature = 5
local event_id_con_open = 6
local event_id_con_close = 7
-- 8 much?
local event_id_oversub_update = 9
local event_id_oversub_create = 10

-- open, v1
-- format: "1,time,uuid,flow_id,mac,policy_id"
local function open_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "open" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_open then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- uuid
	s,e = string.find(event_csv,',',pos)
	event.uuid = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- flow_id
	s,e = string.find(event_csv,',',pos)
	event.flow_id = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- mac
	s,e = string.find(event_csv,',',pos)
	event.mac = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- begin details
	event.details = {}
	-- policy_id
	event.details.policy_id = string.sub(event_csv,pos)

	return event
end
-- close, v1
-- format: "2,time,uuid,flow_id,mac,tx_bytes,rx_bytes"
local function close_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "close" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_close then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- uuid
	s,e = string.find(event_csv,',',pos)
	event.uuid = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- flow_id
	s,e = string.find(event_csv,',',pos)
	event.flow_id = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- mac
	s,e = string.find(event_csv,',',pos)
	event.mac = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- begin details
	event.details = {}
	-- tx_bytes
	s,e = string.find(event_csv,',',pos)
	event.details.tx_bytes = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_bytes
	event.details.rx_bytes = string.sub(event_csv,pos)

	return event
end
-- milestone, v1
-- format: "3,time,uuid,flow_id,tx_bytes,tx_packets,tx_qlen,tx_requeues,tx_overlimits,tx_drops,tx_backlog,rx_bytes,rx_packets,rx_qlen,rx_requeues,rx_overlimits,rx_drops,rx_backlog"
local function milestone_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "milestone" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_milestone then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- uuid
	s,e = string.find(event_csv,',',pos)
	event.uuid = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- flow_id
	s,e = string.find(event_csv,',',pos)
	event.flow_id = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- begin details
	event.details = {}
	-- tx_bytes
	s,e = string.find(event_csv,',',pos)
	event.details.tx_bytes = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- tx_packets
	s,e = string.find(event_csv,',',pos)
	event.details.tx_packets = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- tx_qlen
	s,e = string.find(event_csv,',',pos)
	event.details.tx_qlen = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- tx_requeues
	s,e = string.find(event_csv,',',pos)
	event.details.tx_requeues = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- tx_overlimits
	s,e = string.find(event_csv,',',pos)
	event.details.tx_overlimits = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- tx_drops
	s,e = string.find(event_csv,',',pos)
	event.details.tx_drops = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- tx_backlog
	s,e = string.find(event_csv,',',pos)
	event.details.tx_backlog = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_bytes
	s,e = string.find(event_csv,',',pos)
	event.details.rx_bytes = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_packets
	s,e = string.find(event_csv,',',pos)
	event.details.rx_packets = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_qlen
	s,e = string.find(event_csv,',',pos)
	event.details.rx_qlen = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_requeues
	s,e = string.find(event_csv,',',pos)
	event.details.rx_requeues = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_overlimits
	s,e = string.find(event_csv,',',pos)
	event.details.rx_overlimits = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_drops
	s,e = string.find(event_csv,',',pos)
	event.details.rx_drops = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rx_backlog
	event.details.rx_backlog = string.sub(event_csv,pos)

	return event
end

-- decode a 5-tuple from the csv, where the first character of the
-- 5-tuple starts at pos
-- returns: a 2-tuple of (5-tuple-string, end_of_tuple_pos)
local function tuple_decode_from_csv(event_csv,pos)
	local s,e
	local tstart,tend
	-- tstart points to proto
	tstart = pos
	s,e = string.find(event_csv,',',tstart)
	-- src_ip is e + 1
	s,e = string.find(event_csv,',',e + 1)
	-- sport is e + 1
	s,e = string.find(event_csv,',',e + 1)
	-- dest_ip is e + 1
	s,e = string.find(event_csv,',',e + 1)
	-- dport is e + 1
	s,e = string.find(event_csv,',',e + 1)
	if e then
		tend = e - 1
	else
		tend = nil
	end
	return string.sub(event_csv,tstart,tend) , e
end

-- classification, v1
-- format: "4,time,5-tuple,class,classifier"
local function classification_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "classification" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_classification then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- 5-tuple
	event['5-tuple'], e = tuple_decode_from_csv(event_csv,pos)
	pos = e + 1
	-- class
	s,e = string.find(event_csv,',',pos)
	event.class = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- classifier
	event.classifier = string.sub(event_csv,pos)

	return event
end
-- feature discovery, v1
-- format: "5,time,5-tuple,data"
local function feature_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "feature" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_feature then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- 5-tuple
	event['5-tuple'], e = tuple_decode_from_csv(event_csv,pos)
	pos = e + 1
	-- data
	event.data = string.sub(event_csv,pos)

	return event
end
-- con-open, v1
-- format: "6,time,5-tuple"
local function con_open_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "con-open" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_con_open then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- 5-tuple
	event['5-tuple'], e = tuple_decode_from_csv(event_csv,pos)

	return event
end
-- con-close, v1
-- format: "7,time,5-tuple,orig-bytes,orig-packets,reply-bytes,reply-packets"
local function con_close_decode_from_csv(event_csv)
	local s,e,pos
	local event = { event = "con-close" }

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_con_close then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- 5-tuple
	event['5-tuple'], e = tuple_decode_from_csv(event_csv,pos)
	pos = e + 1
	-- begin details
	event.details = {}
	-- orig-bytes
	s,e = string.find(event_csv,',',pos)
	event.details['orig-bytes'] = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- orig-packets
	s,e = string.find(event_csv,',',pos)
	event.details['orig-packets'] = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- reply-bytes
	s,e = string.find(event_csv,',',pos)
	event.details['reply-bytes'] = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- reply-packets
	event.details['reply-packets'] = string.sub(event_csv,pos)

	return event
end

-- oversub update and create, v1
-- format: "[9,10],time,uuid,flow_id,direction,policy_type,stratum,rate,delay,work"
local function oversub_decode_from_csv(event_csv)
	local s,e,pos
	local event = {}

	pos = 1
	-- event id
	s,e = string.find(event_csv,',',pos)
	local id = tonumber(string.sub(event_csv,pos,e - 1))
	if id ~= event_id_oversub_update and id ~= event_id_oversub_create then
		return nil
	end
	pos = e + 1
	-- time
	s,e = string.find(event_csv,',',pos)
	event.time = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- uuid
	s,e = string.find(event_csv,',',pos)
	event.uuid = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- flow_id
	s,e = string.find(event_csv,',',pos)
	event.flow_id = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- begin details
	event.details = {}
	-- direction
	s,e = string.find(event_csv,',',pos)
	event.details.direction = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- policy_type
	s,e = string.find(event_csv,',',pos)
	event.details.policy_type = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- stratum
	s,e = string.find(event_csv,',',pos)
	event.details.stratum = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- rate
	s,e = string.find(event_csv,',',pos)
	event.details.rate = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- delay
	s,e = string.find(event_csv,',',pos)
	event.details.delay = string.sub(event_csv,pos,e - 1)
	pos = e + 1
	-- work
	event.details.work = string.sub(event_csv,pos)

	return event
end
-- oversub update, v1
-- format: "9,time,uuid,flow_id,direction,policy_type,stratum,rate,delay,work"
local function update_decode_from_csv(event_csv)
	local event = oversub_decode_from_csv(event_csv)
	if not event then
		return nil
	end
	event.event = "update"
	return event
end
-- oversub create, v1
-- format: "10,time,uuid,flow_id,direction,policy_type,stratum,rate,delay,work"
local function create_decode_from_csv(event_csv)
	local event = oversub_decode_from_csv(event_csv)
	if not event then
		return nil
	end
	event.event = "create"
	return event
end

-- lookup table that maps decode function of event types
-- [<event_type_id>] = decode_event_type_fn
local event_decoder_fn = {
	[event_id_open] = open_decode_from_csv,
	[event_id_close] = close_decode_from_csv,
	[event_id_milestone] = milestone_decode_from_csv,
	[event_id_classification] = classification_decode_from_csv,
	[event_id_feature] = feature_decode_from_csv,
	[event_id_con_open] = con_open_decode_from_csv,
	[event_id_con_close] = con_close_decode_from_csv,
	[event_id_oversub_update] = update_decode_from_csv,
	[event_id_oversub_create] = create_decode_from_csv,
}

-- converts a lua table containing a list of events into json
local function table_to_json(events)
	return cjson.encode(events)
end

-- converts a json into lua table
local function json_to_table(json)
	return cjson.decode(json)
end

-- converts a single raw event entry in csv format into a lua table
local function csv_to_table(event_csv)
	if type(event_csv) ~= "string" then
		return nil
	end
	-- the first field is always the ID of the event type
	local s,e = string.find(event_csv,',',1)
	local etype = string.sub(event_csv,1,e - 1)
	local decode = event_decoder_fn[tonumber(etype)]
	if decode then
		return decode(event_csv)
	end
	return nil
end


-----------------------------------------------------------
-- Calculation
-----------------------------------------------------------
local function parseIntFilterNaN(obj)
    local val = tonumber(obj)
    if val == nil then
    	return 0
    end
    return val
end -- local function parseIntFilterNaN(obj)

local function isTimeBetweenRange(targetTimestamp, startTimestamp, endTimestamp)
	targetTimestamp = tonumber(targetTimestamp)
	if endTimestamp >= targetTimestamp and targetTimestamp >= startTimestamp then
		return true
	end 
	return false
end

-- Currently not implemented.
local function findOpenFlow(flowUUID)
	return nil
end
 

local function calculateDeviceData(events, startTimestamp, endTimestamp)
	local flowData = {}
	logit("start getDeviceData")
	for i,event in ipairs(events) do

		-- logit(i .. ") event : ")
		-- logit(table_to_json(event))
		local uuid = event.uuid
		-- logit("uuid: " .. uuid)

		if (flowData[uuid] == nil) then
            -- create new if nil
            flowData[uuid] = {}
            -- logit("create flowData[".. uuid .. "], now number of flowData: ".. #flowData)
		end 

        -- add part to regogize flow and device
        flowData[uuid].uuid        = event.uuid
        flowData[uuid].flow_id     = event.flow_id

        -- logit("flowData[".. uuid .. "].uuid: " .. flowData[uuid].uuid)
        -- logit("flowData[".. uuid .. "].flow_id: " .. flowData[uuid].flow_id)

        -- was this an open event?
        if(event.event == "open") then

            -- copy the open event it to or presort data
            flowData[uuid].openTime    = event.time
            flowData[uuid].policy_id   = event.details.policy_id
            flowData[uuid].closeTime   = nil

            -- set the device
            flowData[uuid].mac          = event.mac

            -- open has no byte counts so init them to 0
            flowData[uuid].rx_bytes = 0
            flowData[uuid].tx_bytes = 0
        
        elseif(event.event == "milestone" or event.event == "close") then -- was this a close or milestone update?
        	if isTimeBetweenRange(event.time, startTimestamp, endTimestamp) == false then
        		flowData[uuid] = nil
        		-- logit("uuid: " .. uuid .. " has been set to nil since event.time: " .. event.time .. " is not in range")
        	else
	            -- set the close time to the last update
	            flowData[uuid].closeTime = event.time

	            -- update the byte counts
	            flowData[uuid].rx_bytes = parseIntFilterNaN(event.details.rx_bytes)
	            flowData[uuid].tx_bytes = parseIntFilterNaN(event.details.tx_bytes)

        	end
        else
        	-- logit("event.event: " .. event.event .. ", do nothing.")
        end

	end


    -- create our return array
    local deviceData = {};

    --init the device array inside our return
    deviceData.devices = {};

    --global byte counts across all devices
    deviceData.rx_total = 0;
    deviceData.tx_total = 0;
    deviceData.startTimestamp = startTimestamp;
    deviceData.endTimestamp = endTimestamp;

    -- pre calculate the totals
    for flowUUID, flow in pairs(flowData) do
        local mac = flow.mac;

        if mac == nil then
            local openFlow = findOpenFlow(flowUUID);
            if openFlow ~= nil then

                flow.policy_id = openFlow.details.policy_id;
                flow.mac       = openFlow.mac;
                mac            = flow.mac ;
            else
                flow.policy_id = "uncategorized";                
                flow.mac       = "Unknown device";
                mac            = flow.mac ;
        	end
        end

        -- if this is a valid device
        if mac ~= nil then 
            -- get up down (for debuggin purposes)
            local nRx = flow.rx_bytes;
            local nTx = flow.tx_bytes;

            -- do global byte counts
            deviceData.rx_total = deviceData.rx_total + nRx;
            deviceData.tx_total = deviceData.tx_total + nTx;
        end

    end -- for flowUUID, flow in pairs(flowData) do

    -- combine by device and flow
    for flowUUID, flow in pairs(flowData) do
        -- get the device mac
        local mac = flow.mac;

        -- if we have a valid device
        if mac ~= nil then
            -- get up down (for debuggin purposes)
            local nRx = flow.rx_bytes;
            local nTx = flow.tx_bytes;

            -- if this is the 1st time we've seen this device
            if deviceData.devices[mac] == nil then
                -- create the device entry in our array
                deviceData.devices[mac] = {};
                deviceData.devices[mac].flows = {};
                deviceData.devices[mac].rx_total         = 0;
                deviceData.devices[mac].tx_total         = 0;
			end

            -- get the flow
            local flowPolicyID = flow.policy_id;

            -- logit('flowPolicyID : ' .. flowPolicyID)

            -- if this is the 1st time we've seen this flow
            if deviceData.devices[mac].flows[flowPolicyID] == nil then
                -- init te flow
                deviceData.devices[mac].flows[flowPolicyID] = {};

                -- init flow byte counts
                deviceData.devices[mac].flows[flowPolicyID].rx_bytes   = 0;
                deviceData.devices[mac].flows[flowPolicyID].tx_bytes   = 0;
            end

            -- do byte count
            deviceData.devices[mac].flows[flowPolicyID].rx_bytes = deviceData.devices[mac].flows[flowPolicyID].rx_bytes + nRx;
            deviceData.devices[mac].flows[flowPolicyID].tx_bytes = deviceData.devices[mac].flows[flowPolicyID].tx_bytes + nTx;

            -- do device byte counts
            deviceData.devices[mac].rx_total = deviceData.devices[mac].rx_total + nRx;
            deviceData.devices[mac].tx_total = deviceData.devices[mac].tx_total + nTx;

            -- do flow percent
            -- deviceData.devices[mac].flows[flowPolicyID].rx_percent = ((deviceData.devices[mac].flows[flowPolicyID].rx_bytes/deviceData.rx_total)*100).toFixed(2);
            -- deviceData.devices[mac].flows[flowPolicyID].tx_percent = ((deviceData.devices[mac].flows[flowPolicyID].tx_bytes/deviceData.tx_total)*100).toFixed(2);



            -- do device  percent
            -- deviceData.devices[mac].rx_percent = ((deviceData.devices[mac].rx_total/deviceData.rx_total)*100).toFixed(2);
            -- deviceData.devices[mac].tx_percent = ((deviceData.devices[mac].tx_total/deviceData.tx_total)*100).toFixed(2);
        end -- if mac ~= nil then
    end -- for flowUUID, flow in pairs(flowData) do



	-- logit("number of flowData: " .. #flowData)

	-- logit("printing flowData: ")
	-- for flowUUID, flow in pairs(flowData) do
	-- 	logit("flowUUID: " .. flowUUID)
	-- 	logit(table_to_json(flow))
	-- end

	-- logit("printing deviceData: ")
	-- for deviceDataKey, deviceDataValue in pairs(deviceData) do
	-- 	logit("deviceDataKey: " .. deviceDataKey)
	-- 	logit(table_to_json(deviceDataValue))
	-- end

	logit("finished getDeviceData")

	return deviceData
end -- local function getDeviceData(events)


local function calculateDeviceDataWithIndex(lowerBoundIndex, higherBoundIndex, startTimestamp, endTimestamp)
	local events = redis.call('LRANGE', DB_NAME, lowerBoundIndex, higherBoundIndex)
	if #events == 0 then return {ok='done'} end

	logit("number of events: " .. #events)

	local ret = {}

	-- convert events retrieved from redis into event objects
	for i,v in ipairs(events) do
		local event = csv_to_table(v)
		ret[#ret+1] = event
	end

	local deviceData = calculateDeviceData(ret, startTimestamp, endTimestamp)
	local jsonDeviceData = table_to_json(deviceData)

	logit("jsonDeviceData: ")
	logit(jsonDeviceData)
	pushDeviceData(jsonDeviceData)
	return startTimestamp
end


local function lengthOfDB()
  return tonumber(redis.call("LLEN", DB_NAME))
end

local function getTimestampWithoutHMS(timestamp)
	local t = new_from_timestamp(timestamp)
	return new_timetable(t.year, t.month, t.day, 0, 0, 0, 0, 0):timestamp()
end

local function getTimestampOfIndex(index)
	local events = redis.call('LRANGE', DB_NAME, index, index)
	if #events == 0 then 
		return nil
	end	

	-- get timestamp from first of array
	for i,v in ipairs(events) do
		local event = csv_to_table(v)
		return tonumber(event.time)
	end
end

local function getPrecalculatedData(index)
	local length = redis.call('LLEN', PrecalculatedDB_NAME)
	logit('length of precalculated DB:')
	logit(length)
	local jsonData = redis.call('LRANGE', PrecalculatedDB_NAME, index, index)
	for i,v in pairs(jsonData) do
		logit('i:')
		logit(i)
		logit('v:')
		logit(v)
		local table = json_to_table(v)
		for x,y in pairs(table) do
			logit('x:')
			logit(x)
			logit('y:')
			logit(y)
		end
	end
end

local function walkIndexOfTimestamp(accOfIndex, lengthOfDB)

	for i=lengthOfDB -1, -accOfIndex, -accOfIndex do
		local index = i
		if i < 0 then
			index = 0
		end
		local timestamp = getTimestampOfIndex(index)
		logit("index: " .. index .. ", timestamp: " .. timestamp .. ", " .. new_from_timestamp(timestamp):rfc_3339())    	
	end

end


local function getHigherBoundIndexOfTimestamp(targetTimestamp, accOfIndex, lengthOfDB)

	for i=lengthOfDB -1, -accOfIndex, -accOfIndex do
		local index = i
		if i < 0 then
			index = 0
		end
		local timestamp = getTimestampOfIndex(index)
		if timestamp < targetTimestamp then
			index = index + accOfIndex * 2
			if index > lengthOfDB then
				index = lengthOfDB -1
			end
			return index
		end 		
	end

	return 0

end

local function getLowerBoundIndexOfTimestamp(targetTimestamp, accOfIndex, lengthOfDB)

	for i=lengthOfDB -1, -accOfIndex, -accOfIndex do
		local index = i
		if i < 0 then
			index = 0
		end
		local timestamp = getTimestampOfIndex(index)
		if timestamp < targetTimestamp then
			index = index - accOfIndex
			if index < 0 then
				index = 0
			end
			return index
		end 		
	end

	return 0

end

-----------------------------------------------------------
-- Main
-----------------------------------------------------------
logit("start Main")

-----------------------------------------------------------
-- For test purpose
-----------------------------------------------------------
if true then
	getPrecalculatedData(0)
	-- logit("start test")
	-- local startTimestamp = getTimestampWithoutHMS(tonumber(KEYS[2]))

	-- -- startTimestamp = new_timetable(2015, 5, 11, 0, 0, 0, 0, 0):timestamp()

	-- logit("startTimestamp(epoch): " .. startTimestamp .. ", " .. new_from_timestamp(startTimestamp):rfc_3339())

	-- local deltaDays = tonumber(KEYS[3])

	-- local endTimestamp = startTimestamp + deltaDays * 86400 -- 86400 sec in one day
	-- logit("endTimestamp(epoch): " .. endTimestamp .. ", " .. new_from_timestamp(endTimestamp):rfc_3339())
	
	-- local accOfIndex = tonumber(KEYS[4])

	-- logit("accOfIndex: " .. accOfIndex)

	-- for i,v in ipairs(KEYS) do
	-- 	logit("KEYS[" .. i .. "]: " .. v)
	-- end

	-- local lengthOfDB = lengthOfDB()

	-- logit("lengthOfDB: " .. lengthOfDB)

	-- local lowerBoundIndex = getLowerBoundIndexOfTimestamp(startTimestamp, accOfIndex, lengthOfDB)

	-- logit("lowerBoundIndex: " .. lowerBoundIndex)

	-- local higherBoundIndex = getHigherBoundIndexOfTimestamp(endTimestamp, accOfIndex, lengthOfDB)

	-- logit("higherBoundIndex: " .. higherBoundIndex)

	-- walkIndexOfTimestamp(accOfIndex, lengthOfDB)

	-- return calculateDeviceDataWithIndex(lowerBoundIndex, higherBoundIndex, startTimestamp, endTimestamp)

end

-- local presidents = {
-- 	{lname = "Obama", fname = "Barack", from = 2009, to = nil},
-- 	{lname = "Bush", fname = "George W", from = 2001, to = 2008},
-- 	{lname = "Bush", fname = "George HW", from = 1989, to = 1992},
-- 	{lname = "Clinton", fname = "Bill", from = 1993, to = 2000}
-- }

-- logit("before add, number of presidents:" .. #presidents )

-- for i,v in ipairs(presidents) do
-- 	logit("i: " .. i)
-- 	logit(table_to_json(v))
-- end

-- table.insert(presidents, 
--    {fname = "Ronald", lname = "Reagan", from = 1981, to = 1988}
-- )

-- -- local uuid = "1234-5678"
-- -- test[uuid] = { key = 'value'} 
-- -- -- table.insert(test, uuid)

-- logit("after add, number of presidents:" .. #presidents )

-- for i,v in ipairs(presidents) do
-- 	logit("i: " .. i)
-- 	logit(table_to_json(v))
-- end
-- 


-- local test = { number = 6}
-- logit('test[number]: '.. test["number"])

-- test['uuid'] = "12345678"

-- logit('test[uuid]: '.. test["uuid"])

-- local uuid= '1234-5678'
-- test[uuid] = "hello world"

-- logit('test['.. uuid ..']: '.. test[uuid])


-- logit("before add, number of test:" .. #test )

-- for i,v in pairs(test) do
-- 	logit("i: " .. i)
-- 	logit(table_to_json(v))
-- end


logit("finished Main")

return 0
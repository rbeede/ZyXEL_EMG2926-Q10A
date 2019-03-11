-----------------------------------------------------------
-- CONST
-----------------------------------------------------------
local DB_NAME = "eventdb:events"
local PrecalculatedDB_NAME = "eventdb:perDevicePrecalculated"
local DBnUsageInfo = "eventdb:dbNUsageInfo"
local NodeHistoryDB_NAME = "nodehistory:nodes"
local NodeDBPrefix = "nodedb:mac:"
local DiffSecondsToPerformCalculation = 90000 -- 1 day & 1 hour before calculating yesterday's data
local ExpectedDBVersion = {main = 0, sub = 1}

-----------------------------------------------------------
-- Name of log saved on redis for debug purpose
-- Delete previous log
-----------------------------------------------------------
local loglist = KEYS[2]
redis.pcall("DEL", loglist)


-----------------------------------------------------------
-- Push log
-----------------------------------------------------------
local function logit(msg)
  redis.pcall("RPUSH", loglist, msg)
end

-----------------------------------------------------------
-- Parse from timezoneOffset and return diff offset in seconds
-- for calculation.
-----------------------------------------------------------
local function secondsOffsetFromTimeZone(timezoneOffset)
  local lengthOfOffset = string.len(timezoneOffset)
  if lengthOfOffset < 4 or lengthOfOffset > 5 then
    return 0
  end

  local sign = string.sub(timezoneOffset, 1, 1)

  if sign ~= "+" and sign ~= "-" then
    return 0
  end

  local hours = 0
  local minutes = 0

  if lengthOfOffset == 4 then
    hours = tonumber(string.sub(timezoneOffset, 2, 2))
    minutes = tonumber(string.sub(timezoneOffset, 3, 4))
  else
    hours = tonumber(string.sub(timezoneOffset, 2, 3))
    minutes = tonumber(string.sub(timezoneOffset, 4, 5))
  end

  local offsetSeconds = hours * 3600 + minutes * 60

  if sign == "+" then
      return offsetSeconds
  else
      return -offsetSeconds
  end
end -- secondsOffsetFromTimeZone

-----------------------------------------------------------
-- Push pushDeviceData
-----------------------------------------------------------
local function pushDeviceData(stringfyDeviceData)
  redis.pcall("LPUSH", PrecalculatedDB_NAME, stringfyDeviceData)
end

-----------------------------------------------------------
-- Push nodeHistory
-----------------------------------------------------------
local function pushNodeHistoryData(stringfyData)
  redis.pcall("SET", NodeHistoryDB_NAME, stringfyData)
end

-----------------------------------------------------------
-- Save DBnUsageInfo
-----------------------------------------------------------
local function pushDBnUsageInfo(stringfyData)
  redis.pcall("SET", DBnUsageInfo, stringfyData)
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

local function lastDayOfDate(year, month)
    local date = new_timetable(year, month + 1, 1, 0, 0, 0, 0, 0):normalise()
    date = new_from_timestamp(date:timestamp() - 86400)
    local yearOfDate , monthOfDate , dayOfDate = date:unpack ( )
    return dayOfDate
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
	if json == nil then
		logit("json_to_table failed, json string is nil")
		return nil
	else
		return cjson.decode(json)
	end
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
-- Sorting table
-----------------------------------------------------------
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
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
	-- logit("targetTimestamp: ".. targetTimestamp .. ", startTimestamp: " .. startTimestamp .. ", endTimestamp: " .. endTimestamp)
	if endTimestamp >= targetTimestamp and targetTimestamp >= startTimestamp then
		return true
	end
	return false
end

local function isPrecalculationExistsForTimestamp(startTimestamp, endTimestamp)
	local precalculationData = redis.call('LRANGE', PrecalculatedDB_NAME, 0, -1)

	if #precalculationData == 0 then
		return 0
	end

	for i, data in ipairs(precalculationData) do
		local walkData = json_to_table(data)
		logit("startTimestamp: ".. startTimestamp .. ", walkData.startTimestamp: " .. walkData.startTimestamp .. ", endTimestamp: " .. endTimestamp .. ", walkData.endTimestamp: " .. walkData.endTimestamp)
		if walkData.startTimestamp == startTimestamp and walkData.endTimestamp == endTimestamp then
			logit("isPrecalculationExistsForTimestamp == YES!!")
			return 1
		end
	end -- for i,event in ipairs(events) do

	return 0
end

local function getLatestPrecalculatedTimestamp()
	local info = {}
	local latestJsonData = redis.call('LRANGE', PrecalculatedDB_NAME, 0, 0)

	if #latestJsonData == 0 then
		return nil
	end

	local latestData = json_to_table(latestJsonData[1])
	info.startTimestamp = latestData.startTimestamp
	info.endTimestamp = latestData.endTimestamp
	return info
end


-- Currently not implemented.
local function findOpenFlow(flowUUID)
	return nil
end

local function index5MinutesOfTimestamp(currentTimestamp, startTimestamp)
	return math.floor((currentTimestamp - startTimestamp) / 60 / 5)
end

local function indexOfHourWithIndexOf5Minutes(indexOf5Minute)
	local returnIndex = 1
	if indexOf5Minute < 12 then
		returnIndex = 1
	else
		returnIndex = math.floor(indexOf5Minute / 12) + 1
		if returnIndex > 24 then
			returnIndex = 24
		end
	end
	return returnIndex
end

local function previousIndexBeforeMilestone(currentIndex, flow)
	local resultIndex = -1
	for index, milestone in pairs(flow.milestones) do
		if currentIndex > index and resultIndex < index then
			resultIndex = index
		end
	end -- for index, milestone in pairs(flow.milestones) do

	return resultIndex
end

local function calculateDeviceData(events, startTimestamp, endTimestamp, secondsTimeZoneOffset)
	local flowData = {}
	logit("start getDeviceData")
	for i,event in ipairs(events) do
        event.time = tonumber(event.time) + secondsTimeZoneOffset
		if ((event.event == "open" or event.event == "milestone" or event.event == "close") and (isTimeBetweenRange(event.time, startTimestamp, endTimestamp) == true)) then

			local uuid = event.uuid

			if (flowData[uuid] == nil) then
	            -- create new if nil
	            flowData[uuid] = {}

		        -- add part to regogize flow and device
		        flowData[uuid].uuid        = event.uuid
		        flowData[uuid].flow_id     = event.flow_id

		        flowData[uuid].milestones = {}

		        flowData[uuid].openTime    = event.time

	            -- logit("create flowData[".. uuid .. "], now number of flowData: ".. #flowData)
			end -- if (flowData[uuid] == nil) then

            local parsedRx = parseIntFilterNaN(event.details.rx_bytes)
            local parsedTx = parseIntFilterNaN(event.details.tx_bytes)

            flowData[uuid].rx_bytes = parsedRx
            flowData[uuid].tx_bytes = parsedTx
            flowData[uuid].closeTime   = event.time

            local index5Minutes = index5MinutesOfTimestamp(event.time, startTimestamp)
            -- logit("index5Minutes: ".. index5Minutes)

            if flowData[uuid].milestones[index5Minutes] == nil then
            	flowData[uuid].milestones[index5Minutes] = {}
	            flowData[uuid].milestones[index5Minutes].rx_bytes = parsedRx
    	        flowData[uuid].milestones[index5Minutes].tx_bytes = parsedTx
    	    elseif (flowData[uuid].milestones[index5Minutes].rx_bytes < parsedRx or flowData[uuid].milestones[index5Minutes].rx_bytes < parsedTx) then
	            flowData[uuid].milestones[index5Minutes].rx_bytes = parsedRx
    	        flowData[uuid].milestones[index5Minutes].tx_bytes = parsedTx
           	end -- if flowData[uuid].milestones[index5Minutes] == nil then

           	if(event.event == "open") then
           		flowData[uuid].policy_id   = event.details.policy_id
           		flowData[uuid].mac          = event.mac
           	end -- if(event.event == "open") then

			-- logit(i .. ") event : ")
			-- logit(table_to_json(event))
			-- logit("uuid: " .. uuid)

	        -- logit("flowData[".. uuid .. "].uuid: " .. flowData[uuid].uuid)
	        -- logit("flowData[".. uuid .. "].flow_id: " .. flowData[uuid].flow_id)

		end -- if ((event.event == "open" or event.event == "milestone" or event.event == "close") and

	end -- for i,event in ipairs(events) do

	-- calculate rx_total & tx_total & peakRx peakTx from milestones
    for flowUUID, flow in pairs(flowData) do

		local lastIndex = -1

		-- first calculate delta between milestones
	    for index, milestone in pairs(flow.milestones) do

	    	lastIndex = previousIndexBeforeMilestone(index, flow)

	    	if lastIndex == -1 then -- first of milestone
				if flow.policy_id ~= nil then
		    		milestone.rx_deltaBytes = milestone.rx_bytes
		    		milestone.tx_deltaBytes = milestone.tx_bytes
		    		-- logit("first of milestone and is open flow, flowUUID:" .. flowUUID)
				else
		    		milestone.rx_deltaBytes = 0
		    		milestone.tx_deltaBytes = 0
				end
	    	else

	    		local deltaRx = milestone.rx_bytes - flow.milestones[lastIndex].rx_bytes
	    		local deltaTx = milestone.tx_bytes - flow.milestones[lastIndex].tx_bytes
	    		if deltaRx < 0 then
	    			deltaRx = 0
	    		end
	    		if deltaTx < 0 then
	    			deltaTx = 0
	    		end

		    	-- logit(" ")
		    	-- logit("index: " .. index)
		    	-- logit("milestone.rx_bytes: " .. milestone.rx_bytes)
		    	-- logit("lastIndex: " .. lastIndex)
		    	-- logit("flow.milestones[lastIndex].rx_bytes: " .. flow.milestones[lastIndex].rx_bytes)
		    	-- logit("deltaRx: " .. deltaRx)

	    		milestone.rx_deltaBytes = deltaRx
	    		milestone.tx_deltaBytes = deltaTx
	    	end -- if lastIndex ~= -1 then

	    	-- logit("index: " .. index)
	    	-- logit(table_to_json(milestone))

	    end -- for index, milestone in pairs(flow.milestones) do

	    -- local peakTx = 0
	    -- local peakTxTimestamp = 0
	    -- local peakRx = 0
	    -- local peakRxTimestamp = 0
	    local rx_TotalFromMilestone = 0
	    local tx_TotalFromMilestone = 0
		-- find peak transfer peek and add total delta
	    for index, milestone in pairs(flow.milestones) do
	    	-- if peakTx < milestone.tx_deltaBytes then
	    	-- 	peakTx = milestone.tx_deltaBytes
	    	-- 	peakTxTimestamp = index * 60 * 5 + flow.openTime
	    	-- end
	    	-- if peakRx < milestone.rx_deltaBytes then
	    	-- 	peakRx = milestone.rx_deltaBytes
	    	-- 	peakRxTimestamp = index * 60 * 5 + flow.openTime
	    	-- end
	    	milestone.rx_bytes = nil
	    	milestone.tx_bytes = nil
	    	rx_TotalFromMilestone = rx_TotalFromMilestone + milestone.rx_deltaBytes
	    	tx_TotalFromMilestone = tx_TotalFromMilestone + milestone.tx_deltaBytes
	    end -- for index, milestone in pairs(flow.milestones) do

	    -- Remove milestones
	    -- flow.milestones = nil

	    if flow.rx_bytes ~= rx_TotalFromMilestone then
	    	-- logit("flow.rx_bytes ~= rx_TotalFromMilestone (".. flow.rx_bytes ..", ".. rx_TotalFromMilestone .."), using mileStone data.")
	    	flow.rx_bytes = rx_TotalFromMilestone
	    end

	    if flow.tx_bytes ~= tx_TotalFromMilestone then
	    	-- logit("flow.tx_bytes ~= tx_TotalFromMilestone (".. flow.tx_bytes ..", ".. tx_TotalFromMilestone .."), using mileStone data.")
	    	flow.tx_bytes = tx_TotalFromMilestone
	    end

		-- logit(table_to_json(flow))

    end -- for flowUUID, flow in pairs(flowData) do

	-- logit("flowData: ")
	-- logit(table_to_json(flowData))

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

		-- logit('flow: ')
		-- logit(table_to_json(flow))

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
                -- init the flow
                deviceData.devices[mac].flows[flowPolicyID] = {};

                -- init milestones
                deviceData.devices[mac].flows[flowPolicyID].milestones = flow.milestones;

                -- init flow byte counts
                deviceData.devices[mac].flows[flowPolicyID].rx_bytes   = 0;
                deviceData.devices[mac].flows[flowPolicyID].tx_bytes   = 0;
                deviceData.devices[mac].flows[flowPolicyID].uptime = 0;
            else -- concat milestones
			    for index, milestone in pairs(flow.milestones) do
			    	if deviceData.devices[mac].flows[flowPolicyID].milestones[index] == nil then
			    		deviceData.devices[mac].flows[flowPolicyID].milestones[index] = milestone
			    	else
			    		deviceData.devices[mac].flows[flowPolicyID].milestones[index].rx_deltaBytes = deviceData.devices[mac].flows[flowPolicyID].milestones[index].rx_deltaBytes + milestone.rx_deltaBytes
			    		deviceData.devices[mac].flows[flowPolicyID].milestones[index].tx_deltaBytes = deviceData.devices[mac].flows[flowPolicyID].milestones[index].tx_deltaBytes + milestone.tx_deltaBytes
			    	end
			    end -- for index, milestone in pairs(flow.milestones) do
            end

            -- do byte count
            deviceData.devices[mac].flows[flowPolicyID].rx_bytes = deviceData.devices[mac].flows[flowPolicyID].rx_bytes + nRx;
            deviceData.devices[mac].flows[flowPolicyID].tx_bytes = deviceData.devices[mac].flows[flowPolicyID].tx_bytes + nTx;

            -- do device byte counts
            deviceData.devices[mac].rx_total = deviceData.devices[mac].rx_total + nRx;
            deviceData.devices[mac].tx_total = deviceData.devices[mac].tx_total + nTx;

            -- uptime
            local uptime = 0

            if flow.closeTime ~= nil and flow.openTime ~= nil then
               uptime = flow.closeTime - flow.openTime
            end

            deviceData.devices[mac].flows[flowPolicyID].uptime = deviceData.devices[mac].flows[flowPolicyID].uptime + uptime

            -- do flow percent
            -- deviceData.devices[mac].flows[flowPolicyID].rx_percent = ((deviceData.devices[mac].flows[flowPolicyID].rx_bytes/deviceData.rx_total)*100).toFixed(2);
            -- deviceData.devices[mac].flows[flowPolicyID].tx_percent = ((deviceData.devices[mac].flows[flowPolicyID].tx_bytes/deviceData.tx_total)*100).toFixed(2);



            -- do device  percent
            -- deviceData.devices[mac].rx_percent = ((deviceData.devices[mac].rx_total/deviceData.rx_total)*100).toFixed(2);
            -- deviceData.devices[mac].tx_percent = ((deviceData.devices[mac].tx_total/deviceData.tx_total)*100).toFixed(2);
        end -- if mac ~= nil then
    end -- for flowUUID, flow in pairs(flowData) do

    -- Calculate delta tx rx of each flowPolicyID
    -- Calculate delta tx rx of each device
    local macPeakMilestones = {}
    local flowPeakMilestones = {}
    local overallPeakMilestones = {}
    for mac, deviceInfo in pairs(deviceData.devices) do
    	-- logit("mac: " .. mac)
    	for flowPolicyID, flow in pairs(deviceInfo.flows) do
    		-- logit("  flowPolicyID: " .. flowPolicyID)
    		-- logit("===============================")
    		local walkingTimePeriod = nil
    		local flowUpTimeNotOverlappedInMinutes = 0
    		local rxHourly = {0,0,0,0,0,
                              0,0,0,0,0,
                              0,0,0,0,0,
                              0,0,0,0,0,
                              0,0,0,0}
            local txHourly = {0,0,0,0,0,
                              0,0,0,0,0,
                              0,0,0,0,0,
                              0,0,0,0,0,
                              0,0,0,0}
    		for index, milestone in spairs(flow.milestones, function(t,a,b) return tonumber(a) < tonumber(b) end) do
    		 	-- logit("    index: " .. index .. ", milestone: " .. table_to_json(milestone))

    		 	if walkingTimePeriod == nil then
    		 		walkingTimePeriod = {}
    		 		walkingTimePeriod.startIndex = index
    		 	end

                local indexOfFiveMinutes = indexOfHourWithIndexOf5Minutes(index)
		 		rxHourly[indexOfFiveMinutes] = rxHourly[indexOfFiveMinutes] + milestone.rx_deltaBytes
                txHourly[indexOfFiveMinutes] = txHourly[indexOfFiveMinutes] + milestone.tx_deltaBytes

    		 	local nextIndex = tonumber(index) + 1

    		 	if flow.milestones[nextIndex] == nil then

    		 		walkingTimePeriod.endIndex = index
    		 		flowUpTimeNotOverlappedInMinutes = flowUpTimeNotOverlappedInMinutes + (walkingTimePeriod.endIndex - walkingTimePeriod.startIndex + 1) * 5
    		 		-- logit("    > nextIndex: " .. nextIndex .. " is the end of series, walkingTimePeriod: " .. table_to_json(walkingTimePeriod) .. ", flowUpTimeNotOverlappedInMinutes is now: " .. flowUpTimeNotOverlappedInMinutes)

    		 		walkingTimePeriod = nil
    		 	else

    		 	end

    		 	if overallPeakMilestones[index] == nil then
    		 		overallPeakMilestones[index] = {}
    		 		overallPeakMilestones[index].rx_deltaBytes = milestone.rx_deltaBytes
    		 		overallPeakMilestones[index].tx_deltaBytes = milestone.tx_deltaBytes
    		 		overallPeakMilestones[index].total_deltaBytes = overallPeakMilestones[index].rx_deltaBytes + overallPeakMilestones[index].tx_deltaBytes
    		 	else
    		 		overallPeakMilestones[index].rx_deltaBytes = overallPeakMilestones[index].rx_deltaBytes + milestone.rx_deltaBytes
    		 		overallPeakMilestones[index].tx_deltaBytes = overallPeakMilestones[index].tx_deltaBytes + milestone.tx_deltaBytes
    		 		overallPeakMilestones[index].total_deltaBytes = overallPeakMilestones[index].rx_deltaBytes + overallPeakMilestones[index].tx_deltaBytes
    		 	end

    		 	if macPeakMilestones[mac] == nil then
    		 		macPeakMilestones[mac] = {}
    		 		macPeakMilestones[mac].milestones = {}
    		 	end
    		 	if macPeakMilestones[mac].milestones[index] == nil then
    		 		macPeakMilestones[mac].milestones[index] = {}
    		 		macPeakMilestones[mac].milestones[index].rx_deltaBytes = milestone.rx_deltaBytes
    		 		macPeakMilestones[mac].milestones[index].tx_deltaBytes = milestone.tx_deltaBytes
    		 		macPeakMilestones[mac].milestones[index].total_deltaBytes = macPeakMilestones[mac].milestones[index].rx_deltaBytes + macPeakMilestones[mac].milestones[index].tx_deltaBytes
    		 	else
    		 		macPeakMilestones[mac].milestones[index].rx_deltaBytes = macPeakMilestones[mac].milestones[index].rx_deltaBytes + milestone.rx_deltaBytes
    		 		macPeakMilestones[mac].milestones[index].tx_deltaBytes = macPeakMilestones[mac].milestones[index].tx_deltaBytes + milestone.tx_deltaBytes
    		 		macPeakMilestones[mac].milestones[index].total_deltaBytes = macPeakMilestones[mac].milestones[index].rx_deltaBytes + macPeakMilestones[mac].milestones[index].tx_deltaBytes
    		 	end

    			if flowPeakMilestones[flowPolicyID] == nil then
    		 		flowPeakMilestones[flowPolicyID] = {}
    		 		flowPeakMilestones[flowPolicyID].milestones = {}
    		 	end
    		 	if flowPeakMilestones[flowPolicyID].milestones[index] == nil then
    		 		flowPeakMilestones[flowPolicyID].milestones[index] = {}
    		 		flowPeakMilestones[flowPolicyID].milestones[index].rx_deltaBytes = milestone.rx_deltaBytes
    		 		flowPeakMilestones[flowPolicyID].milestones[index].tx_deltaBytes = milestone.tx_deltaBytes
    		 		flowPeakMilestones[flowPolicyID].milestones[index].total_deltaBytes = flowPeakMilestones[flowPolicyID].milestones[index].rx_deltaBytes + flowPeakMilestones[flowPolicyID].milestones[index].tx_deltaBytes
    		 	else
    		 		flowPeakMilestones[flowPolicyID].milestones[index].rx_deltaBytes = flowPeakMilestones[flowPolicyID].milestones[index].rx_deltaBytes + milestone.rx_deltaBytes
    		 		flowPeakMilestones[flowPolicyID].milestones[index].tx_deltaBytes = flowPeakMilestones[flowPolicyID].milestones[index].tx_deltaBytes + milestone.tx_deltaBytes
    		 		flowPeakMilestones[flowPolicyID].milestones[index].total_deltaBytes = flowPeakMilestones[flowPolicyID].milestones[index].rx_deltaBytes + flowPeakMilestones[flowPolicyID].milestones[index].tx_deltaBytes
    		 	end

			end -- for index, milestone in pairs(flow.milestones) do

		 	-- logit("    ^ rxHourly: " .. table_to_json(rxHourly))

			-- flow.milestones = nil
			deviceData.devices[mac].flows[flowPolicyID].milestones = nil
			deviceData.devices[mac].flows[flowPolicyID].rxHourly = rxHourly
            deviceData.devices[mac].flows[flowPolicyID].txHourly = txHourly
			deviceData.devices[mac].flows[flowPolicyID].flowUpTimeNotOverlappedInMinutes = flowUpTimeNotOverlappedInMinutes

    	end -- for flowPolicyID, flow in pairs(deviceInfo.flows) do
    end -- for mac, deviceInfo in pairs(deviceData.devices) do

    local overallPeak = {}
    overallPeak.peakTx = 0
    overallPeak.peakTxTimestamp = 0
    overallPeak.peakRx = 0
    overallPeak.peakRxTimestamp = 0
    overallPeak.peakOverall = 0
    overallPeak.peakOverallTimestamp = 0
    overallPeak.peakTxByHour = {0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0}
    overallPeak.peakRxByHour = {0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0}

    -- logit("*** overallPeakMilestones:" )
	for index, milestone in pairs(overallPeakMilestones) do
		-- logit("  index: " .. index .. ", milestone: " .. table_to_json(milestone))
        if overallPeak.peakTx < milestone.tx_deltaBytes then
			overallPeak.peakTx = milestone.tx_deltaBytes
			overallPeak.peakTxTimestamp = index * 60 * 5 + startTimestamp
        end
        if overallPeak.peakRx < milestone.rx_deltaBytes then
			overallPeak.peakRx = milestone.rx_deltaBytes
			overallPeak.peakRxTimestamp = index * 60 * 5 + startTimestamp
        end
        if overallPeak.peakOverall < milestone.total_deltaBytes then
			overallPeak.peakOverall = milestone.total_deltaBytes
			overallPeak.peakOverallTimestamp = index * 60 * 5 + startTimestamp
        end

        local indexOfHour = indexOfHourWithIndexOf5Minutes(index)
        if overallPeak.peakTxByHour[indexOfHour] < milestone.tx_deltaBytes then
            overallPeak.peakTxByHour[indexOfHour] = milestone.tx_deltaBytes
        end
        if overallPeak.peakRxByHour[indexOfHour] < milestone.rx_deltaBytes then
            overallPeak.peakRxByHour[indexOfHour] = milestone.rx_deltaBytes
        end
	end -- for index, milestone in pairs(milestones) do

    local macPeak = {}
    -- Calculate peak for each mac
    for mac, milestones in pairs(macPeakMilestones) do
    	-- logit("mac: " .. mac)
	    local peakTx = 0
	    local peakTxTimestamp = 0
	    local peakRx = 0
	    local peakRxTimestamp = 0
	    local peakOverall = 0
	    local peakOverallTimestamp = 0
      local peakTxByHour = {0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0}
      local peakRxByHour = {0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0}

    	for index, milestone in pairs(milestones.milestones) do
    		-- logit("  index: " .. index .. ", milestone: " .. table_to_json(milestone))
            if peakTx < milestone.tx_deltaBytes then
				peakTx = milestone.tx_deltaBytes
				peakTxTimestamp = index * 60 * 5 + startTimestamp
            end
            if peakRx < milestone.rx_deltaBytes then
				peakRx = milestone.rx_deltaBytes
				peakRxTimestamp = index * 60 * 5 + startTimestamp
            end
	        if peakOverall < milestone.total_deltaBytes then
				peakOverall = milestone.total_deltaBytes
				peakOverallTimestamp = index * 60 * 5 + startTimestamp
	        end

            local indexOfHour = indexOfHourWithIndexOf5Minutes(index)
            if peakTxByHour[indexOfHour] < milestone.tx_deltaBytes then
                peakTxByHour[indexOfHour] = milestone.tx_deltaBytes
            end
            if peakRxByHour[indexOfHour] < milestone.rx_deltaBytes then
                peakRxByHour[indexOfHour] = milestone.rx_deltaBytes
            end

    	end -- for index, milestone in pairs(milestones) do
    	macPeak[mac] = {}
    	macPeak[mac].peak = {}
    	macPeak[mac].peak.peakTx = peakTx
    	macPeak[mac].peak.peakTxTimestamp = peakTxTimestamp
    	macPeak[mac].peak.peakRx = peakRx
    	macPeak[mac].peak.peakRxTimestamp = peakRxTimestamp
    	macPeak[mac].peak.peakOverall = peakOverall
    	macPeak[mac].peak.peakOverallTimestamp = peakOverallTimestamp
      macPeak[mac].peak.peakTxByHour = peakTxByHour
      macPeak[mac].peak.peakRxByHour = peakRxByHour
    end -- for mac, milestones in pairs(macPeakMilestones) do

    local flowPeak = {}
    -- Calculate peak for each mac
    for flowPolicyID, milestones in pairs(flowPeakMilestones) do
    	-- logit("flowPolicyID: " .. flowPolicyID)
	    local peakTx = 0
	    local peakTxTimestamp = 0
	    local peakRx = 0
	    local peakRxTimestamp = 0
	    local peakOverall = 0
	    local peakOverallTimestamp = 0
      local peakTxByHour = {0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0}
      local peakRxByHour = {0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0}
    	for index, milestone in pairs(milestones.milestones) do
    		-- logit("  index: " .. index .. ", milestone: " .. table_to_json(milestone))
            if peakTx < milestone.tx_deltaBytes then
				peakTx = milestone.tx_deltaBytes
				peakTxTimestamp = index * 60 * 5 + startTimestamp
            end
            if peakRx < milestone.rx_deltaBytes then
				peakRx = milestone.rx_deltaBytes
				peakRxTimestamp = index * 60 * 5 + startTimestamp
            end
	        if peakOverall < milestone.total_deltaBytes then
				peakOverall = milestone.total_deltaBytes
				peakOverallTimestamp = index * 60 * 5 + startTimestamp
	        end

            local indexOfHour = indexOfHourWithIndexOf5Minutes(index)
            if peakTxByHour[indexOfHour] < milestone.tx_deltaBytes then
                peakTxByHour[indexOfHour] = milestone.tx_deltaBytes
            end
            if peakRxByHour[indexOfHour] < milestone.rx_deltaBytes then
                peakRxByHour[indexOfHour] = milestone.rx_deltaBytes
            end
    	end -- for index, milestone in pairs(milestones) do
    	flowPeak[flowPolicyID] = {}
    	flowPeak[flowPolicyID].peak = {}
    	flowPeak[flowPolicyID].peak.peakTx = peakTx
    	flowPeak[flowPolicyID].peak.peakTxTimestamp = peakTxTimestamp
    	flowPeak[flowPolicyID].peak.peakRx = peakRx
    	flowPeak[flowPolicyID].peak.peakRxTimestamp = peakRxTimestamp
    	flowPeak[flowPolicyID].peak.peakOverall = peakOverall
    	flowPeak[flowPolicyID].peak.peakOverallTimestamp = peakOverallTimestamp
      flowPeak[flowPolicyID].peak.peakTxByHour = peakTxByHour
      flowPeak[flowPolicyID].peak.peakRxByHour = peakRxByHour
    end -- for mac, milestones in pairs(macPeakMilestones) do

	-- logit("macPeak: " .. table_to_json(macPeak))
	-- logit("flowPeak: " .. table_to_json(flowPeak))

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

	deviceData.macPeak = macPeak
	deviceData.flowPeak = flowPeak
	deviceData.overallPeak = overallPeak

	return deviceData
end -- local function getDeviceData(events)
    --

local function getNodeHistoryDB()
	local data = redis.call('GET', NodeHistoryDB_NAME)
	-- logit('getNodeHistoryDB data:')
	-- logit(data)
	if data == false then
		-- logit('no data, return nil')
		data = nil
	end
	return json_to_table(data)
end

local function getDBnUsageInfo()
	local data = redis.call('GET', DBnUsageInfo)
	if data == false then
        data = {}
        data.mainVersion = 0
        data.subVersion = 0
        data.resetDay = 1
        data.quotaUsage = 0
        data.currentDataUsage = 0
        data.warningThreshold = 0
        data.hasSentMail = 0
        data.lastSentMailTimestamp = 0
		return data
    else
        return json_to_table(data)
	end
end

local function deletePrecalculatedWhenDBVersionUp()
    local dbusageInfo = getDBnUsageInfo()
    if ExpectedDBVersion.main > dbusageInfo.mainVersion or (ExpectedDBVersion.main == dbusageInfo.mainVersion and ExpectedDBVersion.sub > dbusageInfo.subVersion ) then
        dbusageInfo.mainVersion = ExpectedDBVersion.main
        dbusageInfo.subVersion = ExpectedDBVersion.sub
        redis.pcall("DEL", PrecalculatedDB_NAME)

        local stringfyData = table_to_json(dbusageInfo)
        pushDBnUsageInfo(stringfyData)
    end
end

local function dateRangeWithTimestamp(currentTimestamp, timezoneOffset, resetDay)

        local secondsTimeZoneOffset = secondsOffsetFromTimeZone(timezoneOffset)

        currentTimestamp = currentTimestamp + secondsTimeZoneOffset

        -- logit("currentTimestamp(epoch): " .. currentTimestamp .. ", " .. new_from_timestamp(currentTimestamp):rfc_3339())
        local t = new_from_timestamp(currentTimestamp)

        local today = new_timetable(t.year, t.month, t.day, 0, 0, 0, 0, 0)
        logit("today(epoch, no HMS): " .. today:timestamp() .. ", " .. today:rfc_3339())

        resetDay = tonumber(resetDay)
        logit("resetDay: " .. resetDay);
        local lastDayOfWorkingDate = lastDayOfDate(t.year, t.month)

        local workingDate = nil
        if resetDay > lastDayOfWorkingDate then
            workingDate = new_timetable(t.year, t.month, lastDayOfWorkingDate, 0, 0, 0, 0, 0):normalise()
        else
            workingDate = new_timetable(t.year, t.month, resetDay, 0, 0, 0, 0, 0):normalise()
        end

        -- logit("workingDate(epoch): " .. workingDate:timestamp() .. ", " .. workingDate:rfc_3339())

        local dateRange = {}
        if workingDate:timestamp() <= today:timestamp() then
            local lastDay = lastDayOfDate(workingDate.year, workingDate.month + 1)
            if resetDay > lastDay then
                resetDay = lastDay
            end
            local rangeEnd = new_timetable(workingDate.year, workingDate.month +1, resetDay, 23, 59, 59, 0, 0):normalise()
            rangeEnd = new_from_timestamp(rangeEnd:timestamp() - 86400)
            dateRange = { rangeStart = workingDate, rangeEnd = rangeEnd }
        else
            local lastDay = lastDayOfDate(workingDate.year, workingDate.month - 1)
            if resetDay > lastDay then
                resetDay = lastDay
            end
            local rangeStart = new_timetable(workingDate.year, workingDate.month -1, resetDay, 0, 0, 0, 0, 0):normalise()
            local rangeEnd = new_timetable(workingDate.year, workingDate.month, workingDate.day -1, 23, 59, 59, 0, 0):normalise()
            dateRange = { rangeStart = rangeStart, rangeEnd = rangeEnd }
        end

        logit("dateRange.rangeStart(epoch): " .. dateRange.rangeStart:timestamp() .. ", " .. dateRange.rangeStart:rfc_3339())
        logit("dateRange.rangeEnd(epoch): " .. dateRange.rangeEnd:timestamp() .. ", " .. dateRange.rangeEnd:rfc_3339())
        logit("==========================")
        return dateRange
end

local function getNameOfNodeWithMAC(mac)
	-- logit('getNameOfNodeWithMAC data:')
	local data = redis.call('GET', NodeDBPrefix .. mac .. ":name")
	-- logit('getNameOfNodeWithMAC data:')
	-- logit(data)
	if data == false then
		-- logit('no data, return nil')
		data = nil
	end
	return data
end

local function getOSTypeOfNodeWithMAC(mac)
	-- logit('getOSTypeOfNodeWithMAC data:')
	local data = redis.call('GET', NodeDBPrefix .. mac .. ":type")
	-- logit('getOSTypeOfNodeWithMAC data:')
	-- logit(data)
	if data == false then
		-- logit('no data, return nil')
		data = nil
	end
	return data
end

local function getIPAddressesOfNodeWithMAC(mac)
	-- logit('getIPAddressOfNodeWithMAC data:')
	local data = redis.call('SORT', NodeDBPrefix .. mac .. ":ipaddr", "ALPHA")
	-- logit('getOSTypeOfNodeWithMAC data:')
	-- logit(data)
	if data == false then
		-- logit('no data, return nil')
		data = nil
	end
	return data
end

local function appendNodeHistoryWithDeviceData(deviceData, currentTimestamp, writeDB)

	local nodeHistory = {}

	local retrivedNodeHistory = getNodeHistoryDB()
	-- logit("retrivedNodeHistory: ")
	-- logit(retrivedNodeHistory)

	if retrivedNodeHistory ~= nil then
		nodeHistory = retrivedNodeHistory
	else
		logit('retrivedNodeHistory is nil')
	end -- if nodeHistoryLength == 0 then

	if deviceData.devices == nil then
		logit("deviceData.devices is nil, stop calculation appendNodeHistoryWithDeviceData")
		return 0
	end

	for mac, deviceInfo in pairs(deviceData.devices) do
		if nodeHistory[mac] == nil then
			nodeHistory[mac] = {}
			nodeHistory[mac].rx_total = 0
			nodeHistory[mac].tx_total = 0
		end

		-- get Name
		local name = getNameOfNodeWithMAC(mac)

		if name ~= nil and string.len(name) > 0 then
			nodeHistory[mac].name = name
			-- logit('node name:'..nodeHistory[mac].name)
		end

		-- get OSType
		local osType = getOSTypeOfNodeWithMAC(mac)

		if osType ~= nil and string.len(osType) > 0 then
			nodeHistory[mac].osType = osType
		end

		-- get OSType
		local ipAddresses = getIPAddressesOfNodeWithMAC(mac)

		if ipAddresses ~= nil then
			nodeHistory[mac].ipAddresses = ipAddresses
		end

		-- tx, rx
		if deviceInfo.rx_total ~= nil then
			nodeHistory[mac].rx_total = nodeHistory[mac].rx_total + deviceInfo.rx_total
			nodeHistory[mac].epoch_last_change = currentTimestamp
		end
		if deviceInfo.tx_total ~= nil then
			nodeHistory[mac].tx_total = nodeHistory[mac].tx_total + deviceInfo.tx_total
			nodeHistory[mac].epoch_last_change = currentTimestamp
		end
		-- logit('mac:')
		-- logit(mac)
		-- logit('deviceInfo:')
		-- logit(deviceInfo)
		-- for i, v in pairs(deviceInfo) do
		-- 	logit('i:')
		-- 	logit(i)
		-- 	logit('v:')
		-- 	logit(v)
		-- end
	end -- for mac, flowData in pairs(deviceData.devices) do
	-- logit("appendNodeHistory result:")
	-- logit(table_to_json(nodeHistory))
	if writeDB == 1 then
		pushNodeHistoryData(table_to_json(nodeHistory))
	else
		return nodeHistory
	end
end -- appendNodeHistory()

-- outputType: 0: return appended history node
--            1: writeDB & return calculated timestamp
--            2: outputDeviceData
local function calculateDeviceDataWithIndex(lowerBoundIndex, higherBoundIndex, startTimestamp, endTimestamp, currentTimestamp, secondsTimeZoneOffset, outputType)
	local events = redis.call('LRANGE', DB_NAME, lowerBoundIndex, higherBoundIndex)
	if #events == 0 then return {ok='done'} end

	logit("number of events: " .. #events)

	local ret = {}

	-- convert events retrieved from redis into event objects
	for i,v in ipairs(events) do
		-- logit("event: ")
		-- logit(v)
		local event = csv_to_table(v)

		-- logit("converted: ")
		-- logit(table_to_json(event))

		ret[#ret+1] = event
	end

	local deviceData = calculateDeviceData(ret, startTimestamp, endTimestamp, secondsTimeZoneOffset)

	if outputType == 1 then
        logit("writeDB")
		appendNodeHistoryWithDeviceData(deviceData, currentTimestamp, 1)
		local jsonDeviceData = table_to_json(deviceData)
		logit("jsonDeviceData: ")
		logit(jsonDeviceData)
		pushDeviceData(jsonDeviceData)
		return startTimestamp
    elseif outputType == 2 then
        -- change endTimestamp so it wont be filtered out due to currentTime.
        deviceData.endTimestamp = deviceData.startTimestamp + 1;
        logit("outputDeviceData")
        local jsonDeviceData = table_to_json(deviceData)
		logit("jsonDeviceData: ")
		logit(jsonDeviceData)
        return table_to_json(deviceData)
	else
        logit("return appended history node")
		return appendNodeHistoryWithDeviceData(deviceData, currentTimestamp, 0)
	end

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


local function getHigherBoundIndexOfTimestamp(targetTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)

	for i=lengthOfDB -1, -accOfIndex, -accOfIndex do
		local index = i
		if i < 0 then
			index = 0
		end
		local timestamp = getTimestampOfIndex(index) + secondsTimeZoneOffset
		if timestamp > targetTimestamp then
			index = index + accOfIndex
			if index > lengthOfDB then
				index = lengthOfDB -1
			end
			return index
		end
	end

	return lengthOfDB -1

end -- local function getHigherBoundIndexOfTimestamp

local function getLowerBoundIndexOfTimestamp(targetTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)
  logit('lengthOfDB:')
  logit(lengthOfDB)
	for i=lengthOfDB -1, -accOfIndex, -accOfIndex do
		local index = i
		if i < 0 then
			index = 0
		end
		local timestamp = getTimestampOfIndex(index) + secondsTimeZoneOffset
		if timestamp < targetTimestamp then
			index = index - accOfIndex
			if index < 0 then
				index = 0
			end
			return index
		end
	end

	return 0

end -- getLowerBoundIndexOfTimestamp(targetTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)

local function tr069FormatOfNodeHistory(nodeHistory)

	local tr069Nodes = {}

	tr069Nodes.nodes = {}

	if nodeHistory == nil then
		table.insert(tr069Nodes.nodes, {})
		return tr069Nodes
	end
	for mac, deviceInfo in pairs(nodeHistory) do
		local tr069Device = {}
		tr069Device.Pipeline = {}
		-- tr069Device.UI = {}
		tr069Device.Pipeline.default_prio = 242
		tr069Device.Pipeline.static = false
		tr069Device.Pipeline.connected = 0
		tr069Device.Pipeline.mac_addr = mac
		tr069Device.Pipeline.name = deviceInfo.name
		tr069Device.Pipeline.wireless = false
		tr069Device.Pipeline.RSSI = -1
		tr069Device.Pipeline.epoch_last_change = deviceInfo.epoch_last_change
		tr069Device.Pipeline.ip_addr_list = deviceInfo.ipAddresses
		tr069Device.Pipeline.uid = mac
		tr069Device.Pipeline.up = deviceInfo.tx_total
		tr069Device.Pipeline.epoch = deviceInfo.epoch_last_change
		tr069Device.Pipeline.ip_addr = deviceInfo.ipAddresses[1]
		tr069Device.Pipeline.type = deviceInfo.osType
		tr069Device.Pipeline.connections = "/cgi-bin/ozker/api/flows?mac=" .. mac
		tr069Device.Pipeline.up_limit = 30000000
		tr069Device.Pipeline.down = deviceInfo.rx_total
		tr069Device.Pipeline.down_limit = 60000000

		-- logit('mac:')
		-- logit(mac)
		-- logit('deviceInfo:')
		-- logit(deviceInfo)
		-- for i, v in pairs(deviceInfo) do
		-- 	logit('i:')
		-- 	logit(i)
		-- 	logit('v:')
		-- 	logit(v)
		-- end
		table.insert(tr069Nodes.nodes, tr069Device)
	end -- for mac, flowData in pairs(deviceData.devices) do
	return tr069Nodes
end -- tr069FormatOfNodeHistory(nodeHistory)

local function appendCurrentNodeInfoWithNodeHistory(currentTimestamp, accOfIndex, secondsTimeZoneOffset)
	local startTimestamp = 0
	local endTimestamp = currentTimestamp
	local timestamps = getLatestPrecalculatedTimestamp()
	if timestamps ~= nil then
		startTimestamp = timestamps.endTimestamp
	end

	logit("do patch data between: " .. new_from_timestamp(startTimestamp):rfc_3339() .. " to " .. new_from_timestamp(endTimestamp):rfc_3339() )

	local lengthOfDB = lengthOfDB()

    logit("lengthOfDB: " .. lengthOfDB)

    local lowerBoundIndex = getLowerBoundIndexOfTimestamp(startTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)

    logit("lowerBoundIndex: " .. lowerBoundIndex)

    local higherBoundIndex = getHigherBoundIndexOfTimestamp(endTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)

    logit("higherBoundIndex: " .. higherBoundIndex)

    -- walkIndexOfTimestamp(accOfIndex, lengthOfDB)

    local patchedNodeHistory = calculateDeviceDataWithIndex(lowerBoundIndex, higherBoundIndex, startTimestamp, endTimestamp, currentTimestamp, secondsTimeZoneOffset, 0)

    -- logit("patchedNodeHistory: ")
    -- logit(table_to_json(patchedNodeHistory))
    return patchedNodeHistory
end -- appendCurrentNodeInfoWithNodeHistory(nodeHistory)

local function jsonStringOfHistoryInTR069Format(isAppendRealtimeData, currentTimestamp, accOfIndex, secondsTimeZoneOffset)

	local nodeHistory = {}

	local retrivedNodeHistory = nil

	if isAppendRealtimeData == 1 then
		retrivedNodeHistory = appendCurrentNodeInfoWithNodeHistory(currentTimestamp, accOfIndex, secondsTimeZoneOffset)
		logit("nodeHistory after concated: " .. table_to_json(retrivedNodeHistory))
	else
		retrivedNodeHistory = getNodeHistoryDB()
		logit("nodeHistory without concated: " .. table_to_json(retrivedNodeHistory))
	end

	if retrivedNodeHistory ~= nil then
		nodeHistory = tr069FormatOfNodeHistory(retrivedNodeHistory)
		logit("tr069FormatOfNodeHistory: " .. table_to_json(nodeHistory))
	end -- if retrivedNodeHistory ~= nil then

    -- logit("jsonStringOfHistoryInTR069Format: ")
    -- logit(table_to_json(nodeHistory))

	return table_to_json(nodeHistory)

end -- jsonStringOfHistoryInTR069Format()

-----------------------------------------------------------
-- doPrecalculation
-- return 0 if error
--        epoch time if successful
-----------------------------------------------------------
local function doPrecalculation()

	if #KEYS < 8 then
		logit("number of parameters not match, exit")
		return 0
	end

	local startTimestamp = tonumber(KEYS[3])
	local currentTimestamp = tonumber(KEYS[6])

    local timezoneOffset = KEYS[7]
	logit("timezoneOffset: " .. timezoneOffset)

    local secondsTimeZoneOffset = secondsOffsetFromTimeZone(timezoneOffset)
    logit("secondsOffsetFromTimeZone: " .. secondsTimeZoneOffset)

    local outputType = tonumber(KEYS[8])
	logit("outputType: " .. outputType)

    startTimestamp = startTimestamp + secondsTimeZoneOffset
    currentTimestamp = currentTimestamp + secondsTimeZoneOffset

    logit("startTimestamp(epoch): " .. startTimestamp .. ", " .. new_from_timestamp(startTimestamp):rfc_3339())
	logit("currentTimestamp(epoch): " .. currentTimestamp .. ", " .. new_from_timestamp(currentTimestamp):rfc_3339())

	local diffSeconds = currentTimestamp - startTimestamp

	logit("diffSeconds: " .. diffSeconds)

	if diffSeconds < 30 and diffSeconds > -30 then
		-- request for calculating latest data
		local timestamps = getLatestPrecalculatedTimestamp()
		if timestamps == nil then
			-- no previous data, calculate data from yesterday.
			startTimestamp = startTimestamp - 86400 -- 86400 sec in one day
		else
			logit("timestamps.startTimestamp: " .. timestamps.startTimestamp .. ", " .. new_from_timestamp(timestamps.startTimestamp):rfc_3339())
			logit("timestamps.endTimestamp: " .. timestamps.endTimestamp .. ", " .. new_from_timestamp(timestamps.endTimestamp):rfc_3339())
			if startTimestamp - DiffSecondsToPerformCalculation > timestamps.endTimestamp then
				-- its already over 1 day & 1 hour, calculate yesterday's data
				startTimestamp = startTimestamp - 86400
			else
				logit("diffSeconds is : " .. (startTimestamp - timestamps.endTimestamp) .. ", must be over " .. DiffSecondsToPerformCalculation .. " to proceed.")
				return 0
			end
		end
	else
		-- Its best to check if current timestamp has been calculated,
		-- but right now just give it a free pass.
	end

	startTimestamp = getTimestampWithoutHMS(startTimestamp)

	logit("startTimestamp without HMS(epoch): " .. startTimestamp .. ", " .. new_from_timestamp(startTimestamp):rfc_3339())

	local deltaDays = tonumber(KEYS[4])

	local endTimestamp = startTimestamp + deltaDays * 86400 -- 86400 sec in one day
	logit("endTimestamp(epoch): " .. endTimestamp .. ", " .. new_from_timestamp(endTimestamp):rfc_3339())

	if outputType == 1 and isPrecalculationExistsForTimestamp(startTimestamp, endTimestamp) == 1 then
		logit("timestamp already exists in precalculation data")
		return 0
	end

	local accOfIndex = tonumber(KEYS[5])

	logit("accOfIndex: " .. accOfIndex)

	-- for i,v in ipairs(KEYS) do
	-- 	logit("KEYS[" .. i .. "]: " .. v)
	-- end

	local lengthOfDB = lengthOfDB()

	logit("lengthOfDB: " .. lengthOfDB)

	local lowerBoundIndex = getLowerBoundIndexOfTimestamp(startTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)

	logit("lowerBoundIndex: " .. lowerBoundIndex)

	local higherBoundIndex = getHigherBoundIndexOfTimestamp(endTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)

	logit("higherBoundIndex: " .. higherBoundIndex)

	-- walkIndexOfTimestamp(accOfIndex, lengthOfDB)
	return calculateDeviceDataWithIndex(lowerBoundIndex, higherBoundIndex, startTimestamp, endTimestamp, currentTimestamp, secondsTimeZoneOffset, outputType)

end


-----------------------------------------------------------
-- fetchNodeHistory
-- return 0 if error
--        json string of data if success
-----------------------------------------------------------
local function fetchNodeHistory()

	if #KEYS < 6 then
		logit("number of parameters not match, exit")
		return 0
	end

	local currentTimestamp = tonumber(KEYS[3])

  local timezoneOffset = tonumber(KEYS[6])
	logit("timezoneOffset: " .. timezoneOffset)

  local secondsTimeZoneOffset = secondsOffsetFromTimeZone(timezoneOffset)
  logit("secondsOffsetFromTimeZone: " .. secondsTimeZoneOffset)

  currentTimestamp = currentTimestamp + secondsTimeZoneOffset

	logit("currentTimestamp(epoch): " .. currentTimestamp .. ", " .. new_from_timestamp(currentTimestamp):rfc_3339())

	local isAppendRealtimeData = tonumber(KEYS[4])

	logit("isAppendRealtimeData: " .. isAppendRealtimeData)

	local accOfIndex = tonumber(KEYS[5])

	logit("fetchNodeHistory, accOfIndex: " .. accOfIndex)

	return jsonStringOfHistoryInTR069Format(isAppendRealtimeData, currentTimestamp, accOfIndex, secondsTimeZoneOffset)

end

local function calculateDeviceDataOnlyWithTimestamp(startTimestamp, endTimestamp, secondsTimeZoneOffset)
    local accOfIndex = 500
	local lengthOfDB = lengthOfDB()
	local lowerBoundIndex = getLowerBoundIndexOfTimestamp(startTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)
	local higherBoundIndex = getHigherBoundIndexOfTimestamp(endTimestamp, secondsTimeZoneOffset, accOfIndex, lengthOfDB)
	local currentTimestamp = startTimestamp
	return calculateDeviceDataWithIndex(lowerBoundIndex, higherBoundIndex, startTimestamp, endTimestamp, currentTimestamp, secondsTimeZoneOffset, 2)
end

local function lookupTotalTransferWithPrecalculatedDataInDataRange(dataRange, currentTimestamp, timezoneOffset)

    local precalculationData = redis.call('LRANGE', PrecalculatedDB_NAME, 0, -1)
    local startTimestamp = dataRange.rangeStart:timestamp()
    local endTimestamp = dataRange.rangeEnd:timestamp()

    logit("startTimestamp: " .. startTimestamp .. ", endTimestamp: " .. endTimestamp)

    local secondsTimeZoneOffset = secondsOffsetFromTimeZone(timezoneOffset)
    currentTimestamp = currentTimestamp + secondsTimeZoneOffset

    -- logit("currentTimestamp(epoch): " .. currentTimestamp .. ", " .. new_from_timestamp(currentTimestamp):rfc_3339())
    local t = new_from_timestamp(currentTimestamp)

    local currentTimestampNoHMS = new_timetable(t.year, t.month, t.day, 0, 0, 0, 0, 0)
    logit("currentTimestampNoHMS(epoch, no HMS): " .. currentTimestampNoHMS:timestamp() .. ", " .. currentTimestampNoHMS:rfc_3339())

    local deltaDays = 1
	local endTimestamp = currentTimestampNoHMS:timestamp() + deltaDays * 86400 -- 86400 sec in one day

    local transferData = {rx= 0, tx= 0}

    precalculationData[#precalculationData+1]= calculateDeviceDataOnlyWithTimestamp(currentTimestampNoHMS:timestamp(), endTimestamp, secondsTimeZoneOffset)

	if #precalculationData == 0 then
		return transferData
	end

	for i, data in ipairs(precalculationData) do
		local walkData = json_to_table(data)
		-- logit("startTimestamp: ".. startTimestamp .. ", walkData.startTimestamp: " .. walkData.startTimestamp .. ", endTimestamp: " .. endTimestamp .. ", walkData.endTimestamp: " .. walkData.endTimestamp)
		if walkData.startTimestamp >= startTimestamp and walkData.startTimestamp <= endTimestamp and walkData.endTimestamp >= startTimestamp and walkData.endTimestamp <= endTimestamp then
			-- logit("isPrecalculationExistsForTimestamp == YES!!")
			transferData.rx = transferData.rx + walkData.rx_total
            transferData.tx = transferData.tx + walkData.tx_total
		end
	end -- for i,event in ipairs(events) do

	return transferData
end

local function needToResetSendMailFlag(currentTimestamp, timezoneOffset, resetDay, hasSentMail, lastSentMailTimestamp)
    -- egg
    local secondsTimeZoneOffset = secondsOffsetFromTimeZone(timezoneOffset)
    currentTimestamp = currentTimestamp + secondsTimeZoneOffset

    -- logit("currentTimestamp(epoch): " .. currentTimestamp .. ", " .. new_from_timestamp(currentTimestamp):rfc_3339())
    local t = new_from_timestamp(currentTimestamp)

    local currentTimestampNoHMS = new_timetable(t.year, t.month, t.day, 0, 0, 0, 0, 0)
    logit("currentTimestampNoHMS(epoch, no HMS): " .. currentTimestampNoHMS:timestamp() .. ", " .. currentTimestampNoHMS:rfc_3339())

    local lastDayOfWorkingDate = lastDayOfDate(t.year, t.month)

    if resetDay > lastDayOfWorkingDate then
        resetDay = lastDayOfWorkingDate
    end

    if lastSentMailTimestamp == nil then
        lastSentMailTimestamp = 0
    end

    local diffTimestamp = currentTimestamp - lastSentMailTimestamp
    logit("t.day: " .. t.day .. ", resetDay: " .. resetDay .. ", lastSentMailTimestamp: " .. lastSentMailTimestamp .. ", diffTimestamp: " .. diffTimestamp)

    if t.day == resetDay and lastSentMailTimestamp ~= 0 and hasSentMail == 1 and diffTimestamp > 86400  then
        return 1
    end

    return 0

end

-----------------------------------------------------------
-- Main
-----------------------------------------------------------

cjson.encode_sparse_array(true)

deletePrecalculatedWhenDBVersionUp()

if KEYS[1] == "preCalculation" then
	return doPrecalculation()
elseif KEYS[1] == "fetchNodeHistory" then
	return fetchNodeHistory()
elseif KEYS[1] == "fetchUsageInfo" then
    if tonumber(KEYS[3]) == 0 then
        return table_to_json(getDBnUsageInfo())
    else
        local resetDay = tonumber(KEYS[4])
        local quotaUsage = tonumber(KEYS[5])
        local warningThreshold = tonumber(KEYS[6])
        local dbusageInfo = getDBnUsageInfo()
        dbusageInfo.resetDay = resetDay
        dbusageInfo.quotaUsage = quotaUsage
        dbusageInfo.warningThreshold = warningThreshold
        dbusageInfo.currentDataUsage = 0
        dbusageInfo.hasSentMail = 0
        dbusageInfo.lastSentMailTimestamp = 0
        local stringfyData = table_to_json(dbusageInfo)
        pushDBnUsageInfo(stringfyData)
        return stringfyData
    end
elseif KEYS[1] == "usageAlert" then

    local currentTimestamp = tonumber(KEYS[3])
    local timezoneOffset = KEYS[4]
    local dbUsageInfo = getDBnUsageInfo()

    local dateRange = dateRangeWithTimestamp(currentTimestamp, timezoneOffset, dbUsageInfo.resetDay)

    logit("quota: " .. dbUsageInfo.quotaUsage)

    local totalTransferData = lookupTotalTransferWithPrecalculatedDataInDataRange(dateRange, currentTimestamp, timezoneOffset)

    logit("totalTxRx: " .. table_to_json(totalTransferData))

    local sum = totalTransferData.tx + totalTransferData.rx
    logit("totalTransferData: " .. sum)

    local needsResetMailFlag = needToResetSendMailFlag(currentTimestamp, timezoneOffset, dbUsageInfo.resetDay, dbUsageInfo.hasSentMail, dbUsageInfo.lastSentMailTimestamp)
    if needsResetMailFlag == 1 then
        logit("needsResetMailFlag")
        dbUsageInfo.hasSentMail = 0
        dbUsageInfo.lastSentMailTimestamp = 0
        local stringfyData = table_to_json(dbUsageInfo)
        pushDBnUsageInfo(stringfyData)
    end

    -- Only do warning check when user has set criteria.
    if dbUsageInfo.quotaUsage > 0 and dbUsageInfo.warningThreshold > 0 then
        local quotaRatio = 0  --  in percentage

        if dbUsageInfo.quotaUsage > sum then
            quotaRatio =  ( dbUsageInfo.quotaUsage - sum ) / dbUsageInfo.quotaUsage * 100
        end
        logit("quotaRatio: " .. quotaRatio .. ", warningThreshold:" .. dbUsageInfo.warningThreshold)
        if quotaRatio <= dbUsageInfo.warningThreshold then
            if dbUsageInfo.hasSentMail == 0 then
                logit("exeed quota, send mail!")
                dbUsageInfo.hasSentMail = 1
                dbUsageInfo.lastSentMailTimestamp = currentTimestamp + secondsOffsetFromTimeZone(timezoneOffset)
                local stringfyData = table_to_json(dbUsageInfo)
                pushDBnUsageInfo(stringfyData)
                local returnRemainingDataUsage = 0
                if dbUsageInfo.quotaUsage > sum then
                    returnRemainingDataUsage = (dbUsageInfo.quotaUsage - sum) / 1000000
                end
                return returnRemainingDataUsage
            else
                logit("exeed quota, but already send mail, so do nothing!")
                return -1
            end
        end
    end -- if dbUsageInfo.quotaUsage > 0 and dbUsageInfo.warningThreshold > 0 then

    return -1

end

return 0

-----------------------------------------------------------
-- CONST
-----------------------------------------------------------
local DB_NAME = "eventdb:events"

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
  -- redis.pcall("RPUSH", loglist, msg)
end

local function getTimestampOfIndex(index)
	local events = redis.call('LRANGE', DB_NAME, index, index)
	if #events == 0 then 
		return nil
	end	

	-- get timestamp from first of array
	for i,v in ipairs(events) do

		-- time
		local s,e,pos

		pos = 1
		-- event id
		s,e = string.find(v,',',pos)
		local id = tonumber(string.sub(v,pos,e - 1))

		pos = e + 1
		-- time
		s,e = string.find(v,',',pos)
		-- logit(string.sub(v,pos,e - 1))
		return tonumber(string.sub(v,pos,e - 1))
	end
	return nil
end

local function getLowerBoundIndexOfTimestamp(targetTimestamp, accOfIndex, lengthOfDB)

	for i=lengthOfDB -1, -accOfIndex, -accOfIndex do
		local index = i
		if i < 0 then
			index = 0
		end
		local timestamp = getTimestampOfIndex(index)
		logit('timestamp: ' .. timestamp)
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

local function lengthOfDB()
  return tonumber(redis.call("LLEN", DB_NAME))
end

-----------------------------------------------------------
-- Main
-----------------------------------------------------------
logit("start Main")

local startTimestamp = tonumber(KEYS[2])	

logit("startTimestamp: " .. startTimestamp)

local accOfIndex = tonumber(KEYS[3])

logit("accOfIndex: " .. accOfIndex)

local lengthOfDB = lengthOfDB()

logit("lengthOfDB: " .. lengthOfDB)

local lowerBoundIndex = getLowerBoundIndexOfTimestamp(startTimestamp, accOfIndex, lengthOfDB)

logit("lowerBoundIndex: " .. lowerBoundIndex)

logit("finished Main")

return lowerBoundIndex
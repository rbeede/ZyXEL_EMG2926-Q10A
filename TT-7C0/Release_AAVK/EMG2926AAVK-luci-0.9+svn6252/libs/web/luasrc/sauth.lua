--[[

Session authentication
(c) 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id: sauth.lua 5190 2009-07-31 23:36:15Z jow $

]]--

--- LuCI session library.
module("luci.sauth", package.seeall)
require("luci.util")
require("luci.sys")
require("luci.config")
local nixio = require "nixio", require "nixio.util"
local fs = require "nixio.fs"
-- Modification for future time setting error, EMG2926-Q10A, WenHsiang, 2011/12/07
local uci = require("luci.model.uci").cursor()  
-- Modification for future time setting error, EMG2926-Q10A, WenHsiang, 2011/12/07

luci.config.sauth = luci.config.sauth or {}
sessionpath = luci.config.sauth.sessionpath
sessiontime = tonumber(luci.config.sauth.sessiontime)

--- Manually clean up expired sessions.
--[[
--Modifaication for recognize the user's session ID, EMG2926-Q10A, Bruce, 2012/12/10
function clean()
--Modifaication for recognize the user's session ID, EMG2926-Q10A, Bruce, 2012/12/10
]]--
function clean(id)
	local now   = os.time()
	local files = fs.dir(sessionpath)
	local nowS = luci.sys.uptime()
--[[
-- Modification for future time setting error, EMG2926-Q10A, WenHsiang, 2011/12/07	
	local change_TimeSetting = uci:get("time","main","change_TimeSetting")  
-- Modification for future time setting error, EMG2926-Q10A, WenHsiang, 2011/12/07
]]--	
	if not files then
		return nil
	end
	
	for file in files do
		local fname = sessionpath .. "/" .. file
		local stat = fs.stat(fname)
--[[
-- Modification for future time setting error, EMG2926-Q10A, WenHsiang, 2011/12/07, 2011/12/12		
		if change_TimeSetting == "1" then
		   stat.mtime = now
		   uci:set("time","main","change_TimeSetting","0")
		   uci:commit("time")
		end
-- Modification for future time setting error, EMG2926-Q10A, WenHsiang, 2011/12/07, 2011/12/12
]]--
		--change calculated session timeout method from ntp-time to system uptime		
		--if sessiontime > 0 and stat and stat.type == "reg" and stat.mtime + sessiontime < now then

--[[
--Modification for adding a condition, EMG2926-Q10A, Bruce, 2012/12/10
		if sessiontime > 0 and stat and stat.type == "reg" and stat.mtime + sessiontime < nowS then
--Modification for adding a condition, EMG2926-Q10A, Bruce, 2012/12/10
]]--
		if sessiontime > 0 and stat and file == id and stat.type == "reg" and stat.mtime + sessiontime < nowS then

	           fs.unlink(fname)

                   require("luci.template")
                
                   local dsp = require "luci.dispatcher"
                   local sauth = require "luci.sauth"
                   if dsp.context.authsession then
                      sauth.kill(dsp.context.authsession)
                      dsp.context.urltoken.stok = nil
                   end

                   luci.template.render("redirect_index")
		end
                
	end
end

--- Prepare session storage by creating the session directory.
function prepare()
	fs.mkdir(sessionpath, 700)
	 
	if not sane() then
		error("Security Exception: Session path is not sane!")
	end
end

--- Read a session and return its content.
-- @param id	Session identifier
-- @return		Session data
function read(id)
	if not id or #id == 0 then
		return
	end
	if not id:match("^%w+$") then
		error("Session ID is not sane!")
	end
        -- adding the session ID index to function clean(),    Bruce, 2012/12/10
	clean(id)
	if not sane(sessionpath .. "/" .. id) then
		return
	end
	--change stime from ntp-time to system-up-time for logout time setting
        local stime = luci.sys.uptime()
        fs.utimes(sessionpath .. "/" .. id,stime,stime)

	return fs.readfile(sessionpath .. "/" .. id)
end


--- Check whether Session environment is sane.
-- @return Boolean status
function sane(file)
	return luci.sys.process.info("uid")
			== fs.stat(file or sessionpath, "uid")
		and fs.stat(file or sessionpath, "modestr")
			== (file and "rw-------" or "rwx------")
end


--- Write session data to a session file.
-- @param id	Session identifier
-- @param data	Session data
function write(id, data)
	if not sane() then
		prepare()
	end
	if not id:match("^%w+$") then
		error("Session ID is not sane!")
	end
	
	local f = nixio.open(sessionpath .. "/" .. id, "w", 600)
	f:writeall(data)
	f:close()
end


--- Kills a session
-- @param id	Session identifier
function kill(id)
	if not id:match("^%w+$") then
		error("Session ID is not sane!")
	end
	fs.unlink(sessionpath .. "/" .. id)
end

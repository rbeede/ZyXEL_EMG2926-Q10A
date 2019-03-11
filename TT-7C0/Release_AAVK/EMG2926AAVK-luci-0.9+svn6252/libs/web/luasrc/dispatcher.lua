--[[
LuCI - Dispatcher

Description:
The request dispatcher and module dispatcher generators

FileId:
$Id: dispatcher.lua 6425 2010-11-13 20:51:15Z jow $

License:
Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]--

--- LuCI web dispatcher.
local fs = require "nixio.fs"
local sys = require "luci.sys"
local init = require "luci.init"
local util = require "luci.util"
local http = require "luci.http"
local nixio = require "nixio", require "nixio.util"
local uci = require("luci.model.uci").cursor()

module("luci.dispatcher", package.seeall)
context = util.threadlocal()

authenticator = {}

-- Index table
local index = nil

-- Fastindex
local fi


--- Build the URL relative to the server webroot from given virtual path.
-- @param ...	Virtual path
-- @return 		Relative URL
function build_url(...)
	local path = {...}
	local url = { http.getenv("SCRIPT_NAME") or "" }

	local k, v
	for k, v in pairs(context.urltoken) do
		url[#url+1] = "/;"
		url[#url+1] = http.urlencode(k)
		url[#url+1] = "="
		url[#url+1] = http.urlencode(v)
	end

	local p
	for _, p in ipairs(path) do
		if p:match("^[a-zA-Z0-9_%-%.%%/,;]+$") then
			url[#url+1] = "/"
			url[#url+1] = p
		end
	end

	return table.concat(url, "")
end

--- Send a 404 error code and render the "error404" template if available.
-- @param message	Custom error message (optional)
-- @return			false
function error404(message)
	luci.http.status(404, "Not Found")
	message = message or "Not Found"

	require("luci.template")
	if not luci.util.copcall(luci.template.render, "error404") then
		luci.http.prepare_content("text/plain")
		luci.http.write(message)
	end
	return false
end

--- Send a 500 error code and render the "error500" template if available.
-- @param message	Custom error message (optional)#
-- @return			false
function error500(message)
	luci.util.perror(message)
	if not context.template_header_sent then
		luci.http.status(500, "Internal Server Error")
		luci.http.prepare_content("text/plain")
		luci.http.write(message)
	else
		require("luci.template")
		if not luci.util.copcall(luci.template.render, "error500", {message=message}) then
			luci.http.prepare_content("text/plain")
			luci.http.write(message)
		end
	end
	return false
end

function authenticator.htmlauth(validator, accs, default)
	local user = luci.http.formvalue("username")
	local pass = luci.http.formvalue("password")
	
	-- Modify "Password Visible in Source Code" for Login, EMG2926-Q10A, WenHsiang, 2012/05/10
	local chk_pass = luci.http.formvalue("login_error")
    --
	
	if user and validator(user, pass) then
		return user
	end
	
    -- Modify "Password Visible in Source Code" for Login, EMG2926-Q10A, WenHsiang, 2012/05/10	
    if user then
		luci.http.redirect(luci.dispatcher.build_url() .. "?login_error=1")
    end
    --

	require("luci.i18n")
	require("luci.template")
	context.path = {}
	
	sys.exec("rm -f /var/weather")
	sys.exec("rm -f /var/weather_code")
	sys.exec("rm -f /var/weather_temp")

	luci.template.render("sysauth", {
		duser=default, 
		fuser=user,
		city = uci:get("system","main","weather_city"),
		degree = uci:get("system","main","weather_degree"),
		timeindex = uci:get("time","main","tzIndex"),
    -- Modify "Password Visible in Source Code" for Login, EMG2926-Q10A, WenHsiang, 2012/05/10
		chk_password = chk_pass
    --
	})
	return false

end

--- Dispatch an HTTP request.
-- @param request	LuCI HTTP Request object
function httpdispatch(request, prefix)
	luci.http.context.request = request

	local r = {}
	context.request = r
	local pathinfo = http.urldecode(request:getenv("PATH_INFO") or "", true)

	if prefix then
		for _, node in ipairs(prefix) do
			r[#r+1] = node
		end
	end

	for node in pathinfo:gmatch("[^/]+") do
		r[#r+1] = node
	end

	local stat, err = util.coxpcall(function()
		dispatch(context.request)
	end, error500)

	luci.http.close()

	--context._disable_memtrace()
end

--- Dispatches a LuCI virtual path.
-- @param request	Virtual path
function dispatch(request)
	--context._disable_memtrace = require "luci.debug".trap_memtrace("l")
	local ctx = context
	ctx.path = request
	ctx.urltoken   = ctx.urltoken or {}

	local conf = require "luci.config"
	assert(conf.main,
		"/etc/config/luci seems to be corrupt, unable to find section 'main'")

	local lang = conf.main.lang or "auto"
	if lang == "auto" then
		local aclang = http.getenv("HTTP_ACCEPT_LANGUAGE") or ""
		for lpat in aclang:gmatch("[%w-]+") do
			lpat = lpat and lpat:gsub("-", "_")
			if conf.languages[lpat] then
				lang = lpat
				break
			end
		end
	end
	require "luci.i18n".setlanguage(lang)

	local c = ctx.tree
	local stat
	if not c then
		c = createtree()
	end

	local track = {}
	local args = {}
	ctx.args = args
	ctx.requestargs = ctx.requestargs or args
	local n
	local t = true
	local token = ctx.urltoken
	local preq = {}
	local freq = {}

	for i, s in ipairs(request) do
		local tkey, tval
		if t then
			tkey, tval = s:match(";(%w+)=([a-fA-F0-9]*)")
		end

		if tkey then
			token[tkey] = tval
		else
			t = false
			preq[#preq+1] = s
			freq[#freq+1] = s
			c = c.nodes[s]
			n = i
			if not c then
				break
			end

			util.update(track, c)

			if c.leaf then
				break
			end
		end
	end

	if c and c.leaf then
		for j=n+1, #request do
			args[#args+1] = request[j]
			freq[#freq+1] = request[j]
		end
	end

	ctx.requestpath = freq
	ctx.path = preq

	if track.i18n then
		require("luci.i18n").loadc(track.i18n)
	end

	-- Init template engine
	if (c and c.index) or not track.notemplate then
		local tpl = require("luci.template")
		local media = track.mediaurlbase or luci.config.main.mediaurlbase
		if not pcall(tpl.Template, "themes/%s/header" % fs.basename(media)) then
			media = nil
			for name, theme in pairs(luci.config.themes) do
				if name:sub(1,1) ~= "." and pcall(tpl.Template,
				 "themes/%s/header" % fs.basename(theme)) then
					media = theme
				end
			end
			assert(media, "No valid theme found")
		end

		tpl.context.viewns = setmetatable({
		   write       = luci.http.write;
		   include     = function(name) tpl.Template(name):render(getfenv(2)) end;
		   translate   = function(...) return require("luci.i18n").translate(...) end;
		   striptags   = util.striptags;
		   media       = media;
		   theme       = fs.basename(media);
		   resource    = luci.config.main.resourcebase
		}, {__index=function(table, key)
			if key == "controller" then
				return build_url()
			elseif key == "REQUEST_URI" then
				return build_url(unpack(ctx.requestpath))
			else
				return rawget(table, key) or _G[key]
			end
		end})
	end
--for get weather, EMG2926-Q10A, john, 2011/03/25
	local getWeather = luci.http.formvalue("getWeather", true)
	
	if getWeather then
		sys.get_weather()
		luci.http.status(404, "Not Found")
		return
	end
--

--for check weather, EMG2926-Q10A, john, 2011/03/25
	local checkWeather = luci.http.formvalue("checkWeather", true)
	
	if checkWeather then
		local fd,msg,err = io.open("/var/weather", "r")
		
		if not err then
			fd:close()
			
			sys.exec("cat /tmp/weather | grep 'condition' | sed 's/^.*code=\"//g' | sed 's/\".*$//g' > /var/weather_code")
			sys.exec("cat /tmp/weather | grep 'condition' | sed 's/^.*temp=\"//g' | sed 's/\".*$//g' > /var/weather_temp")
			
			local w_code,w_city,w_temp,w_unit = sys.parse_weather()
			
			luci.http.status(200, w_code .. "|" .. w_city .. "|" .. w_temp .. "|" .. w_unit)
		else
			luci.http.status(404, "Not Found")
		end
		
		return
	end
--

--Change Language for eaZy123, EMG2926-Q10A, WenHsiang, 2011/12/09
        local lang_easy = luci.http.formvalue("language_easy", true)
        if lang_easy then
                uci:set("system","main","language",lang_easy)
                uci:commit("system")
                luci.template.render("genie")
		return
        end		
--Change Language for eaZy123, EMG2926-Q10A, WenHsiang, 2011/12/09

--for applying weather and time immidiately, EMG2926-Q10A, john, 2011/03/21	 
	local weatherCity = luci.http.formvalue("weatherCity", true)
	local weatherDegree = luci.http.formvalue("weatherDegree", true)
	local timeZone = luci.http.formvalue("timeZone", true)
	local timeIndex = luci.http.formvalue("timeIndex", true)
	--local defaultUser = luci.http.formvalue("username")

        local lang = luci.http.formvalue("language", true)
        if lang then
                uci:set("system","main","language",lang)
                uci:commit("system")
                luci.template.render("sysauth", {
                        --duser = defaultUser,
                        city = uci:get("system","main","weather_city"),
                        degree = uci:get("system","main","weather_degree"),
                        timeindex = uci:get("time","main","tzIndex")
                })
		return
        end
	
	if weatherCity and weatherDegree or timeZone then
		uci:set("system","main","weather_city", weatherCity)
		uci:set("system","main","weather_degree", weatherDegree)
		uci:commit("system")
		uci:apply("system")
		
		if timeZone then 
			uci:set("time","main","timezone",timeZone)
			uci:set("time","main","tzIndex",timeIndex)
			uci:set("time","main","mode","NTP")
			uci:commit("time")
			uci:apply("time")
		end
		
		sys.exec("rm -f /var/weather")
		sys.exec("rm -f /var/weather_code")
		sys.exec("rm -f /var/weather_temp")
	
		luci.template.render("sysauth", {
			--duser = defaultUser,
			city = uci:get("system","main","weather_city"),
			degree = uci:get("system","main","weather_degree"),
			timeindex = uci:get("time","main","tzIndex")
		})	
		return
	end
--
	track.dependent = (track.dependent ~= false)
	assert(not track.dependent or not track.auto, "Access Violation")

	if track.sysauth then
		local sauth = require "luci.sauth"

		local authen = type(track.sysauth_authenticator) == "function"
		 and track.sysauth_authenticator
		 or authenticator[track.sysauth_authenticator]

		local def  = (type(track.sysauth) == "string") and track.sysauth
		local accs = def and {track.sysauth} or track.sysauth
		local sess = ctx.authsession
		local verifytoken = false
		if not sess then
			sess = luci.http.getcookie("sysauth")
			sess = sess and sess:match("^[a-f0-9]*$")
			verifytoken = true
		end

		local sdat = sauth.read(sess)
		local user

		if sdat then
			sdat = loadstring(sdat)
			setfenv(sdat, {})
			sdat = sdat()
			if not verifytoken or ctx.urltoken.stok == sdat.token then
				user = sdat.user
			end
		else
			local eu = http.getenv("HTTP_AUTH_USER")
			local ep = http.getenv("HTTP_AUTH_PASS")
			if eu and ep and luci.sys.user.checkpasswd(eu, ep) then
				authen = function() return eu end
			end
		end
-- for language configuration
--		local lang = luci.http.formvalue("language", true)
--		if lang then
--			uci:set("system","main","language",lang)
--			uci:commit("system")
--		end
--
		if not util.contains(accs, user) then
			if authen then
				ctx.urltoken.stok = nil
				local user, sess = authen(luci.sys.user.checkpasswd, accs, def)
				if not user or not util.contains(accs, user) then
					return
				else
					local sid = sess or luci.sys.uniqueid(16)
					if not sess then
						local token = luci.sys.uniqueid(16)
						sauth.write(sid, util.get_bytecode({
							user=user,
							token=token,
							secret=luci.sys.uniqueid(16)
						}))
						ctx.urltoken.stok = token
					end
					luci.http.header("Set-Cookie", "sysauth=" .. sid.."; path="..build_url())
					ctx.authsession = sid
					ctx.authuser = user
				end
			else
				luci.http.status(403, "Forbidden")
				return
			end
		else
			ctx.authsession = sess
			ctx.authuser = user
		end
	end

	if track.setgroup then
		luci.sys.process.setgroup(track.setgroup)
	end

	if track.setuser then
		luci.sys.process.setuser(track.setuser)
	end

	local target = nil
	if c then
		if type(c.target) == "function" then
			target = c.target
		elseif type(c.target) == "table" then
			target = c.target.target
		end
	end

	if c and (c.index or type(target) == "function") then
		ctx.dispatched = c
		ctx.requested = ctx.requested or ctx.dispatched
	end

	if c and c.index then
		local tpl = require "luci.template"

		if util.copcall(tpl.render, "indexer", {}) then
			return true
		end
	end

	if type(target) == "function" then
		util.copcall(function()
			local oldenv = getfenv(target)
			local module = require(c.module)
			local env = setmetatable({}, {__index=

			function(tbl, key)
				return rawget(tbl, key) or module[key] or oldenv[key]
			end})

			setfenv(target, env)
		end)

		if type(c.target) == "table" then
			target(c.target, unpack(args))
		else
			target(unpack(args))
		end
	else
		error404()
	end
end

--- Generate the dispatching index using the best possible strategy.
function createindex()
	local path = luci.util.libpath() .. "/controller/"
	local suff = { ".lua", ".lua.gz" }

	if luci.util.copcall(require, "luci.fastindex") then
		createindex_fastindex(path, suff)
	else
		createindex_plain(path, suff)
	end
end

--- Generate the dispatching index using the fastindex C-indexer.
-- @param path		Controller base directory
-- @param suffixes	Controller file suffixes
function createindex_fastindex(path, suffixes)
	index = {}

	if not fi then
		fi = luci.fastindex.new("index")
		for _, suffix in ipairs(suffixes) do
			fi.add(path .. "*" .. suffix)
			fi.add(path .. "*/*" .. suffix)
		end
	end
	fi.scan()

	for k, v in pairs(fi.indexes) do
		index[v[2]] = v[1]
	end
end

--- Generate the dispatching index using the native file-cache based strategy.
-- @param path		Controller base directory
-- @param suffixes	Controller file suffixes
function createindex_plain(path, suffixes)
	local controllers = { }
	for _, suffix in ipairs(suffixes) do
		nixio.util.consume((fs.glob(path .. "*" .. suffix)), controllers)
		nixio.util.consume((fs.glob(path .. "*/*" .. suffix)), controllers)
	end

	if indexcache then
		local cachedate = fs.stat(indexcache, "mtime")
		if cachedate then
			local realdate = 0
			for _, obj in ipairs(controllers) do
				local omtime = fs.stat(path .. "/" .. obj, "mtime")
				realdate = (omtime and omtime > realdate) and omtime or realdate
			end

			if cachedate > realdate then
				assert(
					sys.process.info("uid") == fs.stat(indexcache, "uid")
					and fs.stat(indexcache, "modestr") == "rw-------",
					"Fatal: Indexcache is not sane!"
				)

				index = loadfile(indexcache)()
				return index
			end
		end
	end

	index = {}

	for i,c in ipairs(controllers) do
		local module = "luci.controller." .. c:sub(#path+1, #c):gsub("/", ".")
		for _, suffix in ipairs(suffixes) do
			module = module:gsub(suffix.."$", "")
		end

		local mod = require(module)
		local idx = mod.index

		if type(idx) == "function" then
			index[module] = idx
		end
	end

	if indexcache then
		local f = nixio.open(indexcache, "w", 600)
		f:writeall(util.get_bytecode(index))
		f:close()
	end
end

--- Create the dispatching tree from the index.
-- Build the index before if it does not exist yet.
function createtree()
	if not index then
		createindex()
	end

	local ctx  = context
	local tree = {nodes={}}
	local modi = {}

	ctx.treecache = setmetatable({}, {__mode="v"})
	ctx.tree = tree
	ctx.modifiers = modi

	-- Load default translation
	require "luci.i18n".loadc("default")

	local scope = setmetatable({}, {__index = luci.dispatcher})

	for k, v in pairs(index) do
		scope._NAME = k
		setfenv(v, scope)
		v()
	end

	local function modisort(a,b)
		return modi[a].order < modi[b].order
	end

	for _, v in util.spairs(modi, modisort) do
		scope._NAME = v.module
		setfenv(v.func, scope)
		v.func()
	end

	return tree
end

--- Register a tree modifier.
-- @param	func	Modifier function
-- @param	order	Modifier order value (optional)
function modifier(func, order)
	context.modifiers[#context.modifiers+1] = {
		func = func,
		order = order or 0,
		module
			= getfenv(2)._NAME
	}
end

--- Clone a node of the dispatching tree to another position.
-- @param	path	Virtual path destination
-- @param	clone	Virtual path source
-- @param	title	Destination node title (optional)
-- @param	order	Destination node order value (optional)
-- @return			Dispatching tree node
function assign(path, clone, title, order)
	local obj  = node(unpack(path))
	obj.nodes  = nil
	obj.module = nil

	obj.title = title
	obj.order = order

	setmetatable(obj, {__index = _create_node(clone)})

	return obj
end

--- Create a new dispatching node and define common parameters.
-- @param	path	Virtual path
-- @param	target	Target function to call when dispatched.
-- @param	title	Destination node title
-- @param	order	Destination node order value (optional)
-- @return			Dispatching tree node
function entry(path, target, title, order)
	local c = node(unpack(path))

	c.target = target
	c.title  = title
	c.order  = order
	c.module = getfenv(2)._NAME

	return c
end

--- Fetch or create a dispatching node without setting the target module or
-- enabling the node.
-- @param	...		Virtual path
-- @return			Dispatching tree node
function get(...)
	return _create_node({...})
end

--- Fetch or create a new dispatching node.
-- @param	...		Virtual path
-- @return			Dispatching tree node
function node(...)
	local c = _create_node({...})

	c.module = getfenv(2)._NAME
	c.auto = nil

	return c
end

function _create_node(path, cache)
	if #path == 0 then
		return context.tree
	end

	cache = cache or context.treecache
	local name = table.concat(path, ".")
	local c = cache[name]

	if not c then
		local new = {nodes={}, auto=true, path=util.clone(path)}
		local last = table.remove(path)

		c = _create_node(path, cache)

		c.nodes[last] = new
		cache[name] = new

		return new
	else
		return c
	end
end

-- Subdispatchers --

--- Create a redirect to another dispatching node.
-- @param	...		Virtual path destination
function alias(...)
	local req = {...}
	return function(...)
		for _, r in ipairs({...}) do
			req[#req+1] = r
		end

		dispatch(req)
	end
end

--- Rewrite the first x path values of the request.
-- @param	n		Number of path values to replace
-- @param	...		Virtual path to replace removed path values with
function rewrite(n, ...)
	local req = {...}
	return function(...)
		local dispatched = util.clone(context.dispatched)

		for i=1,n do
			table.remove(dispatched, 1)
		end

		for i, r in ipairs(req) do
			table.insert(dispatched, i, r)
		end

		for _, r in ipairs({...}) do
			dispatched[#dispatched+1] = r
		end

		dispatch(dispatched)
	end
end


local function _call(self, ...)
	if #self.argv > 0 then
		return getfenv()[self.name](unpack(self.argv), ...)
	else
		return getfenv()[self.name](...)
	end
end

--- Create a function-call dispatching target.
-- @param	name	Target function of local controller
-- @param	...		Additional parameters passed to the function
function call(name, ...)
	return {type = "call", argv = {...}, name = name, target = _call}
end


local _template = function(self, ...)
	require "luci.template".render(self.view)
end

--- Create a template render dispatching target.
-- @param	name	Template to be rendered
function template(name)
	return {type = "template", view = name, target = _template}
end


local function _cbi(self, ...)
	local cbi = require "luci.cbi"
	local tpl = require "luci.template"
	local http = require "luci.http"

	local config = self.config or {}
	local maps = cbi.load(self.model, ...)

	local state = nil

	for i, res in ipairs(maps) do
		res.flow = config
		local cstate = res:parse()
		if cstate and (not state or cstate < state) then
			state = cstate
		end
	end

	local function _resolve_path(path)
		return type(path) == "table" and build_url(unpack(path)) or path
	end

	if config.on_valid_to and state and state > 0 and state < 2 then
		http.redirect(_resolve_path(config.on_valid_to))
		return
	end

	if config.on_changed_to and state and state > 1 then
		http.redirect(_resolve_path(config.on_changed_to))
		return
	end

	if config.on_success_to and state and state > 0 then
		http.redirect(_resolve_path(config.on_success_to))
		return
	end

	if config.state_handler then
		if not config.state_handler(state, maps) then
			return
		end
	end

	local pageaction = true
	http.header("X-CBI-State", state or 0)
	if not config.noheader then
		tpl.render("cbi/header", {state = state})
	end
	for i, res in ipairs(maps) do
		res:render()
		if res.pageaction == false then
			pageaction = false
		end
	end
	if not config.nofooter then
		tpl.render("cbi/footer", {flow = config, pageaction=pageaction, state = state, autoapply = config.autoapply})
	end
end

--- Create a CBI model dispatching target.
-- @param	model	CBI model to be rendered
function cbi(model, config)
	return {type = "cbi", config = config, model = model, target = _cbi}
end


local function _arcombine(self, ...)
	local argv = {...}
	local target = #argv > 0 and self.targets[2] or self.targets[1]
	setfenv(target.target, self.env)
	target:target(unpack(argv))
end

--- Create a combined dispatching target for non argv and argv requests.
-- @param trg1	Overview Target
-- @param trg2	Detail Target
function arcombine(trg1, trg2)
	return {type = "arcombine", env = getfenv(), target = _arcombine, targets = {trg1, trg2}}
end


local function _form(self, ...)
	local cbi = require "luci.cbi"
	local tpl = require "luci.template"
	local http = require "luci.http"

	local maps = luci.cbi.load(self.model, ...)
	local state = nil

	for i, res in ipairs(maps) do
		local cstate = res:parse()
		if cstate and (not state or cstate < state) then
			state = cstate
		end
	end

	http.header("X-CBI-State", state or 0)
	tpl.render("header")
	for i, res in ipairs(maps) do
		res:render()
	end
	tpl.render("footer")
end

--- Create a CBI form model dispatching target.
-- @param	model	CBI form model tpo be rendered
function form(model)
	return {type = "cbi", model = model, target = _form}
end

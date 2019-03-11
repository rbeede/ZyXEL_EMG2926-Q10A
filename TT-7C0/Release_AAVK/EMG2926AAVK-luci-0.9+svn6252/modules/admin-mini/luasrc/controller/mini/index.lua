--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 3908 2008-12-15 10:40:45Z Cyrus $
]]--

module("luci.controller.mini.index", package.seeall)

function index()
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate

	local root = node()
	if not root.lock then
		root.target = alias("mini")
		root.index = true
	end
	
	entry({"about"}, template("about")).i18n = "admin-core"
	
	local page   = entry({"mini"}, alias("mini", "index"), i18n("essentials", "Essentials"), 10)
	page.i18n    = "admin-core"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.index = true
	
	entry({"mini", "index"}, alias("mini", "index", "index"), i18n("overview"), 10).index = true
	entry({"mini", "index", "index"}, form("mini/index"), i18n("general"), 1).ignoreindex = true
	entry({"mini", "index", "luci"}, cbi("mini/luci", {autoapply=true}), i18n("settings"), 10)
	entry({"mini", "index", "logout"}, call("action_logout"), i18n("logout"))
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url())
end
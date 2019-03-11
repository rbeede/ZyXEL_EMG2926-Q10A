--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 4040 2009-01-16 12:35:25Z Cyrus $
]]--
module("luci.controller.admin.index", package.seeall)

function index()
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate

	local root = node()
	if not root.target then
		root.target = alias("admin")
		root.index = true
	end
	
	entry({"about"}, template("about")).i18n = "admin-core"
	
	local page   = node("admin")
	page.target  = alias("admin", "index")
	page.title   = i18n("administration", "Administration")
	page.order   = 10
	page.i18n    = "admin-core"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.ucidata = true
	page.index = true
	
	local page  = node("admin", "index")
	page.target = template("admin_index/index")
	page.title  = i18n("overview", "Übersicht")
	page.order  = 10
	page.index = true

	local page  = node("admin", "index", "luci")
	page.target = cbi("admin_index/luci")
	page.title  = i18n("a_i_ui", "Oberfläche")
	page.order  = 10

	entry({"admin", "index", "components"}, call("redir_components"), i18n("luci_components", "LuCI Components"), 20)
	entry({"admin", "index", "logout"}, call("action_logout"), i18n("logout"), 90)
end

function redir_components()
	luci.http.redirect(luci.dispatcher.build_url("admin", "system", "packages")..'?update=1&query=luci')
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

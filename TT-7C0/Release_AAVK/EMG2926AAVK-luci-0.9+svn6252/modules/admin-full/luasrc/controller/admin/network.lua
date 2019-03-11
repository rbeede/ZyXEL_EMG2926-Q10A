--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: network.lua 5752 2010-03-08 02:09:46Z jow $
]]--
module("luci.controller.admin.network", package.seeall)

function index()
	require("luci.i18n")
	local uci = require("luci.model.uci").cursor()
	local i18n = luci.i18n.translate
	local has_wifi = false
	local has_switch = false

	uci:foreach("wireless", "wifi-device",
		function(s)
			has_wifi = true
			return false
		end
	)

	uci:foreach("network", "switch",
		function(s)
			has_switch = true
			return false
		end
	)

	local page  = node("admin", "network")
	page.target = alias("admin", "network", "network")
	page.title  = i18n("network")
	page.order  = 50
	page.index  = true

	if has_switch then
		local page  = node("admin", "network", "vlan")
		page.target = cbi("admin_network/vlan")
		page.title  = i18n("a_n_switch")
		page.order  = 20
	end

	if has_wifi then
		local page = entry({"admin", "network", "wireless"}, arcombine(cbi("admin_network/wireless"), cbi("admin_network/wifi")), i18n("wifi"), 15)
		page.i18n   = "wifi"
		page.leaf = true
		page.subindex = true

		uci:foreach("wireless", "wifi-device",
			function (section)
				local ifc = section[".name"]
					entry({"admin", "network", "wireless", ifc},
					 true,
					 ifc:upper()).i18n = "wifi"
			end
		)
	end

	local page = entry({"admin", "network", "network"}, arcombine(cbi("admin_network/network"), cbi("admin_network/ifaces")), i18n("interfaces", "Schnittstellen"), 10)
	page.leaf   = true
	page.subindex = true

	uci:foreach("network", "interface",
		function (section)
			local ifc = section[".name"]
			if ifc ~= "loopback" then
				entry({"admin", "network", "network", ifc},
				 true,
				 ifc:upper())
			end
		end
	)

	local page  = node("admin", "network", "dhcp")
	page.target = cbi("admin_network/dhcp")
	page.title  = "DHCP"
	page.order  = 30

	local page  = node("admin", "network", "hosts")
	page.target = cbi("admin_network/hosts")
	page.title  = i18n("hostnames", "Hostnames")
	page.order  = 40

	local page  = node("admin", "network", "routes")
	page.target = cbi("admin_network/routes")
	page.title  = i18n("a_n_routes_static")
	page.order  = 50

end

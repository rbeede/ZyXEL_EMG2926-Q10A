--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ddns.lua 6010 2010-04-03 13:55:23Z jow $
]]--

local is_mini = (luci.dispatcher.context.path[1] == "mini")

m = Map("ddns", translate("ddns"), translate("ddns_desc"))

s = m:section(TypedSection, "service", "")
s.addremove = true
s.anonymous = false

s:option(Flag, "enabled", translate("enable"))

svc = s:option(ListValue, "service_name", translate("service"))
svc.rmempty = true

local services = { }
local fd = io.open("/usr/lib/ddns/services", "r")
if fd then
	local ln
	repeat
		ln = fd:read("*l")
		local s = ln and ln:match('^%s*"([^"]+)"')
		if s then services[#services+1] = s end
	until not ln
	fd:close()
end

local v
for _, v in luci.util.vspairs(services) do
	svc:value(v)
end

svc:value("", translate("cbi_manual"))


s:option(Value, "domain", translate("hostname")).rmempty = true
s:option(Value, "username", translate("username")).rmempty = true
pw = s:option(Value, "password", translate("password"))
pw.rmempty = true
pw.password = true


if is_mini then
	s.defaults.ip_source = "network"
	s.defaults.ip_network = "wan"
else
	require("luci.tools.webadmin")

	src = s:option(ListValue, "ip_source")
	src:value("network", translate("network"))
	src:value("interface", translate("interface"))
	src:value("web", "URL")

	iface = s:option(ListValue, "ip_network", translate("network"))
	iface:depends("ip_source", "network")
	iface.rmempty = true
	luci.tools.webadmin.cbi_add_networks(iface)

	iface = s:option(ListValue, "ip_interface", translate("interface"))
	iface:depends("ip_source", "interface")
	iface.rmempty = true
	for k, v in pairs(luci.sys.net.devices()) do
		iface:value(v)
	end

	web = s:option(Value, "ip_url", "URL")
	web:depends("ip_source", "web")
	web.rmempty = true
end

url = s:option(Value, "update_url")
url:depends("service_name", "")
url.rmempty = true

s:option(Value, "check_interval").default = 10
unit = s:option(ListValue, "check_unit")
unit.default = "minutes"
unit:value("minutes", "min")
unit:value("hours", "h")

s:option(Value, "force_interval").default = 72
unit = s:option(ListValue, "force_unit")
unit.default = "hours"
unit:value("minutes", "min")
unit:value("hours", "h")


return m

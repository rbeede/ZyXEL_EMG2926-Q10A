--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: qosmini.lua 5118 2009-07-23 03:32:30Z jow $
]]--

local wa = require "luci.tools.webadmin"
local fs = require "nixio.fs"

m = Map("qos")

s = m:section(NamedSection, "wan", "interface", translate("m_n_inet"))

s:option(Flag, "enabled", translate("qos"))
s:option(Value, "download", translate("qos_interface_download"), "kb/s")
s:option(Value, "upload", translate("qos_interface_upload"), "kb/s")

s = m:section(TypedSection, "classify")
s.template = "cbi/tblsection"

s.anonymous = true
s.addremove = true

t = s:option(ListValue, "target")
t:value("Priority", translate("qos_priority"))
t:value("Express", translate("qos_express"))
t:value("Normal", translate("qos_normal"))
t:value("Bulk", translate("qos_bulk"))
t.default = "Normal"

srch = s:option(Value, "srchost")
srch.rmempty = true
srch:value("", translate("all"))
wa.cbi_add_knownips(srch)

dsth = s:option(Value, "dsthost")
dsth.rmempty = true
dsth:value("", translate("all"))
wa.cbi_add_knownips(dsth)

l7 = s:option(ListValue, "layer7", translate("service"))
l7.rmempty = true
l7:value("", translate("all"))
local pats = fs.dir("/etc/l7-protocols")
if pats then
	for f in pats do
		if f:sub(-4) == ".pat" then
			l7:value(f:sub(1, #f-4))
		end
	end
end

p = s:option(ListValue, "proto", translate("protocol"))
p:value("", translate("all"))
p:value("tcp", "TCP")
p:value("udp", "UDP")
p:value("icmp", "ICMP")
p.rmempty = true

ports = s:option(Value, "ports", translate("ports"))
ports.rmempty = true
ports:value("", translate("allf", translate("all")))

bytes = s:option(Value, "connbytes", translate("qos_connbytes"))

return m

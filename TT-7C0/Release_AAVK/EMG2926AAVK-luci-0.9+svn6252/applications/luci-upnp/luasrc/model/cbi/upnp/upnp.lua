--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: upnp.lua 5606 2009-12-04 23:17:09Z jow $
]]--
m = Map("upnpd", translate("upnpd"), translate("upnpd_desc"))

s = m:section(NamedSection, "config", "upnpd", "")
e = s:option(Flag, "enabled", translate("enable"))
e.rmempty = false

s:option(Flag, "secure_mode").rmempty = true
s:option(Flag, "log_output").rmempty = true
s:option(Value, "download", nil, "kByte/s").rmempty = true
s:option(Value, "upload", nil, "kByte/s").rmempty = true

return m

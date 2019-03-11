--[[
LuCI - Lua Configuration Interface

Copyright 2009 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ff_p2pblock.lua 4793 2009-06-07 20:06:23Z jow $
]]--

module("luci.controller.ff_p2pblock", package.seeall)

function index()
	require("luci.i18n").loadc("freifunk")
	entry({"admin", "network", "firewall", "p2pblock"}, cbi("luci_fw/p2pblock"),
		luci.i18n.translate("ff_p2pblock", "P2P-Block"), 40)
end

--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: livestats.lua 3866 2008-12-07 19:38:31Z Cyrus $
]]--

module("luci.controller.livestats", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("livestats")

	entry( {"admin", "status", "wifistat"}, template("livestats/wireless"), luci.i18n.translate("livestats_stat_wireless"), 90 ).i18n = "livestats"
	entry( {"admin", "status", "trafstat"}, template("livestats/traffic"),  luci.i18n.translate("livestats_stat_traffic"),  91 ).i18n = "livestats"
	entry( {"admin", "status", "loadavg"},  template("livestats/loadavg"),  luci.i18n.translate("livestats_stat_loadavg"),  92 ).i18n = "livestats"
	
	entry( {"mini", "network", "wifistat"}, template("livestats/wireless"), luci.i18n.translate("livestats_stat_wireless"), 90 ).i18n = "livestats"
	entry( {"mini", "network", "trafstat"}, template("livestats/traffic"),  luci.i18n.translate("livestats_stat_traffic"),  91 ).i18n = "livestats"
	entry( {"mini", "system", "loadavg"},  template("livestats/loadavg"),  luci.i18n.translate("livestats_stat_loadavg"),  92 ).i18n = "livestats"
end

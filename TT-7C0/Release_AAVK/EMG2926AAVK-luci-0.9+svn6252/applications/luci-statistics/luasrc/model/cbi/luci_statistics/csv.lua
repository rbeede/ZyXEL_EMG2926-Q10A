--[[

Luci configuration model for statistics - collectd csv plugin configuration
(c) 2008 Freifunk Leipzig / Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id: csv.lua 2226 2008-06-01 23:52:07Z jow $

]]--

m = Map("luci_statistics")

-- collectd_csv config section
s = m:section( NamedSection, "collectd_csv", "luci_statistics" )

-- collectd_csv.enable
enable = s:option( Flag, "enable" )
enable.default = 0

-- collectd_csv.datadir (DataDir)
datadir = s:option( Value, "DataDir" )
datadir.default = "127.0.0.1"
datadir:depends( "enable", 1 )

-- collectd_csv.storerates (StoreRates)
storerates = s:option( Flag, "StoreRates" )
storerates.default = 0
storerates:depends( "enable", 1 )

return m


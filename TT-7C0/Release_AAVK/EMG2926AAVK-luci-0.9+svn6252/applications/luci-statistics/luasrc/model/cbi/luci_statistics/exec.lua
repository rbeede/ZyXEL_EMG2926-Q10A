--[[

Luci configuration model for statistics - collectd exec plugin configuration
(c) 2008 Freifunk Leipzig / Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

$Id: exec.lua 2226 2008-06-01 23:52:07Z jow $

]]--

m = Map("luci_statistics")

-- collectd_exec config section
s = m:section( NamedSection, "collectd_exec", "luci_statistics" )

-- collectd_exec.enable
enable = s:option( Flag, "enable" )
enable.default = 0


-- collectd_exec_input config section (Exec directives)
exec = m:section( TypedSection, "collectd_exec_input" )
exec.addremove = true
exec.anonymous = true

-- collectd_exec_input.cmdline
exec_cmdline = exec:option( Value, "cmdline" )
exec_cmdline.default = "/usr/bin/stat-dhcpusers"

-- collectd_exec_input.cmdline
exec_cmduser = exec:option( Value, "cmduser" )
exec_cmduser.default  = "nobody"
exec_cmduser.rmempty  = true
exec_cmduser.optional = true

-- collectd_exec_input.cmdline
exec_cmdgroup = exec:option( Value, "cmdgroup" )
exec_cmdgroup.default  = "nogroup"
exec_cmdgroup.rmempty  = true
exec_cmdgroup.optional = true


-- collectd_exec_notify config section (NotifyExec directives)
notify = m:section( TypedSection, "collectd_exec_notify" )
notify.addremove = true
notify.anonymous = true

-- collectd_notify_input.cmdline
notify_cmdline = notify:option( Value, "cmdline" )
notify_cmdline.default = "/usr/bin/stat-dhcpusers"

-- collectd_notify_input.cmdline
notify_cmduser = notify:option( Value, "cmduser" )
notify_cmduser.default  = "nobody"
notify_cmduser.rmempty  = true
notify_cmduser.optional = true

-- collectd_notify_input.cmdline
notify_cmdgroup = notify:option( Value, "cmdgroup" )
notify_cmdgroup.default  = "nogroup"
notify_cmdgroup.rmempty  = true
notify_cmdgroup.optional = true


return m

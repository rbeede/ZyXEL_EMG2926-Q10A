module("luci.controller.luci_fw.luci_fw", package.seeall)

function index()
	require("luci.i18n").loadc("luci-fw")
	local i18n = luci.i18n.translate

	entry({"admin", "network", "firewall"}, alias("admin", "network", "firewall", "zones"), i18n("fw_fw"), 60).i18n = "luci-fw"
	entry({"admin", "network", "firewall", "zones"}, cbi("luci_fw/zones"), i18n("fw_zones"), 10)
	entry({"admin", "network", "firewall", "redirect"}, arcombine(cbi("luci_fw/redirect"), cbi("luci_fw/rrule")), i18n("fw_redirect"), 30).leaf = true	
	entry({"admin", "network", "firewall", "rule"}, arcombine(cbi("luci_fw/traffic"), cbi("luci_fw/trule")), i18n("fw_traffic"), 20).leaf = true
	
	entry({"mini", "network", "portfw"}, cbi("luci_fw/miniportfw", {autoapply=true}), i18n("fw_portfw", "Portweiterleitung"), 70).i18n = "luci-fw"
end
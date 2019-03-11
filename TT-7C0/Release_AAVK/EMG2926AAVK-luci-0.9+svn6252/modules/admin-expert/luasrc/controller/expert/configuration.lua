--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 4040 2009-01-16 12:35:25Z Cyrus $
]]--

module("luci.controller.expert.configuration", package.seeall)
local uci = require("luci.model.uci").cursor()
local sys = require("luci.sys")

country_code_table = {
	FF={"reg0", "reg10"},				 -- USA           //DEBUG   old:{"reg0", "reg7"}
	FE={"reg1", "reg7"},				 -- S.Africa     
	FD={"reg1", "reg1"},				 -- Netherland   
	FC={"reg1", "reg1"},				 -- Denmark      
	FA={"reg1", "reg1"},				 -- Sweden       
	F9={"reg1", "reg1"},				 -- UK           
	F8={"reg1", "reg1"},				 -- Belgium      
	F7={"reg1", "reg1"},				 -- Greece       
	F6={"reg1", "reg2"},				 -- Czech        
	F5={"reg1", "reg1"},				 -- Norway       
	F4={"reg1", "reg9"},				 -- Australia    
	F3={"reg1", "reg9"},				 -- New Zealand   //without 165
	F2={"reg1", "reg7"},				 -- Hong Kong    
	F1={"reg1", "reg0"},				 -- Singapore    
	F0={"reg1", "reg1"},				 -- Finland      
	EF={"reg1", "reg6"},				 -- Morocco	     
	EE={"reg0", "reg3"},				 -- Taiwan       // old: {"reg0", "reg13"} 
	ED={"reg1", "reg1"},				 -- German       
	EC={"reg1", "reg1"},				 -- Italy        
	EB={"reg1", "reg1"},				 -- Ireland      
	EA={"reg1", "reg1"},				 -- Japan         //without 184 188 192 196
	E9={"reg1", "reg1"},				 -- Austria      
	E8={"reg1", "reg0"},				 -- Malaysia     
	E7={"reg1", "reg1"},				 -- Poland       
	E6={"reg1", "reg0"},				 -- Russia       
	E5={"reg1", "reg1"},				 -- Hungary      
	E4={"reg1", "reg1"},				 -- Slovak 	     
	E3={"reg1", "reg7"},				 -- Thailand     
	E2={"reg1", "reg2"},				 -- Israel       
	E1={"reg1", "reg1"},				 -- Switzerland  
	E0={"reg1", "reg1"},				 -- UAE          
	DE={"reg1", "reg4"},				 -- China        
	DD={"reg1", "reg0"},				 -- Ukraine      
	DC={"reg1", "reg1"},				 -- Portugal     
	DB={"reg1", "reg1"},				 -- France       
	DA={"reg1", "reg11"},				 -- Korea        
	D9={"reg1", "reg7"},				 -- Korea        
	D8={"reg1", "reg7"},				 -- Philippine   
	D7={"reg1", "reg1"},				 -- Slovenia	 
	D6={"reg1", "reg7"},				 -- India        
	D5={"reg1", "reg1"},				 -- Spain        
	D3={"reg1", "reg1"},				 -- Turkey       
	D1={"reg1", "reg7"},				 -- Peru         
	D0={"reg0", "reg7"},				 -- Brazil       
	CB={"reg1", "reg1"},				 -- Bulgaria     
	CC={"reg1", "reg1"},				 -- Luxembourg   
	CE={"reg0", "reg9"},				 -- Canada 	     
	CD={"reg1", "reg1"},				 -- Iceland	     
	CF={"reg1", "reg1"}				 -- Romania                             	                                           
}

channelRange = {
	reg0="1-11",    --region 0
	reg1="1-13",    --region 1
	reg2="10-11",   --region 2
	reg3="10-13",   --region 3
	reg4="14",      --region 4
	reg5="1-14",    --region 5
	reg6="3-9",     --region 6
	reg7="5-13"    --region 7
}

channelRange5G = {
	reg0="36,40,44,48,52,56,60,64,149,153,157,161,165",                                               --region 0
	reg1="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140",                       --region 1
	reg2="36,40,44,48,52,56,60,64",                                                                   --region 2
	reg3="56,60,64,149,153,157,161",                                                               --region 3
	reg4="149,153,157,161,165",                                                                       --region 4
	reg5="149,153,157,161",                                                                           --region 5
	reg6="36,40,44,48",                                                                               --region 6
	reg7="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165",   --region 7
	reg8="52,56,60,64",                                                                               --region 8
	reg9="36,40,44,48,52,56,60,64,100,104,108,112,116,132,136,140,149,153,157,161,165",               --region 9
	reg10="36,40,44,48,149,153,157,161,165",                                                          --region 10
	reg11="36,40,44,48,52,56,60,64,100,104,108,112,116,120,149,153,157,161",                          --region 11
	reg12="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140",                      --region 12
	reg13="52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161",                  --region 13
	reg14="36,40,44,48,52,56,60,64,100,104,108,112,116,136,140,149,153,157,161,165",                  --region 14
	reg15="149,153,157,161,165,169,173"                                                               --region 15
}
                                    
function index()                     
	
	local i18n = require("luci.i18n")
	local libuci = require("luci.model.uci").cursor()
	local lang = libuci:get("system","main","language") 
	i18n.load("admin-core",lang)
	i18n.setlanguage(lang)

	local ZyXEL_Mode = libuci:get("system","main","system_mode")
	local Product_Model = libuci:get("system","main","product_model")
	local op_mode

	if not ZyXEL_Mode then
		ZyXEL_Mode = "1"
	end

	if ZyXEL_Mode == "1" then
		op_mode = "wan"
	else
		op_mode = "wlan"
	end
                                 
	local page  = node("expert", "configuration")
	page.target = template("expert_configuration/configuration")
	page.title  = i18n.translate("Configuration")    
	page.order  = 40

	local page  = node("expert", "configuration", "network")
    page.target = alias("expert", "configuration", "network", op_mode)
	page.title  = i18n.translate("Network")         
	page.index = true                
	page.order  = 41

if ZyXEL_Mode ~= "2" and ZyXEL_Mode ~= "3" then  	               

	local page  = node("expert", "configuration", "network", "wan", "wan0")
	page.target = call("action_wan_internet_connection")
	page.title  = i18n.translate("WAN")
	page.order  = 421        

    	local page  = node("expert", "configuration", "network", "wan","advanced")
    	page.target = call("action_wan_advanced")
    	page.title  = "Advanced"
    	page.order  = 422

    	local page  = node("expert", "configuration", "network", "wan", "wan1")
	page.target = call("action_wan_internet_connection1")
	page.title  = i18n.translate("WAN")
	page.order  = 423  

        local page  = node("expert", "configuration", "network", "wan", "wan2")
        page.target = call("action_wan_internet_connection2")
        page.title  = i18n.translate("WAN")
        page.order  = 424

        local page  = node("expert", "configuration", "network", "wan", "wan3")
        page.target = call("action_wan_internet_connection3")
        page.title  = i18n.translate("WAN")
        page.order  = 425

        local page  = node("expert", "configuration", "network", "wan", "wan4")
        page.target = call("action_wan_internet_connection4")
        page.title  = i18n.translate("WAN")
        page.order  = 426

        local page  = node("expert", "configuration", "network", "wan","ipv6")
        page.target = call("action_wan_ipv6")
        --page.target = template("expert_configuration/ipv6")
        --page.title  = i18n.translate("IPv6")
        page.title  = "IPv6"
        page.order  = 420

        local page  = node("expert", "configuration", "network", "wan")
        page.target = call("action_wan_management")
        page.title  = i18n.translate("WAN")
        page.order  = 42


--[[
--------------------------------	                                 
	local page  = node("expert", "configuration", "network", "wan")
	page.target = call("action_wan_internet_connection")
	page.title  = i18n.translate("WAN")
	page.order  = 42        

	local page  = node("expert", "configuration", "network", "wan","ipv6")
	page.target = call("action_wan_ipv6")
	--page.target = template("expert_configuration/ipv6")
	--page.title  = i18n.translate("IPv6")
	page.title  = "IPv6"
	page.order  = 420
		
    local page  = node("expert", "configuration", "network", "wan","advanced")
    page.target = call("action_wan_advanced")
    page.title  = "Advanced"
    page.order  = 421		
--]]
end

--[[wireless2.4G]]--
	local page  = node("expert", "configuration", "network", "wlan")
	--[[ page.target = template("expert_configuration/wlan")	]]--
if ZyXEL_Mode ~= "4" then
	page.target = call("wlan_general")
else
	page.target = call("wlan_apcli_wisp")
end
	page.title  = i18n.translate("Wireless_LAN_2_dot_4_G")  
	page.order  = 43

if ZyXEL_Mode ~= "4" then

	local page  = node("expert", "configuration", "network", "wlan", "wlan_multissid")
	--page.target = template("expert_configuration/wlan_multissid")
	page.target = call("wlan_multissid")
	page.title  = "More AP"
	page.order  = 183

        local page  = node("expert", "configuration", "network", "wlan", "multissid_edit")
        --page.target = template("expert_configuration/multissid_edit")
        page.target = call("multiple_ssid")
        page.title  = "SSID Edit"
        page.order  = 185

	local page  = node("expert", "configuration", "network", "wlan", "wlanmacfilter")
	--[[page.target = template("expert_configuration/wlanmacfilter")]]--
	page.target = call("wlanmacfilter")
	page.title  = "MAC Filter"  
	page.order  = 44

	local page  = node("expert", "configuration", "network", "wlan", "wlanadvanced")
	--[[page.target = template("expert_configuration/wlanadvanced")]]--
	page.target = call("wlan_advanced")	
	page.title  = "Advanced"  
	page.order  = 45
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanqos")
	--[[page.target = template("expert_configuration/wlanqos")]]--
	page.target = call("wlan_qos")		
	page.title  = "QoS"  
	page.order  = 46
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanwps")
	--[[page.target = template("expert_configuration/wlanwps")]]--
	page.target = call("wlan_wps")	
	page.title  = "WPS"  
	page.order  = 47
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanwpsstation")
	--[[page.target = template("expert_configuration/wlanwpsstation")]]--
	page.target = call("wlanwpsstation")		
	page.title  = "WPS Station"  
	page.order  = 48
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanscheduling")
	--[[page.target = template("expert_configuration/wlanscheduling")]]--
	page.target = call("wlanscheduling")
	page.title  = "Scheduling"  
	page.order  = 48
end

if ZyXEL_Mode ~= "1" and ZyXEL_Mode ~= "2" then 
        --wireless client 2.4G 2012/06/25
	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp")
	page.target = call("wlan_apcli_wisp")
	page.title  = i18n.translate("universal_repeater")
	page.order  = 187

	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp_ur_site_survey")
	page.target = call("wlan_apcli_wisp_ur_site_survey")
	page.title  = i18n.translate("site_survey")
	page.order  = 188
        --wireless client 2.4G end
end
--[[end2.4G]]--	

--check product_model
if Product_Model == "DUAL_BAND" then

--[[wireless 5G]]--
	local page  = node("expert", "configuration", "network", "wlan5G")
	--[[page.target = template("expert_configuration/wlan5G")	]]--
if ZyXEL_Mode ~= "4" then
	page.target = call("wlan_general_5G")
else
	page.target = call("wlan_apcli_wisp5G")
end
	page.title  = i18n.translate("Wireless_LAN_5_G")  
	page.order  = 49

if ZyXEL_Mode ~= "4" then

        local page  = node("expert", "configuration", "network", "wlan", "wlan_multissid5G")
        --page.target = template("expert_configuration/wlan_multissid5G")
        page.target = call("wlan_multissid5G")
	page.title  = "More AP"
        page.order  = 84

        local page  = node("expert", "configuration", "network", "wlan", "multissid_edit5G")
        --page.target = template("expert_configuration/multissid_edit")
	page.target = call("multiple_ssid5G")
	page.title  = "SSID Edit"
	page.order  = 186

	local page  = node("expert", "configuration", "network", "wlan", "wlanmacfilter5G")
	--[[page.target = template("expert_configuration/wlanmacfilter5G")]]--
	page.target = call("wlanmacfilter_5G")
	page.title  = "MAC Filter"  
	page.order  = 50

	local page  = node("expert", "configuration", "network", "wlan", "wlanadvanced5G")
	--[[page.target = template("expert_configuration/wlanadvanced5G")]]--
	page.target = call("wlan_advanced_5G")
	page.title  = "Advanced"  
	page.order  = 51
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanqos5G")
	--[[page.target = template("expert_configuration/wlanqos5G")]]--
	page.target = call("wlan_qos_5G")
	page.title  = "QoS"  
	page.order  = 52
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanwps5G")
	--[[page.target = template("expert_configuration/wlanwps5G")		]]--
	page.target = call("wlan_wps_5G")	
	page.title  = "WPS"  
	page.order  = 53
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanwpsstation5G")
	--[[page.target = template("expert_configuration/wlanwpsstation5G")		]]--
	page.target = call("wlanwpsstation_5G")	
	page.title  = "WPS Station"  
	page.order  = 54
	
	local page  = node("expert", "configuration", "network", "wlan", "wlanscheduling5G")
	--[[page.target = template("expert_configuration/wlanscheduling5G")		]]--	
	page.target = call("wlanscheduling_5G")
	page.title  = "Scheduling"  
	page.order  = 55
end

if ZyXEL_Mode ~= "1" and ZyXEL_Mode ~= "2" then 
        --wireless client 2.4G 2012/06/25
	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp5G")
	page.target = call("wlan_apcli_wisp5G")
	page.title  = i18n.translate("universal_repeater")
	page.order  = 189

	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp_ur_site_survey5G")
	page.target = call("wlan_apcli_wisp_ur_site_survey5G")
	page.title  = i18n.translate("site_survey")
	page.order  = 190
        --wireless client 2.4G end
end
--[[end5G]]--

end

	local page  = node("expert", "configuration", "network", "lan")
	page.target = call("action_lan")
	page.title  = i18n.translate("LAN")  
	page.order  = 56
	
	local page  = node("expert", "configuration", "network", "lan", "ipalias")
	page.target = call("action_ipalias")
	page.title  = "IP Alias"  
	page.order  = 57
	
	local page  = node("expert", "configuration", "network", "lan", "ipv6LAN")
	page.target = call("action_ipv6lan")
	page.title  = "IPv6 LAN"  
	page.order  = 58

	local page  = node("expert", "configuration", "network", "lan", "igmp_snooping")
	page.target = call("action_igmp_snooping")
	page.title  = "IGMP Snooping"  
	page.order  = 581
	--[[
	local page  = node("expert", "configuration", "network", "lan", "ipadv")
	page.target = template("expert_configuration/ip_advance")
	page.title  = "IP Advance"  
	page.order  = 44
	]]--

if ZyXEL_Mode ~= "2" and ZyXEL_Mode ~= "3" then  	

	local page  = node("expert", "configuration", "network", "dhcpserver")
	page.target = call("action_dhcpSetup")
	page.title  = i18n.translate("DHCP_Server")
	page.order  = 58

	local page  = node("expert", "configuration", "network", "dhcpserver", "ipstatic")
	page.target = call("action_dhcpStatic")
	page.title  = "LAN_IPStatic"
	page.order  = 59

	local page  = node("expert", "configuration", "network", "dhcpserver", "dhcptbl")
	page.target = call("action_clientList")
	page.title  = "LAN_DHCPTbl_1"
	page.order  = 60
	
	local page  = node("expert", "configuration", "network", "nat")
	page.target = call("nat")
	page.title  = i18n.translate("NAT")  
	page.order  = 61
		
	local page  = node("expert", "configuration", "network", "nat", "portfw")
	page.target = call("action_portfw")
	page.title  = "Port Forwarding"
	page.order  = 62

	local page  = node("expert", "configuration", "network", "nat", "portfw","portfw_edit")
	page.target = call("action_portfw_edit")
	page.title  = "Port Forwarding Edit"
	page.order  = 63
	
	local page  = node("expert", "configuration", "network", "nat","nat_advance")
	page.target = call("port_trigger")
	page.title  = "NAT Advance"
	page.order  = 64

	local page  = node("expert", "configuration", "network", "ddns")
	page.target = call("action_ddns")
	page.title  = i18n.translate("Dynamic_DNS")
	page.order  = 65

	local page  = node("expert", "configuration", "network", "static_route")
	page.target = call("action_static_route")
	page.title  = i18n.translate("Static_Route")
	page.order  = 66

	local page  = node("expert", "configuration", "network", "interface_grouping")
	page.target = call("action_int_grouping")
	page.title  = "Interface Group"
	page.order  = 67


	local page  = node("expert", "configuration", "security")
	page.target = alias("expert", "configuration", "security", "firewall")
	page.title  = i18n.translate("Security")
	page.index = true 
	page.order  = 68
	
	local page  = node("expert", "configuration", "security", "firewall")
	page.target = call("firewall")
	page.title  = i18n.translate("Firewall") 
	page.ignoreindex = true	
	page.order  = 69
	
	local page  = node("expert", "configuration", "security", "firewall", "fwsrv")
	page.target = call("fw_services")
	page.title  = "Firewall Service"  
	page.order  = 70

--[[	
	local page  = node("expert", "configuration", "security", "vpn")
	--page.target = template("expert_configuration/vpn")
	page.target = call("action_vpn")
	page.title  = i18n.translate("IPSec_VPN")  
	page.order  = 70
	
	local page  = node("expert", "configuration", "security", "vpn", "vpn_edit")
	page.target = call("action_vpnEdit")
	page.title  = "IPSec VPN Edit"  
	page.order  = 71
	
	local page  = node("expert", "configuration", "security", "vpn", "samonitor")
	--page.target = template("expert_configuration/samonitor")
	page.target = call("action_samonitor")
	page.title  = "SA Monitor"  
	page.order  = 72
--]]	

	local page  = node("expert", "configuration", "security", "ContentFilter")
	page.target = call("action_CF")
	page.title  = i18n.translate("Content_filter")  
	page.order  = 71

	local page  = node("expert", "configuration", "security", "firewall6")
	page.target = call("firewall6")
	page.title  = i18n.translate("IPv6_firewall")
	page.order  = 72
	
	local page  = node("expert", "configuration", "security", "ParentalControl")
	page.target = call("parental_control")
	page.title  = i18n.translate("parental_control")
	page.order  = 73
	
	local page  = node("expert", "configuration", "security", "ParentalControl", "ParentalControl_Edit")
	page.target = call("parental_control_edit")
	page.title  = "Parental Control"
	page.order  = 74
	
--[[	
	local page  = node("expert", "configuration", "usb")
	page.target = template("expert_configuration/3g_connection")
	page.title  = "USB Service"  
	page.order  = 73
	
	local page  = node("expert", "configuration", "powersave")
	page.target = template("expert_configuration/powersaving")
	page.title  = "Power Saving"  
	page.order  = 74
]]--

--[[
	local page  = node("expert", "configuration", "management")
	page.target = alias("expert", "configuration", "management", "qos")
	page.title  = i18n.translate("Management")
	page.index = true  
	page.order  = 75	
			
	local page  = node("expert", "configuration", "management", "qos")
	page.target = alias("expert", "configuration", "management", "qos", "general")
	page.title  = i18n.translate("Bandwidth_MGMT")  
	page.order  = 76
	
	local page  = node("expert", "configuration", "management", "qos", "general")
	page.target = call("action_qos")
	page.title  = "QoS General"  
	page.order  = 77
	
	local page  = node("expert", "configuration", "management", "qos", "advance")
	page.target = call("action_qos_adv")
	page.title  = "QoS Advance"  
	page.order  = 78
	
	local page  = node("expert", "configuration", "management", "qos", "monitor")
	page.target = template("expert_configuration/qos_monitor")
	page.title  = "QoS Monitor"  
	page.order  = 79
--]]
--[[
	local page  = node("expert", "configuration", "management")
	page.target = alias("expert", "configuration", "management", "streamboost")
	page.title  = i18n.translate("Management")
	page.index = true  
	page.order  = 81	
	
	local page  = node("expert", "configuration", "management", "streamboost")		
	page.target = alias("expert", "configuration", "management", "streamboost", "streamboost_bandwidth")	
	page.title  = i18n.translate("StreamBoost_MGMT")
	page.order  = 82
	
	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_bandwidth")		
	page.target = call("streamboost_bandwidth")	
	page.title  = "Streamboost Bandwidth"
	page.order  = 82	

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_network")
	page.target = template("expert_configuration/streamboost_network")
	page.title  = "Streamboost Network"  
	page.order  = 83
	
	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_priorities")		
	page.target = template("expert_configuration/streamboost_priorities")
	page.title  = "Streamboost Priorities"
	page.order  = 84	
	
	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_uptime")		
	page.target = template("expert_configuration/streamboost_uptime")
	page.title  = "Streamboost Up Time"
	page.order  = 85	
	
	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_bytes")		
	page.target = template("expert_configuration/streamboost_bytes")
	page.title  = "Streamboost Bytes"
	page.order  = 86	
	
	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_allevents")		
	page.target = template("expert_configuration/streamboost_allevents")
	page.title  = "Streamboost All Events"
	page.order  = 87

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_node")		
	page.target = template("expert_configuration/streamboost_node")
	page.title  = "Streamboost node"
	page.order  = 87

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_about")		
	page.target = template("expert_configuration/streamboost_about")
	page.title  = "About Streamboost"
	page.order  = 87	
--]]
        local page  = node("expert", "configuration", "management")
        page.target = alias("expert", "configuration", "management", "qos")
        page.title  = i18n.translate("Management")
        page.index = true
        page.order  = 81

	local page  = node("expert", "configuration", "management", "qos")
	page.target = alias("expert", "configuration", "management", "qos", "general")
	page.title  = i18n.translate("Bandwidth_MGMT")  
	page.order  = 82

	local page  = node("expert", "configuration", "management", "qos", "general")
	page.target = call("action_qos")
        page.title  = i18n.translate("Bandwidth_MGMT")
        page.ignoreindex = true
	page.order  =  83

	local page  = node("expert", "configuration", "management", "qos", "qos_queue")
	page.target = call("action_qos_queue")
	page.title  = "Queue Setup"
	page.order  =  84

	local page  = node("expert", "configuration", "management", "qos", "qos_classify")
	page.target = call("action_qos_classify")
	page.title  = "Class Setup"
	page.order  =  85


	local page  = node("expert", "configuration", "management", "remote")
	page.target = call("action_remote_www")
	page.title  = i18n.translate("Remote_MGMT")
	page.ignoreindex = true  
	page.order  = 90

	local page  = node("expert", "configuration", "management", "remote", "snmpsetting")
	page.target = call("action_remote_snmp")
	page.title  = "SNMP"
	page.order  = 901
	
	local page  = node("expert", "configuration", "management", "remote", "telnet")
	page.target = call("action_remote_telnet")
	page.title  = "Remote MGMT Telnet"
	page.order  = 91

	local page  = node("expert", "configuration", "management", "remote", "ssh")
	page.target = call("action_remote_ssh")
	page.title  = "Remote MGMT SSH"
	page.order  = 92
	
	local page  = node("expert", "configuration", "management", "remote", "wol")
	page.target = call("action_wol")
	page.title  = "Wake On LAN"
	page.order  = 93

	local page  = node("expert", "configuration", "management", "upnp")
	page.target = call("action_upnp")
	page.title  = i18n.translate("UPnP")  
	page.order  = 94

	local page  = node("expert", "configuration", "management", "media_sharing")
	page.target = alias("expert", "configuration", "management", "media_sharing", "dlna")
	page.title  = i18n.translate("Media")
	page.index = true  
	page.order  = 96

	local page  = node("expert", "configuration", "management", "media_sharing", "dlna")
	page.target = call("action_dlna")
	page.title  = i18n.translate("DLNA")  
	page.order  = 97

	local page  = node("expert", "configuration", "management", "media_sharing", "samba")
	page.target = call("action_samba")
	page.title  = i18n.translate("SAMBA")  
	page.order  = 98
	
	local page  = node("expert", "configuration", "management", "media_sharing", "ftp")
	page.target = call("action_ftp")
	page.title  = i18n.translate("FTP")  
	page.order  = 99
	
	local page  = node("expert", "configuration", "management", "port_config")
	page.target = call("action_port_config")
	page.title  = i18n.translate("port_config") 
	page.order  = 100	

else

	local page  = node("expert", "configuration", "management")
	page.target = alias("expert", "configuration", "management", "media_sharing")
	page.title  = i18n.translate("Management")
	page.index = true  
	page.order  = 92
	
	local page  = node("expert", "configuration", "management", "media_sharing")
	page.target = alias("expert", "configuration", "management", "media_sharing", "dlna")
	page.title  = i18n.translate("Media")
	page.index = true  
	page.order  = 92

	local page  = node("expert", "configuration", "management", "media_sharing", "dlna")
	page.target = call("action_dlna")
	page.title  = i18n.translate("DLNA")  
	page.order  = 93

	local page  = node("expert", "configuration", "management", "media_sharing", "samba")
	page.target = call("action_samba")
	page.title  = i18n.translate("SAMBA")  
	page.order  = 94
	
	local page  = node("expert", "configuration", "management", "media_sharing", "ftp")
	page.target = call("action_ftp")
	page.title  = i18n.translate("FTP")  
	page.order  = 95

end
	
end

function action_wan_internet_connection()

	local apply = luci.http.formvalue("apply")

	if apply then

		local connection_type = luci.http.formvalue("connectionType")
		local connection_IPmode = luci.http.formvalue("IP_Mode")
		local wan_proto = uci:get("network","wan","proto")
		local vid = luci.http.formvalue("wan_vid")
		local pri = luci.http.formvalue("wan_pri")
		local wan_name = luci.http.formvalue("wan_name")
		local ifname

		-- clean opt121 static route
        uci:delete("network","wan","staticroutes")
        uci:delete("network","wan","msstaticroutes")
		
		-- clean isp_gw
		uci:delete("network","wan","isp_gw")

		if nil == pri then
			pri="0"
		end  

		if ( nil == vid ) then
			ifname = "eth0"
			vid = 0
			pri="0"
		else
			ifname = "eth0."..vid
		end

		uci:set("network","wan","ifname", ifname)
		uci:set("network","wan","vid", vid)
		uci:set("network","wan","pri",pri)
		uci:set("network","wan","name", wan_name)
		
		if connection_type == "Bridge" then

			--local wan_name = luci.http.formvalue("wan_name")
			--local vid = luci.http.formvalue("wan_vid")
			--local tag_flag = luci.http.formvalue("ignore_vid")
			--sys.exec("echo ".."\"enter\"".." >> /tmp/aaa")

			uci:set("network","wan","proto", "bridge")
			uci:set("network","wan","name", "Default")
			uci:set("network","wan","IP_version","IPv4_Only")

			uci:set("dhcp","lan","enabled", "0")
 
			--sys.exec("brctl addif br-lan vlan10")
			--sys.exec("kill \$\(ps \| grep \"udhcpc -t 0 -i vlan10\" \| grep \"grep\" -v \| awk \'\{print \$1\}\'\)") 

			--uci:set("network","wan","ifname", "eth0."..vid)
			--uci:set("network","wan","vid", vid)
			--uci:set("network","wan","enable",1)
			uci:set("network","general","config_section","wan")
			uci:commit("dhcp")
			uci:apply("dhcp")
			uci:commit("network")
			uci:apply("network")
			uci:apply("qos")
                
			local url = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url)
     
		else
			-- lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")
			sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")

			local mac_wan=""

			--Add For IPv6Tunning	
			local ipv6Tunneling = luci.http.formvalue("IPv6_Tunneling")
			--Add FOR 6RD
			local auto_6rd = luci.http.formvalue("auto_6rd")
			local zy6rd6prefix = luci.http.formvalue("zy6rd6prefix")
			local zy6rd4ip= luci.http.formvalue("zy6rd4ip")
			local zy6rdCkWan = luci.http.formvalue("WAN_IP_Auto")
			local zy6rdWanStaticIp = luci.http.formvalue("staticIp")

			local zy6rd6prefixleng = luci.http.formvalue("zy6rd6prefixleng")
			local zy6rd4prefixleng = luci.http.formvalue("zy6rd4prefixleng")
			--Support ipv6 DNS
			local zy6rd_PriDnsv6 = luci.http.formvalue("zy6rd_PriDnsv6")
			local zy6rd_SecDnsv6 = luci.http.formvalue("zy6rd_SecDnsv6")
			local zy6rd_ThiDnsv6 = luci.http.formvalue("zy6rd_ThiDnsv6")

			if not zy6rd6prefixleng then
				zy6rd6prefixleng = 32
			end
			if not zy6rd4prefixleng then
				zy6rd4prefixleng = 0
			end
			if not zy6rd_PriDnsv6 then
				zy6rd_PriDnsv6 = ""
			end
			if not zy6rd_SecDnsv6 then
				zy6rd_SecDnsv6 = ""
			end
			if not zy6rd_ThiDnsv6 then
				zy6rd_ThiDnsv6 = ""
			end

			if connection_IPmode == "IPv4_Only" then

				if ipv6Tunneling == "IPv6_6RD" then
					uci:delete("network","wan6rd")
					uci:delete("network","wan6rdS")
					uci:set("network", "wan6rd", "interface")
					uci:set("network", "wan6rd", "proto", "6rd")
					uci:set("network", "general", "wan6rd_enable", 1)
					uci:set("network", "general", "dhcpv6pd", "1")
					uci:set("network", "wan", "iface6rd", "")
					uci:set("network", "wan", "reqopts", "")
					--Support ipv6 DNS
					uci:set("network", "wan6rd", "PriDns", zy6rd_PriDnsv6)
					uci:set("network", "wan6rd", "SecDns", zy6rd_SecDnsv6)
					uci:set("network", "wan6rd", "ThiDns", zy6rd_ThiDnsv6)

					if connection_type == "PPPOE" then
						zy6rdCkWan = "0" --For pppoe check
					end

					--WAN DHCP
					if zy6rdCkWan == "1" then
						--6RD DHCP
						if auto_6rd == "auto" then
							uci:set("network", "wan", "iface6rd", "wan6rd")
							uci:set("network", "wan", "reqopts", "212")	
							--6RD Static
						else
							uci:set("network", "wan6rd", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd", "ip4prefixlen", zy6rd4prefixleng)
						end
					elseif zy6rdCkWan == "0" then
						if auto_6rd == "auto" then
							uci:set("network", "wan", "iface6rd", "wan6rd")
							uci:set("network", "wan", "reqopts", "212")	
						else
							uci:set("network", "wan6rd", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd", "ip4prefixlen", zy6rd4prefixleng)
						end			
					--WANStatic
					else
						--6RD DHCP
						if auto_6rd == "auto" then
							uci:set("network", "wan", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS", "interface")
							uci:set("network", "wan6rdS", "ifname", ifname)
							uci:set("network", "wan6rdS", "proto", "dhcp")
							uci:set("network", "wan6rdS", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS", "reqopts", "212")	
						--6RD Static
						else		
							uci:set("network", "wan", "iface6rd", "")
							uci:set("network", "wan6rd", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd", "ip4prefixlen", zy6rd4prefixleng)
							uci:set("network", "wan6rd", "ipaddr", zy6rdWanStaticIp)
						end	
					end

				else
					uci:set("network", "general", "wan6rd_enable", 0)
				end
				--Add FOR 6RD

				--Add FOR 6to4
				local zy6to4ip= luci.http.formvalue("zy6to4ip")
				--Support ipv6 DNS
				local zy6to4_PriDnsv6 = luci.http.formvalue("zy6to4_PriDnsv6")
				local zy6to4_SecDnsv6 = luci.http.formvalue("zy6to4_SecDnsv6")
				local zy6to4_ThiDnsv6 = luci.http.formvalue("zy6to4_ThiDnsv6")
				if not zy6to4_PriDnsv6 then
					zy6to4_PriDnsv6 = ""
				end
				if not zy6to4_SecDnsv6 then
					zy6to4_SecDnsv6 = ""
				end
				if not zy6to4_ThiDnsv6 then
					zy6to4_ThiDnsv6 = ""
				end

				if ipv6Tunneling == "IPv6_6to4" then
					uci:set("network", "general", "wan6to4_enable", "1")
					uci:set("network", "general", "dhcpv6pd", "1")
				else
					uci:set("network", "general", "wan6to4_enable", "0")
				end

				uci:set("network", "wan6to4", "interface")
				uci:set("network", "wan6to4", "proto", "6to4")
				--Support ipv6 DNS
				uci:set("network", "wan6to4", "PriDns", zy6to4_PriDnsv6)
				uci:set("network", "wan6to4", "SecDns", zy6to4_SecDnsv6)
				uci:set("network", "wan6to4", "ThiDns", zy6to4_ThiDnsv6)

				if not zy6to4ip or zy6to4ip == "" then
					zy6to4ip = "192.88.99.1"
				end
				uci:set("network", "wan6to4", "relayaddr", zy6to4ip)
				--Add FOR 6to4

				--Add FOR 6in4
				local zy6in4_rtv4= luci.http.formvalue("zy6in4_rtv4")
				local zy6in4_rtv6= luci.http.formvalue("zy6in4_rtv6")
				local zy6in4_lov6= luci.http.formvalue("zy6in4_lov6")
				local zy6in4_v6pfx= luci.http.formvalue("zy6in4_v6pfx")

				--Support ipv6 DNS
				local zy6in4_PriDnsv6 = luci.http.formvalue("zy6in4_PriDnsv6")
				local zy6in4_SecDnsv6 = luci.http.formvalue("zy6in4_SecDnsv6")
				local zy6in4_ThiDnsv6 = luci.http.formvalue("zy6in4_ThiDnsv6")
				if not zy6in4_PriDnsv6 then
					zy6in4_PriDnsv6 = ""
				end
				if not zy6in4_SecDnsv6 then
					zy6in4_SecDnsv6 = ""
				end
				if not zy6in4_ThiDnsv6 then
					zy6in4_ThiDnsv6 = ""
				end

				if ipv6Tunneling == "IPv6_6in4" then
					uci:set("network", "general", "wan6in4_enable", "1")
					uci:set("network", "general", "dhcpv6pd", "1")
				else
					uci:set("network", "general", "wan6in4_enable", "0")
				end

				uci:set("network", "wan6in4", "interface")
				uci:set("network", "wan6in4", "proto", "6in4")

				if not zy6in4_rtv4 then
					zy6in4_rtv4 = ""
				end
				if not zy6in4_rtv6 then
					zy6in4_rtv6 = ""
				end
				if not zy6in4_lov6 then
					zy6in4_lov6= ""
				end
				if not zy6in4_v6pfx then
					zy6in4_v6pfx= ""
				end

				uci:set("network", "wan6in4", "peeraddr", zy6in4_rtv4)
				uci:set("network", "wan6in4", "ipv6peeraddr", zy6in4_rtv6)		
				uci:set("network", "wan6in4", "ip6addr", zy6in4_lov6)
				uci:set("network", "wan6in4", "ip6prefix", zy6in4_v6pfx)
				--Support ipv6 DNS
				uci:set("network", "wan6in4", "PriDns", zy6in4_PriDnsv6)
				uci:set("network", "wan6in4", "SecDns", zy6in4_SecDnsv6)
				uci:set("network", "wan6in4", "ThiDns", zy6in4_ThiDnsv6)
				--Add FOR 6in4

			else
				uci:set("network", "general", "wan6rd_enable", 0)
				uci:set("network", "general", "wan6to4_enable", 0)
				uci:set("network", "general", "wan6in4_enable", 0)
			end

			-- DNSv4
			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			local Server_dns3Type       = luci.http.formvalue("dns3Type")
			local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end

			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end

			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end

			uci:set("network","wan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","wan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","wan","dns3",Server_dns3Type ..",".. Server_staticThiDns)

			-- DNSv6
			local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
			local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
			local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
			local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
			local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
			local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")

			-- write DNSv6 server address into  dhcp6s.uci  , no matter it is ISP/USER defined.
			uci:set("dhcp6s","basic","domain_name_server1","")
			uci:set("dhcp6s","basic","domain_name_server2","")
			uci:set("dhcp6s","basic","domain_name_server3","")

			if Server_staticPriDnsv6 == nil then
				Server_staticPriDnsv6 = ""
			end

			if Server_staticSecDnsv6 == nil then
				Server_staticSecDnsv6 = ""
			end

			if Server_staticThiDnsv6 == nil then
				Server_staticThiDnsv6 = ""
			end


			if Server_staticPriDnsv6 ~= "" then
				uci:set("dhcp6s","basic","domain_name_server1", Server_staticPriDnsv6)

				if Server_staticSecDnsv6 ~= "" and Server_staticSecDnsv6 ~= Server_staticPriDnsv6 then
					uci:set("dhcp6s","basic","domain_name_server2", Server_staticSecDnsv6)
				end

				if Server_staticThiDnsv6 ~= "" and Server_staticThiDnsv6 ~= Server_staticPriDnsv6 and Server_staticThiDnsv6 ~= Server_staticSecDnsv6 then
					uci:set("dhcp6s","basic","domain_name_server3", Server_staticThiDnsv6)
				end
			end

			if connection_IPmode == "IPv4_Only" then
				if ipv6Tunneling == "None" then
					uci:set("radvd","interface","AdvOtherConfigFlag", "0")
					uci:set("dhcp6s","basic","enabled", "0")
				else
					uci:set("radvd","interface","AdvOtherConfigFlag", "1")
					uci:set("dhcp6s","basic","enabled", "1")
				end
			else
				uci:set("radvd","interface","AdvOtherConfigFlag", "1")
				uci:set("dhcp6s","basic","enabled", "1")
			end
			uci:commit("radvd")
			uci:commit("dhcp6s")

			-- write USER defined DNS addr. into  network.uci  .
			if Server_dnsv6_1Type~="USER" or Server_staticPriDnsv6 == "::/0" or not Server_staticPriDnsv6 then
				Server_staticPriDnsv6=""
			end

			if Server_dnsv6_2Type~="USER" or Server_staticSecDnsv6 == "::/0" or not Server_staticSecDnsv6 then
				Server_staticSecDnsv6=""
			end

			if Server_dnsv6_3Type~="USER" or Server_staticThiDnsv6 == "::/0" or not Server_staticThiDnsv6 then
				Server_staticThiDnsv6=""
			end

			uci:set("network","wan","dnsv6_1",Server_dnsv6_1Type ..",".. Server_staticPriDnsv6)
			uci:set("network","wan","dnsv6_2",Server_dnsv6_2Type ..",".. Server_staticSecDnsv6)
			uci:set("network","wan","dnsv6_3",Server_dnsv6_3Type ..",".. Server_staticThiDnsv6)

			--WenHsien -- set IPmode into UCI
			if connection_IPmode == "IPv4_Only" then
				uci:set("network","wan","ipv4","1")
				uci:set("network","wan","ipv6","0")
				uci:set("network","wan","ipv6Enable","0")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","wan","IP_version","IPv4_Only")
			elseif connection_IPmode == "Dual_Stack" then
				uci:set("network","wan","ipv4","1")
				uci:set("network","wan","ipv6","1")
				uci:set("network","wan","ipv6Enable","1")
				uci:set("network","wan","IP_version","Dual_Stack")
			else
				uci:set("network","wan","ipv4","0")
				uci:set("network","wan","ipv6","1")
				uci:set("network","wan","ipv6Enable","1")
				uci:set("network","wan","IP_version","IPv6_Only")
			end

			-- PPPoE
			if connection_type == "PPPOE" then
				uci:set("network","wan","v6_proto","pppoe")

				local ipv6=uci:get("network","wan","ipv6")
				if ipv6=="1" then
					uci:set("network","wan","send_rs","0")
					uci:set("network","wan","accept_ra","1")
					uci:set("dhcp6c","basic","ifname","pppoe-wan")
					uci:set("dhcp6c","basic","interface","wan")
					uci:commit("dhcp6c")	
				end


				local pppoeUser = luci.http.formvalue("pppoeUser")
				local pppoePass = luci.http.formvalue("pppoePass")
				local pppoeMTU = luci.http.formvalue("pppoeMTU")
				local pppoeNailedup = luci.http.formvalue("pppoeNailedup")
				local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
				local pppoeServiceName = luci.http.formvalue("pppoeServiceName")
				--local pppoePassthrough = luci.http.formvalue("pppoePassthrough")
				local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")

				if pppoeNailedup~="1" then
					pppoeNailedup=0
				end

				if not pppoeIdleTime then
					pppoeIdleTime=""
				end
				--[[
				if pppoePassthrough~="1" then
				pppoePassthrough=0
				end
				]]--

				if not pppoeWanIpAddr then
					pppoeWanIpAddr=""
				end
				
				--security issue
				local pppoePass_len = string.len(pppoePass)
							
				if (pppoePass_len >= 4 and string.find(pppoePass,"!@#^") == nil) then
					uci:set("network","wan","password",pppoePass)
				else
					if pppoePass_len < 4 then
						if string.find(pppoePass,"<") == nil then
							uci:set("network","wan","password",pppoePass)
						end
					end	
				end

				uci:set("network","wan","proto","pppoe")
				uci:set("network","wan","username",pppoeUser)
				--uci:set("network","wan","password",pppoePass)
				uci:set("network","wan","pppoe_mtu",pppoeMTU)
				uci:set("network","wan","mtu",pppoeMTU)	
				uci:set("network","wan","pppoeNailedup",pppoeNailedup)
				uci:set("network","wan","demand",pppoeIdleTime)
				uci:set("network","wan","service",pppoeServiceName)
				--uci:set("network","wan","pppoePassthrough",pppoePassthrough)
				uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)
				uci:set("network","wan","ip6addr","")
				uci:set("network","wan","prefixlen","")
				uci:set("network","wan","ip6gw","")  
				uci:set("network","wan","IPv6_dns","")
				--uci:set("network","wan","pppoev6_dns",pppoeipv6dns)
				--if not pppoeipv6dns then
				--sys.exec("echo nameserver "..pppoeipv6dns.." >> /tmp/resolv.conf.auto") 
				--end 
				--[[
				uci:delete("network","wan","ipaddr")
				uci:delete("network","wan","netmask")
				uci:delete("network","wan","gateway")
				]]--
				--[[
				elseif connection_type == "PPTP" then

				local pptpUser = luci.http.formvalue("pptpUser")
				local pptpPass = luci.http.formvalue("pptpPass")
				local pptpMTU = luci.http.formvalue("pptpMTU")
				local pptpNailedup = luci.http.formvalue("pptpNailedup")
				local pptpIdleTime = luci.http.formvalue("pptpIdleTime")
				local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
				local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
				local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
				local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
				local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
				local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")
				local pptpWanIPMode = luci.http.formvalue("pptpWanIPMode")

				if pptpNailedup~="1" then
				pptpNailedup=0
				end

				if not pptpIdleTime then
				pptpIdleTime=""
				end

				if not pptpWanIpAddr then
				pptpWanIpAddr=""
				end					
				uci:set("network","wan","proto","pptp")
				uci:set("network","wan","v6_proto","pptp")
				uci:set("network","vpn","interface")
				uci:set("network","wan","IP_version","IPv4_Only")

				if pptp_config_ip == "1" then
				uci:set("network","vpn","proto","dhcp")
				else
				uci:set("network","vpn","proto","static")
				uci:set("network","wan","ipaddr",pptp_staticIp)
				uci:set("network","wan","netmask",pptp_staticNetmask)
				uci:set("network","wan","gateway",pptp_staticGateway)
				end

				uci:set("network","vpn","pptp_username",pptpUser)
				uci:set("network","vpn","pptp_password",pptpPass)
				uci:set("network","wan","pptp_mtu",pptpMTU)
				uci:set("network","wan","mtu",pptpMTU)
				uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
				uci:set("network","vpn","pptp_demand",pptpIdleTime)
				uci:set("network","vpn","pptp_serverip",pptp_serverIp)
				uci:set("network","vpn","pptpWanIPMode",pptpWanIPMode)
				uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)	
				]]--

				-- IPoE
			else
				-- IPoE/ v4
				if (connection_IPmode == "IPv4_Only") or (connection_IPmode == "Dual_Stack") then	
					local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
					local Fixed_staticIp = luci.http.formvalue("staticIp")
					local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
					local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					local ethMTU = luci.http.formvalue("ethMTU")

					-- IPoE/ v4/ DHCP
					if WAN_IP_Auto == "1" then
						local vendor_id = luci.http.formvalue("vendor_id")
						local dhcp121Enable  = luci.http.formvalue("dhcp121Enable")
						local dhcp125Enable  = luci.http.formvalue("dhcp125Enable")
						local dhcp43Enable  = luci.http.formvalue("dhcp43Enable")
						local dhcp60Enable = luci.http.formvalue("dhcp60Enable")

						uci:set("network","wan","proto","dhcp")

						uci:set("dhcp","lan","enabled","1")

						if not ( nil == vendor_id ) then
							uci:set("network", "wan", "vendorid", vendor_id)
						else
							uci:set("network", "wan", "vendorid", "")
						end

						if not ("0" == dhcp121Enable ) then
							uci:set("network", "wan", "dhcp121", 0)
						else
							uci:set("network", "wan", "dhcp121", 1)
						end

						if not ("0" == dhcp125Enable ) then
							uci:set("network", "wan", "dhcp125", 0)
						else
							uci:set("network", "wan", "dhcp125", 1)
						end
						
						if not ("0" == dhcp43Enable ) then
							uci:set("network", "wan", "dhcp43", 0)
						else
							uci:set("network", "wan", "dhcp43", 1)
						end

						if not ("0" == dhcp60Enable ) then
							uci:set("network", "wan", "dhcp60", 0)
						else
							uci:set("network", "wan", "dhcp60", 1)
						end

					-- IPoE/ v4/ STATIC
					else
						uci:set("network","wan","proto","static")
						uci:set("network","wan","ipaddr",Fixed_staticIp)
						uci:set("network","wan","netmask",Fixed_staticNetmask)
						uci:set("network","wan","gateway",Fixed_staticGateway)
					end
					uci:set("network","wan","eth_mtu",ethMTU)
					uci:set("network","wan","mtu",ethMTU)
					--[[
					uci:delete("network","wan","username")
					uci:delete("network","wan","password")
					uci:delete("network","wan","pppoeNailedup")
					uci:delete("network","wan","pppoeIdleTime")
					uci:delete("network","wan","pppoeServiceName")
					uci:delete("network","wan","pppoePassthrough")
					]]--
				end

				-- IPoE/ v6
				if (connection_IPmode == "IPv6_Only") or (connection_IPmode == "Dual_Stack") then
					local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
					local duidmode = luci.http.formvalue("dhcpv6_autoaddr_duidmode")
					local IPv6_Fixed_StaticIp = luci.http.formvalue("ipv6_address")
					local IPv6_Prefix_Length = luci.http.formvalue("prefix_length")
					local IPv6_Fixed_StaticGateway = luci.http.formvalue("ipv6_gateway")
					--local IPv6_DNS = luci.http.formvalue("ipv6_dns")  
					--local IA_NA = luci.http.formvalue("ia_na")
					--local IA_PD = luci.http.formvalue("ia_pd")
					local request_v6_dns = luci.http.formvalue("auto_dns")
					local ethMTU = luci.http.formvalue("ethMTU")

					--uci:apply("RA_status")
					--uci:set("network6","wan","type", "ipoev6")
					uci:set("network","wan","send_rs","0")
					uci:set("network","wan","accept_ra","1")
					uci:commit("network")	
					--uci:apply("network")

					uci:set("dhcp6c","basic","ifname",ifname)
					uci:set("dhcp6c","basic","interface","wan")
					uci:commit("dhcp6c")
					--uci:apply("dhcp6c")

					-- IPoE/ v6/ DHCP
					if IPv6_WAN_IP_Auto == "auto" then
						uci:set("network","wan","v6_proto","dhcp")
						uci:set("network","wan","ip6addr","")
						uci:set("network","wan","prefixlen","")
						uci:set("network","wan","ip6gw","")  
						uci:set("network","wan","IPv6_dns","")

						--uci:set("network6","wan","type","dhcp")
						uci:set("dhcp6c","basic","enabled", 1)

						local Server_dns1Type       = luci.http.formvalue("dns1Type")
						local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
						local Server_dns2Type       = luci.http.formvalue("dns2Type")
						local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
						local Server_dns3Type       = luci.http.formvalue("dns3Type")
						local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
						--[[ if IA_NA then
						IA_NA=1
						else
						IA_NA=0 
						end
						if IA_PD then
						IA_PD=1
						else
						IA_PD=0
						end ]]--
						--uci:set("dhcp6c","basic","na", IA_NA)
						--uci:set("dhcp6c","basic","pd", IA_PD)
						uci:set("dhcp6c","lan","enabled", 1)
						uci:set("dhcp6c","lan","sla_id", 0)
						uci:set("dhcp6c","lan","sla_len", 0)
						uci:set("dhcp6c","basic","gui_run","1")

						uci:set("dhcp6c","basic","duid_mode", duidmode)
						uci:set("network","wan","ipv6","1")
						uci:set("network","general","linkLocalOnly","0")
						-- IPoE/ v6/ STATIC
					elseif IPv6_WAN_IP_Auto == "static" then
						uci:set("network","wan","v6_proto","static") 
						uci:set("network","wan","v6_static","1")   
						uci:set("network","wan","ip6addr",IPv6_Fixed_StaticIp)
						uci:set("network","wan","prefixlen",IPv6_Prefix_Length)
						uci:set("network","wan","ip6gw",IPv6_Fixed_StaticGateway)  
						--uci:set("network","wan","IPv6_dns", IPv6_DNS) 
						uci:set("network","wan","send_rs","1")
						uci:set("network","wan","accept_ra","0")
						uci:set("network","wan","ipv6","1")
						uci:set("network","general","linkLocalOnly","0")
					elseif IPv6_WAN_IP_Auto == "linkLocal_only" then
						uci:set("network","wan","ipv6","0")
						uci:set("network","general","linkLocalOnly","1")
					end  
					uci:commit("network") 
					uci:commit("dhcp6c")
					--WenHsien denoted for EMG
					--uci:apply("RA_dhcp6c")

					--uci:apply("network")
					-- if not IPv6_DNS then
					--sys.exec("echo nameserver "..IPv6_DNS.." >> /tmp/resolv.conf.auto") 
					-- end 
					--local ipv6_fixed_addr=uci:get("network","wan","ip6addr") 
					--local ipv6_prefixlength=uci:get("network","wan","prefixlen")  
					--if not ipv6_fixed_addr then ipv6_fixed_addr="" end 
					--if not ipv6_prefixlength then ipv6_prefixlength="" end
					--sys.exec("ifconfig vlan10 add "..ipv6_fixed_addr.."/"..IPv6_Prefix_Length)

					--local ipv6_fixedgateway=uci:get("network","wan","ip6gw")
					--   if not ipv6_fixedgateway then ipv6_fixedgateway="" end
					--sys.exec("ip -6 route del default dev vlan10") 
					--sys.exec("ip -6 route add default via "..ipv6_fixedgateway) 
				end
			end -- IP mode


			local WAN_MAC_Clone = luci.http.formvalue("WAN_MAC_Clone")
			local spoofIPAddr = luci.http.formvalue("spoofIPAddr")
			local macCloneMac = luci.http.formvalue("macCloneMac")
			--[[
			local old_WAN_MAC_Clone = uci:get("network", "wan", "wan_mac_status")
			if not old_WAN_MAC_Clone then 
			old_WAN_MAC_Clone = "0"
			uci:set("network","wan","wan_mac_status",old_WAN_MAC_Clone)
			end
			]]--
			--if WAN_MAC_Clone ~= old_WAN_MAC_Clone then
			if WAN_MAC_Clone == "0" then
				uci:set("network","wan","wan_mac_status",WAN_MAC_Clone)

				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 0-15 > /tmp/mac0")
				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 16-17 >> /tmp/mac0")
				local idx_mac = 0
				for line in io.lines("/tmp/mac0") do
					idx_mac = idx_mac + 1
					if( idx_mac == 2 ) then
						line = tran16to10(line , 3)
						if(string.len(line) == 3) then
							line = string.sub(line , 2,3)
						end
						mac_wan = mac_wan..line 

					else
						mac_wan = line
					end
				end
				sys.exec("rm /tmp/mac0")
				uci:set("network","wan","wan_set_mac",mac_wan)
				uci:set("network","wan","macaddr",mac_wan)

			elseif WAN_MAC_Clone == "1" then
				local sw = 0
				local t={}
				t=luci.sys.net.arptable()
				for i,v in ipairs(t) do
					if t[i]["IP address"]==spoofIPAddr then 
						uci:set("network","wan","wan_clone_ip",t[i]["IP address"])
						uci:set("network","wan","wan_clone_ip_mac",t[i]["HW address"])
						uci:set("network","wan","wan_set_mac",t[i]["HW address"])
						uci:set("network","wan","macaddr",t[i]["HW address"])
						sw = 1
					end
				end

				if sw==1 then
					uci:set("network","wan","wan_mac_status","1")
				else
					local url = luci.dispatcher.build_url("expert","configuration","network","wan")		
					luci.http.redirect(url .. "?" .. "arp_error=1" .. "&error_addr=" .. spoofIPAddr)
				end

			elseif WAN_MAC_Clone == "2" then
				uci:set("network","wan","wan_mac_status",WAN_MAC_Clone)
				uci:set("network","wan","wan_set_mac",macCloneMac)
				uci:set("network","wan","macaddr",macCloneMac)
			end

			--end

			uci:set("network","general","config_section","wan")	

			--WenHsien
			local v6_static = uci:get("network","wan","v6_static")
			if v6_static ~= "1" then	
				uci:commit("dhcp")
				--WenHsien denoted for EMG
				--uci:apply("dhcp")
				--uci:commit("network")	
				--uci:apply("network")
			end
			uci:set("network","wan","v6_static","0")

			uci:commit("network")	
			uci:apply("network")  
			
			-- igmpproxy
			local igmpEnabled = luci.http.formvalue("igmpEnabled")
			local ori_igmpEnabled = uci:get("igmpproxy","wan","igmpEnabled")
			if igmpEnabled ~= ori_igmpEnabled then
				uci:set("igmpproxy","wan","igmpEnabled",igmpEnabled)
				if igmpEnabled == "enable" then			
					uci:set("igmpproxy","wan1","igmpEnabled","disable")
					uci:set("igmpproxy","wan2","igmpEnabled","disable")
					uci:set("igmpproxy","wan3","igmpEnabled","disable")
					uci:set("igmpproxy","wan4","igmpEnabled","disable")

				end
				uci:commit("igmpproxy")
				uci:apply("igmpproxy")
			end
			-- igmpproxy

			uci:apply("qos")
			sys.exec("/sbin/configure_intfGrp set_iptables_rule")

			--WenHsien
			local url = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url)
		end
	end


	luci.template.render("expert_configuration/broadband_add")

end

function action_wan_internet_connection1()
	
	local apply = luci.http.formvalue("apply")

	if apply then
		local connection_type = luci.http.formvalue("connectionType")
		local connection_IPmode = luci.http.formvalue("IP_Mode")

		-- clean opt121 static route
		uci:delete("network","wan1","staticroutes")
		uci:delete("network","wan1","msstaticroutes")

		-- clean isp_gw
		uci:delete("network","wan1","isp_gw")

		if connection_type == "Bridge" then

			local wan_name = luci.http.formvalue("wan_name")
			local vid = luci.http.formvalue("wan_vid")
			local tag_flag = luci.http.formvalue("ignore_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end  

			--sys.exec("echo ".."\"enter\"".." >> /tmp/aaa")

			-- Delete default setup wan interface first
			local old_ifname = uci:get("network","wan1","ifname")
			local ifname = "eth0."..vid
			--sys.exec("/bin/set_subwan delete "..old_ifname)

			-- Create sub-wan [vid] [ifname] [Mac-address char] [diff mac address]
			if ("1" == tag_flag) then
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 0".." br")
				uci:set("network","wan1","untag","1")
			else
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 1".." br")
				uci:set("network","wan1","untag","0")
			end

			uci:set("network","wan1","proto", "bridge")
			uci:set("network","wan1","name", wan_name)
			uci:set("network","wan1","ifname", "eth0."..vid)
			uci:set("network","wan1","vid", vid)
			uci:set("network","wan1","pri",pri)
			uci:set("network","wan1","enable",1)
			uci:set("network","general","config_section","wan1")
			uci:set("network","wan1","IP_version","IPv4_Only")
			uci:commit("network")
			uci:apply("network")
			uci:apply("qos")

			local url1 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url1)
		else


			-- lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")
			local wan_proto = uci:get("network","wan1","proto")
			sys.exec("echo "..wan_proto.." > /tmp/old_wan1_proto")

			local wan_name = luci.http.formvalue("wan_name")	
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end 

			local tag_flag = luci.http.formvalue("ignore_vid")	


			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			local Server_dns3Type       = luci.http.formvalue("dns3Type")
			local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

			-- Delete the default wan interface first
			local old_ifname = uci:get("network","wan1","ifname")
			local ifname = "eth0."..vid
			local mac_wan=""


			--And call the script for creating New sub wan

			uci:set("network","wan1","untag","1")
			--Add FOR 6RD	
			local zy6rdEnable = luci.http.formvalue("zy6rdEnable")
			local auto_6rd = luci.http.formvalue("auto_6rd")
			local zy6rd6prefix = luci.http.formvalue("zy6rd6prefix")
			local zy6rd4ip= luci.http.formvalue("zy6rd4ip")
			local zy6rdCkWan = luci.http.formvalue("WAN_IP_Auto")
			local zy6rdWanStaticIp = luci.http.formvalue("staticIp")

			local zy6rd6prefixleng = luci.http.formvalue("zy6rd6prefixleng")
			local zy6rd4prefixleng = luci.http.formvalue("zy6rd4prefixleng")

			if not zy6rd6prefixleng then
				zy6rd6prefixleng = 32
			end
			if not zy6rd4prefixleng then
				zy6rd4prefixleng = 0
			end

			if connection_IPmode == "IPv4_Only" then

				if zy6rdEnable == "on" then
					uci:delete("network","wan6rd1")
					uci:delete("network","wan6rdS1")
					uci:set("network", "wan6rd1", "interface")
					uci:set("network", "wan6rd1", "proto", "6rd")
					uci:set("network", "general", "wan6rd_enable", 1)
					uci:set("network", "wan1", "iface6rd", "")
					uci:set("network", "wan1", "reqopts", "")

					if connection_type == "PPPOE" then
						zy6rdCkWan = "0" --For pppoe check
					end

					--WAN DHCP
					if zy6rdCkWan == "1" then
					--6RD DHCP
						if auto_6rd == "auto" then
							uci:set("network", "wan1", "iface6rd", "wan6rd")
							uci:set("network", "wan1", "reqopts", "212")	
							--6RD Static
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end
					elseif zy6rdCkWan == "0" then
						if auto_6rd == "auto" then
							uci:set("network", "wan1", "iface6rd", "wan6rd")
							uci:set("network", "wan1", "reqopts", "212")	
						else
						uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
						uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
						uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
						uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end			
					--WANStatic
					else
						--6RD DHCP
						local wan_ifname = uci:get("network","wan","ifname")
						if auto_6rd == "auto" then
							uci:set("network", "wan1", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "interface")
							uci:set("network", "wan6rdS1", "ifname", wan_ifname)
							uci:set("network", "wan6rdS1", "proto", "dhcp")
							uci:set("network", "wan6rdS1", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "reqopts", "212")	
						--6RD Static
						else		
							uci:set("network", "wan1", "iface6rd", "")
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
							uci:set("network", "wan6rd1", "ipaddr", zy6rdWanStaticIp)
						end	
					end

				else
					uci:set("network", "general", "wan6rd_enable", 0)
				end

			else
				uci:set("network", "general", "wan6rd_enable", 0)
			end
			--Add FOR 6RD

			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end

			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end

			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end

			uci:set("network","wan1","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","wan1","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","wan1","dns3",Server_dns3Type ..",".. Server_staticThiDns)


			local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
			local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
			local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
			local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
			local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
			local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")

			if Server_dnsv6_1Type~="USER" or Server_staticPriDnsv6 == "::/0" or not Server_staticPriDnsv6 then
				Server_staticPriDnsv6=""
			end

			if Server_dnsv6_2Type~="USER" or Server_staticSecDnsv6 == "::/0" or not Server_staticSecDnsv6 then
				Server_staticSecDnsv6=""
			end

			if Server_dnsv6_3Type~="USER" or Server_staticThiDnsv6 == "::/0" or not Server_staticThiDnsv6 then
				Server_staticThiDnsv6=""
			end

			uci:set("network","wan1","dnsv6_1",Server_dnsv6_1Type ..",".. Server_staticPriDnsv6)
			uci:set("network","wan1","dnsv6_2",Server_dnsv6_2Type ..",".. Server_staticSecDnsv6)
			uci:set("network","wan1","dnsv6_3",Server_dnsv6_3Type ..",".. Server_staticThiDnsv6)

			--WenHsien -- set IPmode into UCI
			if connection_IPmode == "IPv4_Only" then
				uci:set("network","wan1","ipv4","1")
				uci:set("network","wan1","ipv6","0")
				uci:set("network","wan1","ipv6Enable","0")
				uci:set("network","wan1","IP_version","IPv4_Only")
			elseif connection_IPmode == "Dual_Stack" then
				uci:set("network","wan1","ipv4","1")
				uci:set("network","wan1","ipv6","1")
				uci:set("network","wan1","ipv6Enable","1")
				uci:set("network","wan1","IP_version","Dual_Stack")
			else
				uci:set("network","wan1","ipv4","0")
				uci:set("network","wan1","ipv6","1")
				uci:set("network","wan1","ipv6Enable","1")
				uci:set("network","wan1","IP_version","IPv6_Only")
			end

			-- PPPoE
			if connection_type == "PPPOE" then
				uci:set("network","wan1","v6_proto","pppoe")

				local ipv6=uci:get("network","wan1","ipv6")
				if ipv6=="1" then
					uci:set("network","wan1","send_rs","0")
					uci:set("network","wan1","accept_ra","1")
					uci:set("dhcp6c","basic","ifname","pppoe-wan")
					uci:set("dhcp6c","basic","interface","wan")
					uci:commit("dhcp6c")	
				end


				local pppoeUser = luci.http.formvalue("pppoeUser")
				local pppoePass = luci.http.formvalue("pppoePass")
				local pppoeMTU = luci.http.formvalue("pppoeMTU")
				local pppoeNailedup = luci.http.formvalue("pppoeNailedup")
				local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
				local pppoeServiceName = luci.http.formvalue("pppoeServiceName")
				--local pppoePassthrough = luci.http.formvalue("pppoePassthrough")
				local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")

				if pppoeNailedup~="1" then
					pppoeNailedup=0
				end

				if not pppoeIdleTime then
					pppoeIdleTime=""
				end
				--[[
				if pppoePassthrough~="1" then
				pppoePassthrough=0
				end
				]]--

				if not pppoeWanIpAddr then
					pppoeWanIpAddr=""
				end

				--security issue
				local pppoePass_len = string.len(pppoePass)
							
				if (pppoePass_len >= 4 and string.find(pppoePass,"!@#^") == nil) then
					uci:set("network","wan1","password",pppoePass)
				else
					if pppoePass_len < 4 then
						if string.find(pppoePass,"<") == nil then
							uci:set("network","wan1","password",pppoePass)
						end
					end	
				end

				uci:set("network","wan1","proto","pppoe")
				uci:set("network","wan1","username",pppoeUser)
				--uci:set("network","wan1","password",pppoePass)
				uci:set("network","wan1","pppoe_mtu",pppoeMTU)
				uci:set("network","wan1","mtu",pppoeMTU)	
				uci:set("network","wan1","pppoeNailedup",pppoeNailedup)
				uci:set("network","wan1","demand",pppoeIdleTime)
				uci:set("network","wan1","service",pppoeServiceName)
				--uci:set("network","wan1","pppoePassthrough",pppoePassthrough)
				uci:set("network","wan1","pppoeWanIpAddr",pppoeWanIpAddr)
				uci:set("network","wan1","ip6addr","")
				uci:set("network","wan1","prefixlen","")
				uci:set("network","wan1","ip6gw","")  
				uci:set("network","wan1","IPv6_dns","")
				--uci:set("network","wan1","pppoev6_dns",pppoeipv6dns)
				--if not pppoeipv6dns then
				--sys.exec("echo nameserver "..pppoeipv6dns.." >> /tmp/resolv.conf.auto") 
				--end 
				--[[
				uci:delete("network","wan1","ipaddr")
				uci:delete("network","wan1","netmask")
				uci:delete("network","wan1","gateway")
				]]--
				--[[
				elseif connection_type == "PPTP" then

				local pptpUser = luci.http.formvalue("pptpUser")
				local pptpPass = luci.http.formvalue("pptpPass")
				local pptpMTU = luci.http.formvalue("pptpMTU")
				local pptpNailedup = luci.http.formvalue("pptpNailedup")
				local pptpIdleTime = luci.http.formvalue("pptpIdleTime")
				local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
				local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
				local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
				local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
				local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
				local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")
				local pptpWanIPMode = luci.http.formvalue("pptpWanIPMode")

				if pptpNailedup~="1" then
				pptpNailedup=0
				end

				if not pptpIdleTime then
				pptpIdleTime=""
				end

				if not pptpWanIpAddr then
				pptpWanIpAddr=""
				end					
				uci:set("network","wan1","proto","pptp")
				uci:set("network","wan1","v6_proto","pptp")
				uci:set("network","vpn","interface")
				uci:set("network","wan1","IP_version","IPv4_Only")

				if pptp_config_ip == "1" then
				uci:set("network","vpn","proto","dhcp")
				else
				uci:set("network","vpn","proto","static")
				uci:set("network","wan1","ipaddr",pptp_staticIp)
				uci:set("network","wan1","netmask",pptp_staticNetmask)
				uci:set("network","wan1","gateway",pptp_staticGateway)
				end

				uci:set("network","vpn","pptp_username",pptpUser)
				uci:set("network","vpn","pptp_password",pptpPass)
				uci:set("network","wan1","pptp_mtu",pptpMTU)
				uci:set("network","wan1","mtu",pptpMTU)
				uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
				uci:set("network","vpn","pptp_demand",pptpIdleTime)
				uci:set("network","vpn","pptp_serverip",pptp_serverIp)
				uci:set("network","vpn","pptpWanIPMode",pptpWanIPMode)
				uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)	
				]]--

				-- IPoE
			else
			-- IPoE/ v4
				if (connection_IPmode == "IPv4_Only") or (connection_IPmode == "Dual_Stack") then	
					local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
					local Fixed_staticIp = luci.http.formvalue("staticIp")
					local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
					local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					local ethMTU = luci.http.formvalue("ethMTU")

					-- IPoE/ v4/ DHCP
					if WAN_IP_Auto == "1" then
						local vendor_id = luci.http.formvalue("vendor_id")
						local dhcp121Enable  = luci.http.formvalue("dhcp121Enable")
						local dhcp125Enable  = luci.http.formvalue("dhcp125Enable")
						local dhcp43Enable  = luci.http.formvalue("dhcp43Enable")
						local dhcp60Enable = luci.http.formvalue("dhcp60Enable")

						uci:set("network","wan1","proto","dhcp")


						if not ( nil == vendor_id ) then
							uci:set("network", "wan1", "vendorid", vendor_id)
						else
							uci:set("network", "wan1", "vendorid", "")
						end

						if not ("0" == dhcp121Enable ) then
							uci:set("network", "wan1", "dhcp121", 0)
						else
							uci:set("network", "wan1", "dhcp121", 1)
						end

						if not ("0" == dhcp125Enable ) then
							uci:set("network", "wan1", "dhcp125", 0)
						else
							uci:set("network", "wan1", "dhcp125", 1)
						end

						if not ("0" == dhcp43Enable ) then
							uci:set("network", "wan1", "dhcp43", 0)
						else
							uci:set("network", "wan1", "dhcp43", 1)
						end
						
						if not ("0" == dhcp60Enable ) then
							uci:set("network", "wan1", "dhcp60", 0)
						else
							uci:set("network", "wan1", "dhcp60", 1)
						end

						-- IPoE/ v4/ STATIC
					else
						uci:set("network","wan1","proto","static")
						uci:set("network","wan1","ipaddr",Fixed_staticIp)
						uci:set("network","wan1","netmask",Fixed_staticNetmask)
						uci:set("network","wan1","gateway",Fixed_staticGateway)
					end
					uci:set("network","wan1","eth_mtu",ethMTU)
					uci:set("network","wan1","mtu",ethMTU)
					--[[
					uci:delete("network","wan1","username")
					uci:delete("network","wan1","password")
					uci:delete("network","wan1","pppoeNailedup")
					uci:delete("network","wan1","pppoeIdleTime")
					uci:delete("network","wan1","pppoeServiceName")
					uci:delete("network","wan1","pppoePassthrough")
					]]--
				end

				-- IPoE/ v6
				if (connection_IPmode == "IPv6_Only") or (connection_IPmode == "Dual_Stack") then
					local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
					local IPv6_Fixed_StaticIp = luci.http.formvalue("ipv6_address")
					local IPv6_Prefix_Length = luci.http.formvalue("prefix_length")
					local IPv6_Fixed_StaticGateway = luci.http.formvalue("ipv6_gateway")
					local IPv6_DNS = luci.http.formvalue("ipv6_dns")  
					--local IA_NA = luci.http.formvalue("ia_na")
					--local IA_PD = luci.http.formvalue("ia_pd")
					local request_v6_dns = luci.http.formvalue("auto_dns")
					local ethMTU = luci.http.formvalue("ethMTU")

					--uci:apply("RA_status")
					--uci:set("network6","wan1","type", "ipoev6")
					uci:set("network","wan1","send_rs","0")
					uci:set("network","wan1","accept_ra","1")
					uci:set("network","wan1","ifname", "eth0."..vid)
					uci:commit("network")	
					--uci:apply("network")

					uci:set("dhcp6c","basic","ifname","eth0."..vid)
					uci:set("dhcp6c","basic","interface","wan1")
					uci:commit("dhcp6c")
					--uci:apply("dhcp6c")

					-- IPoE/ v6/ DHCP
					if IPv6_WAN_IP_Auto == "auto" then
						uci:set("network","wan1","v6_proto","dhcp")
						uci:set("network","wan1","ip6addr","")
						uci:set("network","wan1","prefixlen","")
						uci:set("network","wan1","ip6gw","")  
						uci:set("network","wan1","IPv6_dns","")

						--uci:set("network6","wan1","type","dhcp")
						uci:set("dhcp6c","basic","enabled", 1)

						--local Server_dns1Type       = luci.http.formvalue("dns1Type")
						--local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
						--local Server_dns2Type       = luci.http.formvalue("dns2Type")
						--local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
						--local Server_dns3Type       = luci.http.formvalue("dns3Type")
						--local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
						--[[ if IA_NA then
						IA_NA=1
						else
						IA_NA=0 
						end
						if IA_PD then
						IA_PD=1
						else
						IA_PD=0
						end ]]--
						--uci:set("dhcp6c","basic","na", IA_NA)
						--uci:set("dhcp6c","basic","pd", IA_PD)
						uci:set("dhcp6c","lan","enabled", 1)
						uci:set("dhcp6c","lan","sla_id", 0)
						uci:set("dhcp6c","lan","sla_len", 0)
						uci:set("dhcp6c","basic","gui_run","1")

					-- IPoE/ v6/ STATIC
					else 
						uci:set("network","wan1","v6_proto","static") 
						uci:set("network","wan1","v6_static","1")   
						uci:set("network","wan1","ip6addr",IPv6_Fixed_StaticIp)
						uci:set("network","wan1","prefixlen",IPv6_Prefix_Length)
						uci:set("network","wan1","ip6gw",IPv6_Fixed_StaticGateway)  
						uci:set("network","wan1","IPv6_dns", IPv6_DNS) 
						uci:set("network","wan1","send_rs","1")
						uci:set("network","wan1","accept_ra","0")
					end  
					uci:commit("network") 
					uci:commit("dhcp6c")
					--WenHsien denoted for EMG
					--uci:apply("RA_dhcp6c")

					--uci:apply("network")
					-- if not IPv6_DNS then
					--sys.exec("echo nameserver "..IPv6_DNS.." >> /tmp/resolv.conf.auto") 
					-- end 
					--local ipv6_fixed_addr=uci:get("network","wan1","ip6addr") 
					--local ipv6_prefixlength=uci:get("network","wan1","prefixlen")  
					--if not ipv6_fixed_addr then ipv6_fixed_addr="" end 
					--if not ipv6_prefixlength then ipv6_prefixlength="" end
					--sys.exec("ifconfig eth0."..vid.." add "..ipv6_fixed_addr.."/"..IPv6_Prefix_Length)

					--local ipv6_fixedgateway=uci:get("network","wan1","ip6gw")
					--   if not ipv6_fixedgateway then ipv6_fixedgateway="" end
					--sys.exec("ip -6 route del default dev eth0."..vid) 
					--sys.exec("ip -6 route add default via "..ipv6_fixedgateway) 
				end
			end -- IP mode


			local WAN_MAC_Clone = luci.http.formvalue("WAN_MAC_Clone")
			local spoofIPAddr = luci.http.formvalue("spoofIPAddr")
			local macCloneMac = luci.http.formvalue("macCloneMac")
			--[[
			local old_WAN_MAC_Clone = uci:get("network", "wan1", "wan_mac_status")
			if not old_WAN_MAC_Clone then 
			old_WAN_MAC_Clone = "0"
			uci:set("network","wan1","wan_mac_status",old_WAN_MAC_Clone)
			end
			]]--
			--if WAN_MAC_Clone ~= old_WAN_MAC_Clone then
			if WAN_MAC_Clone == "0" then
				uci:set("network","wan1","wan_mac_status",WAN_MAC_Clone)

				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 0-15 > /tmp/mac0")
				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 16-17 >> /tmp/mac0")
				local idx_mac = 0
				for line in io.lines("/tmp/mac0") do
					idx_mac = idx_mac + 1
					if( idx_mac == 2 ) then
					line = tran16to10(line , 3)
						if(string.len(line) == 3) then
							line = string.sub(line , 2,3)
						end
					mac_wan = mac_wan..line 

					else
						mac_wan = line
					end
				end
				sys.exec("rm /tmp/mac0")
				uci:set("network","wan1","wan_set_mac",mac_wan)		
				uci:set("network","wan1","macaddr",mac_wan)	

			elseif WAN_MAC_Clone == "1" then
				local sw = 0
				local t={}
				t=luci.sys.net.arptable()
				for i,v in ipairs(t) do
					if t[i]["IP address"]==spoofIPAddr then 
						uci:set("network","wan1","wan_clone_ip",t[i]["IP address"])
						uci:set("network","wan1","wan_clone_ip_mac",t[i]["HW address"])
						uci:set("network","wan1","wan_set_mac",t[i]["HW address"])
						uci:set("network","wan1","macaddr",t[i]["HW address"])
						sw = 1
					end
				end

				if sw==1 then
					uci:set("network","wan1","wan_mac_status","1")
				else
					local url1 = luci.dispatcher.build_url("expert","configuration","network","wan1")		
					luci.http.redirect(url1 .. "?" .. "arp_error=1" .. "&error_addr=" .. spoofIPAddr)
				end

			elseif WAN_MAC_Clone == "2" then
				uci:set("network","wan1","wan_mac_status",WAN_MAC_Clone)
				uci:set("network","wan1","wan_set_mac",macCloneMac)
				uci:set("network","wan1","macaddr",macCloneMac)
			end

			--end

			uci:set("network","wan1","name", wan_name)
			uci:set("network","wan1","ifname", "eth0."..vid)
			uci:set("network","wan1","vid", vid)
			uci:set("network","wan1","pri",pri)
			uci:set("network","wan1","enable",1)

			uci:set("network","general","config_section","wan1")	

			--WenHsien
			local v6_static = uci:get("network","wan1","v6_static")
			if v6_static ~= "1" then	
				uci:commit("dhcp")
				--WenHsien denoted for EMG
				--uci:apply("dhcp")
				--uci:commit("network")	
				--uci:apply("network")
			end
			uci:set("network","wan1","v6_static","0")
			uci:commit("network")	
			uci:apply("network")  

			-- igmpproxy
			local igmpEnabled = luci.http.formvalue("igmpEnabled")
			local ori_igmpEnabled = uci:get("igmpproxy","wan1","igmpEnabled")
			if igmpEnabled ~= ori_igmpEnabled then
				uci:set("igmpproxy","wan1","igmpEnabled",igmpEnabled)
				if igmpEnabled == "enable" then			
					uci:set("igmpproxy","wan","igmpEnabled","disable")
					uci:set("igmpproxy","wan2","igmpEnabled","disable")
					uci:set("igmpproxy","wan3","igmpEnabled","disable")
					uci:set("igmpproxy","wan4","igmpEnabled","disable")
				end	
				uci:commit("igmpproxy")
				uci:apply("igmpproxy")
			end
			-- igmpproxy

			uci:apply("qos")
			sys.exec("/sbin/configure_intfGrp set_iptables_rule")

			--WenHsien
			local url1 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url1)
		end
		io.popen("/etc/init.d/default_lan_radvd boot")   
	end

	luci.template.render("expert_configuration/broadband1_add")

end


function action_wan_internet_connection2()

	local apply = luci.http.formvalue("apply")

	if apply then
		local connection_type = luci.http.formvalue("connectionType")
		local connection_IPmode = luci.http.formvalue("IP_Mode")

		-- clean opt121 static route
		uci:delete("network","wan2","staticroutes")
		uci:delete("network","wan2","msstaticroutes")

		-- clean isp_gw
		uci:delete("network","wan2","isp_gw")		
	
		if connection_type == "Bridge" then

			local wan_name = luci.http.formvalue("wan_name")
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end 

			local tag_flag = luci.http.formvalue("ignore_vid")

			--sys.exec("echo ".."\"enter\"".." >> /tmp/aaa")

			local old_ifname = uci:get("network","wan2","ifname")
			local ifname = "eth0."..vid
			--sys.exec("/bin/set_subwan delete "..old_ifname)
			-- Create sub-wan [vid] [ifname] [Mac-address char] [tag or not] [diff mac address]
			if ("1" == tag_flag) then
				----sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 0".." br")
				uci:set("network","wan2","untag","1")
			else
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 1".." br")
				uci:set("network","wan2","untag","0")
			end

			uci:set("network","wan2","proto", "bridge")
			uci:set("network","wan2","name", wan_name)
			uci:set("network","wan2","ifname", "eth0."..vid)
			uci:set("network","wan2","vid", vid)
			uci:set("network","wan2","pri",pri)
			uci:set("network","wan2","enable",1)
			uci:set("network","general","config_section","wan2")
			uci:set("network","wan2","IP_version","IPv4_Only")
			uci:commit("network")
			uci:apply("network")
			uci:apply("qos")

			local url2 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url2)
		else


			-- lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")
			local wan_proto = uci:get("network","wan2","proto")
			sys.exec("echo "..wan_proto.." > /tmp/old_wan2_proto")

			local wan_name = luci.http.formvalue("wan_name")	
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end 

			local tag_flag = luci.http.formvalue("ignore_vid")	


			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			local Server_dns3Type       = luci.http.formvalue("dns3Type")
			local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

			-- Delete the default wan interface first
			local old_ifname = uci:get("network","wan2","ifname")
			local ifname = "eth0."..vid
			local mac_wan=""


			--And call the script for creating New sub wan

			uci:set("network","wan2","untag","1")
			--Add FOR 6RD	
			local zy6rdEnable = luci.http.formvalue("zy6rdEnable")
			local auto_6rd = luci.http.formvalue("auto_6rd")
			local zy6rd6prefix = luci.http.formvalue("zy6rd6prefix")
			local zy6rd4ip= luci.http.formvalue("zy6rd4ip")
			local zy6rdCkWan = luci.http.formvalue("WAN_IP_Auto")
			local zy6rdWanStaticIp = luci.http.formvalue("staticIp")

			local zy6rd6prefixleng = luci.http.formvalue("zy6rd6prefixleng")
			local zy6rd4prefixleng = luci.http.formvalue("zy6rd4prefixleng")

			if not zy6rd6prefixleng then
				zy6rd6prefixleng = 32
			end
			if not zy6rd4prefixleng then
				zy6rd4prefixleng = 0
			end

			if connection_IPmode == "IPv4_Only" then

				if zy6rdEnable == "on" then
					uci:delete("network","wan6rd1")
					uci:delete("network","wan6rdS1")
					uci:set("network", "wan6rd1", "interface")
					uci:set("network", "wan6rd1", "proto", "6rd")
					uci:set("network", "general", "wan6rd_enable", 1)
					uci:set("network", "wan2", "iface6rd", "")
					uci:set("network", "wan2", "reqopts", "")

					if connection_type == "PPPOE" then
						zy6rdCkWan = "0" --For pppoe check
					end

					--WAN DHCP
					if zy6rdCkWan == "1" then
						--6RD DHCP
						if auto_6rd == "auto" then
							uci:set("network", "wan2", "iface6rd", "wan6rd")
							uci:set("network", "wan2", "reqopts", "212")	
							--6RD Static
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end
					elseif zy6rdCkWan == "0" then
						if auto_6rd == "auto" then
							uci:set("network", "wan2", "iface6rd", "wan6rd")
							uci:set("network", "wan2", "reqopts", "212")	
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end			
					--WANStatic
					else
						--6RD DHCP
						local wan_ifname = uci:get("network","wan","ifname")
						if auto_6rd == "auto" then
							uci:set("network", "wan2", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "interface")
							uci:set("network", "wan6rdS1", "ifname", wan_ifname)
							uci:set("network", "wan6rdS1", "proto", "dhcp")
							uci:set("network", "wan6rdS1", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "reqopts", "212")	
							--6RD Static
						else		
							uci:set("network", "wan2", "iface6rd", "")
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
							uci:set("network", "wan6rd1", "ipaddr", zy6rdWanStaticIp)
						end	
					end

				else
					uci:set("network", "general", "wan6rd_enable", 0)
				end

			else
				uci:set("network", "general", "wan6rd_enable", 0)
			end
			--Add FOR 6RD

			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end

			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end

			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end

			uci:set("network","wan2","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","wan2","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","wan2","dns3",Server_dns3Type ..",".. Server_staticThiDns)


			local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
			local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
			local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
			local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
			local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
			local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")

			if Server_dnsv6_1Type~="USER" or Server_staticPriDnsv6 == "::/0" or not Server_staticPriDnsv6 then
				Server_staticPriDnsv6=""
			end

			if Server_dnsv6_2Type~="USER" or Server_staticSecDnsv6 == "::/0" or not Server_staticSecDnsv6 then
				Server_staticSecDnsv6=""
			end

			if Server_dnsv6_3Type~="USER" or Server_staticThiDnsv6 == "::/0" or not Server_staticThiDnsv6 then
				Server_staticThiDnsv6=""
			end

			uci:set("network","wan2","dnsv6_1",Server_dnsv6_1Type ..",".. Server_staticPriDnsv6)
			uci:set("network","wan2","dnsv6_2",Server_dnsv6_2Type ..",".. Server_staticSecDnsv6)
			uci:set("network","wan2","dnsv6_3",Server_dnsv6_3Type ..",".. Server_staticThiDnsv6)

			--WenHsien -- set IPmode into UCI
			if connection_IPmode == "IPv4_Only" then
				uci:set("network","wan2","ipv4","1")
				uci:set("network","wan2","ipv6","0")
				uci:set("network","wan2","ipv6Enable","0")
				uci:set("network","wan2","IP_version","IPv4_Only")
			elseif connection_IPmode == "Dual_Stack" then
				uci:set("network","wan2","ipv4","1")
				uci:set("network","wan2","ipv6","1")
				uci:set("network","wan2","ipv6Enable","1")
				uci:set("network","wan2","IP_version","Dual_Stack")
			else
				uci:set("network","wan2","ipv4","0")
				uci:set("network","wan2","ipv6","1")
				uci:set("network","wan2","ipv6Enable","1")
				uci:set("network","wan2","IP_version","IPv6_Only")
			end

			-- PPPoE
			if connection_type == "PPPOE" then
				uci:set("network","wan2","v6_proto","pppoe")

				local ipv6=uci:get("network","wan2","ipv6")
				if ipv6=="1" then
					uci:set("network","wan2","send_rs","0")
					uci:set("network","wan2","accept_ra","1")
					uci:set("dhcp6c","basic","ifname","pppoe-wan")
					uci:set("dhcp6c","basic","interface","wan")
					uci:commit("dhcp6c")	
				end


				local pppoeUser = luci.http.formvalue("pppoeUser")
				local pppoePass = luci.http.formvalue("pppoePass")
				local pppoeMTU = luci.http.formvalue("pppoeMTU")
				local pppoeNailedup = luci.http.formvalue("pppoeNailedup")
				local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
				local pppoeServiceName = luci.http.formvalue("pppoeServiceName")
				--local pppoePassthrough = luci.http.formvalue("pppoePassthrough")
				local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")

				if pppoeNailedup~="1" then
					pppoeNailedup=0
				end

				if not pppoeIdleTime then
					pppoeIdleTime=""
				end
				--[[
				if pppoePassthrough~="1" then
				pppoePassthrough=0
				end
				]]--

				if not pppoeWanIpAddr then
					pppoeWanIpAddr=""
				end

				--security issue
				local pppoePass_len = string.len(pppoePass)
							
				if (pppoePass_len >= 4 and string.find(pppoePass,"!@#^") == nil) then
					uci:set("network","wan2","password",pppoePass)
				else
					if pppoePass_len < 4 then
						if string.find(pppoePass,"<") == nil then
							uci:set("network","wan2","password",pppoePass)
						end
					end	
				end

				uci:set("network","wan2","proto","pppoe")
				uci:set("network","wan2","username",pppoeUser)
				--uci:set("network","wan2","password",pppoePass)
				uci:set("network","wan2","pppoe_mtu",pppoeMTU)
				uci:set("network","wan2","mtu",pppoeMTU)	
				uci:set("network","wan2","pppoeNailedup",pppoeNailedup)
				uci:set("network","wan2","demand",pppoeIdleTime)
				uci:set("network","wan2","service",pppoeServiceName)
				--uci:set("network","wan2","pppoePassthrough",pppoePassthrough)
				uci:set("network","wan2","pppoeWanIpAddr",pppoeWanIpAddr)
				uci:set("network","wan2","ip6addr","")
				uci:set("network","wan2","prefixlen","")
				uci:set("network","wan2","ip6gw","")  
				uci:set("network","wan2","IPv6_dns","")
				--uci:set("network","wan2","pppoev6_dns",pppoeipv6dns)
				--if not pppoeipv6dns then
				--sys.exec("echo nameserver "..pppoeipv6dns.." >> /tmp/resolv.conf.auto") 
				--end 
				--[[
				uci:delete("network","wan2","ipaddr")
				uci:delete("network","wan2","netmask")
				uci:delete("network","wan2","gateway")
				]]--
				--[[
				elseif connection_type == "PPTP" then

				local pptpUser = luci.http.formvalue("pptpUser")
				local pptpPass = luci.http.formvalue("pptpPass")
				local pptpMTU = luci.http.formvalue("pptpMTU")
				local pptpNailedup = luci.http.formvalue("pptpNailedup")
				local pptpIdleTime = luci.http.formvalue("pptpIdleTime")
				local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
				local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
				local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
				local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
				local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
				local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")
				local pptpWanIPMode = luci.http.formvalue("pptpWanIPMode")

				if pptpNailedup~="1" then
				pptpNailedup=0
				end

				if not pptpIdleTime then
				pptpIdleTime=""
				end

				if not pptpWanIpAddr then
				pptpWanIpAddr=""
				end					
				uci:set("network","wan2","proto","pptp")
				uci:set("network","wan2","v6_proto","pptp")
				uci:set("network","vpn","interface")
				uci:set("network","wan2","IP_version","IPv4_Only")

				if pptp_config_ip == "1" then
				uci:set("network","vpn","proto","dhcp")
				else
				uci:set("network","vpn","proto","static")
				uci:set("network","wan2","ipaddr",pptp_staticIp)
				uci:set("network","wan2","netmask",pptp_staticNetmask)
				uci:set("network","wan2","gateway",pptp_staticGateway)
				end

				uci:set("network","vpn","pptp_username",pptpUser)
				uci:set("network","vpn","pptp_password",pptpPass)
				uci:set("network","wan2","pptp_mtu",pptpMTU)
				uci:set("network","wan2","mtu",pptpMTU)
				uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
				uci:set("network","vpn","pptp_demand",pptpIdleTime)
				uci:set("network","vpn","pptp_serverip",pptp_serverIp)
				uci:set("network","vpn","pptpWanIPMode",pptpWanIPMode)
				uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)	
				]]--

				-- IPoE
			else
				-- IPoE/ v4
				if (connection_IPmode == "IPv4_Only") or (connection_IPmode == "Dual_Stack") then	
					local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
					local Fixed_staticIp = luci.http.formvalue("staticIp")
					local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
					local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					local ethMTU = luci.http.formvalue("ethMTU")

					-- IPoE/ v4/ DHCP
					if WAN_IP_Auto == "1" then
						local vendor_id = luci.http.formvalue("vendor_id")
						local dhcp121Enable  = luci.http.formvalue("dhcp121Enable")
						local dhcp125Enable  = luci.http.formvalue("dhcp125Enable")
						local dhcp43Enable  = luci.http.formvalue("dhcp43Enable")
						local dhcp60Enable = luci.http.formvalue("dhcp60Enable")

						uci:set("network","wan2","proto","dhcp")


						if not ( nil == vendor_id ) then
							uci:set("network", "wan2", "vendorid", vendor_id)
						else
							uci:set("network", "wan2", "vendorid", "")
						end

						if not ("0" == dhcp121Enable ) then
							uci:set("network", "wan2", "dhcp121", 0)
						else
							uci:set("network", "wan2", "dhcp121", 1)
						end

						if not ("0" == dhcp125Enable ) then
							uci:set("network", "wan2", "dhcp125", 0)
						else
							uci:set("network", "wan2", "dhcp125", 1)
						end

						if not ("0" == dhcp43Enable ) then
							uci:set("network", "wan2", "dhcp43", 0)
						else
							uci:set("network", "wan2", "dhcp43", 1)
						end

						if not ("0" == dhcp60Enable ) then
							uci:set("network", "wan2", "dhcp60", 0)
						else
							uci:set("network", "wan2", "dhcp60", 1)
						end

					-- IPoE/ v4/ STATIC
					else
						uci:set("network","wan2","proto","static")
						uci:set("network","wan2","ipaddr",Fixed_staticIp)
						uci:set("network","wan2","netmask",Fixed_staticNetmask)
						uci:set("network","wan2","gateway",Fixed_staticGateway)
					end
					uci:set("network","wan2","eth_mtu",ethMTU)
					uci:set("network","wan2","mtu",ethMTU)
					--[[
					uci:delete("network","wan2","username")
					uci:delete("network","wan2","password")
					uci:delete("network","wan2","pppoeNailedup")
					uci:delete("network","wan2","pppoeIdleTime")
					uci:delete("network","wan2","pppoeServiceName")
					uci:delete("network","wan2","pppoePassthrough")
					]]--
				end

				-- IPoE/ v6
				if (connection_IPmode == "IPv6_Only") or (connection_IPmode == "Dual_Stack") then
					local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
					local IPv6_Fixed_StaticIp = luci.http.formvalue("ipv6_address")
					local IPv6_Prefix_Length = luci.http.formvalue("prefix_length")
					local IPv6_Fixed_StaticGateway = luci.http.formvalue("ipv6_gateway")
					local IPv6_DNS = luci.http.formvalue("ipv6_dns")  
					--local IA_NA = luci.http.formvalue("ia_na")
					--local IA_PD = luci.http.formvalue("ia_pd")
					local request_v6_dns = luci.http.formvalue("auto_dns")
					local ethMTU = luci.http.formvalue("ethMTU")

					--uci:apply("RA_status")
					--uci:set("network6","wan2","type", "ipoev6")
					uci:set("network","wan2","send_rs","0")
					uci:set("network","wan2","accept_ra","1")
					uci:set("network","wan2","ifname", "eth0."..vid)
					uci:commit("network")	
					--uci:apply("network")

					uci:set("dhcp6c","basic","ifname","eth0."..vid)
					uci:set("dhcp6c","basic","interface","wan2")
					uci:commit("dhcp6c")
					--uci:apply("dhcp6c")

					-- IPoE/ v6/ DHCP
					if IPv6_WAN_IP_Auto == "auto" then
						uci:set("network","wan2","v6_proto","dhcp")
						uci:set("network","wan2","ip6addr","")
						uci:set("network","wan2","prefixlen","")
						uci:set("network","wan2","ip6gw","")  
						uci:set("network","wan2","IPv6_dns","")

						--uci:set("network6","wan2","type","dhcp")
						uci:set("dhcp6c","basic","enabled", 1)

						--local Server_dns1Type       = luci.http.formvalue("dns1Type")
						--local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
						--local Server_dns2Type       = luci.http.formvalue("dns2Type")
						--local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
						--local Server_dns3Type       = luci.http.formvalue("dns3Type")
						--local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
						--[[ if IA_NA then
						IA_NA=1
						else
						IA_NA=0 
						end
						if IA_PD then
						IA_PD=1
						else
						IA_PD=0
						end ]]--
						--uci:set("dhcp6c","basic","na", IA_NA)
						--uci:set("dhcp6c","basic","pd", IA_PD)
						uci:set("dhcp6c","lan","enabled", 1)
						uci:set("dhcp6c","lan","sla_id", 0)
						uci:set("dhcp6c","lan","sla_len", 0)
						uci:set("dhcp6c","basic","gui_run","1")

					-- IPoE/ v6/ STATIC
					else 
						uci:set("network","wan2","v6_proto","static") 
						uci:set("network","wan2","v6_static","1")   
						uci:set("network","wan2","ip6addr",IPv6_Fixed_StaticIp)
						uci:set("network","wan2","prefixlen",IPv6_Prefix_Length)
						uci:set("network","wan2","ip6gw",IPv6_Fixed_StaticGateway)  
						uci:set("network","wan2","IPv6_dns", IPv6_DNS) 
						uci:set("network","wan2","send_rs","1")
						uci:set("network","wan2","accept_ra","0")
					end  
					uci:commit("network") 
					uci:commit("dhcp6c")
					--WenHsien denoted for EMG
					--uci:apply("RA_dhcp6c")

					--uci:apply("network")
					-- if not IPv6_DNS then
					--sys.exec("echo nameserver "..IPv6_DNS.." >> /tmp/resolv.conf.auto") 
					-- end 
					--local ipv6_fixed_addr=uci:get("network","wan2","ip6addr") 
					--local ipv6_prefixlength=uci:get("network","wan2","prefixlen")  
					--if not ipv6_fixed_addr then ipv6_fixed_addr="" end 
					--if not ipv6_prefixlength then ipv6_prefixlength="" end
					--sys.exec("ifconfig eth0."..vid.." add "..ipv6_fixed_addr.."/"..IPv6_Prefix_Length)

					--local ipv6_fixedgateway=uci:get("network","wan2","ip6gw")
					--   if not ipv6_fixedgateway then ipv6_fixedgateway="" end
					--sys.exec("ip -6 route del default dev eth0."..vid) 
					--sys.exec("ip -6 route add default via "..ipv6_fixedgateway) 
				end
			end -- IP mode


			local WAN_MAC_Clone = luci.http.formvalue("WAN_MAC_Clone")
			local spoofIPAddr = luci.http.formvalue("spoofIPAddr")
			local macCloneMac = luci.http.formvalue("macCloneMac")
			--[[
			local old_WAN_MAC_Clone = uci:get("network", "wan2", "wan_mac_status")
			if not old_WAN_MAC_Clone then 
			old_WAN_MAC_Clone = "0"
			uci:set("network","wan2","wan_mac_status",old_WAN_MAC_Clone)
			end
			]]--
			--if WAN_MAC_Clone ~= old_WAN_MAC_Clone then
			if WAN_MAC_Clone == "0" then
				uci:set("network","wan2","wan_mac_status",WAN_MAC_Clone)

				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 0-15 > /tmp/mac0")
				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 16-17 >> /tmp/mac0")
				local idx_mac = 0
				for line in io.lines("/tmp/mac0") do
					idx_mac = idx_mac + 1
					if( idx_mac == 2 ) then
						line = tran16to10(line , 3)
						if(string.len(line) == 3) then
							line = string.sub(line , 2,3)
						end
						mac_wan = mac_wan..line 

					else
						mac_wan = line
					end
				end
				sys.exec("rm /tmp/mac0")
				uci:set("network","wan2","wan_set_mac",mac_wan)
				uci:set("network","wan2","macaddr",mac_wan)

				elseif WAN_MAC_Clone == "1" then
				local sw = 0
				local t={}
				t=luci.sys.net.arptable()
				for i,v in ipairs(t) do
					if t[i]["IP address"]==spoofIPAddr then 
						uci:set("network","wan2","wan_clone_ip",t[i]["IP address"])
						uci:set("network","wan2","wan_clone_ip_mac",t[i]["HW address"])
						uci:set("network","wan2","wan_set_mac",t[i]["HW address"])
						uci:set("network","wan2","macaddr",t[i]["HW address"])
						sw = 1
					end
				end

				if sw==1 then
					uci:set("network","wan2","wan_mac_status","1")
				else
					local url2 = luci.dispatcher.build_url("expert","configuration","network","wan2")		
					luci.http.redirect(url2 .. "?" .. "arp_error=1" .. "&error_addr=" .. spoofIPAddr)
				end

			elseif WAN_MAC_Clone == "2" then
				uci:set("network","wan2","wan_mac_status",WAN_MAC_Clone)
				uci:set("network","wan2","wan_set_mac",macCloneMac)
				uci:set("network","wan2","macaddr",macCloneMac)
			end

				--end

			uci:set("network","wan2","name", wan_name)
			uci:set("network","wan2","ifname", "eth0."..vid)
			uci:set("network","wan2","vid", vid)
			uci:set("network","wan2","pri",pri)
			uci:set("network","wan2","enable",1)

			uci:set("network","general","config_section","wan2")	

			--WenHsien
			local v6_static = uci:get("network","wan2","v6_static")
			if v6_static ~= "1" then	
				uci:commit("dhcp")
				--WenHsien denoted for EMG
				--uci:apply("dhcp")
				--uci:commit("network")	
				--uci:apply("network")
			end
			uci:set("network","wan2","v6_static","0")


			uci:commit("network")	
			uci:apply("network")  

			-- igmpproxy
			local igmpEnabled = luci.http.formvalue("igmpEnabled")
			local ori_igmpEnabled = uci:get("igmpproxy","wan2","igmpEnabled")
			if igmpEnabled ~= ori_igmpEnabled then
				uci:set("igmpproxy","wan2","igmpEnabled",igmpEnabled)
				if igmpEnabled == "enable" then			
					uci:set("igmpproxy","wan","igmpEnabled","disable")
					uci:set("igmpproxy","wan1","igmpEnabled","disable")
					uci:set("igmpproxy","wan3","igmpEnabled","disable")
					uci:set("igmpproxy","wan4","igmpEnabled","disable")
				end	
				uci:commit("igmpproxy")
				uci:apply("igmpproxy")
			end
			-- igmpproxy		

			uci:apply("qos")
			sys.exec("/sbin/configure_intfGrp set_iptables_rule")

			--WenHsien
			local url2 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url2)
		end
		io.popen("/etc/init.d/default_lan_radvd boot")
	end

	luci.template.render("expert_configuration/broadband2_add")
end

function action_wan_internet_connection3()

	local apply = luci.http.formvalue("apply")

	if apply then

		local connection_type = luci.http.formvalue("connectionType")
		local connection_IPmode = luci.http.formvalue("IP_Mode")
	
		-- clean opt121 static route
		uci:delete("network","wan3","staticroutes")
		uci:delete("network","wan3","msstaticroutes")
		
		-- clean isp_gw
		uci:delete("network","wan3","isp_gw")

		if connection_type == "Bridge" then

			local wan_name = luci.http.formvalue("wan_name")
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end 

			local tag_flag = luci.http.formvalue("ignore_vid")

			--sys.exec("echo ".."\"enter\"".." >> /tmp/aaa")

			local old_ifname = uci:get("network","wan3","ifname")
			local ifname = "eth0."..vid
			--sys.exec("/bin/set_subwan delete "..old_ifname)
			-- Create sub-wan [vid] [ifname] [Mac-address char] [tag or not]
			if ("1" == tag_flag) then
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 0".." br")
				uci:set("network","wan3","untag","1")
			else
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 1".." br")
				uci:set("network","wan3","untag","0")
			end

			uci:set("network","wan3","proto", "bridge")
			uci:set("network","wan3","name", wan_name)
			uci:set("network","wan3","ifname", "eth0."..vid)
			uci:set("network","wan3","vid", vid)
			uci:set("network","wan3","pri",pri)
			uci:set("network","wan3","enable",1)
			uci:set("network","general","config_section","wan3")
			uci:set("network","wan3","IP_version","IPv4_Only")	
			uci:commit("network")	
			uci:apply("network")
			uci:apply("qos")

			local url3 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url3)
		else

			-- lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")
			local wan_proto = uci:get("network","wan3","proto")
			sys.exec("echo "..wan_proto.." > /tmp/old_wan3_proto")

			local wan_name = luci.http.formvalue("wan_name")	
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end 

			local tag_flag = luci.http.formvalue("ignore_vid")	


			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			local Server_dns3Type       = luci.http.formvalue("dns3Type")
			local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

			-- Delete the default wan interface first
			local old_ifname = uci:get("network","wan3","ifname")
			local ifname = "eth0."..vid
			local mac_wan=""

			--And call the script for creating New sub wan

			uci:set("network","wan3","untag","1")
			--Add FOR 6RD	
			local zy6rdEnable = luci.http.formvalue("zy6rdEnable")
			local auto_6rd = luci.http.formvalue("auto_6rd")
			local zy6rd6prefix = luci.http.formvalue("zy6rd6prefix")
			local zy6rd4ip= luci.http.formvalue("zy6rd4ip")
			local zy6rdCkWan = luci.http.formvalue("WAN_IP_Auto")
			local zy6rdWanStaticIp = luci.http.formvalue("staticIp")

			local zy6rd6prefixleng = luci.http.formvalue("zy6rd6prefixleng")
			local zy6rd4prefixleng = luci.http.formvalue("zy6rd4prefixleng")

			if not zy6rd6prefixleng then
				zy6rd6prefixleng = 32
			end
			if not zy6rd4prefixleng then
				zy6rd4prefixleng = 0
			end

			if connection_IPmode == "IPv4_Only" then

				if zy6rdEnable == "on" then
					uci:delete("network","wan6rd1")
					uci:delete("network","wan6rdS1")
					uci:set("network", "wan6rd1", "interface")
					uci:set("network", "wan6rd1", "proto", "6rd")
					uci:set("network", "general", "wan6rd_enable", 1)
					uci:set("network", "wan3", "iface6rd", "")
					uci:set("network", "wan3", "reqopts", "")

					if connection_type == "PPPOE" then
						zy6rdCkWan = "0" --For pppoe check
					end

					--WAN DHCP
					if zy6rdCkWan == "1" then
						--6RD DHCP
						if auto_6rd == "auto" then
							uci:set("network", "wan3", "iface6rd", "wan6rd")
							uci:set("network", "wan3", "reqopts", "212")	
							--6RD Static
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end
					elseif zy6rdCkWan == "0" then
						if auto_6rd == "auto" then
							uci:set("network", "wan3", "iface6rd", "wan6rd")
							uci:set("network", "wan3", "reqopts", "212")	
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end			
					--WANStatic
					else
					--6RD DHCP
						local wan_ifname = uci:get("network","wan","ifname")
						if auto_6rd == "auto" then
							uci:set("network", "wan3", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "interface")
							uci:set("network", "wan6rdS1", "ifname", wan_ifname)
							uci:set("network", "wan6rdS1", "proto", "dhcp")
							uci:set("network", "wan6rdS1", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "reqopts", "212")	
						--6RD Static
						else		
							uci:set("network", "wan3", "iface6rd", "")
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
							uci:set("network", "wan6rd1", "ipaddr", zy6rdWanStaticIp)
						end	
					end

				else
					uci:set("network", "general", "wan6rd_enable", 0)
				end

			else
				uci:set("network", "general", "wan6rd_enable", 0)
			end
			--Add FOR 6RD

			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end

			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end

			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end

			uci:set("network","wan3","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","wan3","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","wan3","dns3",Server_dns3Type ..",".. Server_staticThiDns)


			local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
			local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
			local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
			local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
			local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
			local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")

			if Server_dnsv6_1Type~="USER" or Server_staticPriDnsv6 == "::/0" or not Server_staticPriDnsv6 then
				Server_staticPriDnsv6=""
			end

			if Server_dnsv6_2Type~="USER" or Server_staticSecDnsv6 == "::/0" or not Server_staticSecDnsv6 then
				Server_staticSecDnsv6=""
			end

			if Server_dnsv6_3Type~="USER" or Server_staticThiDnsv6 == "::/0" or not Server_staticThiDnsv6 then
				Server_staticThiDnsv6=""
			end

			uci:set("network","wan3","dnsv6_1",Server_dnsv6_1Type ..",".. Server_staticPriDnsv6)
			uci:set("network","wan3","dnsv6_2",Server_dnsv6_2Type ..",".. Server_staticSecDnsv6)
			uci:set("network","wan3","dnsv6_3",Server_dnsv6_3Type ..",".. Server_staticThiDnsv6)

			--WenHsien -- set IPmode into UCI
			if connection_IPmode == "IPv4_Only" then
				uci:set("network","wan3","ipv4","1")
				uci:set("network","wan3","ipv6","0")
				uci:set("network","wan3","ipv6Enable","0")
				uci:set("network","wan3","IP_version","IPv4_Only")
			elseif connection_IPmode == "Dual_Stack" then
				uci:set("network","wan3","ipv4","1")
				uci:set("network","wan3","ipv6","1")
				uci:set("network","wan3","ipv6Enable","1")
				uci:set("network","wan3","IP_version","Dual_Stack")
			else
				uci:set("network","wan3","ipv4","0")
				uci:set("network","wan3","ipv6","1")
				uci:set("network","wan3","ipv6Enable","1")
				uci:set("network","wan3","IP_version","IPv6_Only")
			end

			-- PPPoE
			if connection_type == "PPPOE" then
				uci:set("network","wan3","v6_proto","pppoe")

				local ipv6=uci:get("network","wan3","ipv6")
				if ipv6=="1" then
					uci:set("network","wan3","send_rs","0")
					uci:set("network","wan3","accept_ra","1")
					uci:set("dhcp6c","basic","ifname","pppoe-wan")
					uci:set("dhcp6c","basic","interface","wan")
					uci:commit("dhcp6c")	
				end

				local pppoeUser = luci.http.formvalue("pppoeUser")
				local pppoePass = luci.http.formvalue("pppoePass")
				local pppoeMTU = luci.http.formvalue("pppoeMTU")
				local pppoeNailedup = luci.http.formvalue("pppoeNailedup")
				local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
				local pppoeServiceName = luci.http.formvalue("pppoeServiceName")
				--local pppoePassthrough = luci.http.formvalue("pppoePassthrough")
				local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")

				if pppoeNailedup~="1" then
					pppoeNailedup=0
				end

				if not pppoeIdleTime then
					pppoeIdleTime=""
				end
				--[[
				if pppoePassthrough~="1" then
				pppoePassthrough=0
				end
				]]--

				if not pppoeWanIpAddr then
					pppoeWanIpAddr=""
				end

				--security issue
				local pppoePass_len = string.len(pppoePass)
							
				if (pppoePass_len >= 4 and string.find(pppoePass,"!@#^") == nil) then
					uci:set("network","wan3","password",pppoePass)
				else
					if pppoePass_len < 4 then
						if string.find(pppoePass,"<") == nil then
							uci:set("network","wan3","password",pppoePass)
						end
					end	
				end

				uci:set("network","wan3","proto","pppoe")
				uci:set("network","wan3","username",pppoeUser)
				--uci:set("network","wan3","password",pppoePass)
				uci:set("network","wan3","pppoe_mtu",pppoeMTU)
				uci:set("network","wan3","mtu",pppoeMTU)	
				uci:set("network","wan3","pppoeNailedup",pppoeNailedup)
				uci:set("network","wan3","demand",pppoeIdleTime)
				uci:set("network","wan3","service",pppoeServiceName)
				--uci:set("network","wan3","pppoePassthrough",pppoePassthrough)
				uci:set("network","wan3","pppoeWanIpAddr",pppoeWanIpAddr)
				uci:set("network","wan3","ip6addr","")
				uci:set("network","wan3","prefixlen","")
				uci:set("network","wan3","ip6gw","")  
				uci:set("network","wan3","IPv6_dns","")
				--uci:set("network","wan3","pppoev6_dns",pppoeipv6dns)
				--if not pppoeipv6dns then
				--sys.exec("echo nameserver "..pppoeipv6dns.." >> /tmp/resolv.conf.auto") 
				--end 
				--[[
				uci:delete("network","wan3","ipaddr")
				uci:delete("network","wan3","netmask")
				uci:delete("network","wan3","gateway")
				]]--
				--[[
				elseif connection_type == "PPTP" then

				local pptpUser = luci.http.formvalue("pptpUser")
				local pptpPass = luci.http.formvalue("pptpPass")
				local pptpMTU = luci.http.formvalue("pptpMTU")
				local pptpNailedup = luci.http.formvalue("pptpNailedup")
				local pptpIdleTime = luci.http.formvalue("pptpIdleTime")
				local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
				local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
				local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
				local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
				local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
				local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")
				local pptpWanIPMode = luci.http.formvalue("pptpWanIPMode")

				if pptpNailedup~="1" then
				pptpNailedup=0
				end

				if not pptpIdleTime then
				pptpIdleTime=""
				end

				if not pptpWanIpAddr then
				pptpWanIpAddr=""
				end					
				uci:set("network","wan3","proto","pptp")
				uci:set("network","wan3","v6_proto","pptp")
				uci:set("network","vpn","interface")
				uci:set("network","wan3","IP_version","IPv4_Only")

				if pptp_config_ip == "1" then
				uci:set("network","vpn","proto","dhcp")
				else
				uci:set("network","vpn","proto","static")
				uci:set("network","wan3","ipaddr",pptp_staticIp)
				uci:set("network","wan3","netmask",pptp_staticNetmask)
				uci:set("network","wan3","gateway",pptp_staticGateway)
				end

				uci:set("network","vpn","pptp_username",pptpUser)
				uci:set("network","vpn","pptp_password",pptpPass)
				uci:set("network","wan3","pptp_mtu",pptpMTU)
				uci:set("network","wan3","mtu",pptpMTU)
				uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
				uci:set("network","vpn","pptp_demand",pptpIdleTime)
				uci:set("network","vpn","pptp_serverip",pptp_serverIp)
				uci:set("network","vpn","pptpWanIPMode",pptpWanIPMode)
				uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)	
				]]--

			-- IPoE
			else
				-- IPoE/ v4
				if (connection_IPmode == "IPv4_Only") or (connection_IPmode == "Dual_Stack") then	
					local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
					local Fixed_staticIp = luci.http.formvalue("staticIp")
					local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
					local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					local ethMTU = luci.http.formvalue("ethMTU")

					-- IPoE/ v4/ DHCP
					if WAN_IP_Auto == "1" then
						local vendor_id = luci.http.formvalue("vendor_id")
						local dhcp121Enable  = luci.http.formvalue("dhcp121Enable")
						local dhcp125Enable  = luci.http.formvalue("dhcp125Enable")
						local dhcp43Enable  = luci.http.formvalue("dhcp43Enable")
						local dhcp60Enable = luci.http.formvalue("dhcp60Enable")

						uci:set("network","wan3","proto","dhcp")


						if not ( nil == vendor_id ) then
							uci:set("network", "wan3", "vendorid", vendor_id)
						else
							uci:set("network", "wan3", "vendorid", "")
						end

						if not ("0" == dhcp121Enable ) then
							uci:set("network", "wan3", "dhcp121", 0)
						else
							uci:set("network", "wan3", "dhcp121", 1)
						end

						if not ("0" == dhcp125Enable ) then
							uci:set("network", "wan3", "dhcp125", 0)
						else
							uci:set("network", "wan3", "dhcp125", 1)
						end

						if not ("0" == dhcp43Enable ) then
							uci:set("network", "wan3", "dhcp43", 0)
						else
							uci:set("network", "wan3", "dhcp43", 1)
						end

						if not ("0" == dhcp60Enable ) then
							uci:set("network", "wan3", "dhcp60", 0)
						else
							uci:set("network", "wan3", "dhcp60", 1)
						end

					-- IPoE/ v4/ STATIC
					else
						uci:set("network","wan3","proto","static")
						uci:set("network","wan3","ipaddr",Fixed_staticIp)
						uci:set("network","wan3","netmask",Fixed_staticNetmask)
						uci:set("network","wan3","gateway",Fixed_staticGateway)
					end
					uci:set("network","wan3","eth_mtu",ethMTU)
					uci:set("network","wan3","mtu",ethMTU)
					--[[
					uci:delete("network","wan3","username")
					uci:delete("network","wan3","password")
					uci:delete("network","wan3","pppoeNailedup")
					uci:delete("network","wan3","pppoeIdleTime")
					uci:delete("network","wan3","pppoeServiceName")
					uci:delete("network","wan3","pppoePassthrough")
					]]--
				end

				-- IPoE/ v6
				if (connection_IPmode == "IPv6_Only") or (connection_IPmode == "Dual_Stack") then
					local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
					local IPv6_Fixed_StaticIp = luci.http.formvalue("ipv6_address")
					local IPv6_Prefix_Length = luci.http.formvalue("prefix_length")
					local IPv6_Fixed_StaticGateway = luci.http.formvalue("ipv6_gateway")
					local IPv6_DNS = luci.http.formvalue("ipv6_dns")  
					--local IA_NA = luci.http.formvalue("ia_na")
					--local IA_PD = luci.http.formvalue("ia_pd")
					local request_v6_dns = luci.http.formvalue("auto_dns")
					local ethMTU = luci.http.formvalue("ethMTU")

					--uci:apply("RA_status")
					--uci:set("network6","wan3","type", "ipoev6")
					uci:set("network","wan3","send_rs","0")
					uci:set("network","wan3","accept_ra","1")
					uci:set("network","wan3","ifname", "eth0."..vid)
					uci:commit("network")	
					--uci:apply("network")

					uci:set("dhcp6c","basic","ifname","eth0."..vid)
					uci:set("dhcp6c","basic","interface","wan3")
					uci:commit("dhcp6c")
					--uci:apply("dhcp6c")

					-- IPoE/ v6/ DHCP
					if IPv6_WAN_IP_Auto == "auto" then
						uci:set("network","wan3","v6_proto","dhcp")
						uci:set("network","wan3","ip6addr","")
						uci:set("network","wan3","prefixlen","")
						uci:set("network","wan3","ip6gw","")  
						uci:set("network","wan3","IPv6_dns","")

						--uci:set("network6","wan3","type","dhcp")
						uci:set("dhcp6c","basic","enabled", 1)

						--local Server_dns1Type       = luci.http.formvalue("dns1Type")
						--local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
						--local Server_dns2Type       = luci.http.formvalue("dns2Type")
						--local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
						--local Server_dns3Type       = luci.http.formvalue("dns3Type")
						--local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
						--[[ if IA_NA then
						IA_NA=1
						else
						IA_NA=0 
						end
						if IA_PD then
						IA_PD=1
						else
						IA_PD=0
						end ]]--
						--uci:set("dhcp6c","basic","na", IA_NA)
						--uci:set("dhcp6c","basic","pd", IA_PD)
						uci:set("dhcp6c","lan","enabled", 1)
						uci:set("dhcp6c","lan","sla_id", 0)
						uci:set("dhcp6c","lan","sla_len", 0)
						uci:set("dhcp6c","basic","gui_run","1")

						-- IPoE/ v6/ STATIC
					else 
						uci:set("network","wan3","v6_proto","static") 
						uci:set("network","wan3","v6_static","1")   
						uci:set("network","wan3","ip6addr",IPv6_Fixed_StaticIp)
						uci:set("network","wan3","prefixlen",IPv6_Prefix_Length)
						uci:set("network","wan3","ip6gw",IPv6_Fixed_StaticGateway)  
						uci:set("network","wan3","IPv6_dns", IPv6_DNS) 
						uci:set("network","wan3","send_rs","1")
						uci:set("network","wan3","accept_ra","0")
					end  
					uci:commit("network") 
					uci:commit("dhcp6c")
					--WenHsien denoted for EMG
					--uci:apply("RA_dhcp6c")

					--uci:apply("network")
					-- if not IPv6_DNS then
					--sys.exec("echo nameserver "..IPv6_DNS.." >> /tmp/resolv.conf.auto") 
					-- end 
					--local ipv6_fixed_addr=uci:get("network","wan3","ip6addr") 
					--local ipv6_prefixlength=uci:get("network","wan3","prefixlen")  
					--if not ipv6_fixed_addr then ipv6_fixed_addr="" end 
					--if not ipv6_prefixlength then ipv6_prefixlength="" end
					--sys.exec("ifconfig eth0."..vid.." add "..ipv6_fixed_addr.."/"..IPv6_Prefix_Length)

					--local ipv6_fixedgateway=uci:get("network","wan3","ip6gw")
					--   if not ipv6_fixedgateway then ipv6_fixedgateway="" end
					--sys.exec("ip -6 route del default dev eth0."..vid) 
					--sys.exec("ip -6 route add default via "..ipv6_fixedgateway) 
				end
			end -- IP mode


			local WAN_MAC_Clone = luci.http.formvalue("WAN_MAC_Clone")
			local spoofIPAddr = luci.http.formvalue("spoofIPAddr")
			local macCloneMac = luci.http.formvalue("macCloneMac")
			--[[
			local old_WAN_MAC_Clone = uci:get("network", "wan3", "wan_mac_status")
			if not old_WAN_MAC_Clone then 
			old_WAN_MAC_Clone = "0"
			uci:set("network","wan3","wan_mac_status",old_WAN_MAC_Clone)
			end
			]]--
			--if WAN_MAC_Clone ~= old_WAN_MAC_Clone then
			if WAN_MAC_Clone == "0" then
				uci:set("network","wan3","wan_mac_status",WAN_MAC_Clone)

				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 0-15 > /tmp/mac0")
				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 16-17 >> /tmp/mac0")
				local idx_mac = 0
				for line in io.lines("/tmp/mac0") do
					idx_mac = idx_mac + 1
					if( idx_mac == 2 ) then
						line = tran16to10(line , 3)
						if(string.len(line) == 3) then
							line = string.sub(line , 2,3)
						end
						mac_wan = mac_wan..line 

					else
						mac_wan = line
					end
				end
				sys.exec("rm /tmp/mac0")
				uci:set("network","wan3","wan_set_mac",mac_wan)
				uci:set("network","wan3","macaddr",mac_wan)

			elseif WAN_MAC_Clone == "1" then
				local sw = 0
				local t={}
				t=luci.sys.net.arptable()
				for i,v in ipairs(t) do
					if t[i]["IP address"]==spoofIPAddr then 
						uci:set("network","wan3","wan_clone_ip",t[i]["IP address"])
						uci:set("network","wan3","wan_clone_ip_mac",t[i]["HW address"])
						uci:set("network","wan3","wan_set_mac",t[i]["HW address"])
						uci:set("network","wan3","macaddr",t[i]["HW address"])
						sw = 1
					end
				end

				if sw==1 then
					uci:set("network","wan3","wan_mac_status","1")
				else
					local url3 = luci.dispatcher.build_url("expert","configuration","network","wan3")		
					luci.http.redirect(url3 .. "?" .. "arp_error=1" .. "&error_addr=" .. spoofIPAddr)
				end

			elseif WAN_MAC_Clone == "2" then
				uci:set("network","wan3","wan_mac_status",WAN_MAC_Clone)
				uci:set("network","wan3","wan_set_mac",macCloneMac)
				uci:set("network","wan3","macaddr",macCloneMac)
			end

			--end

			uci:set("network","wan3","name", wan_name)
			uci:set("network","wan3","ifname", "eth0."..vid)
			uci:set("network","wan3","vid", vid)
			uci:set("network","wan3","pri",pri)
			uci:set("network","wan3","enable",1)

			uci:set("network","general","config_section","wan3")	

			--WenHsien
			local v6_static = uci:get("network","wan3","v6_static")
			if v6_static ~= "1" then	
				uci:commit("dhcp")
				--WenHsien denoted for EMG
				--uci:apply("dhcp")
				--uci:commit("network")	
				--uci:apply("network")
			end
			uci:set("network","wan3","v6_static","0")


			uci:commit("network")	
			uci:apply("network")  

			-- igmpproxy
			local igmpEnabled = luci.http.formvalue("igmpEnabled")
			local ori_igmpEnabled = uci:get("igmpproxy","wan3","igmpEnabled")
			if igmpEnabled ~= ori_igmpEnabled then
				uci:set("igmpproxy","wan3","igmpEnabled",igmpEnabled)
				if igmpEnabled == "enable" then			
					uci:set("igmpproxy","wan","igmpEnabled","disable")
					uci:set("igmpproxy","wan1","igmpEnabled","disable")
					uci:set("igmpproxy","wan2","igmpEnabled","disable")
					uci:set("igmpproxy","wan4","igmpEnabled","disable")
				end
				uci:commit("igmpproxy")
				uci:apply("igmpproxy")
			end
			-- igmpproxy

			uci:apply("qos")
			sys.exec("/sbin/configure_intfGrp set_iptables_rule")

			--WenHsien
			local url3 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url3)
		end

		io.popen("/etc/init.d/default_lan_radvd boot")   
	end
	luci.template.render("expert_configuration/broadband3_add")

end

function action_wan_internet_connection4()

	local apply = luci.http.formvalue("apply")

	if apply then
		local connection_type = luci.http.formvalue("connectionType")
		local connection_IPmode = luci.http.formvalue("IP_Mode")	

		-- clean opt121 static route
		uci:delete("network","wan4","staticroutes")
		uci:delete("network","wan4","msstaticroutes")
		
		-- clean isp_gw
		uci:delete("network","wan4","isp_gw")

		if connection_type == "Bridge" then

			local wan_name = luci.http.formvalue("wan_name")
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end 

			local tag_flag = luci.http.formvalue("ignore_vid")

			--sys.exec("echo ".."\"enter\"".." >> /tmp/aaa")

			local old_ifname = uci:get("network","wan4","ifname")
			local ifname = "eth0."..vid
			--sys.exec("/bin/set_subwan delete "..old_ifname)
			-- Create sub-wan [vid] [ifname] [Mac-address char] [tag or not] [diff mac address]
			if ("1" == tag_flag) then
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 0".." br")
				uci:set("network","wan4","untag","1")
			else
				--sys.exec("/bin/set_subwan add "..vid.." "..ifname.." 1".." br")
				uci:set("network","wan4","untag","0")
			end

			uci:set("network","wan4","proto", "bridge")
			uci:set("network","wan4","name", wan_name)
			uci:set("network","wan4","ifname", "eth0."..vid)
			uci:set("network","wan4","vid", vid)
			uci:set("network","wan4","pri",pri)
			uci:set("network","wan4","enable",1)
			uci:set("network","general","config_section","wan4")
			uci:set("network","wan4","IP_version","IPv4_Only")	
			uci:commit("network")	
			uci:apply("network")
			uci:apply("qos")


			local url4 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url4) 
		else


			-- lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")
			local wan_proto = uci:get("network","wan4","proto")
			sys.exec("echo "..wan_proto.." > /tmp/old_wan4_proto")

			local wan_name = luci.http.formvalue("wan_name")	
			local vid = luci.http.formvalue("wan_vid")
			local pri = luci.http.formvalue("wan_pri")

			if nil == pri then
				pri="0"
			end  

			local tag_flag = luci.http.formvalue("ignore_vid")	


			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			local Server_dns3Type       = luci.http.formvalue("dns3Type")
			local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

			-- Delete the default wan interface first
			local old_ifname = uci:get("network","wan4","ifname")
			local ifname = "eth0."..vid
			local mac_wan=""

			--And call the script for creating New sub wan

			uci:set("network","wan4","untag","1")
			--Add FOR 6RD	
			local zy6rdEnable = luci.http.formvalue("zy6rdEnable")
			local auto_6rd = luci.http.formvalue("auto_6rd")
			local zy6rd6prefix = luci.http.formvalue("zy6rd6prefix")
			local zy6rd4ip= luci.http.formvalue("zy6rd4ip")
			local zy6rdCkWan = luci.http.formvalue("WAN_IP_Auto")
			local zy6rdWanStaticIp = luci.http.formvalue("staticIp")

			local zy6rd6prefixleng = luci.http.formvalue("zy6rd6prefixleng")
			local zy6rd4prefixleng = luci.http.formvalue("zy6rd4prefixleng")

			if not zy6rd6prefixleng then
				zy6rd6prefixleng = 32
			end
			if not zy6rd4prefixleng then
				zy6rd4prefixleng = 0
			end

			if connection_IPmode == "IPv4_Only" then

				if zy6rdEnable == "on" then
					uci:delete("network","wan6rd1")
					uci:delete("network","wan6rdS1")
					uci:set("network", "wan6rd1", "interface")
					uci:set("network", "wan6rd1", "proto", "6rd")
					uci:set("network", "general", "wan6rd_enable", 1)
					uci:set("network", "wan4", "iface6rd", "")
					uci:set("network", "wan4", "reqopts", "")

					if connection_type == "PPPOE" then
						zy6rdCkWan = "0" --For pppoe check
					end

					--WAN DHCP
					if zy6rdCkWan == "1" then
						--6RD DHCP
						if auto_6rd == "auto" then
							uci:set("network", "wan4", "iface6rd", "wan6rd")
							uci:set("network", "wan4", "reqopts", "212")	
							--6RD Static
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end
					elseif zy6rdCkWan == "0" then
						if auto_6rd == "auto" then
							uci:set("network", "wan4", "iface6rd", "wan6rd")
							uci:set("network", "wan4", "reqopts", "212")	
						else
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
						end			
					--WANStatic
					else
					--6RD DHCP
						local wan_ifname = uci:get("network","wan","ifname")
						if auto_6rd == "auto" then
							uci:set("network", "wan4", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "interface")
							uci:set("network", "wan6rdS1", "ifname", wan_ifname)
							uci:set("network", "wan6rdS1", "proto", "dhcp")
							uci:set("network", "wan6rdS1", "iface6rd", "wan6rd")
							uci:set("network", "wan6rdS1", "reqopts", "212")	
						--6RD Static
						else		
							uci:set("network", "wan4", "iface6rd", "")
							uci:set("network", "wan6rd1", "peeraddr", zy6rd4ip)
							uci:set("network", "wan6rd1", "ip6prefix", zy6rd6prefix)
							uci:set("network", "wan6rd1", "ip6prefixlen", zy6rd6prefixleng)
							uci:set("network", "wan6rd1", "ip4prefixlen", zy6rd4prefixleng)
							uci:set("network", "wan6rd1", "ipaddr", zy6rdWanStaticIp)
						end	
					end

				else
					uci:set("network", "general", "wan6rd_enable", 0)
				end

			else
				uci:set("network", "general", "wan6rd_enable", 0)
			end
			--Add FOR 6RD

			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end

			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end

			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end

			uci:set("network","wan4","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","wan4","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","wan4","dns3",Server_dns3Type ..",".. Server_staticThiDns)


			local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
			local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
			local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
			local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
			local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
			local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")

			if Server_dnsv6_1Type~="USER" or Server_staticPriDnsv6 == "::/0" or not Server_staticPriDnsv6 then
				Server_staticPriDnsv6=""
			end

			if Server_dnsv6_2Type~="USER" or Server_staticSecDnsv6 == "::/0" or not Server_staticSecDnsv6 then
				Server_staticSecDnsv6=""
			end

			if Server_dnsv6_3Type~="USER" or Server_staticThiDnsv6 == "::/0" or not Server_staticThiDnsv6 then
				Server_staticThiDnsv6=""
			end

			uci:set("network","wan4","dnsv6_1",Server_dnsv6_1Type ..",".. Server_staticPriDnsv6)
			uci:set("network","wan4","dnsv6_2",Server_dnsv6_2Type ..",".. Server_staticSecDnsv6)
			uci:set("network","wan4","dnsv6_3",Server_dnsv6_3Type ..",".. Server_staticThiDnsv6)

			--WenHsien -- set IPmode into UCI
			if connection_IPmode == "IPv4_Only" then
				uci:set("network","wan4","ipv4","1")
				uci:set("network","wan4","ipv6","0")
				uci:set("network","wan4","ipv6Enable","0")
				uci:set("network","wan4","IP_version","IPv4_Only")
			elseif connection_IPmode == "Dual_Stack" then
				uci:set("network","wan4","ipv4","1")
				uci:set("network","wan4","ipv6","1")
				uci:set("network","wan4","ipv6Enable","1")
				uci:set("network","wan4","IP_version","Dual_Stack")
			else
				uci:set("network","wan4","ipv4","0")
				uci:set("network","wan4","ipv6","1")
				uci:set("network","wan4","ipv6Enable","1")
				uci:set("network","wan4","IP_version","IPv6_Only")
			end

			-- PPPoE
			if connection_type == "PPPOE" then
				uci:set("network","wan4","v6_proto","pppoe")

				local ipv6=uci:get("network","wan4","ipv6")
				if ipv6=="1" then
					uci:set("network","wan4","send_rs","0")
					uci:set("network","wan4","accept_ra","1")
					uci:set("dhcp6c","basic","ifname","pppoe-wan")
					uci:set("dhcp6c","basic","interface","wan")
					uci:commit("dhcp6c")	
				end


				local pppoeUser = luci.http.formvalue("pppoeUser")
				local pppoePass = luci.http.formvalue("pppoePass")
				local pppoeMTU = luci.http.formvalue("pppoeMTU")
				local pppoeNailedup = luci.http.formvalue("pppoeNailedup")
				local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
				local pppoeServiceName = luci.http.formvalue("pppoeServiceName")
				--local pppoePassthrough = luci.http.formvalue("pppoePassthrough")
				local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")

				if pppoeNailedup~="1" then
					pppoeNailedup=0
				end

				if not pppoeIdleTime then
					pppoeIdleTime=""
				end
				--[[
				if pppoePassthrough~="1" then
				pppoePassthrough=0
				end
				]]--

				if not pppoeWanIpAddr then
					pppoeWanIpAddr=""
				end

				--security issue
				local pppoePass_len = string.len(pppoePass)
							
				if (pppoePass_len >= 4 and string.find(pppoePass,"!@#^") == nil) then
					uci:set("network","wan4","password",pppoePass)
				else
					if pppoePass_len < 4 then
						if string.find(pppoePass,"<") == nil then
							uci:set("network","wan4","password",pppoePass)
						end
					end	
				end

				uci:set("network","wan4","proto","pppoe")
				uci:set("network","wan4","username",pppoeUser)
				--uci:set("network","wan4","password",pppoePass)
				uci:set("network","wan4","pppoe_mtu",pppoeMTU)
				uci:set("network","wan4","mtu",pppoeMTU)	
				uci:set("network","wan4","pppoeNailedup",pppoeNailedup)
				uci:set("network","wan4","demand",pppoeIdleTime)
				uci:set("network","wan4","service",pppoeServiceName)
				--uci:set("network","wan4","pppoePassthrough",pppoePassthrough)
				uci:set("network","wan4","pppoeWanIpAddr",pppoeWanIpAddr)
				uci:set("network","wan4","ip6addr","")
				uci:set("network","wan4","prefixlen","")
				uci:set("network","wan4","ip6gw","")  
				uci:set("network","wan4","IPv6_dns","")
				--uci:set("network","wan4","pppoev6_dns",pppoeipv6dns)
				--if not pppoeipv6dns then
				--sys.exec("echo nameserver "..pppoeipv6dns.." >> /tmp/resolv.conf.auto") 
				--end 
				--[[
				uci:delete("network","wan4","ipaddr")
				uci:delete("network","wan4","netmask")
				uci:delete("network","wan4","gateway")
				]]--
				--[[
				elseif connection_type == "PPTP" then

				local pptpUser = luci.http.formvalue("pptpUser")
				local pptpPass = luci.http.formvalue("pptpPass")
				local pptpMTU = luci.http.formvalue("pptpMTU")
				local pptpNailedup = luci.http.formvalue("pptpNailedup")
				local pptpIdleTime = luci.http.formvalue("pptpIdleTime")
				local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
				local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
				local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
				local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
				local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
				local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")
				local pptpWanIPMode = luci.http.formvalue("pptpWanIPMode")

				if pptpNailedup~="1" then
				pptpNailedup=0
				end

				if not pptpIdleTime then
				pptpIdleTime=""
				end

				if not pptpWanIpAddr then
				pptpWanIpAddr=""
				end					
				uci:set("network","wan4","proto","pptp")
				uci:set("network","wan4","v6_proto","pptp")
				uci:set("network","vpn","interface")
				uci:set("network","wan4","IP_version","IPv4_Only")

				if pptp_config_ip == "1" then
				uci:set("network","vpn","proto","dhcp")
				else
				uci:set("network","vpn","proto","static")
				uci:set("network","wan4","ipaddr",pptp_staticIp)
				uci:set("network","wan4","netmask",pptp_staticNetmask)
				uci:set("network","wan4","gateway",pptp_staticGateway)
				end

				uci:set("network","vpn","pptp_username",pptpUser)
				uci:set("network","vpn","pptp_password",pptpPass)
				uci:set("network","wan4","pptp_mtu",pptpMTU)
				uci:set("network","wan4","mtu",pptpMTU)
				uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
				uci:set("network","vpn","pptp_demand",pptpIdleTime)
				uci:set("network","vpn","pptp_serverip",pptp_serverIp)
				uci:set("network","vpn","pptpWanIPMode",pptpWanIPMode)
				uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)	
				]]--

				-- IPoE
			else
				-- IPoE/ v4
				if (connection_IPmode == "IPv4_Only") or (connection_IPmode == "Dual_Stack") then	
					local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
					local Fixed_staticIp = luci.http.formvalue("staticIp")
					local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
					local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					local ethMTU = luci.http.formvalue("ethMTU")

					-- IPoE/ v4/ DHCP
					if WAN_IP_Auto == "1" then
						local vendor_id = luci.http.formvalue("vendor_id")
						local dhcp121Enable  = luci.http.formvalue("dhcp121Enable")
						local dhcp125Enable  = luci.http.formvalue("dhcp125Enable")
						local dhcp43Enable  = luci.http.formvalue("dhcp43Enable")
						local dhcp60Enable = luci.http.formvalue("dhcp60Enable")

						uci:set("network","wan4","proto","dhcp")


						if not ( nil == vendor_id ) then
							uci:set("network", "wan4", "vendorid", vendor_id)
						else
							uci:set("network", "wan4", "vendorid", "")
						end

						if not ("0" == dhcp121Enable ) then
							uci:set("network", "wan4", "dhcp121", 0)
						else
							uci:set("network", "wan4", "dhcp121", 1)
						end

						if not ("0" == dhcp125Enable ) then
							uci:set("network", "wan4", "dhcp125", 0)
						else
							uci:set("network", "wan4", "dhcp125", 1)
						end

						if not ("0" == dhcp43Enable ) then
							uci:set("network", "wan4", "dhcp43", 0)
						else
							uci:set("network", "wan4", "dhcp43", 1)
						end
						
						if not ("0" == dhcp60Enable ) then
							uci:set("network", "wan4", "dhcp60", 0)
						else
							uci:set("network", "wan4", "dhcp60", 1)
						end

					-- IPoE/ v4/ STATIC
					else
						uci:set("network","wan4","proto","static")
						uci:set("network","wan4","ipaddr",Fixed_staticIp)
						uci:set("network","wan4","netmask",Fixed_staticNetmask)
						uci:set("network","wan4","gateway",Fixed_staticGateway)
					end
					uci:set("network","wan4","eth_mtu",ethMTU)
					uci:set("network","wan4","mtu",ethMTU)
					--[[
					uci:delete("network","wan4","username")
					uci:delete("network","wan4","password")
					uci:delete("network","wan4","pppoeNailedup")
					uci:delete("network","wan4","pppoeIdleTime")
					uci:delete("network","wan4","pppoeServiceName")
					uci:delete("network","wan4","pppoePassthrough")
					]]--
				end

				-- IPoE/ v6
				if (connection_IPmode == "IPv6_Only") or (connection_IPmode == "Dual_Stack") then
					local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
					local IPv6_Fixed_StaticIp = luci.http.formvalue("ipv6_address")
					local IPv6_Prefix_Length = luci.http.formvalue("prefix_length")
					local IPv6_Fixed_StaticGateway = luci.http.formvalue("ipv6_gateway")
					local IPv6_DNS = luci.http.formvalue("ipv6_dns")  
					--local IA_NA = luci.http.formvalue("ia_na")
					--local IA_PD = luci.http.formvalue("ia_pd")
					local request_v6_dns = luci.http.formvalue("auto_dns")
					local ethMTU = luci.http.formvalue("ethMTU")

					--uci:apply("RA_status")
					--uci:set("network6","wan4","type", "ipoev6")
					uci:set("network","wan4","send_rs","0")
					uci:set("network","wan4","accept_ra","1")
					uci:set("network","wan4","ifname", "eth0."..vid)
					uci:commit("network")	
					--uci:apply("network")

					uci:set("dhcp6c","basic","ifname","eth0."..vid)
					uci:set("dhcp6c","basic","interface","wan4")
					uci:commit("dhcp6c")
					--uci:apply("dhcp6c")

					-- IPoE/ v6/ DHCP
					if IPv6_WAN_IP_Auto == "auto" then
						uci:set("network","wan4","v6_proto","dhcp")
						uci:set("network","wan4","ip6addr","")
						uci:set("network","wan4","prefixlen","")
						uci:set("network","wan4","ip6gw","")  
						uci:set("network","wan4","IPv6_dns","")

						--uci:set("network6","wan4","type","dhcp")
						uci:set("dhcp6c","basic","enabled", 1)

						--local Server_dns1Type       = luci.http.formvalue("dns1Type")
						--local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
						--local Server_dns2Type       = luci.http.formvalue("dns2Type")
						--local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
						--local Server_dns3Type       = luci.http.formvalue("dns3Type")
						--local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
						--[[ if IA_NA then
						IA_NA=1
						else
						IA_NA=0 
						end
						if IA_PD then
						IA_PD=1
						else
						IA_PD=0
						end ]]--
						--uci:set("dhcp6c","basic","na", IA_NA)
						--uci:set("dhcp6c","basic","pd", IA_PD)
						uci:set("dhcp6c","lan","enabled", 1)
						uci:set("dhcp6c","lan","sla_id", 0)
						uci:set("dhcp6c","lan","sla_len", 0)
						uci:set("dhcp6c","basic","gui_run","1")

					-- IPoE/ v6/ STATIC
					else 
						uci:set("network","wan4","v6_proto","static") 
						uci:set("network","wan4","v6_static","1")   
						uci:set("network","wan4","ip6addr",IPv6_Fixed_StaticIp)
						uci:set("network","wan4","prefixlen",IPv6_Prefix_Length)
						uci:set("network","wan4","ip6gw",IPv6_Fixed_StaticGateway)  
						uci:set("network","wan4","IPv6_dns", IPv6_DNS) 
						uci:set("network","wan4","send_rs","1")
						uci:set("network","wan4","accept_ra","0")
					end  
					uci:commit("network") 
					uci:commit("dhcp6c")
					--WenHsien denoted for EMG
					--uci:apply("RA_dhcp6c")

					--uci:apply("network")
					-- if not IPv6_DNS then
					--sys.exec("echo nameserver "..IPv6_DNS.." >> /tmp/resolv.conf.auto") 
					-- end 
					--local ipv6_fixed_addr=uci:get("network","wan4","ip6addr") 
					--local ipv6_prefixlength=uci:get("network","wan4","prefixlen")  
					--if not ipv6_fixed_addr then ipv6_fixed_addr="" end 
					--if not ipv6_prefixlength then ipv6_prefixlength="" end
					--sys.exec("ifconfig eth0."..vid.." add "..ipv6_fixed_addr.."/"..IPv6_Prefix_Length)

					--local ipv6_fixedgateway=uci:get("network","wan4","ip6gw")
					--   if not ipv6_fixedgateway then ipv6_fixedgateway="" end
					--sys.exec("ip -6 route del default dev eth0."..vid) 
					--sys.exec("ip -6 route add default via "..ipv6_fixedgateway) 
				end
			end -- IP mode


			local WAN_MAC_Clone = luci.http.formvalue("WAN_MAC_Clone")
			local spoofIPAddr = luci.http.formvalue("spoofIPAddr")
			local macCloneMac = luci.http.formvalue("macCloneMac")
			--[[
			local old_WAN_MAC_Clone = uci:get("network", "wan4", "wan_mac_status")
			if not old_WAN_MAC_Clone then 
			old_WAN_MAC_Clone = "0"
			uci:set("network","wan4","wan_mac_status",old_WAN_MAC_Clone)
			end
			]]--
			--if WAN_MAC_Clone ~= old_WAN_MAC_Clone then
			if WAN_MAC_Clone == "0" then
				uci:set("network","wan4","wan_mac_status",WAN_MAC_Clone)

				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 0-15 > /tmp/mac0")
				sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' | cut -c 16-17 >> /tmp/mac0")
				local idx_mac = 0
				for line in io.lines("/tmp/mac0") do
					idx_mac = idx_mac + 1
					if( idx_mac == 2 ) then
						line = tran16to10(line , 3)
						if(string.len(line) == 3) then
							line = string.sub(line , 2,3)
						end
						mac_wan = mac_wan..line 

					else
						mac_wan = line
					end
				end
				sys.exec("rm /tmp/mac0")
				uci:set("network","wan4","wan_set_mac",mac_wan)
				uci:set("network","wan4","macaddr",mac_wan)
			elseif WAN_MAC_Clone == "1" then
				local sw = 0
				local t={}
				t=luci.sys.net.arptable()
				for i,v in ipairs(t) do
					if t[i]["IP address"]==spoofIPAddr then 
						uci:set("network","wan4","wan_clone_ip",t[i]["IP address"])
						uci:set("network","wan4","wan_clone_ip_mac",t[i]["HW address"])
						uci:set("network","wan4","wan_set_mac",t[i]["HW address"])
						uci:set("network","wan4","macaddr",t[i]["HW address"])
						sw = 1
					end
				end

				if sw==1 then
					uci:set("network","wan4","wan_mac_status","1")
				else
					local url4 = luci.dispatcher.build_url("expert","configuration","network","wan4")		
					luci.http.redirect(url4 .. "?" .. "arp_error=1" .. "&error_addr=" .. spoofIPAddr)
				end

			elseif WAN_MAC_Clone == "2" then
				uci:set("network","wan4","wan_mac_status",WAN_MAC_Clone)
				uci:set("network","wan4","wan_set_mac",macCloneMac)
				uci:set("network","wan4","macaddr",macCloneMac)
			end

			--end

			uci:set("network","wan4","name", wan_name)
			uci:set("network","wan4","ifname", "eth0."..vid)
			uci:set("network","wan4","vid", vid)
			uci:set("network","wan4","pri",pri)
			uci:set("network","wan4","enable",1)

			uci:set("network","general","config_section","wan4")	

			--WenHsien
			local v6_static = uci:get("network","wan4","v6_static")
			if v6_static ~= "1" then	
				uci:commit("dhcp")
				--WenHsien denoted for EMG
				--uci:apply("dhcp")
				--uci:commit("network")	
				--uci:apply("network")
			end
			uci:set("network","wan4","v6_static","0")


			uci:commit("network")	
			uci:apply("network") 

			-- igmpproxy
			local igmpEnabled = luci.http.formvalue("igmpEnabled")
			local ori_igmpEnabled = uci:get("igmpproxy","wan4","igmpEnabled")
			if igmpEnabled ~= ori_igmpEnabled then
				uci:set("igmpproxy","wan4","igmpEnabled",igmpEnabled)
				if igmpEnabled == "enable" then			
					uci:set("igmpproxy","wan","igmpEnabled","disable")
					uci:set("igmpproxy","wan1","igmpEnabled","disable")
					uci:set("igmpproxy","wan2","igmpEnabled","disable")
					uci:set("igmpproxy","wan3","igmpEnabled","disable")
				end
				uci:commit("igmpproxy")
				uci:apply("igmpproxy")
			end
			-- igmpproxy

			uci:apply("qos")
			sys.exec("/sbin/configure_intfGrp set_iptables_rule")

			--WenHsien
			local url4 = luci.dispatcher.build_url("expert","configuration","network","wan")
			luci.http.redirect(url4)
		end

		io.popen("/etc/init.d/default_lan_radvd boot")   
	end
	luci.template.render("expert_configuration/broadband4_add")

end

function action_wan_management()
	
        local delete = luci.http.formvalue("delete")
        local defaultWan = luci.http.formvalue("defaultWan")

	if delete then
		local vid = uci:get("network",delete ,"vid")
		
                uci:set("network",delete, "proto", "dhcp")		
                uci:set("network",delete, "username", "")
                uci:set("network",delete, "password", "")
                uci:set("network",delete, "vid", "4500")
                uci:set("network",delete, "enable", "0")
                uci:set("network",delete, "untag", "1")
                uci:set("network",delete, "wan_mac_status", "0")
                uci:set("network",delete, "wan_set_mac", "")
				uci:set("network",delete, "macaddr", "")
                uci:set("network",delete, "name", "")
                -- fix when delete multi WAN interface on WAN management page, it will display error.
                uci:set("network",delete, "dns1", "ISP,")
                uci:set("network",delete, "dns2", "ISP,")
                uci:set("network",delete, "dns3", "ISP,")
                uci:set("network",delete, "dnsv6_1", "ISP,")
                uci:set("network",delete, "dnsv6_2", "ISP,")
                uci:set("network",delete, "dnsv6_3", "ISP,")
                uci:set("network",delete, "IP_version", "")
                uci:set("network",delete, "wan_mac_status", "")
                uci:set("network",delete, "ifname", "")
                local wan_ifname = uci:get("network","wan","ifname")

	
                -- If the delete wan is default wan, then move the default to wan	
                local default_flag = uci:get("network",delete, "default")
                if default_flag == "1" then
                   uci:set("network",delete, "default", "0")
                   uci:set("network","wan", "default", "1")
                   sys.exec("ip route delete")
                   sys.exec("ip route add default dev "..wan_ifname)
                end
               
                uci:commit("network")
		uci:apply("network")
		io.popen("/etc/init.d/default_lan_radvd boot")
		uci:apply("qos")

		--check nat rule
		uci:foreach( "nat", "nat", function( section )
            		if not ( "general" == section[ '.name' ] ) then
                		if (section.wan_name == delete) then
					--uci:delete("nat",section[ '.name' ])
					wanChkiptablesRule("nat",section[ '.name' ])
				end
            		end
        	end )
		--uci:commit("nat")
		--uci:apply("nat")

		--check portTrigger
		uci:foreach( "portTrigger", "trigger", function( section )
               		if (section.trigger_wanif == delete) then
				uci:delete("portTrigger",section[ '.name' ])
				--wanChkiptablesRule("portTrigger",section[ '.name' ])
			end
        	end )
		uci:commit("portTrigger")
		uci:apply("portTrigger")
		sys.exec("vconfig rem eth0."..vid) 

	end

        if defaultWan then

	    local old_select = uci:get("network", "general", "defaultWan")
	    local new_name = uci:get("network",defaultWan , "name")
	    uci:set("network", old_select, "grouped", "0")  
	    uci:set("network", defaultWan, "grouped", "1")
	    uci:delete("network", old_select, "bind_LAN")  
	    uci:set("network", defaultWan, "bind_LAN" , "br-lan")
	    uci:set("intfGrp", "Default", "wanint", defaultWan) 
	    uci:set("intfGrp", "Default", "ifname", new_name) 


	    uci:commit("intfGrp")

             -- reset all wan UCI data to Non-Default
             uci:set("network", "wan", "default", "0")  
             for i = 1,4 do
               uci:set("network", "wan"..i, "default", "0")
             end
 
             -- set User Chosen as  default wan
             uci:set("network", defaultWan, "default", "1")
             uci:set("network", "general", "defaultWan", defaultWan)
             uci:commit("network")

             uci:set("dhcp6c", "basic", "defaultWan", defaultWan)
             uci:commit("dhcp6c")   

             sys.exec("/bin/select_defaultwan") 


		--if default wan  change need to reload qos module 
		if old_select ~= defaultWan then
			local qos_enable=uci:get("qos", "general", "enable")
			if ( "1" == qos_enable ) then
				uci:apply("qos")
			end
		end


        end        

        luci.template.render("expert_configuration/optWan")
end


function action_wan_ipv6()
	local apply = luci.http.formvalue("apply")

	if apply then
		local connect_type = luci.http.formvalue("connectionType")

		if ( connect_type == "None" ) then
			--IPoE
			--PPPoE
			--Tunnel
			sys.exec("/etc/init.d/gw6c stop 2>/dev/null")
			uci:set("gw6c", "basic", "disabled", "1")
			uci:commit("gw6c")
			uci:set("network6","wan","type", "none")
			uci:commit("network6")
		elseif ( connect_type == "Tunnelv6" ) then
			--local broker = luci.http.formvalue("tunnel_broker")
			--freenet6
			--if (broker == "freenet6") then
				local user_name = luci.http.formvalue("gogo6_user_name")
				local password = luci.http.formvalue("gogo6_pwd")
				local tunnel_type = luci.http.formvalue("tunnel_mode")
				--local server = luci.http.formvalue("gogo6_server")
                                local server = luci.http.formvalue("tunnel_broker")

				uci:set("network6","wan","type", "tunnel")
				uci:commit("network6")

				uci:set("gw6c", "basic", "disabled", 0)
				uci:set("gw6c", "basic", "userid", user_name)
				uci:set("gw6c", "basic", "passwd", password)
				uci:set("gw6c", "advanced", "if_tunnel_mode", tunnel_type)

				if (server == "best_server") then
					uci:set("gw6c", "basic", "server", "anon.freenet6.net")
				else
					uci:set("gw6c", "basic", "server", server)
				end

				uci:commit("gw6c")
				uci:apply("gw6c")
			--end
		end 
	end

	luci.template.render("expert_configuration/ipv6")
end

function action_wan_advanced()
	local apply = luci.http.formvalue("apply")
		
	if apply then
		local apply_ip_change = luci.http.formvalue("apply_ip_change")
			
	        
	        if apply_ip_change then
	        	local ipChangeEnabled  = luci.http.formvalue("ipChangeEnabled")
	        	
	        	uci:set("network", "general", "auto_ip_change", ipChangeEnabled)
	        	uci:set("network", "general", "config_section", "advance")
	        	
	        	uci:commit("network")
	        	uci:apply("network")
				uci:apply("qos")
	        end
	end
        luci.template.render("expert_configuration/broadband_advance")
end

function subnet(ip, mask)
	local ip_byte1, ip_byte2, ip_byte3, ip_byte4 = ip:match("(%d+).(%d+).(%d+).(%d+)")
	local mask_byte1, mask_byte2, mask_byte3, mask_byte4 = mask:match("(%d+).(%d+).(%d+).(%d+)")
	
	return bit.band(tonumber(ip_byte1), tonumber(mask_byte1)) .. "." .. bit.band(tonumber(ip_byte2), tonumber(mask_byte2)) .. "." .. bit.band(tonumber(ip_byte3), tonumber(mask_byte3)) .. "." .. bit.band(tonumber(ip_byte4), tonumber(mask_byte4))
end

function action_lan()
	local apply = luci.http.formvalue("apply")

	if apply then
		local ipaddr  = luci.http.formvalue("ipaddr")
		local netmask = luci.http.formvalue("netmask")
		local lan_ip = uci:get("network", "lan", "ipaddr")
		local lan_mask = uci:get("network", "lan", "netmask")
		local changed = false
		local subnet_changed = false
		local hostname = uci:get("system", "main", "hostname")

		local system_mode = uci:get("system", "main", "system_mode")

		if system_mode ~= "2" and system_mode ~= "3" then

			if not (ipaddr == lan_ip) then
				uci:set("network", "lan", "ipaddr", ipaddr)
	
				local file = io.open( "/etc/hosts", "w" )
                        	file:write(ipaddr .. " " .. hostname .. "\n")
                        	file:write(ipaddr .. " " .. "myrouter" .. "\n")							
                     	   	file:write("127.0.0.1" .. " " .. "localhost" .. "\n")							
                        	file:close()

				changed = true
			end

			if not (netmask == lan_mask) then
				uci:set("network", "lan", "netmask", netmask)
				changed = true
				subnet_changed = true
			end


			if not ("static" == uci:get("network", "lan", "proto")) then
				uci:set("network", "lan", "proto", "static")
				changed = true
			end

			if changed then
								
				local lan_subnet = subnet(lan_ip, lan_mask)
				local cfg_subnet = subnet(ipaddr, netmask)
			
				uci:set("network","general","config_section","lan")
				uci:commit("network")
				uci:apply("network")
				uci:apply("qos")
			
				if lan_subnet ~= cfg_subnet or subnet_changed then
					sys.exec("/bin/switch_port lan reset") 
				end			
			end
		
		else
			local LAN_IP_Auto = luci.http.formvalue("LAN_IP_Auto")
			local gateway = luci.http.formvalue("gateway")
			local lan_gw = uci:get("network", "lan", "gateway")

			if not LAN_IP_Auto then
				LAN_IP_Auto="0"
			end

			if LAN_IP_Auto == "1" then
				uci:set("network","lan","proto","dhcp")
          		else
				uci:set("network","lan","proto","static")
          		end
			
			uci:set("network", "lan", "ipaddr", ipaddr)
			uci:set("network", "lan", "netmask", netmask)
			
			if not gateway then
				gateway = ""
			end
			uci:set("network", "lan", "gateway", gateway)

			--lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")
			local lan_proto = uci:get("network","lan","proto")
			sys.exec("echo "..lan_proto.." > /tmp/old_lan_proto")
	               
        		local Server_dns1Type       = luci.http.formvalue("dns1Type")
        		local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
        		local Server_dns2Type       = luci.http.formvalue("dns2Type")
        		local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
        		local Server_dns3Type       = luci.http.formvalue("dns3Type")
        		local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
					
			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end
				
			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end
				
			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end
				
			uci:set("network","lan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","lan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","lan","dns3",Server_dns3Type ..",".. Server_staticThiDns)
			
			uci:set("network","general","config_section","lan")
			uci:commit("network")
			uci:apply("network")
			uci:apply("qos")
			if system_mode == "3" then
				uci:apply("wireless_client")
			end
		end
	end

	luci.template.render("expert_configuration/lan")
end

function action_igmp_snooping()
	local apply = luci.http.formvalue("igmpSubmit")
	
	if apply then
		local igmp_check = luci.http.formvalue("IGMP_SNOOPING")
		local igmp_mode = luci.http.formvalue("IGMPRadio")


		if (igmp_check == "enabled") then 
			if (igmp_mode == "1") then
				uci:set("network","lan","igmpmode","1")
			else
				uci:set("network","lan","igmpmode","2")
			end
		else
			uci:set("network","lan","igmpmode","0")
		end
		uci:commit("network")
		sys.exec("/bin/IGMP_snooping") 
	end

	luci.template.render("expert_configuration/igmp_snooping")
end


function action_ipalias()
	local apply = luci.http.formvalue("apply")
	
	if apply then
		local i = 1

		uci:delete_all("network", "alias")
		while not (nil == luci.http.formvalue("alias" .. i .. "_ip")) do
			local aliasEntry = "alias"..i
			uci:set("network",aliasEntry,"alias")
			
			local aliasIP = luci.http.formvalue("alias" .. i .. "_ip")
			local aliasNetmask = luci.http.formvalue("alias" .. i .. "_netmask")
			local lan_ifname
			if uci:get("network","lan","type") == "bridge" then
				lan_ifname = "lan"
			else
				lan_ifname = uci:get("network","lan","ifname")
			end 

			--local lan_ifname = "br0"--#change eth0 to br0#
			local enabled = luci.http.formvalue("alias" .. i .. "_enabled")
			
			if not (enabled == "enabled") then 
				enabled = "disabled" 
			end			
				
			uci:set("network", aliasEntry, "interface_alias", lan_ifname)
			uci:set("network", aliasEntry, "enabled", enabled)
			uci:set("network", aliasEntry, "proto_alias", "static")
			uci:set("network", aliasEntry, "ipaddr_alias", aliasIP)
			uci:set("network", aliasEntry, "netmask_alias", aliasNetmask)

			i = i + 1
		end
		uci:set("network","general","config_section","ipalias")
		uci:commit("network")
		--uci:apply("network")
		sys.exec("/bin/ip_alias")
	end

	luci.template.render("expert_configuration/ip_alias")
end

function action_ipv6lan()
	local apply = luci.http.formvalue("apply")
	
	if apply then
		local PD = luci.http.formvalue("PDEnable")
		local MinRtrAdvInterval = luci.http.formvalue("MinRtrAdvInterval")
		local MaxRtrAdvInterval
		
		local ipv6_Enable = uci:get("network", "wan", "ipv6")

		uci:set("radvd", "interface", "MinRtrAdvInterval", MinRtrAdvInterval)
		MaxRtrAdvInterval = MinRtrAdvInterval*2
		uci:set("radvd", "interface", "MaxRtrAdvInterval", MaxRtrAdvInterval)

		-- 1. Clean all LAN Global IPs.
		sys.exec("ifconfig br-lan |grep Global |awk '{print $3}' |xargs -n 1 ifconfig br-lan del");
		
		--dhcpv6pd
		if PD == "1" then 
			if ipv6_Enable == "1" then
				local auto_config_select = luci.http.formvalue("auto_config_select")
				local range_start = luci.http.formvalue("range_start")
				local range_end = luci.http.formvalue("range_end")
				local lifetime = luci.http.formvalue("lifetime")
			
				if auto_config_select == "1" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "0")
				elseif auto_config_select == "2" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
				else
					uci:set("radvd", "interface", "AdvManagedFlag", "1")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
					uci:set("dhcp6s", "basic", "addrstart", range_start)
					uci:set("dhcp6s", "basic", "addrend", range_end)
					uci:set("dhcp6s", "basic", "lifetime", lifetime)
				end
				uci:commit("radvd")
				uci:commit("dhcp6s")
			
				-- 2. Set UCI default_lan_radvd
				uci:set("default_lan_radvd", "basic", "address", "")
				uci:set("default_lan_radvd", "basic", "prefixlen", "")
				uci:set("default_lan_radvd", "basic", "prefix", "")
				uci:set("default_lan_radvd", "basic", "masked_address", "")
				uci:commit("default_lan_radvd")
			
				uci:set("network", "general", "dhcpv6pd", "1")
				uci:set("network","wan","ipv6","1")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","general","ULA","0")
				uci:commit("network")
				uci:apply("radvd")
			else
				local auto_config_select = luci.http.formvalue("auto_config_select")
				local range_start = luci.http.formvalue("range_start")
				local range_end = luci.http.formvalue("range_end")
				local lifetime = luci.http.formvalue("lifetime")
			
				if auto_config_select == "1" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "0")
				elseif auto_config_select == "2" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
				else
					uci:set("radvd", "interface", "AdvManagedFlag", "1")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
					uci:set("dhcp6s", "basic", "addrstart", range_start)
					uci:set("dhcp6s", "basic", "addrend", range_end)
					uci:set("dhcp6s", "basic", "lifetime", lifetime)
				end
				uci:commit("radvd")
				uci:commit("dhcp6s")

				uci:set("network", "general", "dhcpv6pd", "1")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","general","ULA","0")
				uci:commit("network")
				
				uci:apply("network")
				uci:apply("qos")
			end
			
		--v6lanstatic
		elseif PD == "2" then 
			local ipaddrv6 = luci.http.formvalue("ipv6address") 
			local prefixlenipv6 = luci.http.formvalue("ipv6prefixlen")
			local pref_lt = luci.http.formvalue("ipv6_pref_lt")
			local vali_lt = luci.http.formvalue("ipv6_vali_lt")
			local min_ra_intv = luci.http.formvalue("ipv6_min_ra_intv")
			local ra_m_flag = luci.http.formvalue("ipv6_ra_m_flag")
			
			-- 1. Set LAN Static IP.  Set this later by  radvd.sh  .
			--sys.exec("ifconfig br-lan add "..ipaddrv6.."/64")	
			
			-- 2. Set UCI default_lan_radvd
			uci:set("default_lan_radvd", "basic", "address", ipaddrv6)
			uci:set("default_lan_radvd", "basic", "prefixlen", prefixlenipv6)
			uci:set("radvd", "prefix", "AdvPreferredLifetime", pref_lt)
			uci:set("radvd", "prefix", "AdvValidLifetime", vali_lt)
			uci:set("radvd", "interface", "MinRtrAdvInterval", min_ra_intv)
			uci:set("radvd", "interface", "AdvManagedFlag", ra_m_flag)
			-- WenHsien: Prefix and Masked_Address option is calculated in  radvd.sh  .2014.0505.
			uci:commit("default_lan_radvd")
			uci:commit("radvd")
			
			uci:set("network","wan","ipv6","1")
			uci:set("network", "general", "dhcpv6pd", "0")
			uci:set("network","general","v6lanstatic","1")
			uci:set("network","general","linkLocalOnly","0")
			uci:set("network","general","ULA","0")
			uci:commit("network")
			
			uci:apply("default_lan_radvd")

		--linkLocalOnly
		elseif PD == "3" then
			uci:set("network","wan","ipv6","0")		
			uci:set("network", "general", "dhcpv6pd", "0")
			uci:set("network","general","v6lanstatic","0")
			uci:set("network","general","linkLocalOnly","1")
			uci:set("network","general","ULA","0")
			uci:commit("network")
			
			uci:apply("network")
			uci:apply("qos")
		
		--ULA
		elseif PD == "4" then	
			uci:set("network","wan","ipv6","1")
			uci:set("network", "general", "dhcpv6pd", "0")
			uci:set("network","general","v6lanstatic","0")
			uci:set("network","general","linkLocalOnly","0")
			uci:set("network","general","ULA","1")
			uci:set("radvd", "interface", "AdvManagedFlag", "0")
			uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
			uci:commit("network")
			uci:commit("radvd")
			
			uci:apply("radvd")
			
		end
	end

	luci.template.render("expert_configuration/ipv6lan")
	--Page Count - VT
	sys.exec("pages_count lan_ipv6")
end
--dipper firewall
function firewall()

	local apply = luci.http.formvalue("apply")
	
	if apply then
		local enabled = luci.http.formvalue("DoSEnabled")
		local fw_level
		local flag = 1
		
		if enabled == nil then
			enabled = "0"
		end
		uci:set("firewall","general","dos_enable",enabled)	
		uci:commit("firewall")
		uci:apply("firewall")
		
	end
	
	luci.template.render("expert_configuration/firewall")
end

function fw_services()

	local icmp_apply = luci.http.formvalue("icmp_apply")
	local enable_apply = luci.http.formvalue("enable_apply")
	local add_rule = luci.http.formvalue("add_rule")
	local remove = luci.http.formvalue("remove")
	
	if icmp_apply then				
		
		local pingEnabled = luci.http.formvalue("pingFrmWANFilterEnabled")
		local ori_pingEnabled = uci:get("firewall","general","pingEnabled")
		
		
		if not (ori_pingEnabled==pingEnabled) then
			pingEnabled = checkInjection(pingEnabled)
			if pingEnabled ~= false then
				uci:set("firewall","general","pingEnabled",pingEnabled)
			end
			uci:commit("firewall")
			uci:apply("firewall")
		end
	end
	
	if enable_apply then
	
		local filterEnabled = luci.http.formvalue("portFilterEnabled")
		local target = luci.http.formvalue("target")
		
		if filterEnabled then 
			filterEnabled = "1"
		else
			filterEnabled = "0"
		end
		

		uci:set("firewall","general","filterEnabled",filterEnabled)
		uci:set("firewall","general","target",target)
		uci:commit("firewall")
		uci:apply("firewall")	
	
	end
	
	if add_rule then
	
		local srvName = luci.http.formvalue("srvName")
		local mac_address = luci.http.formvalue("mac_address")
		local dip_address = luci.http.formvalue("dip_address")
		local sip_address = luci.http.formvalue("sip_address")
		local protocol = luci.http.formvalue("protocol")
		local dFromPort = luci.http.formvalue("dFromPort")
		local dToPort = luci.http.formvalue("dToPort")
		local sFromPort = luci.http.formvalue("sFromPort")
		local sToPort = luci.http.formvalue("sToPort")
			
		-----firewall-----
		local enabled = 1
		if mac_address=="" then
			mac_address="00:00:00:00:00:00"
		end
		if dip_address=="" then
			dip_address="0.0.0.0"
		end
		if sip_address=="" then
			sip_address="0.0.0.0"
		end
		
		if protocol == "ICMP" then
			dFromPort = ""
			dToPort = ""
			sFromPort = ""
			sToPort = ""
		end
		
		if dFromPort=="" then
			if not dToPort=="" then
				dFromPort=dToPort
			end
		end
		
		if sFromPort=="" then
			if not sToPort=="" then
				sFromPort=sToPort
			end
		end
		
		local fw_type = "in"
		local wan = 0
		local lan = 0
		local fw_time = "always"
		--local target = "DROP"
		--local target =	uci:get("firewall","general","filterEnabled")
		
		local rules_count = uci:get("firewall","general","rules_count")
		local NextRulePos = uci:get("firewall","general","NextRulePos")
		--local service_count = uci:get("firewall","general","service_count")
		rules_count = rules_count+1
		NextRulePos = NextRulePos+1
		--service_count = service_count+1
		local rules = "rule"..rules_count
		local services = "service"..rules_count
		--[[
		uci:set("firewall",services,"service")
		uci:set("firewall",services,"name",srvName)
		uci:set("firewall",services,"protocol",protocol)
		uci:set("firewall",services,"dFromPort",dFromPort)
		uci:set("firewall",services,"dToPort",dToPort)
		uci:set("firewall",services,"sFromPort",sFromPort)
		uci:set("firewall",services,"sToPort",sToPort)		
		]]--
		
		uci:set("firewall",rules,"firewall")
		uci:set("firewall",rules,"StatusEnable",enabled)
		uci:set("firewall",rules,"CurPos",rules_count)
		uci:set("firewall",rules,"type",fw_type)
		uci:set("firewall",rules,"service",services)
		uci:set("firewall",rules,"wan",wan)
		uci:set("firewall",rules,"local",lan)
		
		srvName = checkInjection(srvName)
		if srvName ~= false then
			uci:set("firewall",rules,"name",srvName)
		end
		
		if string.match(protocol, "(%w+)") then
			protocol = string.match(protocol, "(%w+)")
			uci:set("firewall",rules,"protocol",protocol)
		end
		if string.match(dFromPort, "(%d+)") then
			dFromPort = string.match(dFromPort, "(%d+)")
			uci:set("firewall",rules,"dFromPort",dFromPort)
		end
		if string.match(dToPort, "(%d+)") then
			dToPort = string.match(dToPort, "(%d+)")
			uci:set("firewall",rules,"dToPort",dToPort)
		end
		if string.match(sFromPort, "(%d+)") then
			sFromPort = string.match(sFromPort, "(%d+)")
			uci:set("firewall",rules,"sFromPort",sFromPort)
		end
		if string.match(sToPort, "(%d+)") then
			sToPort = string.match(sToPort, "(%d+)")
			uci:set("firewall",rules,"sToPort",sToPort)
		end
		if string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac_address = string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("firewall",rules,"mac_address",mac_address)
		end	
		if string.match(sip_address, "(%d+.%d+.%d+.%d+)") then
			sip_address = string.match(sip_address, "(%d+.%d+.%d+.%d+)")
			uci:set("firewall",rules,"src_ip",sip_address)
		end	
		if string.match(dip_address, "(%d+.%d+.%d+.%d+)") then
			dip_address = string.match(dip_address, "(%d+.%d+.%d+.%d+)")
			uci:set("firewall",rules,"dst_ip",dip_address)
		end	

		uci:set("firewall",rules,"time",fw_time)
		--uci:set("firewall",rules,"target",target)	
	
		uci:set("firewall","general","rules_count",rules_count)
		uci:set("firewall","general","NextRulePos",NextRulePos)
		--uci:set("firewall","general","service_count",service_count)
		
		uci:commit("firewall")
		uci:apply("firewall")
			
	end
	
	
	if remove then
	
		local cur_num = remove
		local del_rule ="rule"..cur_num
		uci:delete("firewall",del_rule)
		
		-----firewall-----
		local rules_count = uci:get("firewall","general","rules_count")
		local NextRulePos = uci:get("firewall","general","NextRulePos")
		local num = rules_count-cur_num
		
		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("firewall",rules)
			
			if old_data then
				uci:set("firewall",new_rule,"firewall")
				uci:tset("firewall",new_rule,old_data)
				uci:set("firewall",new_rule,"CurPos",cur_num)
				uci:commit("firewall")
				uci:delete("firewall",rules)
				uci:commit("firewall")
				cur_num =cur_num+1				
			end
		end	
		
		uci:set("firewall","general","rules_count",rules_count-1)
		uci:set("firewall","general","NextRulePos",NextRulePos-1)
		
		uci:commit("firewall")
		uci:apply("firewall")
	
	end

	luci.template.render("expert_configuration/fw_services")
end
--dipper firewall

function firewall6()

	local icmp_apply = luci.http.formvalue("icmp_apply")
	local enable_apply = luci.http.formvalue("enable_apply")
	local enable_simpleSecurity = luci.http.formvalue("simpleSecurity_apply")
	local add_rule = luci.http.formvalue("add_rule")
	local remove = luci.http.formvalue("remove")
	
	if icmp_apply then				
		
		local pingEnabled = luci.http.formvalue("pingFrmWANFilterEnabled")
		local ori_pingEnabled = uci:get("firewall6","general","pingEnabled")
		
		
		if not (ori_pingEnabled==pingEnabled) then
			pingEnabled = checkInjection(pingEnabled)
			if pingEnabled ~= false then
				uci:set("firewall6","general","pingEnabled",pingEnabled)
			end
			uci:commit("firewall6")
			uci:apply("firewall6")
		end
	end
	
	if enable_apply then
	
		local filterEnabled = luci.http.formvalue("portFilterEnabled")
		local ori_filterEnabled = uci:get("firewall6","general","filterEnabled")
		
		if filterEnabled then 
			filterEnabled = "1"
		else
			filterEnabled = "0"
		end
		
		if not (ori_filterEnabled==filterEnabled) then
			uci:set("firewall6","general","filterEnabled",filterEnabled)
			uci:commit("firewall6")
			uci:apply("firewall6")
		end	
	
	end

	if enable_simpleSecurity then
	
		local simpleSecurityEnabled = luci.http.formvalue("simpleSecurityEnabled")
		local ori_simpleSecurityEnabled = uci:get("firewall6","general","isSimpleSecurity")
		
		if simpleSecurityEnabled then 
			simpleSecurityEnabled = "1"
		else
			simpleSecurityEnabled = "0"
		end
		
		if not (ori_simpleSecurityEnabled==simpleSecurityEnabled) then
			uci:set("firewall6","general","simpleSecurityEnabled",simpleSecurityEnabled)
			uci:commit("firewall6")
			uci:apply("firewall6")
		end		
	end
	
	if add_rule then
	
		local srvName = luci.http.formvalue("srvName")
		local mac_address = luci.http.formvalue("mac_address")
		local dip_address = luci.http.formvalue("dip_address")
		local sip_address = luci.http.formvalue("sip_address")
		local protocol = luci.http.formvalue("protocol")
		local dFromPort = luci.http.formvalue("dFromPort")
		local dToPort = luci.http.formvalue("dToPort")
		local sFromPort = luci.http.formvalue("sFromPort")
		local sToPort = luci.http.formvalue("sToPort")
			
		-----firewall-----
		local enabled = 1
		if mac_address=="" then
			mac_address="00:00:00:00:00:00"
		end
		if dip_address=="" then
			dip_address="::"
		end
		if sip_address=="" then
			sip_address="::"
		end
		
		if protocol == "ICMPv6" then
			dFromPort = ""
			dToPort = ""
			sFromPort = ""
			sToPort = ""
		end
		
		if dFromPort=="" then
			if not dToPort=="" then
				dFromPort=dToPort
			end
		end
		
		if sFromPort=="" then
			if not sToPort=="" then
				sFromPort=sToPort
			end
		end
		
		local fw_type = "in"
		local wan = 0
		local lan = 0
		local fw_time = "always"
		local target = "DROP"
		--local target =	uci:get("firewall6","general","filterEnabled")
		
		local rules_count = uci:get("firewall6","general","rules_count")
		local NextRulePos = uci:get("firewall6","general","NextRulePos")
		--local service_count = uci:get("firewall6","general","service_count")
		rules_count = rules_count+1
		NextRulePos = NextRulePos+1
		--service_count = service_count+1
		local rules = "rule"..rules_count
		local services = "service"..rules_count
		--[[
		uci:set("firewall6",services,"service")
		uci:set("firewall6",services,"name",srvName)
		uci:set("firewall6",services,"protocol",protocol)
		uci:set("firewall6",services,"dFromPort",dFromPort)
		uci:set("firewall6",services,"dToPort",dToPort)
		uci:set("firewall6",services,"sFromPort",sFromPort)
		uci:set("firewall6",services,"sToPort",sToPort)		
		]]--
		
		uci:set("firewall6",rules,"firewall6")
		uci:set("firewall6",rules,"StatusEnable",enabled)
		uci:set("firewall6",rules,"CurPos",rules_count)
		uci:set("firewall6",rules,"type",fw_type)
		uci:set("firewall6",rules,"service",services)
		uci:set("firewall6",rules,"wan",wan)
		uci:set("firewall6",rules,"local",lan)
		uci:set("firewall6",rules,"time",fw_time)
		uci:set("firewall6",rules,"target",target)

		srvName = checkInjection(srvName)
		if srvName ~= false then
		uci:set("firewall6",rules,"name",srvName)
		end
		
		if string.match(protocol, "(%w+)") then
			protocol = string.match(protocol, "(%w+)")
			uci:set("firewall6",rules,"protocol",protocol)
		end
		if string.match(dFromPort, "(%d+)") then
			dFromPort = string.match(dFromPort, "(%d+)")
			uci:set("firewall6",rules,"dFromPort",dFromPort)
		end
		if string.match(dToPort, "(%d+)") then
			dToPort = string.match(dToPort, "(%d+)")
			uci:set("firewall6",rules,"dToPort",dToPort)
		end
		if string.match(sFromPort, "(%d+)") then
			sFromPort = string.match(sFromPort, "(%d+)")
			uci:set("firewall6",rules,"sFromPort",sFromPort)
		end
		if string.match(sToPort, "(%d+)") then
			sToPort = string.match(sToPort, "(%d+)")
			uci:set("firewall6",rules,"sToPort",sToPort)
		end
		if string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac_address = string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("firewall6",rules,"mac_address",mac_address)
		end	
		sip_address = checkInjection(sip_address)
		if sip_address ~= false then
		uci:set("firewall6",rules,"src_ip",sip_address)
		end
		
		dip_address = checkInjection(dip_address)
		if dip_address ~= false then
		uci:set("firewall6",rules,"dst_ip",dip_address)	
		end
	
		uci:set("firewall6","general","rules_count",rules_count)
		uci:set("firewall6","general","NextRulePos",NextRulePos)
		--uci:set("firewall6","general","service_count",service_count)
		
		uci:commit("firewall6")
		uci:apply("firewall6")
			
	end
	
	
	if remove then
	
		local cur_num = remove
		local del_rule ="rule"..cur_num
		uci:delete("firewall6",del_rule)
		
		-----firewall-----
		local rules_count = uci:get("firewall6","general","rules_count")
		local NextRulePos = uci:get("firewall6","general","NextRulePos")
		local num = rules_count-cur_num
		
		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("firewall6",rules)
			
			if old_data then
				uci:set("firewall6",new_rule,"firewall6")
				uci:tset("firewall6",new_rule,old_data)
				uci:set("firewall6",new_rule,"CurPos",cur_num)
				uci:commit("firewall6")
				uci:delete("firewall6",rules)
				uci:commit("firewall6")
				cur_num =cur_num+1				
			end
		end	
		
		uci:set("firewall6","general","rules_count",rules_count-1)
		uci:set("firewall6","general","NextRulePos",NextRulePos-1)
		
		uci:commit("firewall6")
		uci:apply("firewall6")
	
	end

	luci.template.render("expert_configuration/IPv6firewall")
end

--dipper nat
function nat()
	
	local apply = luci.http.formvalue("apply")
	
	if apply then
	
		local enabled = luci.http.formvalue("enabled")
		local enabled3 = luci.http.formvalue("enabled_sip")
		--local sessions_user = luci.http.formvalue("sessions_user")
		
		if not max_user then
			max_user=""
		end
			
		uci:set("nat","general","nat")
		uci:set("nat","general","nat",enabled)
		--uci:set("nat","general","sessions_user",sessions_user)

		uci:set("nat","general","sip")
		if not ( "enable" == enabled3 ) then
			uci:set("nat","general","sip","disable")
		else
			uci:set("nat","general","sip","enable")
		end

		uci:commit("nat")
		uci:apply("nat")
		
		--uci:set("nat_new","general_new","nat")
		--uci:set("nat_new","general_new","nat",enabled)
		--uci:set("nat_new","general_new","max_user",max_user)
		--uci:commit("nat_new")
		--uci:apply("nat_new")
		
	end

	luci.template.render("expert_configuration/nat")
end

--dipper content filter
function action_CF()

	local apply = luci.http.formvalue("apply")
	
	if apply then
	
		local IPAddress = luci.http.formvalue("websTrustedIPAddress")
		if string.match(IPAddress, "(%d+.%d+.%d+.%d+)") then
			IPAddress = string.match(IPAddress, "(%d+.%d+.%d+.%d+)")
			uci:set("parental","trust_ip","ipaddr",IPAddress)
		end

		local Activex = luci.http.formvalue("websFilterActivex")
		local Java = luci.http.formvalue("websFilterJava")
		local Cookies = luci.http.formvalue("websFilterCookies")		
		local Proxy = luci.http.formvalue("websFilterProxy")
		
		if not Activex then Activex=0 end
		if not Java then Java=0 end 
		if not Cookies then Cookies=0 end 
		if not Proxy then Proxy=0 end 
		
		
		if not ( 0 == Activex ) then
			uci:set("parental","restrict_web","activeX",1)
		else
			uci:set("parental","restrict_web","activeX",0)
		end
		
		if not ( 0 == Java ) then
			uci:set("parental","restrict_web","java",1)
		else
			uci:set("parental","restrict_web","java",0)
		end
		
		if not ( 0 == Cookies ) then
			uci:set("parental","restrict_web","cookies",1)
		else
			uci:set("parental","restrict_web","cookies",0)
		end

		if not ( 0 == Proxy ) then
			uci:set("parental","restrict_web","web_proxy",1)
		else
			uci:set("parental","restrict_web","web_proxy",0)
		end
		
		local KeyWord_Enable = luci.http.formvalue("cfKeyWord_Enable")
		local url_str = luci.http.formvalue("url_str")
		
		if not KeyWord_Enable then KeyWord_Enable=0 end
		if not url_str  then url_str="" end 
		
		uci:set("parental","keyword","enable",KeyWord_Enable)
		
		url_str = checkInjection(url_str)
		if url_str ~= false then
			uci:set("parental","keyword","keywords",url_str)	
		end		
		
		uci:commit("parental")
		uci:apply("parental")
		
	end

	luci.template.render("expert_configuration/ContentFilter")

end

function parental_control()
	local sysSubmit = luci.http.formvalue("sysSubmit")
	local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	local submitType = luci.http.formvalue("SRSubmitType")
	
	if delete then
		uci:set("parental", "rule" .. delete, "delete", "1")
		uci:commit("parental")
		uci:apply("parental")
	end
	
	if sysSubmit then
		local parentalEnable = luci.http.formvalue("parental_state")
		uci:set("parental", "general" , "enable", parentalEnable)
		uci:commit("parental")
		uci:apply("parental")
	end
luci.template.render("expert_configuration/ParentalControl")

end

function parental_control_edit()
	local edit = luci.http.formvalue("edit")
	local Back = luci.http.formvalue("Back")
	local Back2 = luci.http.formvalue("Back2")
	local apply = luci.http.formvalue("apply")
	local apply2 = luci.http.formvalue("apply2")
	local delete = luci.http.formvalue("delete")
	local idx = 0
	local mac_list=""
	local editID = luci.http.formvalue("SREditID")
	sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $2}' >/tmp/maclist")
	sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $4}' >/tmp/namelist")
	for line in io.lines("/tmp/maclist") do
		idx = idx + 1
		local idx_2 = 0
		for line2 in io.lines("/tmp/namelist") do
		idx_2 = idx_2 + 1
			if( idx == idx_2 ) then
				mac_list=mac_list..line2.."("..line..");"
			end
		end
	end
	sys.exec("rm /tmp/maclist")
	sys.exec("rm /tmp/namelist")
	
	if edit then
		rule_ind="rule"..edit+1
		local tmp_count=edit+1
		local rule_count=uci:get("parental", "general" , "count")
		if (tonumber(rule_count) < tonumber(tmp_count)) then
			uci:set("parental","general","count",edit+1)
			uci:set("parental",rule_ind,"parental_rule")
			uci:set("parental",rule_ind,"src_mac","00:00:00:00:00:00")
			uci:set("parental",rule_ind,"stop_hour","24")
			uci:set("parental",rule_ind,"weekdays","Mon,Tue,Wed,Thu,Fri,Sat,Sun")
			uci:set("parental",rule_ind,"service_count","0")
		else
			sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $2}' >/tmp/maclist")
			editmac = uci:get("parental", rule_ind , "src_mac")
			local idx_3 = 0
			for mac in io.lines("/tmp/maclist") do
				if ( mac == editmac) then
					selectindx = idx_3
					uci:set("parental",rule_ind,"src_type","single")
					break
				else
					selectindx = "none"
				end
				idx_3 = idx_3 + 1
			end
			if ( selectindx == "none") and ( editmac ~= "00:00:00:00:00:00" ) then
				uci:set("parental",rule_ind,"src_type","custom")
			end
			sys.exec("rm /tmp/maclist")
		end
		uci:set("parental", "general", "ruleIdx", rule_ind)
		uci:commit("parental")
		keywords = uci:get("parental", rule_ind , "keyword")
		luci.template.render("expert_configuration/ParentalControl_Edit",{keywords = keywords, selectindx = selectindx, rule=rule_ind, mac_list=mac_list })
	else
		rule_ind = uci:get("parental", "general" , "ruleIdx")
	end
	
	if delete then
		sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $2}' >/tmp/maclist")
		editmac = uci:get("parental", rule_ind , "src_mac")
		local idx_3 = 0
		for mac in io.lines("/tmp/maclist") do
			if ( mac == editmac) then
				selectindx = idx_3
				uci:set("parental",rule_ind,"src_type","single")
				break
			else
				selectindx = "none"
			end
			idx_3 = idx_3 + 1
		end
		if ( selectindx == "none") and ( editmac ~= "00:00:00:00:00:00" ) then
			uci:set("parental",rule_ind,"src_type","custom")
		end
			sys.exec("rm /tmp/maclist")
		uci:set("parental", rule_ind.."_service"..delete, "delete", "1")
		uci:commit("parental")
		uci:apply("parental")
		rule_ind = uci:get("parental", "general" , "ruleIdx")
		keywords = uci:get("parental", rule_ind , "keyword")
		luci.template.render("expert_configuration/ParentalControl_Edit",{keywords = keywords, selectindx = selectindx, rule=rule_ind, mac_list=mac_list })
	end
	
	if apply then
	
		local rule_enable = luci.http.formvalue("rule_enable")

		if not(rule_enable) then
			uci:set("parental", rule_ind, "enable", "0")
		else
			uci:set("parental", rule_ind, "enable", "1")
		end

		local rule_name = luci.http.formvalue("rule_name")
		
		rule_name = checkInjection(rule_name)
		if rule_name ~= false then

			uci:set("parental", rule_ind, "name", rule_name)
			
			local weekdays = ""
			local Date_Mon = luci.http.formvalue("Date_Mon")
			local Date_Tue = luci.http.formvalue("Date_Tue")
			local Date_Wed = luci.http.formvalue("Date_Wed")
			local Date_Thu = luci.http.formvalue("Date_Thu")
			local Date_Fri = luci.http.formvalue("Date_Fri")
			local Date_Sat = luci.http.formvalue("Date_Sat")
			local Date_Sun = luci.http.formvalue("Date_Sun")
			if Date_Mon then
				weekdays = weekdays.."Mon,"
			end
			if Date_Tue then
				weekdays = weekdays.."Tue,"
			end
			if Date_Wed then
				weekdays = weekdays.."Wed,"
			end
			if Date_Thu then
				weekdays = weekdays.."Thu,"
			end
			if Date_Fri then
				weekdays = weekdays.."Fri,"
			end
			if Date_Sat then
				weekdays = weekdays.."Sat,"
			end
			if Date_Sun then
				weekdays = weekdays.."Sun"
			else 
				weekdays = string.sub(weekdays,1,-2)
			end
			uci:set("parental", rule_ind, "weekdays", weekdays)
			
			local StartHour = luci.http.formvalue("StartHour")
			local StartMin = luci.http.formvalue("StartMin")
			local EndHour = luci.http.formvalue("EndHour")
			local EndMin = luci.http.formvalue("EndMin")
			if string.match(StartHour, "(%d%d)") then
				StartHour = string.match(StartHour, "(%d%d)")
				uci:set("parental",rule_ind,"start_hour",StartHour)	
			end
			if string.match(StartMin, "(%d%d)") then
				StartMin = string.match(StartMin, "(%d%d)")
				uci:set("parental",rule_ind,"start_min",StartMin)
			end
			if string.match(EndHour, "(%d%d)") then
				EndHour = string.match(EndHour, "(%d%d)")
				uci:set("parental",rule_ind,"stop_hour",EndHour)	
			end
			if string.match(EndMin, "(%d%d)") then
				EndMin = string.match(EndMin, "(%d%d)")
				uci:set("parental",rule_ind,"stop_min",EndMin)		
			end	
			
			local url_str = luci.http.formvalue("url_str")
			if not url_str  then url_str="" end 
			
			url_str = checkInjection(url_str)
			if url_str ~= false then
				uci:set("parental",rule_ind,"keyword",url_str)
			end

			local src_select = luci.http.formvalue("src_select")
			if  (src_select == "Custom")  then
				uci:set("parental",rule_ind,"src_type","custom")
				local MAC_Address = luci.http.formvalue("MAC_Address")
				MAC_Address = string.lower(MAC_Address)
				if string.match(MAC_Address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
					MAC_Address = string.match(MAC_Address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
					uci:set("parental",rule_ind,"src_mac",MAC_Address)
				end
			elseif (src_select == "All") then
				uci:set("parental",rule_ind,"src_type","all")	
				uci:set("parental",rule_ind,"src_mac","00:00:00:00:00:00")
			else 
				mac = "%w%w:%w%w:%w%w:%w%w:%w%w:%w%w"
				src_mac = string.sub(src_select, string.find(src_select, mac))
				if string.match(src_mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
					src_mac = string.match(src_mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
					uci:set("parental",rule_ind,"src_mac",src_mac)
				end
				uci:set("parental",rule_ind,"src_type","single")	
			end
			
			local service_act = luci.http.formvalue("service_act")
			if  (service_act == "block")  then
				uci:set("parental",rule_ind,"service_act","block")
			else
				uci:set("parental",rule_ind,"service_act","allow")
			end	
			
			uci:commit("parental")
			uci:apply("parental")
		end --if rule_name ~= false then
		luci.template.render("expert_configuration/ParentalControl")
	end
	
	if apply2 then
	
		rule_ind = uci:get("parental", "general" , "ruleIdx")
		
		if "New" == editID then
			local count = 1 + uci:get("parental", rule_ind , "service_count")
			uci:set("parental",rule_ind.."_service"..count,"parental_netservice"..rule_ind)
			uci:set("parental",rule_ind,"service_count",count)
			editID = rule_ind.."_service"..count
		end
		
		local service_name = luci.http.formvalue("service_name")
		service_name = checkInjection(service_name)
		local service_proto = luci.http.formvalue("service_proto")
		service_proto = checkInjection(service_proto)
		
		if service_name ~= false and service_proto ~= false then		
		
			if service_name ~= "UserDefined" then		
				uci:set("parental",editID ,"name",service_name)
				uci:set("parental",editID ,"proto",service_proto)
			end

			local service_port
			if service_name == "UserDefined" then
				service_port = luci.http.formvalue("service_port")
				local user_define_name = luci.http.formvalue("user_define_name")
				user_define_name = checkInjection(user_define_name)
				if user_define_name ~= false  and string.match(service_port, "(%d+)") then
					--service_port = string.match(service_port, "(%d+)")
					uci:set("parental",editID ,"name",service_name)
					uci:set("parental",editID ,"proto",service_proto)
					uci:set("parental",editID ,"user_define_name",user_define_name)
				end			
			elseif service_name == "XboxLive" then
				service_port = "3074"
			elseif service_name == "HTTP" then
				service_port = "80"
			elseif service_name == "HTTPS" then
				service_port = "443"
			elseif service_name == "ISPEC_IKE" then
				service_port = "500,4500"
			elseif service_name == "MicrosoftRemoteDesktop" then
				service_port = "3389"
			elseif service_name == "NetMeeting" then
				service_port = "1720"
			elseif service_name == "POP3" then
				service_port = "110"
			elseif service_name == "PPTP" then
				service_port = "1723"
			elseif service_name == "SMTP" then
				service_port = "25"
			elseif service_name == "SSH" then
				service_port = "22"
			else
				service_port = "5500,5800,5900-5910"
			end
			sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $2}' >/tmp/maclist")
			editmac = uci:get("parental", rule_ind , "src_mac")
			local idx_3 = 0
			for mac in io.lines("/tmp/maclist") do
				if ( mac == editmac) then
					selectindx = idx_3
					uci:set("parental",rule_ind,"src_type","single")
					break
				else
					selectindx = "none"
				end
				idx_3 = idx_3 + 1
			end
			if ( selectindx == "none") and ( editmac ~= "00:00:00:00:00:00" ) then
				uci:set("parental",rule_ind,"src_type","custom")
			end
			uci:set("parental",editID ,"port",service_port)
			uci:commit("parental")
			uci:apply("parental")
		end --if service_name ~= false and service_proto ~= false then
		
		rule_ind = uci:get("parental", "general" , "ruleIdx")
		keywords = uci:get("parental", rule_ind , "keyword")
		luci.template.render("expert_configuration/ParentalControl_Edit",{keywords = keywords, selectindx = selectindx, rule=rule_ind, mac_list=mac_list })
	end
	

	if Back then
		luci.template.render("expert_configuration/ParentalControl")
	end

	
end

--Eten dynamic DNS
function action_ddns()
	local apply = luci.http.formvalue("apply")

	if apply then
		local provider = luci.http.formvalue("DDNSProvider")
		local update   = luci.http.formvalue("DDNSUpdate")
		local host     = luci.http.formvalue("DDNSHost")
		local user     = luci.http.formvalue("DDNSUser")
		local passwd   = luci.http.formvalue("DDNSPasswd")
		local entry = nil

		uci:foreach("updatedd", "updatedd", function( section )
			entry = section[".name"]
			if provider ~= false then
				uci:set("updatedd", entry, "service", provider)
			end
			
			-- if nil == section.service and nil == entry then
				-- entry = section[".name"]
				-- provider = checkInjection(provider)
				-- if provider ~= false then
					-- uci:set("updatedd", entry, "service", provider)
				-- end
			-- end
			-- if section.service == provider then
				-- entry = section[".name"]
			-- end
		end)

		-- if nil == entry then
			-- entry = uci:add("updatedd", "updatedd")
			-- uci:set("updatedd", entry, "service", provider)
		-- end

		if "enable" == update then
			uci:set("updatedd", entry, "update", "1")
		else
			uci:set("updatedd", entry, "update", "0")
		end

		host = checkInjection(host)
		if host ~= false then
			uci:set("updatedd", entry, "host", host)
		end
		
		user = checkInjection(user)
		if user ~= false then
			uci:set("updatedd", entry, "username", user)
		end
		
		passwd = checkInjection(passwd)
		if passwd ~= false and string.find(passwd,"-") == nil then
			uci:set("updatedd", entry, "password", passwd)
		end

		uci:save("updatedd")
		uci:commit("updatedd")
		uci:apply("updatedd")
	end

	luci.template.render("expert_configuration/ddns")
end
--Eten END
--
--Eten Static Route
function action_static_route()
	local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	local submitType = luci.http.formvalue("SRSubmitType")

	if apply then
		if "edit" == submitType then
			local editID = luci.http.formvalue("SREditID")
			local enable = luci.http.formvalue("SREditRadio")
			local name   = luci.http.formvalue("SREditName")
			local dest   = luci.http.formvalue("SREditDest")
			local mask   = luci.http.formvalue("SREditMask")
			local gw_enable = luci.http.formvalue("SR_GW_Radio")
			local gw     = luci.http.formvalue("SREditGW")
			local wan_iface = luci.http.formvalue("SR_Wan_Face")
			local entryName = nil

			if "New" == editID then
				editID = uci:get("route", "general", "routes_count") + 1
				uci:set("route", "general", "routes_count", editID)
				entryName = "route" .. editID
				uci:set("route", entryName, "route")
				uci:set("route", entryName, "new", "1")
			else
				entryName = editID
				local wan_iface_temp = uci:get("route", entryName, "wan_iface")
				
				uci:set("route", entryName, "edit", "1")
				uci:set("route", entryName, "dest_ip_old", uci:get("route", entryName, "dest_ip"))
				uci:set("route", entryName, "netmask_old", uci:get("route", entryName, "netmask"))
				uci:set("route", entryName, "gateway_enable_old", uci:get("route", entryName, "gateway_enable"))
				uci:set("route", entryName, "gateway_old", uci:get("route", entryName, "gateway"))
				uci:set("route", entryName, "enable_old", uci:get("route", entryName, "enable"))
				if  not( wan_iface_temp == nil) then
				    uci:set("route", entryName, "wan_iface_old",wan_iface_temp )
				else
					uci:delete("route", entryName, "wan_iface_old" )
				end
			end

			uci:set("route", entryName, "name", name)
			uci:set("route", entryName, "dest_ip", dest)
			uci:set("route", entryName, "netmask", mask)
			--uci:set("route", entryName, "gateway", gw)
			
			if  not( wan_iface == nil) then
				uci:set("route", entryName, "wan_iface", wan_iface)
			else
				uci:delete("route", entryName, "wan_iface" )
			end

			if  not( gw == nil) then
				uci:set("route", entryName, "gateway", gw)
			else
				uci:set("route", entryName, "gateway", "0.0.0.0")
			end
			
			if not ("enable" == enable) then
				uci:set("route", entryName, "enable", 0)
			else
				uci:set("route", entryName, "enable", 1)
			end

			if not ("enable" == gw_enable) then
				uci:set("route", entryName, "gateway_enable", 0)
			else
				uci:set("route", entryName, "gateway_enable", 1)
			end
			
			uci:save("route")
			uci:commit("route")
			uci:apply("route")
		elseif "table" == submitType then

			local list = luci.http.formvalue("SRDeleteIDs")

			if not ( "" == list ) then
				local i, j = 0, 0

				while true do
				        j = string.find(list, ",", i + 1)
		        		if j == nil then break end
					uci:set("route", string.sub(list, i + 1, j - 1 ), "delete", "1")
				        i = j
				end

				uci:save("route")
				uci:commit("route")
				uci:apply("route")
			end

		end
	end
	
	if delete then
		uci:set("route", "route" .. delete, "delete", "1")
		uci:commit("route")
		uci:apply("route")
	end

	luci.template.render("expert_configuration/static_route")
end
--Eten Static Route END

function action_portfw()
	local new = luci.http.formvalue("new")
	local apply = luci.http.formvalue("apply")
	local add = luci.http.formvalue("add")
	local remove = luci.http.formvalue("remove")
	
	if new then	
		uci:revert("nat")
		--uci:revert("nat_new")
	end
	
	if apply then
		local serChange = luci.http.formvalue("serChange")
		local changeToSerIP = luci.http.formvalue("changeToSerIP")
		local last_changeToSerIP
		local last_changeToSer = uci:get("nat","general","changeToSer")
		local changeToSer = 0		
		if (serChange=="change") then
			last_changeToSerIP = uci:get("nat","general","changeToSerIP")
			if not (changeToSerIP=="") then
				local changeToSer = 1
				uci:set("nat","general","changeToSer",changeToSer)
				uci:set("nat","general","changeToSerIP",changeToSerIP)
				if last_changeToSerIP then
					uci:set("nat","general","last_changeToSerIP",last_changeToSerIP)
				end
				if last_changeToSer=="0" then
					uci:set("nat","general","last_changeToSerIP","0.0.0.0")
				end

				--uci:set("nat_new","general_new","changeToSer",changeToSer)
				--uci:set("nat_new","general_new","changeToSerIP",changeToSerIP)
			end	
		else
			last_changeToSerIP = uci:get("nat","general","changeToSerIP")
			if last_changeToSerIP then
				uci:delete("nat","general","changeToSerIP")
				uci:set("nat","general","last_changeToSerIP",last_changeToSerIP)
				--uci:set("nat_new","general_new","last_changeToSerIP",last_changeToSerIP)
			end
			uci:set("nat","general","changeToSer",changeToSer)			
			--uci:set("nat_new","general_new","changeToSer",changeToSer)
			
		end	
		
		uci:commit("nat")
		uci:apply("nat")
		--uci:commit("nat_new")
		--uci:apply("nat_new")
	end	
	
	if add then
		local enabled = 1
		local srvIndex = luci.http.formvalue("srvIndex")
		local srvName,extPort,protocol,trPort = fetchProtocolInfo(srvIndex)
		
		if (protocol=="") then
			protocol = luci.http.formvalue("protocol")
		end
		
		local srvIp = luci.http.formvalue("srvIp")
		local wake_up = 1
		local wan = 1
		local wan_ip = "0.0.0.0"
		local rules_count = uci:get("nat","general","rules_count")
		local NextRulePos = uci:get("nat","general","NextRulePos")		
		rules_count = rules_count+1
		local rules = "rule"..rules_count	
		uci:set("nat",rules,"nat")		
		uci:set("nat",rules,"StatusEnable",enabled)
		uci:set("nat",rules,"CurPos",NextRulePos)
		uci:set("nat",rules,"service",srvName)
		uci:set("nat",rules,"service_idx",srvIndex)
		uci:set("nat",rules,"protocol",protocol)
		uci:set("nat",rules,"port",extPort)
		uci:set("nat",rules,"trport",trPort)
		uci:set("nat",rules,"wan",wan)
		uci:set("nat",rules,"wan_ip",wan_ip)
		uci:set("nat",rules,"local_ip",srvIp)
		uci:set("nat",rules,"wake_up",wake_up)
		uci:set("nat",rules,"wan_name","wan")	--2015/10/06 add for zlibmapping, in order to sync TR-098 and uci data model
		uci:set("nat","general","rules_count",rules_count)
		
		uci:save("nat")
		uci:commit("nat")
		uci:apply("nat")
		
		-- must reset remote management of WWW from port 80 to 8080 
		if srvIndex=="0" then
			local remote_www_port = uci:get("firewall", "remote_www", "port")
	
			if remote_www_port=="80" then

				uci:set("firewall", "remote_www", "port", 8080)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				uci:apply("uhttpd")
				uci:apply("firewall")
			end
		end
		
		-- must reset remote management of HTTPS from port 443 to 44343 
		if srvIndex=="1" then
			local remote_https = uci:get("firewall", "remote_https", "port")
			if remote_https=="443" then
				uci:set("firewall", "remote_https", "port", 44343)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				uci:apply("uhttpd")
				uci:apply("firewall")
			end	
		end

		-- must reset remote management of Telnet from port 23 to 2323
		if srvIndex=="5" then 
			local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
			if remote_telnet_port=="23" then
				sys.exec("/etc/init.d/telnet stop 2>/dev/null")
				uci:set("firewall", "remote_telnet", "port", 2323)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				sys.exec("/etc/init.d/telnet start 2>/dev/null")
				uci:apply("firewall")
			end
		end
		--[[
		-----nat_new-----
		local new_rule = 1
		local new_rules_count = uci:get("nat_new","general_new","rules_count")
		new_rules_count = new_rules_count+1
		local new_rules = "rule_new"..new_rules_count		
		
		uci:set("nat_new",new_rules,"nat")
		uci:set("nat_new",new_rules,"new_rule",new_rule)		
		uci:set("nat_new",new_rules,"CurPos",NextRulePos)
		uci:set("nat_new",new_rules,"service",srvName)
		uci:set("nat_new",new_rules,"port",extPort)
		uci:set("nat_new",new_rules,"wan",wan)
		uci:set("nat_new",new_rules,"wan_ip",wan_ip)
		uci:set("nat_new",new_rules,"local_ip",srvIp)
		uci:set("nat_new",new_rules,"StatusEnable",enabled)	
		uci:set("nat_new","general_new","rules_count",new_rules_count)
		uci:save("nat_new")
		uci:commit("nat_new")
		uci:apply("nat_new")		
				
		NextRulePos = NextRulePos+1
		uci:set("nat","general","NextRulePos",NextRulePos)
		uci:commit("nat")
		uci:apply("nat")
		]]--
	end		
	
	if remove then
		local del_rule = remove
		local rul_num = tonumber(string.match(del_rule,"%d+"))
		local cur_num = rul_num
		local rm_curpos = uci:get("nat",del_rule,"CurPos")
		local extPort = uci:get("nat",del_rule,"port")
		uci:delete("nat",del_rule)
		
		local rules_count = uci:get("nat","general","rules_count")
		local NextRulePos = uci:get("nat","general","NextRulePos")		
		local num = rules_count-cur_num
		
		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("nat",rules)
			
			if old_data then				
				uci:set("nat",new_rule,"nat")
				uci:tset("nat",new_rule,old_data)
				
				local edit_CurPos=uci:get("nat",new_rule,"CurPos")				
				uci:set("nat",new_rule,"CurPos",edit_CurPos-1)

				uci:delete("nat",rules)
				uci:commit("nat")
				cur_num =cur_num+1				
			end
		end		
		uci:set("nat","general","rules_count",rules_count-1)
		uci:set("nat","general","NextRulePos",NextRulePos-1)
		uci:commit("nat")
		uci:apply("nat")
		
		-- must reset remote management of WWW from port 8080 to 80 
		if extPort=="80" then
			local remote_www_port = uci:get("firewall", "remote_www", "port")
			if remote_www_port=="8080" then
				uci:set("firewall", "remote_www", "port", 80)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				uci:apply("uhttpd")
				uci:apply("firewall")
			end
		end

		-- must reset remote management of HTTPS from port 44343 to 443
		if extPort=="443" then
			local remote_https = uci:get("firewall", "remote_https", "port")
			if remote_https=="44343" then
			
				uci:set("firewall", "remote_https", "port", 443)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				uci:apply("uhttpd")
				uci:apply("firewall")

			end
		end
		
		-- must reset remote management of Telnet from port 2323 to 23
		if extPort=="23" then 
			local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
			if remote_telnet_port=="2323" then
				sys.exec("/etc/init.d/telnet stop 2>/dev/null")
				uci:set("firewall", "remote_telnet", "port", 23)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				sys.exec("/etc/init.d/telnet start 2>/dev/null")
				uci:apply("firewall")
			end
		end
		
		--[[
		-----nat_new-----
		local delete_rule=1
		local new_rules_count = uci:get("nat_new","general_new","rules_count")
		new_rules_count = new_rules_count+1
		local new_rules = "rule_new"..new_rules_count
		
		uci:set("nat_new",new_rules,"nat")
		uci:set("nat_new",new_rules,"delete_rule",delete_rule)
		uci:set("nat_new",new_rules,"CurPos",rm_curpos)
		uci:set("nat_new","general_new","rules_count",new_rules_count)
		
		uci:commit("nat_new")
		uci:apply("nat_new")
		]]--
	end
	
	luci.template.render("expert_configuration/nat_application")
end

function action_portfw_edit()

	local apply = luci.http.formvalue("apply")
	local edit = luci.http.formvalue("edit")	
	
	if apply then
		local rules = luci.http.formvalue("rules")
		local enabled = luci.http.formvalue("enabled")		
		local srvIndex = luci.http.formvalue("srvIndex")
		local srvName,extPort,protocol,trPort = fetchServerInfo(srvIndex)
		local cfgPort = uci:get("nat",rules,"port")
		
		local srvIp = luci.http.formvalue("srvIp")
		local wake_up = luci.http.formvalue("wake_up")
		local url = luci.dispatcher.build_url("expert","configuration","network","nat","portfw")		
		local wan = 1
		local wan_ip = "0.0.0.0"
		local CurPos =uci:get("nat",rules,"CurPos")
		local NextRulePos = uci:get("nat","general","NextRulePos")
		local ori_StatusEnable=uci:get("nat",rules,"StatusEnable")
						
		if not wake_up then
			wake_up = 0
		end
		
		uci:set("nat",rules,"service",srvName)
		uci:set("nat",rules,"service_idx",srvIndex)
		uci:set("nat",rules,"port",extPort)
		uci:set("nat",rules,"trport",trPort)
		uci:set("nat",rules,"protocol",protocol)
		uci:set("nat",rules,"wan",wan)
		uci:set("nat",rules,"wan_ip",wan_ip)
		uci:set("nat",rules,"local_ip",srvIp)
		uci:set("nat",rules,"wake_up",wake_up)

		local rules_count = uci:get("nat","general","rules_count")
		local rul_num = tonumber(string.match(rules,"%d+"))
		local cur_num = rul_num
		local edit_rules
		local edit_rules_curpos
		if enabled=="0" then
			uci:set("nat",rules,"StatusEnable",enabled)
			if not (ori_StatusEnable==enabled) then							
				for i=rules_count,1,-1 do
					cur_num = cur_num+1
					edit_rules="rule"..cur_num
					edit_rules_curpos = uci:get("nat",edit_rules,"CurPos")
					if edit_rules_curpos then					
						uci:set("nat",edit_rules,"CurPos",edit_rules_curpos-1)
					end
				end
				uci:set("nat","general","NextRulePos",NextRulePos-1)
			end
		elseif enabled=="1" then
			uci:set("nat",rules,"StatusEnable",enabled)
			if not (ori_StatusEnable==enabled) then
				for i=rules_count,1,-1 do
					cur_num = cur_num+1
					edit_rules="rule"..cur_num
					edit_rules_curpos = uci:get("nat",edit_rules,"CurPos")
					if edit_rules_curpos then					
						uci:set("nat",edit_rules,"CurPos",edit_rules_curpos+1)
					end
				end
				uci:set("nat","general","NextRulePos",NextRulePos+1)				
			end
			
		end
		
		uci:commit("nat")		
		uci:apply("nat")
		
		local remote_www_port = uci:get("firewall", "remote_www", "port")
		local remote_https = uci:get("firewall", "remote_https", "port")
		local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
		local reload_uhttpd="0"
		local reload_telnet="0"

		-- must reset remote management of WWW from port 80 to 8080 
		if extPort==80 and cfgPort~="80" then
			if remote_www_port=="80" then

				uci:set("firewall", "remote_www", "port", 8080)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				reload_uhttpd="1"
			end
		end

		-- must reset remote management of HTTPS from port 443 to 44343 
		if extPort==443 and cfgPort~="443" then			
			if remote_https=="443" then
				uci:set("firewall", "remote_https", "port", 44343)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				reload_uhttpd="1"
			end
		end

		-- must reset remote management of Telnet from port 23 to 2323
		if extPort==23 and cfgPort~="23" then 
			if remote_telnet_port=="23" then
				uci:set("firewall", "remote_telnet", "port", 2323)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				reload_telnet="1"
			end
		end
		
		-- must reset remote management of WWW from port 8080 to 80
		if cfgPort=="80" and extPort~=80 then
			if remote_www_port=="8080" then
				uci:set("firewall", "remote_www", "port", 80)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				reload_uhttpd="1"
			end
		end

		-- must reset remote management of HTTPS from port 44343 to 443
		if cfgPort=="443" and extPort~=443 then
			if remote_https=="44343" then
				uci:set("firewall", "remote_https", "port", 443)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				reload_uhttpd="1"
			end
		end

		-- must reset remote management of Telnet from port 2323 to 23
		if cfgPort=="23" and extPort~=23 then 
			if remote_telnet_port=="2323" then
				uci:set("firewall", "remote_telnet", "port", 23)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")
				reload_telnet="1"
			end
		end
		
		if reload_telnet=="1" then
			sys.exec("/etc/init.d/telnet stop 2>/dev/null")
			sys.exec("/etc/init.d/telnet start 2>/dev/null")
			uci:apply("firewall")
		end
		
		if reload_uhttpd=="1" then
			uci:apply("uhttpd")
			uci:apply("firewall")
		end
		--[[
		-----nat_new-----		
		local new_rules_count = uci:get("nat_new","general_new","rules_count")
		new_rules_count = new_rules_count+1
		local new_rules = "rule_new"..new_rules_count
		if enabled=="0" then
			if not (ori_StatusEnable==enabled) then
				local delete_rule = 1								
				uci:set("nat_new",new_rules,"nat")
				uci:set("nat_new",new_rules,"delete_rule",delete_rule)
				uci:set("nat_new",new_rules,"CurPos",CurPos)
				uci:set("nat_new","general_new","rules_count",new_rules_count)
			end
		else
			if not (ori_StatusEnable==enabled) then
				local insert_rule = 1
				uci:set("nat_new",new_rules,"nat")
				uci:set("nat_new",new_rules,"insert_rule",insert_rule)
				uci:set("nat_new",new_rules,"service",srvName)
				uci:set("nat_new",new_rules,"port",extPort)
				uci:set("nat_new",new_rules,"wan",wan)
				uci:set("nat_new",new_rules,"wan_ip",wan_ip)
				uci:set("nat_new",new_rules,"local_ip",srvIp)			
				uci:set("nat_new",new_rules,"CurPos",CurPos)
				uci:set("nat_new","general_new","rules_count",new_rules_count)
			else
				local edit_rule = 1
				uci:set("nat_new",new_rules,"nat")
				uci:set("nat_new",new_rules,"edit_rule",edit_rule)
				uci:set("nat_new",new_rules,"service",srvName)
				uci:set("nat_new",new_rules,"port",extPort)
				uci:set("nat_new",new_rules,"wan",wan)
				uci:set("nat_new",new_rules,"wan_ip",wan_ip)
				uci:set("nat_new",new_rules,"local_ip",srvIp)
				uci:set("nat_new",new_rules,"CurPos",CurPos)
				uci:set("nat_new","general_new","rules_count",new_rules_count)		
			end
		end
		
		uci:commit("nat_new")		
		uci:apply("nat_new")
		]]--
		luci.http.redirect(url)		
	end	
	
	if edit then
		local rules = edit
		local enabled = uci:get("nat",rules,"StatusEnable")
		local protocol = uci:get("nat",rules,"protocol")
		local extPort = uci:get("nat",rules,"port")		
		local trPort = uci:get("nat",rules,"trport")
		local srvName = uci:get("nat",rules,"service")
		local srvIdx = uci:get("nat",rules,"service_idx")
		local srvIp = uci:get("nat",rules,"local_ip")
		local wake_up = uci:get("nat",rules,"wake_up")		
		local url = luci.dispatcher.build_url("expert","configuration","network","nat","portfw","portfw_edit")
		
		luci.http.redirect(url .. "?" .. "service_name=" .. srvName .. "&rules=" .. rules .. "&enabled=" .. enabled .. "&protocol=" .. protocol .. "&srvIdx=" .. srvIdx .. "&external_port=" .. extPort .. "&tr_port=" .. trPort .. "&server_ip=" .. srvIp .. "&wake_up=" .. wake_up .. "&rt=" .. 1 .. "&errmsg=test!!")
		return
	end

	luci.template.render("expert_configuration/nat_application_edit")
end


function port_trigger()

	local apply = luci.http.formvalue("apply")
	
	if apply then		
	
		local trigger_named
		local inComing_port_start
		local inComing_port_end
		local trigger_port_start
		local trigger_port_end		
		local preInfo

		
			--if not (luci.http.formvalue("trigger_name1") == "") then
			trigger_named = luci.http.formvalue("trigger_name1")
			inComing_port_start = luci.http.formvalue("inComing_port_start1")
			inComing_port_end = luci.http.formvalue("inComing_port_end1")
			trigger_port_start = luci.http.formvalue("trigger_port_start1")
			trigger_port_end = luci.http.formvalue("trigger_port_end1")	
			preName = luci.http.formvalue("preData1")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name2") == "") then
			trigger_named = luci.http.formvalue("trigger_name2")
			inComing_port_start = luci.http.formvalue("inComing_port_start2")
			inComing_port_end = luci.http.formvalue("inComing_port_end2")
			trigger_port_start = luci.http.formvalue("trigger_port_start2")
			trigger_port_end = luci.http.formvalue("trigger_port_end2")	
			preName = luci.http.formvalue("preData2")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name3") == "") then
			trigger_named = luci.http.formvalue("trigger_name3")
			inComing_port_start = luci.http.formvalue("inComing_port_start3")
			inComing_port_end = luci.http.formvalue("inComing_port_end3")
			trigger_port_start = luci.http.formvalue("trigger_port_start3")
			trigger_port_end = luci.http.formvalue("trigger_port_end3")
			preName = luci.http.formvalue("preData3")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name4") == "") then
			trigger_named = luci.http.formvalue("trigger_name4")
			inComing_port_start = luci.http.formvalue("inComing_port_start4")
			inComing_port_end = luci.http.formvalue("inComing_port_end4")
			trigger_port_start = luci.http.formvalue("trigger_port_start4")
			trigger_port_end = luci.http.formvalue("trigger_port_end4")
			preName = luci.http.formvalue("preData4")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name5") == "") then
			trigger_named = luci.http.formvalue("trigger_name5")
			inComing_port_start = luci.http.formvalue("inComing_port_start5")
			inComing_port_end = luci.http.formvalue("inComing_port_end5")
			trigger_port_start = luci.http.formvalue("trigger_port_start5")
			trigger_port_end = luci.http.formvalue("trigger_port_end5")
			preName = luci.http.formvalue("preData5")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name6") == "") then
			trigger_named = luci.http.formvalue("trigger_name6")
			inComing_port_start = luci.http.formvalue("inComing_port_start6")
			inComing_port_end = luci.http.formvalue("inComing_port_end6")
			trigger_port_start = luci.http.formvalue("trigger_port_start6")
			trigger_port_end = luci.http.formvalue("trigger_port_end6")
			preName = luci.http.formvalue("preData6")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name7") == "") then
			trigger_named = luci.http.formvalue("trigger_name7")
			inComing_port_start = luci.http.formvalue("inComing_port_start7")
			inComing_port_end = luci.http.formvalue("inComing_port_end7")
			trigger_port_start = luci.http.formvalue("trigger_port_start7")
			trigger_port_end = luci.http.formvalue("trigger_port_end7")
			preName = luci.http.formvalue("preData7")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name8") == "") then
			trigger_named = luci.http.formvalue("trigger_name8")
			inComing_port_start = luci.http.formvalue("inComing_port_start8")
			inComing_port_end = luci.http.formvalue("inComing_port_end8")
			trigger_port_start = luci.http.formvalue("trigger_port_start8")
			trigger_port_end = luci.http.formvalue("trigger_port_end8")
			preName = luci.http.formvalue("preData8")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name9") == "") then
			trigger_named = luci.http.formvalue("trigger_name9")
			inComing_port_start = luci.http.formvalue("inComing_port_start9")
			inComing_port_end = luci.http.formvalue("inComing_port_end9")
			trigger_port_start = luci.http.formvalue("trigger_port_start9")
			trigger_port_end = luci.http.formvalue("trigger_port_end9")
			preName = luci.http.formvalue("preData9")			
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name10") == "") then
			trigger_named = luci.http.formvalue("trigger_name10")
			inComing_port_start = luci.http.formvalue("inComing_port_start10")
			inComing_port_end = luci.http.formvalue("inComing_port_end10")
			trigger_port_start = luci.http.formvalue("trigger_port_start10")
			trigger_port_end = luci.http.formvalue("trigger_port_end10")
			preName = luci.http.formvalue("preData10")			
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name11") == "") then
			trigger_named = luci.http.formvalue("trigger_name11")
			inComing_port_start = luci.http.formvalue("inComing_port_start11")
			inComing_port_end = luci.http.formvalue("inComing_port_end11")
			trigger_port_start = luci.http.formvalue("trigger_port_start11")
			trigger_port_end = luci.http.formvalue("trigger_port_end11")
			preName = luci.http.formvalue("preData11")			
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------
			--if not (luci.http.formvalue("trigger_name12") == "") then
			trigger_named = luci.http.formvalue("trigger_name12")
			inComing_port_start = luci.http.formvalue("inComing_port_start12")
			inComing_port_end = luci.http.formvalue("inComing_port_end12")
			trigger_port_start = luci.http.formvalue("trigger_port_start12")
			trigger_port_end = luci.http.formvalue("trigger_port_end12")
			preName = luci.http.formvalue("preData12")
			if preName=="" then
				if not (trigger_named == "") then
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
				end
			else
				if (trigger_named == "") then trigger_named=" " end
					port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
			end
			-- ------------------------------------------------------------------------------------------------------	
			
	end

	luci.template.render("expert_configuration/nat_advance")
end

function port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)
		
		if not (preName=="") then 
			if not (trigger_named==preName) then
				uci:delete("portTrigger",preName)
				uci:commit("portTrigger")
			end
		end
		
		local section = uci:get("portTrigger",trigger_named)
		
		if not section then
			uci:set("portTrigger",trigger_named,"trigger")
		end			
		
		uci:set("portTrigger",trigger_named,"inComing_port_start",inComing_port_start)
		uci:set("portTrigger",trigger_named,"inComing_port_end",inComing_port_end)
		uci:set("portTrigger",trigger_named,"trigger_port_start",trigger_port_start)
		uci:set("portTrigger",trigger_named,"trigger_port_end",trigger_port_end)
		uci:commit("portTrigger")
		uci:apply("portTrigger")
end


function fetchProtocolInfo(num)

local protNam
local portNumb
local protocol
local trportNumb

	if num=="0" then
		protNam="WWW"
		portNumb=80
		protocol="tcpandudp"
		trportNumb=80
	elseif num=="1" then
		protNam="HTTPS"
		portNumb=443
		protocol="tcp"
		trportNumb=443
	elseif num=="2" then
		protNam="FTP"
		portNumb=21
		protocol="tcp"
		trportNumb=21
	elseif num=="3" then
		protNam="SMTP"
		portNumb=25
		protocol="tcp"
		trportNumb=25
	elseif num=="4" then
		protNam="POP3"
		portNumb=110
		protocol="tcp"
		trportNumb=110
	elseif num=="5" then
		protNam="Telnet"
		portNumb=23
		protocol="tcp"
		trportNumb=23
	elseif num=="6" then
		protNam="NetMeeting"
		portNumb=1720
		protocol="tcp"
		trportNumb=1720
	elseif num=="7" then
		protNam="PPTP"
		portNumb=1723
		protocol="tcpandudp"
		trportNumb=1723
	elseif num=="8" then
		protNam="IPSec"
		portNumb=500
		protocol="udp"
		trportNumb=500
	elseif num=="9" then
		protNam="SIP"
		portNumb=5060
		protocol="tcpandudp"
		trportNumb=5060
	elseif num=="10" then
		protNam="TFTP"
		portNumb=69
		protocol="udp"
		trportNumb=69
	elseif num=="11" then
		protNam="Real-Audio"
		portNumb=554
		protocol="tcpandudp"
		trportNumb=554
	elseif num=="12" then
		protNam=luci.http.formvalue("srvName")
		portNumb=luci.http.formvalue("srvPort")
		trportNumb=luci.http.formvalue("srvTrPort")
		protocol=luci.http.formvalue("protocol")
	else 
		protNam=""
		portNumb=0
		protocol=""
		trportNumb=0
	end
	
	return protNam,portNumb,protocol,trportNumb
end

function fetchServerInfo(srvidx)

local protNam
local portNumb
local protocol
local trportNumb

	if srvidx=="0" then
		protNam="WWW"
		portNumb=80
		protocol="tcpandudp"
		trportNumb=80
	elseif srvidx=="1" then
		protNam="HTTPS"
		portNumb=443
		protocol="tcp"
		trportNumb=443
	elseif srvidx=="2" then
		protNam="FTP"
		portNumb=21
		protocol="tcp"
		trportNumb=21
	elseif srvidx=="3" then
		protNam="SMTP"
		portNumb=25
		protocol="tcp"
		trportNumb=25
	elseif srvidx=="4" then
		protNam="POP3"
		portNumb=110
		protocol="tcp"
		trportNumb=110
	elseif srvidx=="5" then
		protNam="Telnet"
		portNumb=23
		protocol="tcp"
		trportNumb=23
	elseif srvidx=="6" then
		protNam="NetMeeting"
		portNumb=1720
		protocol="tcp"
		trportNumb=1720
	elseif srvidx=="7" then
		protNam="PPTP"
		portNumb=1723
		protocol="tcpandudp"
		trportNumb=1723
	elseif srvidx=="8" then
		protNam="IPSec"
		portNumb=500
		protocol="udp"
		trportNumb=500
	elseif srvidx=="9" then
		protNam="SIP"
		portNumb=5060
		protocol="tcpandudp"
		trportNumb=5060
	elseif srvidx=="10" then
		protNam="TFTP"
		portNumb=69
		protocol="udp"
		trportNumb=69
	elseif srvidx=="11" then
		protNam="Real-Audio"
		portNumb=554
		protocol="tcpandudp"
		trportNumb=554
	elseif srvidx=="12" then
		protNam=luci.http.formvalue("srvName")
		portNumb=luci.http.formvalue("extPort")
		trportNumb=luci.http.formvalue("srvTrPort")
		protocol=luci.http.formvalue("protocol")
		
	else 
		portNumb=0
		trportNumb=0
		protocol=""
	end
	
	return protNam,portNumb,protocol,trportNumb
end
--dipper nat

--benson dhcp
function action_dhcpSetup()
        local apply = luci.http.formvalue("sysSubmit")
        if apply then
			local enabled = luci.http.formvalue("ssid_state")
			local startAddress = luci.http.formvalue("startAdd")
			local poolSize = luci.http.formvalue("poolSize")
			local old_startAddress = uci:get("dhcp", "lan", "start")			
			local old_poolSize = uci:get("dhcp", "lan", "limit")			
			local start=string.match(startAddress,"%d+.%d+.%d+.(%d+)")
			
			local day = luci.http.formvalue("lease_day")
			local hour = luci.http.formvalue("lease_hour")
			local minute = luci.http.formvalue("lease_minute")
			local new_lease = day*1440 + hour*60 + minute .."m"
		
			if startAddress ~= old_startAddress or poolSize ~= old_poolSize then
				sys.exec("echo 1 > /tmp/lan_dhcp_range")
			end			
			
			uci:set("dhcp","lan","dhcp")
			uci:set("dhcp","lan",'enabled',enabled)
			uci:set("dhcp","lan",'start',start)
			uci:set("dhcp","lan",'limit',poolSize)
			uci:set("dhcp","lan",'lease',new_lease)
			
			uci:commit("dhcp")
			uci:apply("dhcp")
        end

        luci.template.render("expert_configuration/lan_dhcp_setup")
end

function action_dhcpStatic()
        local apply = luci.http.formvalue("sysSubmit")
        if apply then
		
                local old_lan_dns = uci:get("dhcp","lan","lan_dns")
                if old_lan_dns == nil then
                	old_lan_dns=""
                end
				
                local staticIp
                local file = io.open( "/etc/ethers", "w" )
                local dhcp_static_mac1= luci.http.formvalue("dhcp_static_mac1")
                local dhcp_static_ip1 = luci.http.formvalue("dhcp_static_ip1")
                local dhcp_static_mac2= luci.http.formvalue("dhcp_static_mac2")
                local dhcp_static_ip2 = luci.http.formvalue("dhcp_static_ip2")
                local dhcp_static_mac3= luci.http.formvalue("dhcp_static_mac3")
                local dhcp_static_ip3 = luci.http.formvalue("dhcp_static_ip3")
                local dhcp_static_mac4= luci.http.formvalue("dhcp_static_mac4")
                local dhcp_static_ip4 = luci.http.formvalue("dhcp_static_ip4")
                local dhcp_static_mac5= luci.http.formvalue("dhcp_static_mac5")
                local dhcp_static_ip5 = luci.http.formvalue("dhcp_static_ip5")
                local dhcp_static_mac6= luci.http.formvalue("dhcp_static_mac6")
                local dhcp_static_ip6 = luci.http.formvalue("dhcp_static_ip6")
                local dhcp_static_mac7= luci.http.formvalue("dhcp_static_mac7")
                local dhcp_static_ip7 = luci.http.formvalue("dhcp_static_ip7")
                local dhcp_static_mac8= luci.http.formvalue("dhcp_static_mac8")
                local dhcp_static_ip8 = luci.http.formvalue("dhcp_static_ip8")

                local sysFirstDNSAddr = luci.http.formvalue("sysFirDNSAddr")
                local sysSecondDNSAddr = luci.http.formvalue("sysSecDNSAddr")
                local sysThirdDNSAddr = luci.http.formvalue("sysThirdDNSAddr")


                if dhcp_static_ip1 ~= "0.0.0.0" and dhcp_static_mac1~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac1 .. " " .. dhcp_static_ip1 .. "\n")
			staticIp=dhcp_static_mac1 .. " " .. dhcp_static_ip1
                end

                if dhcp_static_ip2 ~= "0.0.0.0" and dhcp_static_mac2~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac2 .. " " .. dhcp_static_ip2 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac2 .. " " .. dhcp_static_ip2
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac2 .. " " .. dhcp_static_ip2
			end

                end

                if dhcp_static_ip3 ~= "0.0.0.0" and dhcp_static_mac3~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac3 .. " " .. dhcp_static_ip3 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac3 .. " " .. dhcp_static_ip3
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac3 .. " " .. dhcp_static_ip3
			end

                end

                if dhcp_static_ip4 ~= "0.0.0.0" and dhcp_static_mac4~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac4 .. " " .. dhcp_static_ip4 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac4 .. " " .. dhcp_static_ip4
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac4 .. " " .. dhcp_static_ip4
			end

                end

                if dhcp_static_ip5 ~= "0.0.0.0" and dhcp_static_mac5~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac5 .. " " .. dhcp_static_ip5 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac5 .. " " .. dhcp_static_ip5
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac5 .. " " .. dhcp_static_ip5
			end

                end

                if dhcp_static_ip6 ~= "0.0.0.0" and dhcp_static_mac6~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac6 .. " " .. dhcp_static_ip6 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac6 .. " " .. dhcp_static_ip6
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac6 .. " " .. dhcp_static_ip6
			end

                end

                if dhcp_static_ip7 ~= "0.0.0.0" and dhcp_static_mac7~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac7 .. " " .. dhcp_static_ip7 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac7 .. " " .. dhcp_static_ip7
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac7 .. " " .. dhcp_static_ip7
			end

                end

                if dhcp_static_ip8 ~= "0.0.0.0" and dhcp_static_mac8~= "00:00:00:00:00:00" then
                        file:write(dhcp_static_mac8 .. " " .. dhcp_static_ip8 .. "\n")

			if staticIp == nil then
				staticIp=dhcp_static_mac8 .. " " .. dhcp_static_ip8
			else
				staticIp=staticIp .. ";" .. dhcp_static_mac8 .. " " .. dhcp_static_ip8
			end

                end

                file:close()
				
		if staticIp == nil then
			staticIp=""
			uci:delete("dhcp","lan","staticIP")
			--uci:commit("dhcp")
			--uci:apply("dhcp")
		else
			uci:set("dhcp","lan",'staticIP',staticIp)
			--uci:commit("dhcp")
			--uci:apply("dhcp")
		end

		local lan_dns=""
		local d1= luci.http.formvalue("LAN_FirstDNS")
		if d1 == "00000000" then
			lan_dns=lan_dns .. "FromISP,"
		elseif d1 == "00000001"  then
			lan_dns=lan_dns .. sysFirstDNSAddr .. ","
		elseif d1 == "00000003"  then
			lan_dns=lan_dns .. "None,"
		else
			lan_dns=lan_dns .. "dnsRelay,"
		end

		local d2= luci.http.formvalue("LAN_SecondDNS")
		if d2 == "00000000" then
			lan_dns=lan_dns .. "FromISP,"
		elseif d2 == "00000001"  then
			lan_dns=lan_dns .. sysSecondDNSAddr .. ","
		elseif d2 == "00000003"  then
			lan_dns=lan_dns .. "None,"
		else
			lan_dns=lan_dns .. "dnsRelay,"
		end

		local d3= luci.http.formvalue("LAN_ThirdDNS")
		if d3 == "00000000" then
			lan_dns=lan_dns .. "FromISP"
		elseif d3 == "00000001"  then
			lan_dns=lan_dns .. sysThirdDNSAddr
		elseif d3 == "00000003"  then
			lan_dns=lan_dns .. "None"
		else
			lan_dns=lan_dns .. "dnsRelay"
		end

		if  not ( lan_dns == old_lan_dns ) then
			sys.exec("echo 1 > /tmp/lan_dhcp_range")
		end

		uci:set("dhcp","lan","dhcp")
		uci:set("dhcp","lan",'lan_dns',lan_dns)
		uci:commit("dhcp")
		uci:apply("dhcp")

                sys.exec("/etc/init.d/dnsmasq stop 2>/dev/null")
                sys.exec("/etc/init.d/dnsmasq start 2>/dev/null")
        end
        luci.template.render("expert_configuration/LAN_IPStatic")
end

function action_clientList()
	local apply = luci.http.formvalue("sysSubmit")
 	if apply then
		local staticIp= luci.http.formvalue("macIp")
                local onlyOne=luci.http.formvalue("onlyOne")
                uci:set("dhcp","lan",'staticIP',staticIp)
                uci:commit("dhcp")
                uci:apply("dhcp")

		local staticInfo=uci.get("dhcp","lan","staticIP")

		if not staticInfo then
			local file = io.open( "/etc/ethers", "w" )
			file:write("")
			file:close()
		else
			local have=string.split(staticInfo,";")
			if onlyOne=="1" then
				local file = io.open( "/etc/ethers", "w" )
				file:write(staticInfo .. "\n")
				file:close()
			else
				local file = io.open( "/etc/ethers", "w" )
				for index,info in pairs(have) do
					file:write(info .. "\n")
				end
				file:close()
			end
		end
		sys.exec("/etc/init.d/dnsmasq stop 2>/dev/null")
		sys.exec("/etc/init.d/dnsmasq start 2>/dev/null")
	end

	luci.template.render("expert_configuration/LAN_DHCPTbl_1")
end
--benson dhcp

--Eten remote
function action_remote_www()
	local uname = luci.dispatcher.context.authuser
	local privilege = uci:get("account",uname,"privilege")
	local password = uci:get("account",uname,"password")
	if privilege ~= "1" then
		return 0
	end
	sys.exec("/sbin/parsePort.sh")

	local addWANremoteHTTPSClient = luci.http.formvalue("addWANremoteHTTPSClient")
	local addLANremoteHTTPSClient = luci.http.formvalue("addLANremoteHTTPSClient")
	local addWANremoteHTTPClient = luci.http.formvalue("addWANremoteHTTPClient")
	local addLANremoteHTTPClient = luci.http.formvalue("addLANremoteHTTPClient")
	local HTTPSWANRemoteEditApply = luci.http.formvalue("HTTPSWANRemoteEditApply")
	local HTTPSLANRemoteEditApply = luci.http.formvalue("HTTPSLANRemoteEditApply")
	local HTTPWANRemoteEditApply = luci.http.formvalue("HTTPWANRemoteEditApply")
	local HTTPLANRemoteEditApply = luci.http.formvalue("HTTPLANRemoteEditApply")
	local httpswandelete = luci.http.formvalue("httpswandelete")
	local httpslandelete = luci.http.formvalue("httpslandelete")
	local httpwandelete = luci.http.formvalue("httpwandelete")
	local httplandelete = luci.http.formvalue("httplandelete")
	local apply = luci.http.formvalue("apply")
	local cancel = luci.http.formvalue("Cancel")
	
	if addWANremoteHTTPSClient then
		local client_addr = luci.http.formvalue("WANremoteHTTPSClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_https_WAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		uci:set("firewall", "remote_https_WAN", "client_check", "2")
		uci:set("firewall", "remote_https_WAN", "client_count", client_count)
		uci:set("firewall", "remote_https_WAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
		if password == "supervisor" then
			uci:apply("account") 
		end  
	end
	
	if addLANremoteHTTPSClient then
		local client_addr = luci.http.formvalue("LANremoteHTTPSClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_https_LAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		uci:set("firewall", "remote_https_LAN", "client_check", "2")
		uci:set("firewall", "remote_https_LAN", "client_count", client_count)
		uci:set("firewall", "remote_https_LAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if addWANremoteHTTPClient then
		local client_addr = luci.http.formvalue("WANremoteHTTPClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_WWW_WAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		uci:set("firewall", "remote_WWW_WAN", "client_check", "2")
		uci:set("firewall", "remote_WWW_WAN", "client_count", client_count)
		uci:set("firewall", "remote_WWW_WAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
		if password == "supervisor" then
			uci:apply("account") 
		end 
	end
	
	if addLANremoteHTTPClient then
		local client_addr = luci.http.formvalue("LANremoteHTTPClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_WWW_LAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		uci:set("firewall", "remote_WWW_LAN", "client_check", "2")
		uci:set("firewall", "remote_WWW_LAN", "client_count", client_count)
		uci:set("firewall", "remote_WWW_LAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if HTTPSWANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("HTTPSWANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("HTTPSWANInputIP")
	
		uci:set("firewall", "remote_https_WAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if HTTPSLANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("HTTPSLANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("HTTPSLANInputIP")
		
		uci:set("firewall", "remote_https_LAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if HTTPWANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("HTTPWANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("HTTPWANInputIP")
	
		uci:set("firewall", "remote_WWW_WAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if HTTPLANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("HTTPLANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("HTTPLANInputIP")
		
		uci:set("firewall", "remote_WWW_LAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if httpswandelete then
		local delete_no = tonumber(httpswandelete)
		local client_addr = "client_addr" .. httpswandelete
		local client_count = tonumber(uci:get( "firewall", "remote_https_WAN","client_count"))
		
		uci:set("firewall", "remote_https_WAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_https_WAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_https_WAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_https_WAN", client_addr_no)
				uci:set("firewall", "remote_https_WAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if httpslandelete then
		local delete_no = tonumber(httpslandelete)
		local client_addr = "client_addr" .. httpslandelete
		local client_count = tonumber(uci:get( "firewall", "remote_https_LAN","client_count"))
		
		uci:set("firewall", "remote_https_LAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_https_LAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_https_LAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_https_LAN", client_addr_no)
				uci:set("firewall", "remote_https_LAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if httpwandelete then
		local delete_no = tonumber(httpwandelete)
		local client_addr = "client_addr" .. httpwandelete
		local client_count = tonumber(uci:get( "firewall", "remote_WWW_WAN","client_count"))
		
		uci:set("firewall", "remote_WWW_WAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_WWW_WAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_WWW_WAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_WWW_WAN", client_addr_no)
				uci:set("firewall", "remote_WWW_WAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if httplandelete then
		local delete_no = tonumber(httplandelete)
		local client_addr = "client_addr" .. httplandelete
		local client_count = tonumber(uci:get( "firewall", "remote_WWW_LAN","client_count"))
		
		uci:set("firewall", "remote_WWW_LAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_WWW_LAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_WWW_LAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_WWW_LAN", client_addr_no)
				uci:set("firewall", "remote_WWW_LAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		uci:apply("uhttpd")
		uci:apply("firewall")
	end
	
	if apply then
		local old_WWWport = uci:get("firewall", "remote_www", "port")
		local old_httpsport = uci:get("firewall", "remote_https", "port")
		local https_port = luci.http.formvalue("remoteWWWPortHttps")
		local http_port = luci.http.formvalue("remoteWWWPort")
		local https_wan_client_count = tonumber(luci.http.formvalue("HTTPS_ClientIP_WAN_count"))
		local https_lan_client_count = tonumber(luci.http.formvalue("HTTPS_ClientIP_LAN_count"))
		local https_wan_client_check = luci.http.formvalue("HTTPS_WAN_selected_item")
		local https_lan_client_check = luci.http.formvalue("HTTPS_LAN_selected_item")
		local http_wan_client_count = tonumber(luci.http.formvalue("HTTP_ClientIP_WAN_count"))
		local http_lan_client_count = tonumber(luci.http.formvalue("HTTP_ClientIP_LAN_count"))
		local http_wan_client_check = luci.http.formvalue("HTTP_WAN_selected_item")
		local http_lan_client_check = luci.http.formvalue("HTTP_LAN_selected_item")
		
		uci:set("firewall", "remote_https", "port", https_port)
		uci:set("firewall", "remote_www", "port", http_port)
		
		uci:set("firewall", "remote_https_WAN", "client_check", https_wan_client_check)
		uci:set("firewall", "remote_https_LAN", "client_check", https_lan_client_check)
		uci:set("firewall", "remote_https_WAN", "client_count", https_wan_client_count)
		uci:set("firewall", "remote_https_LAN", "client_count", https_lan_client_count)
		
		uci:set("firewall", "remote_WWW_WAN", "client_check", http_wan_client_check)
		uci:set("firewall", "remote_WWW_LAN", "client_check", http_lan_client_check)
		uci:set("firewall", "remote_WWW_WAN", "client_count", http_wan_client_count)
		uci:set("firewall", "remote_WWW_LAN", "client_count", http_lan_client_count)

		sys.exec("echo 0 > /tmp/restart_lighttpd")
		if  old_WWWport ~= http_port  or old_httpsport ~= https_port then
			sys.exec("echo 1 > /tmp/restart_lighttpd")
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		uci:apply("uhttpd")
		uci:apply("firewall")
		if password == "supervisor" and ( https_wan_client_check ~= "1" or http_wan_client_check ~= "1" ) then
			uci:apply("account") 
		end
		
	end

	luci.template.render("expert_configuration/remote")
end

function action_remote_telnet()
	local uname = luci.dispatcher.context.authuser
	local privilege = uci:get("account",uname,"privilege")
	local password = uci:get("account",uname,"password")
	if privilege ~= "1" then
		return 0
	end
	sys.exec("/sbin/parsePort.sh")
	
	local addWANremoteTelnetClient = luci.http.formvalue("addWANremoteTelnetClient")
	local addLANremoteTelnetClient = luci.http.formvalue("addLANremoteTelnetClient")
	local WANRemoteEditApply = luci.http.formvalue("WANRemoteEditApply")
	local LANRemoteEditApply = luci.http.formvalue("LANRemoteEditApply")
	local wandelete = luci.http.formvalue("wandelete")
	local landelete = luci.http.formvalue("landelete")
	local apply = luci.http.formvalue("apply")
	local cancel = luci.http.formvalue("Cancel")
	
	if addWANremoteTelnetClient then
		local client_addr = luci.http.formvalue("WANremoteTelnetClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_telnet_WAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		sys.exec("/etc/init.d/telnet stop 2>/dev/null")

		uci:set("firewall", "remote_telnet_WAN", "client_check", "2")
		uci:set("firewall", "remote_telnet_WAN", "client_count", client_count)
		uci:set("firewall", "remote_telnet_WAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
		if password == "supervisor" then
			uci:apply("account") 
		end
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if addLANremoteTelnetClient then
		local client_addr = luci.http.formvalue("LANremoteTelnetClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_telnet_LAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		sys.exec("/etc/init.d/telnet stop 2>/dev/null")

		uci:set("firewall", "remote_telnet_LAN", "client_check", "2")
		uci:set("firewall", "remote_telnet_LAN", "client_count", client_count)
		uci:set("firewall", "remote_telnet_LAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if WANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("WANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("WANInputIP")
		
		sys.exec("/etc/init.d/telnet stop 2>/dev/null")
		
		uci:set("firewall", "remote_telnet_WAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if LANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("LANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("LANInputIP")
		
		sys.exec("/etc/init.d/telnet stop 2>/dev/null")
		
		uci:set("firewall", "remote_telnet_LAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if wandelete then
		local delete_no = tonumber(wandelete)
		local client_addr = "client_addr" .. wandelete
		local client_count = tonumber(uci:get( "firewall", "remote_telnet_WAN","client_count"))
		
		sys.exec("/etc/init.d/telnet stop 2>/dev/null")
		
		uci:set("firewall", "remote_telnet_WAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_telnet_WAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_telnet_WAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_telnet_WAN", client_addr_no)
				uci:set("firewall", "remote_telnet_WAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if landelete then
		local delete_no = tonumber(landelete)
		local client_addr = "client_addr" .. landelete
		local client_count = tonumber(uci:get( "firewall", "remote_telnet_LAN","client_count"))
		
		sys.exec("/etc/init.d/telnet stop 2>/dev/null")
		
		uci:set("firewall", "remote_telnet_LAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_telnet_LAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_telnet_LAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_telnet_LAN", client_addr_no)
				uci:set("firewall", "remote_telnet_LAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if apply then
		local port = luci.http.formvalue("RemoteTelnetPort")
		local wan_client_count = tonumber(luci.http.formvalue("ClientIP_WAN_count"))
		local wan_client_check = luci.http.formvalue("WAN_selected_item")
		local lan_client_count = tonumber(luci.http.formvalue("ClientIP_LAN_count"))
		local lan_client_check = luci.http.formvalue("LAN_selected_item")
		
		uci:delete("firewall", "remote_telnet_WAN")
		uci:delete("firewall", "remote_telnet_LAN")
		uci:set("firewall", "remote_telnet", "port", port)
		
		sys.exec("/etc/init.d/telnet stop 2>/dev/null")
		
		uci:set("firewall", "remote_telnet_WAN", "firewall")
		uci:set("firewall", "remote_telnet_WAN", "client_check", wan_client_check)
		uci:set("firewall", "remote_telnet_WAN", "client_count", wan_client_count)
		
		uci:set("firewall", "remote_telnet_LAN", "firewall")
		uci:set("firewall", "remote_telnet_LAN", "client_check", lan_client_check)
		uci:set("firewall", "remote_telnet_LAN", "client_count", lan_client_count)
		
		if wan_client_count > 0 then
			for i=1, wan_client_count do
				local client_addr_tmp = "ClientIP_WAN" .. i
				local client_addr = luci.http.formvalue(client_addr_tmp)
				local Addr = "client_addr" .. i
					
				uci:set("firewall", "remote_telnet_WAN", Addr, client_addr)	
			end
		end
			
		if lan_client_count > 0 then
			for i=1, lan_client_count do
				local client_addr_tmp = "ClientIP_LAN" .. i
				local client_addr = luci.http.formvalue(client_addr_tmp)
				local Addr = "client_addr" .. i
					
				uci:set("firewall", "remote_telnet_LAN", Addr, client_addr)	
			end
		end	
			
		uci:save("firewall")
		uci:commit("firewall")
		if password == "supervisor" and wan_client_check ~= "1" then
			uci:apply("account") 
		end
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
		uci:apply("firewall")
		
	end
	
	luci.template.render("expert_configuration/remote_telnet")
end

function action_remote_ssh()
	local uname = luci.dispatcher.context.authuser
	local privilege = uci:get("account",uname,"privilege")
	local password = uci:get("account",uname,"password")
	if privilege ~= "1" then
		return 0
	end
	sys.exec("/sbin/parsePort.sh")
	
	local addWANremoteSSHClient = luci.http.formvalue("addWANremoteSSHClient")
	local addLANremoteSSHClient = luci.http.formvalue("addLANremoteSSHClient")
	local SSHWANRemoteEditApply = luci.http.formvalue("SSHWANRemoteEditApply")
	local SSHLANRemoteEditApply = luci.http.formvalue("SSHLANRemoteEditApply")
	local sshwandelete = luci.http.formvalue("sshwandelete")
	local sshlandelete = luci.http.formvalue("sshlandelete")
	local apply = luci.http.formvalue("apply")
	local cancel = luci.http.formvalue("Cancel")
	
	if addWANremoteSSHClient then
		local client_addr = luci.http.formvalue("WANremoteSSHClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_ssh_WAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		sys.exec("/etc/init.d/ssh stop 2>/dev/null")

		uci:set("firewall", "remote_ssh_WAN", "client_check", "2")
		uci:set("firewall", "remote_ssh_WAN", "client_count", client_count)
		uci:set("firewall", "remote_ssh_WAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
		if password == "supervisor" then
			uci:apply("account") 
		end
		
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if addLANremoteSSHClient then
		local client_addr = luci.http.formvalue("LANremoteSSHClientAddr")
		local client_count = tonumber(uci:get( "firewall", "remote_ssh_LAN","client_count"))+1
		local Addr = "client_addr" .. client_count

		sys.exec("/etc/init.d/ssh stop 2>/dev/null")

		uci:set("firewall", "remote_ssh_LAN", "client_check", "2")
		uci:set("firewall", "remote_ssh_LAN", "client_count", client_count)
		uci:set("firewall", "remote_ssh_LAN", Addr, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if SSHWANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("WANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("WANInputIP")
		
		sys.exec("/etc/init.d/ssh stop 2>/dev/null")
		
		uci:set("firewall", "remote_ssh_WAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if SSHLANRemoteEditApply then
		local client_addr_no = luci.http.formvalue("LANEditNO")
		local client_addr_tmp = "client_addr" .. client_addr_no
		local client_addr = luci.http.formvalue("LANInputIP")
		
		sys.exec("/etc/init.d/ssh stop 2>/dev/null")
		
		uci:set("firewall", "remote_ssh_LAN", client_addr_tmp, client_addr)
		
		uci:save("firewall")
		uci:commit("firewall")
	
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if sshwandelete then
		local delete_no = tonumber(sshwandelete)
		local client_addr = "client_addr" .. sshwandelete
		local client_count = tonumber(uci:get( "firewall", "remote_ssh_WAN","client_count"))
		
		sys.exec("/etc/init.d/ssh stop 2>/dev/null")
		
		uci:set("firewall", "remote_ssh_WAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_ssh_WAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_ssh_WAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_ssh_WAN", client_addr_no)
				uci:set("firewall", "remote_ssh_WAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if sshlandelete then
		local delete_no = tonumber(sshlandelete)
		local client_addr = "client_addr" .. sshlandelete
		local client_count = tonumber(uci:get( "firewall", "remote_ssh_LAN","client_count"))
		
		sys.exec("/etc/init.d/ssh stop 2>/dev/null")
		
		uci:set("firewall", "remote_ssh_LAN", "client_count", client_count-1 )
		uci:delete("firewall", "remote_ssh_LAN", client_addr)
		
		if client_count > delete_no then
			for i=delete_no+1, client_count do
				local client_addr_no = "client_addr" .. i
				local client_addr_tmp = uci:get("firewall", "remote_ssh_LAN", client_addr_no)
				local client_addr_set = "client_addr" .. (i-1)
				
				uci:delete("firewall", "remote_ssh_LAN", client_addr_no)
				uci:set("firewall", "remote_ssh_LAN", client_addr_set, client_addr_tmp )
			end
		end
		
		uci:save("firewall")
		uci:commit("firewall")
		
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
	end
	
	if apply then
		local port = luci.http.formvalue("RemoteSSHPort")
		local ssh_wan_client_count = tonumber(luci.http.formvalue("SSH_ClientIP_WAN_count"))
		local ssh_wan_client_check = luci.http.formvalue("SSH_WAN_selected_item")
		local ssh_lan_client_count = tonumber(luci.http.formvalue("SSH_ClientIP_LAN_count"))
		local ssh_lan_client_check = luci.http.formvalue("SSH_LAN_selected_item")
		
		uci:delete("firewall", "remote_ssh_WAN")
		uci:delete("firewall", "remote_shh_LAN")
		uci:set("firewall", "remote_ssh", "port", port)
		sys.exec("uci set dropbear.@dropbear[0].Port=" ..port)
		
		sys.exec("/etc/init.d/ssh stop 2>/dev/null")
		
		uci:set("firewall", "remote_ssh_WAN", "firewall")
		uci:set("firewall", "remote_ssh_WAN", "client_check", ssh_wan_client_check)
		uci:set("firewall", "remote_ssh_WAN", "client_count", ssh_wan_client_count)
		
		uci:set("firewall", "remote_ssh_LAN", "firewall")
		uci:set("firewall", "remote_ssh_LAN", "client_check", ssh_lan_client_check)
		uci:set("firewall", "remote_ssh_LAN", "client_count", ssh_lan_client_count)
		
		if ssh_wan_client_count > 0 then
			for i=1, ssh_wan_client_count do
				local client_addr_tmp = "ClientIP_WAN" .. i
				local client_addr = luci.http.formvalue(client_addr_tmp)
				local Addr = "client_addr" .. i
					
				uci:set("firewall", "remote_ssh_WAN", Addr, client_addr)	
			end
		end
			
		if ssh_lan_client_count > 0 then
			for i=1, ssh_lan_client_count do
				local client_addr_tmp = "ClientIP_LAN" .. i
				local client_addr = luci.http.formvalue(client_addr_tmp)
				local Addr = "client_addr" .. i
					
				uci:set("firewall", "remote_ssh_LAN", Addr, client_addr)	
			end
		end	
			
		uci:save("firewall")
		uci:commit("firewall")
		uci:commit("dropbear")
		if password == "supervisor" and ssh_wan_client_check ~= "1" then
			uci:apply("account") 
		end
		sys.exec("/etc/init.d/ssh start 2>/dev/null")
		uci:apply("firewall")
		
	end
	luci.template.render("expert_configuration/remote_SSH")
end	

function action_remote_icmp()
	local apply = luci.http.formvalue("apply")
	
	if apply then
		local interface = luci.http.formvalue("RemoteICMPInterface")

		uci:set("firewall", "remote_telnet", "interface", tonumber(interface))
		uci:save("firewall")
		uci:commit("firewall")
		uci:apply("firewall")
	end
	luci.template.render("expert_configuration/remote_icmp")
end
--Eten Remote END

--Eten Upnp
function action_upnp()
	local apply = luci.http.formvalue("apply")

	if apply then
		local enabled = luci.http.formvalue("UPnPState")

		if "enable" == enabled then
			uci:set("upnpd", "config", "enabled", "1")
		else
			uci:set("upnpd", "config", "enabled", "0")
		end

		uci:save("upnpd")
		uci:commit("upnpd")
		uci:apply("upnpd")
	end

	luci.template.render("expert_configuration/upnp")
end
--Eten Upnp END

--sendoh
--2.4G Wireless
function wlan_general()
	require("luci.model.uci")
	local apply = luci.http.formvalue("sysSubmit")
	local wps_enable = uci:get("wps","wps","enabled")
	local tmppsk	

	if apply then
		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
	--SSID
		local SSID = luci.http.formvalue("SSID_value")
		local SSID_old = uci:get("wireless", "ath0","ssid")
		if not (SSID == SSID_old)then
			SSID = checkInjection(SSID)
			if SSID ~= false then
				uci:set("wireless", "ath0","ssid",SSID)   
			end
		end--SSID
	--radioON
		local Wireless_enable = luci.http.formvalue("ssid_state")
		local Wireless_enable_old = uci:get("wireless", "wifi0","disabled")  
		if not(Wireless_enable == Wireless_enable_old)then
			uci:set("wireless", "wifi0","disabled",Wireless_enable)
			uci:set("wireless", "ath0","disabled",Wireless_enable)
		end--radioON
	--HideSSID
		local wireless_hidden = luci.http.formvalue("Hide_SSID")
		local wireless_hidden_old = uci:get("wireless", "ath0","hidden")   
		if not (wireless_hidden)then
			wireless_hidden = "0"
		else
			wireless_hidden = "1"
		end

		if not(wireless_hidden == wireless_hidden_old)then			
			uci:set("wireless", "ath0","hidden",wireless_hidden) 
		end
	--ChannelID
		local Channel_ID = luci.http.formvalue("Channel_ID_index")
		local Channel_ID_old = uci:get("wireless", "wifi0","channel",Channel_ID)   
		if not(Channel_ID)then
			Channel_ID = Channel_ID_old
		end
		if not(Channel_ID == Channel_ID_old) then
			uci:set("wireless", "wifi0","channel",Channel_ID)   
		end
	--AutoChSelect
		local Auto_Channel = luci.http.formvalue("Auto_Channel")
		local Auto_Channel_old = uci:get("wireless", "wifi0","AutoChannelSelect")  
		if not(Auto_Channel)then
			Auto_Channel = 0
		else
			Auto_Channel = 1
		end
		if not(Auto_Channel == Auto_Channel_old) then
			uci:set("wireless", "wifi0","AutoChannelSelect",Auto_Channel)   
			if (Auto_Channel==1) then                                			
				uci:set("wireless", "wifi0", "channel", "auto")    			
			end
			if (Wireless_enable=="1") then
				uci:set("wireless", "wifi0", "channel", "1")  
			end
		end	
	--ChannelWidth
		local Channel_Width = luci.http.formvalue("ChWidth_select")
		uci:set("wireless", "wifi0","channel_width", Channel_Width)
	--WirelessMode
		local Wireless_Mode = luci.http.formvalue("Mode_select")
		uci:set("wireless", "wifi0","hwmode", Wireless_Mode)
		--if set 802.11n default enable wmm
		if ( Wireless_Mode == "11gn" or  Wireless_Mode == "11n" or Wireless_Mode == "11bgn" ) then
			uci:set("wireless", "ath0", "wmm",1)
		end
	--SecurityMode
		local security_mode = luci.http.formvalue("security_value")
		if (security_mode) then
			--No security
			if( security_mode == "NONE") then
				uci:set("wireless", "wifi0","auth","OPEN")  
				uci:set("wireless", "ath0","auth","NONE") 
				uci:set("wireless", "ath0","encryption","NONE")
				uci:set("wireless", "ath0","pmf", "0")
			end

			--WEP_wlan
			if( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
--				uci:set("wireless", "wifi0","encryption","WEP")
				if (EncrypAuto_shared)	then
					if(EncrypAuto_shared == "WEPAUTO")then
						uci:set("wireless", "ath0","encryption","wep-mixed")
						uci:set("wireless", "ath0","auth",EncrypAuto_shared)
					elseif(EncrypAuto_shared == "SHARED") then
						uci:set("wireless", "ath0","encryption","wep-shared")
						uci:set("wireless", "ath0","auth",EncrypAuto_shared)
					end
				end
				local wep_passphrase = luci.http.formvalue("wep_passphrase")	
				if not (wep_passphrase) then
					uci:set("wireless", "ath0","PassPhrase","")
				else 
					uci:set("wireless", "ath0","PassPhrase",wep_passphrase)
				end
				--64-128bit
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				if (WEP64_128)then
					if(WEP64_128 == "0")then--[[64-bit]]--
						uci:set("wireless", "ath0","wepencryp128", WEP64_128)
					elseif(WEP64_128 == "1") then--[[128-bit]]--
						uci:set("wireless", "ath0","wepencryp128", WEP64_128)
					end
				end
				--ASCIIHEX
				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
				if (WEPKey_Code == "1")then--[[HEx]]--
					uci:set("wireless", "ath0","keytype", "1")
				elseif (WEPKey_Code == "0") then--[[ASCII]]--
					uci:set("wireless", "ath0","keytype", "0")
				end
				--keyindex
				local DefWEPKey = luci.http.formvalue("DefWEPKey")
				if (DefWEPKey)then
					uci:set("wireless", "ath0","key", DefWEPKey)
				end
                                	
				--WEP key value
				local wepkey
				local key_name
				for i=1,4 do
					wepkey = luci.http.formvalue("wep_key_"..i)
					key_name="key"..i
					if ( wepkey ) then
						uci:set("wireless", "ath0", key_name, wepkey)
					else
						uci:set("wireless", "ath0", key_name, "")
					end
				end
				uci:set("wireless", "ath0","pmf", "0")
			end

			--WPA_wlan
			if (security_mode == "WPA")then
				uci:set("wireless", "ath0","auth","WPA")
				uci:set("wireless", "ath0","encryption","WPA")

				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				if (RekeyInterval == "") then
					uci:set("wireless", "ath0","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
				end
				--[[
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				if (PMKCachePeriod == "") then
					uci:set("wireless", "ra0","PMKCachePeriod", "10")
				else
					uci:set("wireless", "ra0","PMKCachePeriod", PMKCachePeriod)
				end					
				]]--
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				if (RadiusServerIP == "") then
					uci:set("wireless", "ath0","RADIUS_Server", "192.168.2.3")
				else
					uci:set("wireless", "ath0","RADIUS_Server", RadiusServerIP)
				end

				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				if (RadiusServerPort == "") then
					uci:set("wireless", "ath0","RADIUS_Port", "1812")
				else
					uci:set("wireless", "ath0","RADIUS_Port", RadiusServerPort)
				end

				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				if (RadiusServerSecret == "") then
					uci:set("wireless", "ath0","RADIUS_Key", "ralink")
				else
					uci:set("wireless", "ath0","RADIUS_Key", RadiusServerSecret)
				end

				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
				if (RadiusServerSessionTimeout == "") then
					uci:set("wireless", "ath0","session_timeout_interval", "0")
				else
					uci:set("wireless", "ath0","session_timeout_interval", RadiusServerSessionTimeout)
				end
				--[[
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				if (PreAuthentication == "") then
					uci:set("wireless", "ra0","PreAuth", "0")
				else
					uci:set("wireless", "ra0","PreAuth", PreAuthentication)
				end
				]]--
				uci:set("wireless", "ath0","pmf", "0")
			end

			--WPAPSK_wlan
			if(security_mode == "WPAPSK")then
				uci:set("wireless", "ath0","auth","WPAPSK")
				uci:set("wireless", "ath0","encryption","WPAPSK")
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
				if (WPAPSKkey == "") or (WPAPSKAuto) then
					uci:set("wireless", "ath0","WPAPSKkey", "")
				else						
					uci:set("wireless", "ath0","WPAPSKkey", WPAPSKkey)
				end
				if not(RekeyInterval) then
					uci:set("wireless", "ath0","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
				end
				uci:set("wireless", "ath0","pmf", "0")
			end

			--WPA2
			if (security_mode == "WPA2")then
				uci:set("wireless", "ath0","auth","WPA2")
				uci:set("wireless", "ath0","encryption","WPA2")
				local WPACompatible = luci.http.formvalue("wpa_compatible")
				if not (WPACompatible) then
					uci:set("wireless", "ath0","WPACompatible", "0")
				else
					uci:set("wireless", "ath0","WPACompatible", WPACompatible)
				end					
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				if (RekeyInterval == "") then
					uci:set("wireless", "ath0","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
				end

				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				if (PMKCachePeriod == "") then
					uci:set("wireless", "ath0","PMKCachePeriod", "10")
				else
					uci:set("wireless", "ath0","PMKCachePeriod", PMKCachePeriod)
				end					
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				if (PreAuthentication == "") then
					uci:set("wireless", "ath0","PreAuth", "0")
				else
					uci:set("wireless", "ath0","PreAuth", PreAuthentication)
				end						
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				if (RadiusServerIP == "") then
					uci:set("wireless", "ath0","RADIUS_Server", "192.168.2.3")
				else
					uci:set("wireless", "ath0","RADIUS_Server", RadiusServerIP)
				end

				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				if (RadiusServerPort == "") then
					uci:set("wireless", "ath0","RADIUS_Port", "1812")
				else
					uci:set("wireless", "ath0","RADIUS_Port", RadiusServerPort)
				end	

				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				if (RadiusServerSecret == "") then
					uci:set("wireless", "ath0","RADIUS_Key", "ralink")
				else
					uci:set("wireless", "ath0","RADIUS_Key", RadiusServerSecret)
				end

				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
				if (RadiusServerSessionTimeout == "") then
					uci:set("wireless", "ath0","session_timeout_interval", "0")
				else
					uci:set("wireless", "ath0","session_timeout_interval", RadiusServerSessionTimeout)
				end
				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set("wireless", "ath0","pmf", "0")
				else
					uci:set("wireless", "ath0","pmf", PMF)
				end	
			end

			--WPA2PSK_wlan
			if(security_mode=="WPA2PSK")then
				uci:set("wireless", "ath0","auth","WPA2PSK")
				uci:set("wireless", "ath0","encryption","WPA2PSK")
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
				if (WPAPSKkey == "") or (WPAPSKAuto) then
					uci:set("wireless", "ath0","WPAPSKkey", "")
				else						
					uci:set("wireless", "ath0","WPAPSKkey", WPAPSKkey)
				end
				if (RekeyInterval == "") then
					uci:set("wireless", "ath0","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
				end	
				if not (WPAPSKCompatible) then
					uci:set("wireless", "ath0","WPAPSKCompatible", "0")
				else
					uci:set("wireless", "ath0","WPAPSKCompatible", WPAPSKCompatible)
				end
				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set("wireless", "ath0","pmf", "0")
				else
					uci:set("wireless", "ath0","pmf", PMF)
				end
			end
		end

		uci:set("wps","wps","conf","1")
		uci:commit("wps")

		uci:commit("wireless")
		sys.exec("echo wifi0 >/tmp/WirelessDev")
		uci:apply("wireless")

		sys.exec("/etc/init.d/intfGrp restart")
	end --end apply

	if (wps_enable == "1") then
		wps=1
	else
        	wps=0
	end

	sys.exec("set_tmp_psk")
	tmppsk=sys.exec("cat /tmp/tmppsk")
	sys.exec("rm /tmp/tmppsk")

	local file = io.open("/var/countrycode", "r")	
	local temp = file:read("*all")
	file:close()

	local code = temp:match("([0-9a-fA-F]+)")
	local region = country_code_table[code:gsub("[a-fA-F]", string.upper)]
	sys.exec("uci set wireless.wifi0.channel=$(iwlist ath0 channel | grep 'Current Frequency'| awk -F 'Channel ' '{print $2}'| awk -F ')' '{print $1}'|sed 's/\"//g')")
	luci.template.render("expert_configuration/wlan", {wps_enabled = wps, psk = tmppsk, channels = channelRange[region[1]]})	
end

function wlan_multissid()
	security = {"","",""}
	local iface
	local Wireless_enable
	local cfgfile="wireless"
	local apply = luci.http.formvalue("sysSubmit")


	for i=1,3 do
		iface="ath"..i
		security[i]=uci.get(cfgfile,iface,"auth")

        	if security[i] == "WPAPSK" then
                	security[i]="WPA-PSK"
        	elseif security[i] == "WPA2PSK" then
                	security[i]="WPA2-PSK"
        	elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
                	security[i]="WEP"
        	elseif security[i] == "OPEN" then
                	security[i]="No Security"
        	end
	end

	luci.template.render("expert_configuration/wlan_multissid", { security1 = security[1], security2 = security[2], security3 = security[3]})
end

function multiple_ssid() 
	require("luci.model.uci")
	security = {"","",""}
	local apply = luci.http.formvalue("sysSubmit")
	local interface = luci.http.formvalue("interface")
	local iface
	local cfgfile="wireless"
	local wireless_mode = uci:get("wireless", "wifi0", "hwmode")
	local WMM_Choose

	if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
      	uci:set("wireless", "ath1", "wmm",1)
		uci:set("wireless", "ath2", "wmm",1)
		uci:set("wireless", "ath3", "wmm",1)
		uci:commit("wireless")
		WMM_Choose="disabled"
	end

	if interface == "1" then
		iface="ath1"
	elseif interface == "2" then
		iface="ath2"
	elseif interface == "3" then
		iface="ath3"
	else
		iface=interface
	end

	if apply then
		--SSID
		local SSID = luci.http.formvalue("SSID_value")

		SSID = checkInjection(SSID)
		if SSID ~= false then
			uci:set(cfgfile, iface, "ssid", SSID)
		end

		--Active
		local Wireless_enable = luci.http.formvalue("ssid_state")
		if Wireless_enable then
			uci:set(cfgfile, iface, "disabled", 0)
		else
			uci:set(cfgfile, iface, "disabled", 1)
		end
		--HideSSID
		local wireless_hidden = luci.http.formvalue("Hide_SSID")
		if not (wireless_hidden)then
			uci:set(cfgfile, iface, "hidden", 0)
		else
			uci:set(cfgfile, iface, "hidden", 1)
		end
		--Intra BSS
		local intra_bss = luci.http.formvalue("Intra_BSS")
                if not (intra_bss) then
			uci:set(cfgfile, iface, "IntraBSS", 0)
                else
			uci:set(cfgfile, iface, "IntraBSS", 1)
		end
		--WMM QoS
		local wmm_qos = luci.http.formvalue("WMM_QoS")
		
		if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
			uci:set(cfgfile, iface, "wmm", 1)
		else
			if not (wmm_qos) then
				uci:set(cfgfile, iface, "wmm", 0)
        		else
				uci:set(cfgfile, iface, "wmm", 1)
			end
		end

		--Guest WLAN
                local guest_ssid = luci.http.formvalue("guest_ssid")
                if not (guest_ssid) then
                        uci:set(cfgfile, iface, "enable_guest_wlan", 0)
                else
                        uci:set(cfgfile, iface, "enable_guest_wlan", 1)
                        local ip_addr = luci.http.formvalue("guest_ip")
                        local ip_mask = "255.255.255." .. luci.http.formvalue("guest_ip_mask")
			local band_manage = luci.http.formvalue("guest_wlan_bandwidth")
			local max_band = luci.http.formvalue("max_bandwidth")
                        if ip_addr then
                                uci:set(cfgfile, iface, "guest_ip", ip_addr)
                        end
                        if ip_mask then
                                uci:set(cfgfile, iface, "guest_ip_mask", ip_mask)
                        end
			if band_manage then
				uci:set(cfgfile, iface, "guest_bandwidth_enable", 1)
			else
				uci:set(cfgfile, iface, "guest_bandwidth_enable", 0)
			end
			uci:set(cfgfile, iface, "guest_max_bandwidth", max_band)
                end
		--SecurityMode
		local security_mode = luci.http.formvalue("security_value")
		if (security_mode) then
			--No security
			if( security_mode == "NONE") then
				uci:set(cfgfile, iface, "auth", "OPEN")
				uci:set(cfgfile, iface, "encryption", "NONE")
				uci:set(cfgfile, iface,"pmf", "0")
			end

			--WEP_wlan
			if( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
--				uci:set(cfgfile, iface,"encryption","WEP")

--				if(EncrypAuto_shared == "WEPAUTO")then
--					uci:set(cfgfile, iface, "auth", EncrypAuto_shared)
--              elseif(EncrypAuto_shared == "SHARED") then
--					uci:set(cfgfile, iface, "auth", EncrypAuto_shared)
--				end
				if (EncrypAuto_shared)	then
					if(EncrypAuto_shared == "WEPAUTO")then
						uci:set(cfgfile, iface,"encryption","wep-mixed")
						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
					elseif(EncrypAuto_shared == "SHARED") then
						uci:set(cfgfile, iface,"encryption","wep-shared")
						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
					end
				end

				local wep_passphrase = luci.http.formvalue("wep_passphrase")
				if not (wep_passphrase) then
					uci:set(cfgfile, iface, "PassPhrase","")
				else
					uci:set(cfgfile, iface, "PassPhrase",wep_passphrase)
				end

				--64-128bit
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				if (WEP64_128)then
					if(WEP64_128 == "0")then--[[64-bit]]--
						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
					else
						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
					end
				end

                                --ASCIIHEX
                                local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
                                if (WEPKey_Code == "1")then--[[HEx]]--
                                	uci:set(cfgfile, iface, "keytype", "1")
                                elseif (WEPKey_Code == "0") then--[[ASCII]]--
                                        uci:set(cfgfile, iface, "keytype", "0")
                                end
                                --keyindex
                                local DefWEPKey = luci.http.formvalue("DefWEPKey")
                                if (DefWEPKey)then
                                	uci:set(cfgfile, iface, "key", DefWEPKey)
                                end
			
				--WEP key value
				local wepkey
				local key_name
				for i=1,4 do
					wepkey = luci.http.formvalue("wep_key_"..i)
					key_name="key"..i
					if ( wepkey ) then
						uci:set(cfgfile, iface, key_name, wepkey)
					else
						uci:set(cfgfile, iface, key_name, "")
					end
				end
				uci:set(cfgfile, iface,"pmf", "0")
			end --End WEP
			
			--WPA_wlan
                        if (security_mode == "WPA")then
                        	uci:set(cfgfile, iface, "auth","WPA")
                                uci:set(cfgfile, iface, "encryption","WPA")

                                local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
                                if (RekeyInterval == "") then
                                        uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end

                                local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
                                if (RadiusServerIP == "") then
                                	uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
                                end

                                local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
                                if (RadiusServerPort == "") then
                                	uci:set(cfgfile, iface, "RADIUS_Port", "1812")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
                                end

                                local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
                                if (RadiusServerSecret == "") then
                                	uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
                                end

                                local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
                                if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
                                        uci:set(cfgfile, iface, "session_timeout_interval", "0")
                                else
                                        uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
                                end
				uci:set(cfgfile, iface,"pmf", "0")
                	end --End WPA

                        --WPAPSK_wlan
                        if(security_mode == "WPAPSK")then
                        	uci:set(cfgfile, iface, "auth", "WPAPSK")
                                uci:set(cfgfile, iface, "encryption", "WPAPSK")
                                local WPAPSKkey = luci.http.formvalue("PSKey")
                                local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
								local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
								if (WPAPSKkey == "") or (WPAPSKAuto) then
                                	uci:set(cfgfile, iface, "WPAPSKkey", "")
                                else
                                	uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
                                end
                                if not(RekeyInterval) then
                                	uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end
				uci:set(cfgfile, iface,"pmf", "0")
                	end --End WPAPSK

                        --WPA2
                        if (security_mode == "WPA2")then
                                uci:set(cfgfile, iface, "auth", "WPA2")
                                uci:set(cfgfile, iface, "encryption", "WPA2")
                                local WPACompatible = luci.http.formvalue("wpa_compatible")
                                if not (WPACompatible) then
                                	uci:set(cfgfile, iface, "WPACompatible", "0")
                                else
                                        uci:set(cfgfile, iface, "WPACompatible", WPACompatible)
                                end
                                
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
                                if (RekeyInterval == "") then
                                        uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end

                                local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
                                if (PMKCachePeriod == "") then
                                        uci:set(cfgfile, iface, "PMKCachePeriod", "10")
                                else
                                        uci:set(cfgfile, iface, "PMKCachePeriod", PMKCachePeriod)
                                end
                                local PreAuthentication = luci.http.formvalue("PreAuthentication")
                                if (PreAuthentication == "") then
                                        uci:set(cfgfile, iface, "PreAuth", "0")
                                else
                                        uci:set(cfgfile, iface, "PreAuth", PreAuthentication)
                                end
                                local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
                                if (RadiusServerIP == "") then
                                        uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
                                end

                                local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
                                if (RadiusServerPort == "") then
                                        uci:set(cfgfile, iface, "RADIUS_Port", "1812")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
                                end
                                local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
                                if (RadiusServerSecret == "") then
                                        uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
                                end

                                local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
                                if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
                                        uci:set(cfgfile, iface, "session_timeout_interval", "0")
                                else
                                        uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
                                end				

				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set(cfgfile, iface,"pmf", "0")
				else
					uci:set(cfgfile, iface,"pmf", PMF)
				end
                	end --End WPA2

                        --WPA2PSK_wlan
                        if(security_mode=="WPA2PSK")then
                        	uci:set(cfgfile, iface, "auth", "WPA2PSK")
                        	uci:set(cfgfile, iface, "encryption", "WPA2PSK")
                                local WPAPSKkey = luci.http.formvalue("PSKey")
                                local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
                                local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
								local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
								if (WPAPSKkey == "") or (WPAPSKAuto) then
                                	uci:set(cfgfile, iface, "WPAPSKkey", "")
                                else
                                        uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
                                end
                                if (RekeyInterval == "") then
                                        uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end
                                if not (WPAPSKCompatible) then
                                        uci:set(cfgfile, iface, "WPAPSKCompatible", "0")
                                else
                                        uci:set(cfgfile, iface, "WPAPSKCompatible", WPAPSKCompatible)
                                end

				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set(cfgfile, iface,"pmf", "0")
				else
					uci:set(cfgfile, iface,"pmf", PMF)
				end
                	end --End WPA2PSK
		end

		sys.exec("echo "..iface.." >> /tmp/moreAP")
		sys.exec("echo wifi0 >/tmp/WirelessDev")
		uci:commit(cfgfile)
		uci:apply(cfgfile)

		local qos_enable=uci:get("qos", "general", "enable")
		if ( "1" == qos_enable ) then
			uci:apply("qos")
		end		

	        for i=1,3 do
	                iface="ath"..i
	                security[i]=uci.get(cfgfile,iface,"auth")

	                if security[i] == "WPAPSK" then
	                        security[i]="WPA-PSK"
	                elseif security[i] == "WPA2PSK" then
	                        security[i]="WPA2-PSK"
	                elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
	                        security[i]="WEP"
	                elseif security[i] == "OPEN" then
	                        security[i]="No Security"
	                end
		end

		luci.template.render("expert_configuration/wlan_multissid", { security1 = security[1], security2 = security[2], security3 = security[3]})		
		sys.exec("/etc/init.d/intfGrp restart")
		return
	end --End Apply

        sys.exec("set_tmp_psk")
        tmppsk=sys.exec("cat /tmp/tmppsk")
        sys.exec("rm /tmp/tmppsk")

	luci.template.render("expert_configuration/multissid_edit",{ifacename=iface, psk = tmppsk, wmm_choice=WMM_Choose})
end

function wlanmacfilter()
	local apply = luci.http.formvalue("sysSubmit")
	local select_ap = luci.http.formvalue("ap_select")
	local changed = 0
	local filter

	if not select_ap then
		select_ap="0"
	end

	filter="general"..select_ap	
	
	
	
	if apply then
		--filter on/of
		local MACfilter_ON = luci.http.formvalue("MACfilter_ON")
		MACfilter_ON_old = uci:get("wireless_macfilter", filter,"mac_state")
		if not (MACfilter_ON == MACfilter_ON_old) then
			changed = 1
			uci:set("wireless_macfilter", filter,"mac_state", MACfilter_ON)
		end
		--filter action
		local filter_act = luci.http.formvalue("filter_act")
		filter_act_old = uci:get("wireless_macfilter", filter,"filter_action")
		if not (filter_act == filter_act_old) then
			changed = 1
			uci:set("wireless_macfilter", filter,"filter_action", filter_act)
		end

		--mac address
		local MacAddr
		local Mac_field
		local MacAddr_old
		for i=1,32 do
			Mac_field="MacAddr"..i
			MacAddr_old = uci:get("wireless_macfilter", filter, Mac_field)
			MacAddr = luci.http.formvalue(Mac_field)
			if not ( MacAddr == MacAddr_old ) then
				changed = 1
				uci:set("wireless_macfilter", filter, Mac_field, MacAddr)
			end
		end

		--new value need to be saved
		if (changed == 1) then
			local iface_reset="ath"..select_ap
			local iface
			local iface_filter
			for i=0,3 do
				iface="ath"..i
				iface_filter="general"..i
				if (iface == iface_reset) then
					uci:set("wireless_macfilter", iface_filter, "reset", "1")
				else
					uci:set("wireless_macfilter", iface_filter, "reset", "0")	
				end
			end
			uci:commit("wireless_macfilter")
			uci:apply("wireless_macfilter")
		end
		if (MACfilter_ON == "1") then
			uci:set("wps","wps","enabled","0")
			uci:commit("wps")
			sys.exec("echo wifi0 >/tmp/WirelessDev")
			uci:apply("wireless")
		end
	end
	luci.template.render("expert_configuration/wlanmacfilter",{filter_iface=filter, ap=select_ap})	
end

function wlan_advanced() 
	local apply = luci.http.formvalue("sysSubmit")
	local changed = 0
	local wireless_mode = uci:get("wireless", "wifi0", "hwmode")
	local RTS_Set
	local Frag_Set

        if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
                uci:set("wireless", "ath0", "rts",2346)
		uci:set("wireless", "ath0", "frag",2346)
                uci:commit("wireless")
                RTS_Set="disabled"
		Frag_Set="disabled"
        end

	if apply then
--rts_Threshold
		local rts_Threshold = luci.http.formvalue("rts_Threshold")
		local rts_Threshold_old = uci:get("wireless", "ath0","rts")
		if not (rts_Threshold) then
			changed = 1
			uci:set("wireless", "ath0","rts", "2345")
		else
			if not (rts_Threshold == rts_Threshold_old) then
			changed = 1
			uci:set("wireless", "ath0","rts", rts_Threshold)
			end
		end
--fr_threshold		
		local fr_threshold = luci.http.formvalue("fr_threshold")
		local fr_threshold_old = uci:get("wireless", "ath0","frag")
		if not (fr_threshold) then
			changed = 1
			uci:set("wireless", "ath0","frag", "2354")
		else
			if not (fr_threshold == fr_threshold_old) then
			changed = 1
			uci:set("wireless", "ath0","frag", fr_threshold)
			end
		end
--Intra-BSS Traffic
		local IntraBSS_state = luci.http.formvalue("IntraBSS_state")
		local IntraBSS_state_old = uci:get("wireless", "ath0","IntraBSS")
		if not (IntraBSS_state) then
			changed = 1
			uci:set("wireless", "ath0","IntraBSS", "0")
		else
			if not (IntraBSS_state == IntraBSS_state_old) then
			changed = 1
			uci:set("wireless", "ath0","IntraBSS", IntraBSS_state)
			end
		end		
--tx power
		local txPower = luci.http.formvalue("TxPower_value")
		local txPower_old = uci:get("wireless", "wifi0", "txpower")
		if not (txPower) then
			changed = 1
			uci:set("wireless", "wifi0", "txpower","100")
		else
			if not (txPower == txPower_old) then 
			changed = 1
			uci:set("wireless", "wifi0", "txpower",txPower)
			end
		end
		if (changed == 1) then
			uci:commit("wireless")
			sys.exec("echo wifi0 >/tmp/WirelessDev")
			uci:apply("wireless")
		end
	end
	luci.template.render("expert_configuration/wlanadvanced",{rts_set=RTS_Set, frag_set=Frag_Set})	
end

function wlan_qos()
	local apply = luci.http.formvalue("sysSubmit")
	local wireless_mode = uci:get("wireless", "wifi0", "hwmode") 
	local WMM_Choose

	if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
		uci:set("wireless", "ath0", "wmm",1)
          	uci:commit("wireless")
          	WMM_Choose="disabled"
	end	

	if apply then
		local wmm_enable = luci.http.formvalue("WMM_QoS")
		
		if (wmm_enable == "1") then
			uci:set("wireless", "ath0","wmm", wmm_enable)
		elseif (wmm_enable == "0") then
			uci:set("wireless", "ath0","wmm", wmm_enable)		
		end
		sys.exec("echo wifi0 >/tmp/WirelessDev")
		uci:commit("wireless")	
		uci:apply("wireless")
	end
	luci.template.render("expert_configuration/wlanqos", {wmm_choice=WMM_Choose})	
end

function wlan_wps()
	require("luci.model.uci")
	local releaseConf = luci.http.formvalue("Release")
	local genPin = luci.http.formvalue("Generate")
	local pincode = uci:get("wps","wps","appin")
	local apply = luci.http.formvalue("sysSubmit")
	local wps_enable = uci:get("wps","wps","enabled")
	local wps_choice = luci.http.formvalue("wps_function")
	local wps_set
	local pincode_enable = uci:get("wps","wps","PinEnable")
	local pincode_choice = luci.http.formvalue("pincode_function")
	local pincode_set
	local wps_change
	local wps_chk -- +
	local configured
	local apssid
	local radiomode
	local authmode
	local securemode
	local config_status
	local configfile
	local wps_enable_choose
	local security_mode

	local WPAPSKCompatible_24G = uci.get("wireless", "ath0", "WPAPSKCompatible")
    local WPACompatible_24G = uci.get("wireless", "ath0", "WPACompatible")
	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 " -- +

	security_mode=uci:get("wireless","ath0","auth")

	if( security_mode=="WEPAUTO" or security_mode=="SHARED" or security_mode=="WPA" or security_mode=="WPA2" ) then
		wps_enable_choose="disabled"
	end

	if releaseConf then
		uci:set("wps","wps","conf",0)
		uci:commit("wps")
--		sys.exec("iwpriv ra0 set WscConfStatus=1")    -
		sys.exec("echo wifi0 >/tmp/WirelessDev")
		uci:apply("wireless")  -- +
		-- Re-generate the pin code when release configuration
		if(pincode_enable=="1") then
			pincode=sys.exec(hstapd_cli .. "wps_ap_pin random" )
			uci:set("wps","wps","appin",pincode)
			uci:commit("wps")
		end
		sys.exec("wps ath0 on")		
	end

	sys.exec(hstapd_cli .. "get_config" .. "" ..  "> /tmp/wps_config")
	configfile = io.open("/tmp/wps_config", "r")

	local tmp = configfile:read("*all")
	configfile:close()
	
	configured = tmp:match("wps_state=(%a+)")

	if ( configured == "configured" ) then
--		uci:set("wps","wps","conf",1)
--		uci:commit("wps")

		apssid = uci:get("wireless","ath0","ssid")
		radiomode = uci:get("wireless","wifi0","hwmode")
		radiomode = "802."..radiomode
		authmode = uci:get("wireless","ath0","encryption")

		if not apssid then
			local mac_24g=luci.sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12")
			local mac_ssid_24g=string.match( mac_24g,"%x+")
			apssid="ZyXEL" .. mac_ssid_24g
		end
		
		if authmode == "WPAPSK" then
			securemode="WPA-PSK"
		elseif authmode == "WPA2PSK" then
		-- add by darren 2012.03.07
            if WPAPSKCompatible_24G == "0" then
               securemode="WPA2-PSK"
            elseif WPAPSKCompatible_24G == "1" then
               securemode="WPA-PSK / WPA2-PSK"
            end
                --
		elseif authmode == "WEPAUTO" or authmode == "SHARED" then
			securemode="WEP"
		elseif authmode == "NONE" then
			securemode="No Security"
		elseif authmode == "WPAPSKWPA2PSK" then
			securemode="WPA2-PSK"
		-- add by darren 2012.03.07
                elseif authmode == "WPA2" then
                        if WPACompatible_24G == "0" then
                                securemode=authmode
                        elseif WPACompatible_24G == "1" then
                                securemode="WPA / WPA2"
                        end
		else
			securemode=authmode
		end

		config_status="Configured"
	else
		config_status="Unconfigured"
	end
	--Generate a new vendor pin code
	if genPin then
		pincode=sys.exec(hstapd_cli .. "wps_ap_pin random" )
		uci:set("wps","wps","appin",pincode)
		uci:commit("wps")
		sys.exec("wps ath0 on")
	end
	--Variable "wps_set" will be used in the GUI
	if (wps_enable == "1") then
		wps_set="enabled"
	elseif (wps_enable == "0") then
		wps_set="disabled"
	end

	--Variable "pincode_set" will be used in the GUI
        if (pincode_enable == "1") then
                pincode_set="enabled"
        elseif (pincode_enable == "0") then
                pincode_set="disabled"
        end

	if apply then

		wlan_btn=sys.exec("cat /tmp/wlan_on | tr -d '\n'")
		if (wlan_btn == "0") then

			if not(pincode_choice == nil) then
				uci:set("wps","wps", "PinEnable", pincode_choice)
				if (pincode_choice == "1") then
					pincode_set="enabled"
				else
					pincode_set="disabled"
				end
			end

			uci:set("wps","wps", "enabled", wps_choice)
			if (wps_choice == "1") then
				wps_set="enabled"
			else
				wps_set="disabled"
			end			
			uci:commit("wps")

		else

			if (wps_choice == "1") then
				config_status="Configured"
				apssid = uci:get("wireless","ath0","ssid")
				radiomode = uci:get("wireless","wifi0","hwmode")
				radiomode = "802."..radiomode
				authmode = uci:get("wireless","ath0","encryption")
				if not apssid then
					local mac_24g=luci.sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12")
					local mac_ssid_24g=string.match( mac_24g,"%x+")
					apssid="ZyXEL" .. mac_ssid_24g
				end
				if authmode == "WPAPSK" then
					securemode="WPA-PSK"
				elseif authmode == "WPA2PSK" then
				-- add by darren 2012.03.07
					if WPAPSKCompatible_24G == "0" then
						securemode="WPA2-PSK"
					elseif WPAPSKCompatible_24G == "1" then
						securemode="WPA-PSK / WPA2-PSK"
					end
				--
				elseif authmode == "WEPAUTO" or authmode == "SHARED" then
					securemode="WEP"
				elseif authmode == "NONE" then
					securemode="No Security"
				elseif authmode == "WPAPSKWPA2PSK" then
					securemode="WPA2-PSK"
				-- add by darren 2012.03.07
				elseif authmode == "WPA2" then
					if WPACompatible_24G == "0" then
						securemode=authmode
					elseif WPACompatible_24G == "1" then
						securemode="WPA / WPA2"
					end
				--                
				else
					securemode=authmode
				end	

				if (wps_enable == "0") then --From disable wps to enable wps
					wps_chk="1"
					if (pincode_enable == "1") then
		                            pincode_enable=1
		                            pincode_set="enabled"
									wps_change = true
										
		            elseif (pincode_enable == "0") then --PIN-code disable
									pincode_enable=0
									pincode_set="disabled"
									wps_change = true
					end
				elseif(wps_enable == "1") then
					if (pincode_choice == "1") then
		                 if (pincode_enable == "0") then --From disable PIN-code to enable PIN-code
		                    pincode_enable=1
		                    pincode_set="enabled"
							wps_change = true
		                 end
		            elseif (pincode_choice == "0") then --From enable PIN-code to disable PIN-code
		                 if (pincode_enable == "1") then
							pincode_enable=0
							pincode_set="disabled"
							wps_change = true
						end
		            end			
				end
			
				if wps_change then
					wps_enable=1
		          	wps_set="enabled"
					uci:set("wps","wps", "PinEnable", pincode_enable)
		    	    uci:set("wps","wps", "enabled", wps_enable)
		            uci:commit("wps")
					if (wps_chk == "1") then
						sys.exec("echo wifi0 >/tmp/WirelessDev")
						uci:apply("wireless")
		            end
				end

				sys.exec("wps ath0 on")

			elseif (wps_choice == "0") then --From enable wps to disable wps
				config_status="Unconfigured"
				radiomode = " "
				apssid = " "
				securemode = " "

				if (wps_enable == "1") then
		            wps_chk="1"
				end
				wps_enable=0
				wps_set="disabled"

				uci:set("wps","wps", "PinEnable", pincode_enable)
				uci:set("wps","wps", "enabled", wps_enable)
				uci:commit("wps")

				if (wps_chk == "1") then
					sys.exec("echo wifi0 >/tmp/WirelessDev")
					uci:apply("wireless")
				end

				sys.exec("wps ath0 off")
			end

			local configuredx = uci:get("wps","wps","conf")
			if (configuredx == "0") then
				config_status="Unconfigured"
				radiomode = " "
				apssid = " "
				securemode = " "
			end

		end
	end

	luci.template.render("expert_configuration/wlanwps", {AP_PIN = pincode,
								SSID = apssid,
								RadioMode = radiomode,
								SecureMode = securemode,
								ConfigStatus = config_status,
								WPS_Enabled = wps_set,
								WPS_Enabled_Choose = wps_enable_choose,
								PINCode_Enabled = pincode_set})
end

function wlanwpsstation()
	local wps_enable = uci:get("wps","wps","enabled")
	local wps_set
	local enable_wps_btn = luci.http.formvalue("wps_button")
	local enable_wps_pin = luci.http.formvalue("wps_pin")
	local configured = uci:get("wps","wps","conf")
	local config_status
	local valid = 1
	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 "
	--Variable "wps_set" will be used in the GUI
	if (wps_enable == "1") then
		wps_set="enabled"
	elseif (wps_enable == "0") then
		wps_set="disabled"
	end

--	if (configured == "1") then
--		config_status = "conf"
--	else
--		config_status = "unconf"
--	end

	local fd
	if enable_wps_btn then
		sys.exec("killall -9 wps")
		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
		fd = io.popen("wps ath0 on wps_btn &")
		sys.exec("rm /tmp/pbc_overlap")
		sys.exec("rm /tmp/wps_success")
		sys.exec("rm /tmp/wps_timeout")
		for i=1,120 do
			sys.exec("sleep 1")
			if io.open( "/tmp/pbc_overlap", "r" ) then
				valid = 2
				sys.exec("killall wps")
				sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				break;
			end
			if io.open( "/tmp/wps_success", "r" ) then
				valid = 4
				sys.exec("killall wps")
				sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				break;
			end
			if io.open( "/tmp/wps_timeout", "r" ) then
				valid = 3
				sys.exec("killall wps")
				sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				break;
			end
		end
		luci.template.render("expert_configuration/wlanwpsstation",{WPS_Enabled = wps_set, pin_valid = valid})
		return
	end

	if enable_wps_pin then
		local pincode
		local pin_verify
		pincode = luci.http.formvalue("wps_pincode")
		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
		end
		pin_verify = sys.exec(hstapd_cli .. "wps_check_pin " .. pincode)
		if ( pin_verify == pincode ) then
			sys.exec("killall -9 wps")
			sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
			fd = io.popen("wps ath0 on wps_pin ".. pincode .. " &")
		else
			luci.template.render("expert_configuration/wlanwpsstation",{WPS_Enabled = wps_set, pin_valid = 0})
			return
		end
	end

	luci.template.render("expert_configuration/wlanwpsstation",{WPS_Enabled = wps_set, pin_valid = 1})
end

function wlanscheduling()
	local apply = luci.http.formvalue("sysSubmit")

	if apply then
		uci:set("wifi_schedule", "wlan", "enabled", luci.http.formvalue("WLanSchRadio"))

		local schedulingNames = { "Everyday", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }

		for i, name in ipairs(schedulingNames) do
			local prefixStr = "WLanSch" .. name
			local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)

			uci:set("wifi_schedule", token, "status_onoff", luci.http.formvalue(prefixStr .. "Radio"))
			uci:set("wifi_schedule", token, "start_hour",   luci.http.formvalue(prefixStr .. "StartHour"))
			uci:set("wifi_schedule", token, "start_min",    luci.http.formvalue(prefixStr .. "StartMin"))
			uci:set("wifi_schedule", token, "end_hour",     luci.http.formvalue(prefixStr .. "EndHour"))
			uci:set("wifi_schedule", token, "end_min",      luci.http.formvalue(prefixStr .. "EndMin"))

			if "on" == luci.http.formvalue(prefixStr .. "Enabled") then
				uci:set("wifi_schedule", token, "enabled", "1")
			else
				uci:set("wifi_schedule", token, "enabled", "0")
			end
		end

		uci:commit("wifi_schedule")
		uci:apply("wifi_schedule")
	end

	luci.template.render("expert_configuration/wlanscheduling")	
end

--Wireless client
function wlan_apcli_wisp()

	local apply = luci.http.formvalue("apply")

	if apply then
		local ApCliSsid = luci.http.formvalue("apcli_ssid")
		local ApCliBssid = luci.http.formvalue("apcli_bssid")		
		local ApCliAuthMode = luci.http.formvalue("apcli_mode")		
		local ApCliWepEncry = luci.http.formvalue("wep_encry")		
		local ApCliKeyType = luci.http.formvalue("WEPKey_Code")
		local ApCliDefaultKeyId = luci.http.formvalue("DefWEPKey")
		local ApCliKey1Str = luci.http.formvalue("apcli_key1")
		local ApCliKey2Str = luci.http.formvalue("apcli_key2")
		local ApCliKey3Str = luci.http.formvalue("apcli_key3")
		local ApCliKey4Str = luci.http.formvalue("apcli_key4")
		local ApClicipher = luci.http.formvalue("cipher")
		local ApCliWPAPSK = luci.http.formvalue("apcli_wpapsk")
		local ApCliWepMethod = luci.http.formvalue("auth_method")
		local passphrase = luci.http.formvalue("wep_passphrase")
		local auth_method = luci.http.formvalue("auth_method")	

		uci:set("wireless_client", "general", "ApCliSsid", ApCliSsid)
		uci:set("wireless_client", "general", "ApCliBssid", ApCliBssid)
		uci:set("wireless_client", "general", "ApCliAuthMode", ApCliAuthMode)		

		if (ApCliAuthMode == "SHARED") then		

			uci:set("wireless_client", "general", "ApCliKeyType", ApCliKeyType)
			uci:set("wireless_client", "general", "ApCliDefaultKeyId", ApCliDefaultKeyId)
			uci:set("wireless_client", "general", "ApCliEncrypType", "WEP")
			uci:set("wireless_client", "general", "ApCliWepMethod", ApCliWepMethod)

			if ApCliKey1Str then
				uci:set("wireless_client", "general", "ApCliKey1Str", ApCliKey1Str)
			end
			if ApCliKey2Str then
				uci:set("wireless_client", "general", "ApCliKey2Str", ApCliKey2Str)
			end
			if ApCliKey3Str then
				uci:set("wireless_client", "general", "ApCliKey3Str", ApCliKey3Str)
			end
			if ApCliKey4Str then
				uci:set("wireless_client", "general", "ApCliKey4Str", ApCliKey4Str)
			end
		elseif (ApCliAuthMode == "OPEN") then
			
			uci:set("wireless_client", "general", "ApCliEncrypType", "NONE")
		
		else		
			
			if ApClicipher == "0" then
				uci:set("wireless_client", "general", "ApCliEncrypType", "TKIP")
			else
				uci:set("wireless_client", "general", "ApCliEncrypType", "AES")
			end

			uci:set("wireless_client", "general", "ApCliWPAPSK", ApCliWPAPSK)

		end
		
		--ChannelID
		local Apcli_channel = luci.http.formvalue("apcli_channel")
		local Channel_ID_old = uci:get("wireless", "ra0","channel",Channel_ID)
		if not(Apcli_channel)then
			Apcli_channel = Channel_ID_old
		end
		if not(Apcli_channel == Channel_ID_old) then
			uci:set("wireless", "ra0","channel",Apcli_channel)
		end
		uci:set("wireless", "ra0","AutoChannelSelect","0")		

		uci:commit("wireless")
		uci:commit("wireless_client")
		uci:apply("wireless_client")
	end

	local file = io.open("/var/countrycode", "r")	
	local temp = file:read("*all")
	file:close()

	local code = temp:match("([0-9a-fA-F]+)")
	local region = country_code_table[code:gsub("[a-fA-F]", string.upper)]

	luci.template.render("expert_configuration/wlan_apcli_wisp",{channels = channelRange[region[1]]})

end

function wlan_apcli_wisp_ur_site_survey()

	local apply = luci.http.formvalue("survey_apply")

	if apply then
		local ssid = luci.http.formvalue("site_ssid")
		--local signal = luci.http.formvalue("site_signal")		
		local channel = luci.http.formvalue("site_channel")
		local auth = luci.http.formvalue("site_auth")
		local encry = luci.http.formvalue("site_encry")
		local bssid = luci.http.formvalue("site_bssid")
		local nt = luci.http.formvalue("site_nt")
		local network_type
		local auth_selected
		local encry_selected

		if (nt == "In") then
			network_type = "1"
		elseif (nt == "Ad") then
			network_type = "0"
		else
			network_type = "1"
		end

		if auth:find("WPA2PSK") then
			auth_selected = "WPA2PSK"
		elseif auth:find("WPAPSK") then
			auth_selected = "WPAPSK"
		else
			auth_selected = "OPEN"
		end

		if encry:find("TKIP") then
			encry_selected = "TKIP"
		elseif encry:find("AES") then
			encry_selected = "AES"
		elseif encry:find("WEP") then
			encry_selected = "WEP"
		else
			encry_selected = "NONE"
		end

	
		local url = luci.dispatcher.build_url("expert","configuration","network","wlan","wlan_apcli_wisp")		
		luci.http.redirect(url .. "?" .. "site_ssid=" .. luci.http.protocol.urlencode(ssid) .. "&site_network_type=" .. network_type  .. "&site_channel=" .. channel .. "&site_auth=" .. auth_selected .. "&site_encry=" .. encry_selected .. "&site_bssid=" .. bssid .. "&site_survey=1")

		return
	end	

	luci.template.render("expert_configuration/wlan_apcli_wisp_ur_site_survey")

end

function wlan_apcli_wisp5G()

	luci.template.render("expert_configuration/wlan_apcli_wisp5G")

end

function wlan_apcli_wisp_ur_site_survey5G()

	luci.template.render("expert_configuration/wlan_apcli_wisp_ur_site_survey5G")

end
--Wireless client 2.4G end

--Wireless 5G
function wlan_general_5G()
	local apply = luci.http.formvalue("sysSubmit")
	local wps_enable = uci:get("wps5G","wps","enabled")

	if apply then
		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
	--SSID
		local SSID = luci.http.formvalue("SSID_value")
		local SSID_old = uci:get("wireless", "ath10","ssid")
		if not (SSID == SSID_old)then
			SSID = checkInjection(SSID)
			if SSID ~= false then
				uci:set("wireless", "ath10","ssid",SSID)
			end
		end--SSID
	--radioON
		local Wireless_enable = luci.http.formvalue("ssid_state")
		local Wireless_enable_old = uci:get("wireless", "wifi1","disabled")
		if not(Wireless_enable == Wireless_enable_old)then
			uci:set("wireless", "wifi1","disabled",Wireless_enable)
			uci:set("wireless", "ath10","disabled",Wireless_enable)
		end--radioON
	--HideSSID
		local wireless_hidden = luci.http.formvalue("Hide_SSID")
		local wireless_hidden_old = uci:get("wireless", "ath10","hidden")
		if not (wireless_hidden)then
			wireless_hidden = "0"
		else
			wireless_hidden = "1"
		end
			
		if not(wireless_hidden == wireless_hidden_old)then			
			uci:set("wireless", "ath10","hidden",wireless_hidden)
		end
	--DFS
		--[[local dfs = luci.http.formvalue("DFS")
		if dfs then
			dfs=1
		else
			dfs=0
		end
		uci:set("wireless", "ath10","DFS",dfs)]]--
	--ChannelID
		local Channel_ID = luci.http.formvalue("Channel_ID_index")
		local Channel_ID_old = uci:get("wireless", "wifi1","channel")
		if not(Channel_ID)then
			Channel_ID = Channel_ID_old
		end
		if not(Channel_ID == Channel_ID_old) then
			uci:set("wireless", "wifi1","channel",Channel_ID)
		end
	--AutoChSelect
		local Auto_Channel = luci.http.formvalue("Auto_Channel")
		local Auto_Channel_old = uci:get("wireless", "wifi1","AutoChannelSelect")
		if not(Auto_Channel)then
			Auto_Channel = 0
		else
			Auto_Channel = 1
		end
		if not(Auto_Channel == Auto_Channel_old) then
			uci:set("wireless", "wifi1","AutoChannelSelect",Auto_Channel)   
			if (Auto_Channel==1) then                                		
				uci:set("wireless", "wifi1", "channel", "auto")    			
			end
			if (Wireless_enable=="1") then
				uci:set("wireless", "wifi1", "channel", "40")  
			end
		end	
        --ChannelWidth
		local Channel_Index = uci:get("wireless", "wifi1","channel")
		local Channel_Width = luci.http.formvalue("ChWidth_select")
		if ( Channel_Width == "80" and  Channel_Index == "132" ) then
			uci:set("wireless", "wifi1","channel_width", 40)
		elseif ( Channel_Width == "80" and  Channel_Index == "136" ) then
			uci:set("wireless", "wifi1","channel_width", 40)
		elseif ( Channel_Width == "80" and  Channel_Index == "140" ) then
			uci:set("wireless", "wifi1","channel_width", 20)
		elseif ( Channel_Width == "80" and  Channel_Index == "165" ) then
                        uci:set("wireless", "wifi1","channel_width", 20)
		elseif ( Channel_Width == "40" and  Channel_Index == "140" ) then
			uci:set("wireless", "wifi1","channel_width", 20)
		elseif ( Channel_Width == "40" and  Channel_Index == "165" ) then
			uci:set("wireless", "wifi1","channel_width", 20)
		else
			uci:set("wireless", "wifi1","channel_width", Channel_Width)
		end
        --WirelessMode
		local Wireless_Mode = luci.http.formvalue("Mode_select")
		uci:set("wireless", "wifi1","hwmode", Wireless_Mode)
		--if set 802.11n or 802.11ac default enable wmm
		if ( Wireless_Mode == "11an" or  Wireless_Mode == "11ac" ) then
			uci:set("wireless", "ath10", "wmm",1)
		end	
	--SecurityMode
		local security_mode = luci.http.formvalue("security_value")
		if (security_mode) then
			--No security
			if( security_mode == "NONE") then
				uci:set("wireless", "wifi1","auth","OPEN")  
				uci:set("wireless", "ath10","auth","NONE") 
				uci:set("wireless", "ath10","encryption","NONE")
				uci:set("wireless", "ath10","pmf", "0")
			end
				
			--WEP
			if( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
--				uci:set("wireless", "rai0","encryption","WEP")
				if (EncrypAuto_shared)	then
					if(EncrypAuto_shared == "WEPAUTO")then
						uci:set("wireless", "ath10","encryption","wep-mixed")
						uci:set("wireless", "ath10","auth",EncrypAuto_shared)
					elseif(EncrypAuto_shared == "SHARED") then
						uci:set("wireless", "ath10","encryption","wep-shared")
						uci:set("wireless", "ath10","auth",EncrypAuto_shared)
					end
				end
				local wep_passphrase = luci.http.formvalue("wep_passphrase")	
				if not (wep_passphrase) then
					uci:set("wireless", "ath10","PassPhrase","")
				else 
					uci:set("wireless", "ath10","PassPhrase",wep_passphrase)
				end
				--64-128bit
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				if (WEP64_128)then
					if(WEP64_128 == "0")then--[[64-bit]]--
						uci:set("wireless", "ath10","wepencryp128", WEP64_128)
					elseif(WEP64_128 == "1") then--[[128-bit]]--
						uci:set("wireless", "ath10","wepencryp128", WEP64_128)
					end
				end
				--ASCIIHEX
				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
				if (WEPKey_Code == "1")then--[[HEx]]--
					uci:set("wireless", "ath10","keytype", "1")
				elseif (WEPKey_Code == "0") then--[[ASCII]]--
					uci:set("wireless", "ath10","keytype", "0")
				end
				--keyindex
				local DefWEPKey = luci.http.formvalue("DefWEPKey")
				if (DefWEPKey)then
					uci:set("wireless", "ath10","key", DefWEPKey)
				end
				--WEP key value
				local wepkey
				local key_name
				for i=1,4 do
					wepkey = luci.http.formvalue("wep_key_"..i)
					key_name="key"..i
					if ( wepkey ) then
						uci:set("wireless", "ath10", key_name, wepkey)
					else
						uci:set("wireless", "ath10", key_name, "")
					end
				end
				uci:set("wireless", "ath10","pmf", "0")
			end

			--WPA
			if (security_mode == "WPA")then
				uci:set("wireless", "ath10","auth","WPA")
				uci:set("wireless", "ath10","encryption","WPA")

				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				if (RekeyInterval == "") then
					uci:set("wireless", "ath10","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
				end
				--[[
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				if (PMKCachePeriod == "") then
					uci:set("wireless", "ath10","PMKCachePeriod", "10")
				else
					uci:set("wireless", "ath10","PMKCachePeriod", PMKCachePeriod)
				end					
				]]--
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				if (RadiusServerIP == "") then
					uci:set("wireless", "ath10","RADIUS_Server", "192.168.2.3")
				else
					uci:set("wireless", "ath10","RADIUS_Server", RadiusServerIP)
				end
					
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				if (RadiusServerPort == "") then
					uci:set("wireless", "ath10","RADIUS_Port", "1812")
				else
					uci:set("wireless", "ath10","RADIUS_Port", RadiusServerPort)
				end	
					
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				if (RadiusServerSecret == "") then
					uci:set("wireless", "ath10","RADIUS_Key", "ralink")
				else
					uci:set("wireless", "ath10","RADIUS_Key", RadiusServerSecret)
				end
					
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
				if (RadiusServerSessionTimeout == "") then
					uci:set("wireless", "ath10","session_timeout_interval", "0")
				else
					uci:set("wireless", "ath10","session_timeout_interval", RadiusServerSessionTimeout)
				end
				--[[
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				if (PreAuthentication == "") then
					uci:set("wireless", "ath10","PreAuth", "0")
				else
					uci:set("wireless", "ath10","PreAuth", PreAuthentication)
				end
				]]--
				uci:set("wireless", "ath10","pmf", "0")
			end
				
			--WPAPSK
			if(security_mode == "WPAPSK")then
				uci:set("wireless", "ath10","auth","WPAPSK")
				uci:set("wireless", "ath10","encryption","WPAPSK")
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
				if (WPAPSKkey == "") or (WPAPSKAuto) then
					uci:set("wireless", "ath10","WPAPSKkey", "")
				else						
					uci:set("wireless", "ath10","WPAPSKkey", WPAPSKkey)
				end
				if not(RekeyInterval) then
					uci:set("wireless", "ath10","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
				end
				uci:set("wireless", "ath10","pmf", "0")
			end
				
			--WPA2
			if (security_mode == "WPA2")then
				uci:set("wireless", "ath10","auth","WPA2")
				uci:set("wireless", "ath10","encryption","WPA2")
				local WPACompatible = luci.http.formvalue("wpa_compatible")
				if not (WPACompatible) then
					uci:set("wireless", "ath10","WPACompatible", "0")
				else
					uci:set("wireless", "ath10","WPACompatible", WPACompatible)
				end					
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				if (RekeyInterval == "") then
					uci:set("wireless", "ath10","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
				end
					
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				if (PMKCachePeriod == "") then
					uci:set("wireless", "ath10","PMKCachePeriod", "10")
				else
					uci:set("wireless", "ath10","PMKCachePeriod", PMKCachePeriod)
				end					
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				if (PreAuthentication == "") then
					uci:set("wireless", "ath10","PreAuth", "0")
				else
					uci:set("wireless", "ath10","PreAuth", PreAuthentication)
				end						
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				if (RadiusServerIP == "") then
					uci:set("wireless", "ath10","RADIUS_Server", "192.168.2.3")
				else
					uci:set("wireless", "ath10","RADIUS_Server", RadiusServerIP)
				end
					
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				if (RadiusServerPort == "") then
					uci:set("wireless", "ath10","RADIUS_Port", "1812")
				else
					uci:set("wireless", "ath10","RADIUS_Port", RadiusServerPort)
				end	
					
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				if (RadiusServerSecret == "") then
					uci:set("wireless", "ath10","RADIUS_Key", "ralink")
				else
					uci:set("wireless", "ath10","RADIUS_Key", RadiusServerSecret)
				end
					
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
				if (RadiusServerSessionTimeout == "") then
					uci:set("wireless", "ath10","session_timeout_interval", "0")
				else
					uci:set("wireless", "ath10","session_timeout_interval", RadiusServerSessionTimeout)
				end
										
				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set("wireless", "ath10","pmf", "0")
				else
					uci:set("wireless", "ath10","pmf", PMF)
				end
			end
			
			--WPA2PSK
			if(security_mode=="WPA2PSK")then
				uci:set("wireless", "ath10","auth","WPA2PSK")
				uci:set("wireless", "ath10","encryption","WPA2PSK")
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
				local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
				if (WPAPSKkey == "") or (WPAPSKAuto) then
					uci:set("wireless", "ath10","WPAPSKkey", "")
				else						
					uci:set("wireless", "ath10","WPAPSKkey", WPAPSKkey)
				end
				if (RekeyInterval == "") then
					uci:set("wireless", "ath10","RekeyInterval", "3600")
				else
					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
				end
				if not (WPAPSKCompatible) then
					uci:set("wireless", "ath10","WPAPSKCompatible", "0")
				else
					uci:set("wireless", "ath10","WPAPSKCompatible", WPAPSKCompatible)
				end					

				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set("wireless", "ath10","pmf", "0")
				else
					uci:set("wireless", "ath10","pmf", PMF)
				end
			end
		end

		uci:set("wps5G","wps","conf","1")
                uci:commit("wps5G")

		uci:commit("wireless")
		sys.exec("echo wifi1 >/tmp/WirelessDev")
		uci:apply("wireless")
		
		sys.exec("/etc/init.d/intfGrp restart") 
	end --end apply

	if (wps_enable == "1") then
		wps=1
	else
		wps=0
	end

        sys.exec("set_tmp_psk")
        tmppsk=sys.exec("cat /tmp/tmppsk")
        sys.exec("rm /tmp/tmppsk")

	local file = io.open("/var/countrycode", "r")	
	local temp = file:read("*all")
	file:close()

	local show_dfs="1"
	if temp:match("[fF][fF]") then
		show_dfs="0"
	elseif temp:match("[eE][eE]") then
                show_dfs="0"
	end
	
	local code = temp:match("([0-9a-fA-F]+)")
	local region = country_code_table[code:gsub("[a-fA-F]", string.upper)]
	sys.exec("uci set wireless.wifi1.channel=$(iwlist ath10 channel | grep 'Current Frequency'| awk -F 'Channel ' '{print $2}'| awk -F ')' '{print $1}'|sed 's/\"//g')")	
	luci.template.render("expert_configuration/wlan5G", {wps_enabled = wps, psk = tmppsk, channels = channelRange5G[region[2]], dfs_show=show_dfs})	
end

function wlan_multissid5G()
        security = {"","",""}
        local iface
	local Wireless_enable
	local cfgfile="wireless"
	local apply = luci.http.formvalue("sysSubmit")

        for i=1,3 do
                iface="ath1"..i
                security[i]=uci.get(cfgfile,iface,"auth")

                if security[i] == "WPAPSK" then
                        security[i]="WPA-PSK"
                elseif security[i] == "WPA2PSK" then
                        security[i]="WPA2-PSK"
                elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
                        security[i]="WEP"
                elseif security[i] == "OPEN" then
                        security[i]="No Security"
                end
        end

        luci.template.render("expert_configuration/wlan_multissid5G", { security1 = security[1], security2 = security[2], security3 = security[3]})
end

function multiple_ssid5G()
	require("luci.model.uci")
	security = {"","",""}
	local apply = luci.http.formvalue("sysSubmit")
	local interface = luci.http.formvalue("interface")
	local iface
	local cfgfile="wireless"
	local wireless_mode = uci:get("wireless", "wifi1", "hwmode")
	local WMM_Choose

        if ( wireless_mode == "11an" or wireless_mode == "11ac" ) then
            uci:set("wireless", "ath11", "wmm",1)
			uci:set("wireless", "ath12", "wmm",1)
			uci:set("wireless", "ath13", "wmm",1)
            uci:commit("wireless")
            WMM_Choose="disabled"
        end

	if interface == "1" then
		iface="ath11"
	elseif interface == "2" then
		iface="ath12"
	elseif interface == "3" then
		iface="ath13"
	else
		iface=interface
	end

	if apply then
		--SSID
		local SSID = luci.http.formvalue("SSID_value")

		SSID = checkInjection(SSID)
		if SSID ~= false then
			uci:set(cfgfile, iface, "ssid", SSID)
		end

		--Active
		local Wireless_enable = luci.http.formvalue("ssid_state")
		if Wireless_enable then
			uci:set(cfgfile, iface, "disabled", 0)
		else
			uci:set(cfgfile, iface, "disabled", 1)
		end
		--HideSSID
		local wireless_hidden = luci.http.formvalue("Hide_SSID")
		if not (wireless_hidden)then
			uci:set(cfgfile, iface, "hidden", 0)
		else
			uci:set(cfgfile, iface, "hidden", 1)
		end
		--Intra BSS
        local intra_bss = luci.http.formvalue("Intra_BSS")
		if not (intra_bss) then
			uci:set(cfgfile, iface, "IntraBSS", 0)
		else
			uci:set(cfgfile, iface, "IntraBSS", 1)
		end
		--WMM QoS
		local wmm_qos = luci.http.formvalue("WMM_QoS")

		if ( wireless_mode == "11an" ) then
			uci:set(cfgfile, iface, "wmm", 1)
		else
			if not (wmm_qos) then
				uci:set(cfgfile, iface, "wmm", 0)
			else
				uci:set(cfgfile, iface, "wmm", 1)
			end
		end

		--5G Guest WLAN
                local guest_ssid = luci.http.formvalue("guest_ssid")
                if not (guest_ssid) then
                        uci:set(cfgfile, iface, "enable_guest_wlan", 0)
                else
                        uci:set(cfgfile, iface, "enable_guest_wlan", 1)
                        local ip_addr = luci.http.formvalue("guest_ip")
                        local ip_mask = "255.255.255." .. luci.http.formvalue("guest_ip_mask")
			local band_manage = luci.http.formvalue("guest_wlan_bandwidth")
			local max_band = luci.http.formvalue("max_bandwidth")
                        if ip_addr then
                                uci:set(cfgfile, iface, "guest_ip", ip_addr)
                        end
                        if ip_mask then
                                uci:set(cfgfile, iface, "guest_ip_mask", ip_mask)
                        end
			if band_manage then
				uci:set(cfgfile, iface, "guest_bandwidth_enable", 1)
			else
				uci:set(cfgfile, iface, "guest_bandwidth_enable", 0)
			end
			uci:set(cfgfile, iface, "guest_max_bandwidth", max_band)
                end

		--SecurityMode
		local security_mode = luci.http.formvalue("security_value")
		if (security_mode) then
			--No security
			if( security_mode == "NONE") then
				uci:set(cfgfile, iface, "auth", "OPEN")
				uci:set(cfgfile, iface, "encryption", "NONE")
				uci:set(cfgfile, iface,"pmf", "0")
			end
			
			--WEP
			if( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
				uci:set(cfgfile, iface,"encryption","WEP")
				if (EncrypAuto_shared)	then
					if(EncrypAuto_shared == "WEPAUTO")then
						uci:set(cfgfile, iface,"encryption","wep-mixed")
						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
					elseif(EncrypAuto_shared == "SHARED") then
						uci:set(cfgfile, iface,"encryption","wep-shared")
						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
					end
				end

				local wep_passphrase = luci.http.formvalue("wep_passphrase")
				if not (wep_passphrase) then
					uci:set(cfgfile, iface, "PassPhrase","")
				else
					uci:set(cfgfile, iface, "PassPhrase",wep_passphrase)
				end

				--64-128bit
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				if (WEP64_128)then
					if(WEP64_128 == "0")then--[[64-bit]]--
						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
					else
						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
					end
				end

                                --ASCIIHEX
                                local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
                                if (WEPKey_Code == "1")then--[[HEx]]--
                                	uci:set(cfgfile, iface, "keytype", "1")
                                elseif (WEPKey_Code == "0") then--[[ASCII]]--
                                        uci:set(cfgfile, iface, "keytype", "0")
                                end
                                --keyindex
                                local DefWEPKey = luci.http.formvalue("DefWEPKey")
                                if (DefWEPKey)then
                                	uci:set(cfgfile, iface, "key", DefWEPKey)
                                end
								
				--WEP key value
				local wepkey
				local key_name
				for i=1,4 do
					wepkey = luci.http.formvalue("wep_key_"..i)
					key_name="key"..i
					if ( wepkey ) then
						uci:set(cfgfile, iface, key_name, wepkey)
					else
						uci:set(cfgfile, iface, key_name, "")
					end
				end
				uci:set(cfgfile, iface,"pmf", "0")
			end --End WEP
			
			--WPA
                        if (security_mode == "WPA")then
                        	uci:set(cfgfile, iface, "auth","WPA")
                                uci:set(cfgfile, iface, "encryption","WPA")

                                local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
                                if (RekeyInterval == "") then
                                        uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end

                                local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
                                if (RadiusServerIP == "") then
                                	uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
                                end

                                local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
                                if (RadiusServerPort == "") then
                                	uci:set(cfgfile, iface, "RADIUS_Port", "1812")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
                                end

                                local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
                                if (RadiusServerSecret == "") then
                                	uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
                                end
				
                                local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
                                if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
                                        uci:set(cfgfile, iface, "session_timeout_interval", "0")
                                else
                                        uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
                                end				
				uci:set(cfgfile, iface,"pmf", "0")
                	end --End WPA

                        --WPAPSK
                        if(security_mode == "WPAPSK")then
                        	uci:set(cfgfile, iface, "auth", "WPAPSK")
                                uci:set(cfgfile, iface, "encryption", "WPAPSK")
                                local WPAPSKkey = luci.http.formvalue("PSKey")
                                local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
								local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
								if (WPAPSKkey == "") or (WPAPSKAuto) then
                                	uci:set(cfgfile, iface, "WPAPSKkey", "")
                                else
                                	uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
                                end
                                if not(RekeyInterval) then
                                	uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end
				uci:set(cfgfile, iface,"pmf", "0")
                	end --End WPAPSK

                        --WPA2
                        if (security_mode == "WPA2")then
                                uci:set(cfgfile, iface, "auth", "WPA2")
                                uci:set(cfgfile, iface, "encryption", "WPA2")
                                local WPACompatible = luci.http.formvalue("wpa_compatible")
                                if not (WPACompatible) then
                                	uci:set(cfgfile, iface, "WPACompatible", "0")
                                else
                                        uci:set(cfgfile, iface, "WPACompatible", WPACompatible)
                                end
                                
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
                                if (RekeyInterval == "") then
                                        uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end

                                local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
                                if (PMKCachePeriod == "") then
                                        uci:set(cfgfile, iface, "PMKCachePeriod", "10")
                                else
                                        uci:set(cfgfile, iface, "PMKCachePeriod", PMKCachePeriod)
                                end
                                local PreAuthentication = luci.http.formvalue("PreAuthentication")
                                if (PreAuthentication == "") then
                                        uci:set(cfgfile, iface, "PreAuth", "0")
                                else
                                        uci:set(cfgfile, iface, "PreAuth", PreAuthentication)
                                end
                                local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
                                if (RadiusServerIP == "") then
                                        uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
                                end

                                local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
                                if (RadiusServerPort == "") then
                                        uci:set(cfgfile, iface, "RADIUS_Port", "1812")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
                                end
                                local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
                                if (RadiusServerSecret == "") then
                                        uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
                                else
                                        uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
                                end

                                local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
                                if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
                                        uci:set(cfgfile, iface, "session_timeout_interval", "0")
                                else
                                        uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
                                end

				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set(cfgfile, iface,"pmf", "0")
				else
					uci:set(cfgfile, iface,"pmf", PMF)
				end
                	end --End WPA2

                        --WPA2PSK
                        if(security_mode=="WPA2PSK")then
                        	uci:set(cfgfile, iface, "auth", "WPA2PSK")
                        	uci:set(cfgfile, iface, "encryption", "WPA2PSK")
                                local WPAPSKkey = luci.http.formvalue("PSKey")
                                local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
                                local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
								local WPAPSKAuto = luci.http.formvalue("WPAPSKAuto")
				
								if (WPAPSKkey == "") or (WPAPSKAuto) then
                                	uci:set(cfgfile, iface, "WPAPSKkey", "")
                                else
                                        uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
                                end
                                if (RekeyInterval == "") then
                                        uci:set(cfgfile, iface, "RekeyInterval", "3600")
                                else
                                        uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
                                end
                                if not (WPAPSKCompatible) then
                                        uci:set(cfgfile, iface, "WPAPSKCompatible", "0")
                                else
                                        uci:set(cfgfile, iface, "WPAPSKCompatible", WPAPSKCompatible)
                                end

				local PMF = luci.http.formvalue("pmf")
				if not (PMF) then
					uci:set(cfgfile, iface,"pmf", "0")
				else
					uci:set(cfgfile, iface,"pmf", PMF)
				end
                	end --End WPA2PSK
		end
		
		sys.exec("echo "..iface.." >> /tmp/moreAP5G")
		sys.exec("echo wifi1 >/tmp/WirelessDev")
		uci:commit(cfgfile)
		uci:apply(cfgfile)

		for i=1,3 do
                	iface="ath1"..i
                	security[i]=uci.get(cfgfile,iface,"auth")

                	if security[i] == "WPAPSK" then
                	        security[i]="WPA-PSK"
                	elseif security[i] == "WPA2PSK" then
                	        security[i]="WPA2-PSK"
                	elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
                	        security[i]="WEP"
                	elseif security[i] == "OPEN" then
                	        security[i]="No Security"
                	end			
		end

		sys.exec("/etc/init.d/intfGrp restart") 
		luci.template.render("expert_configuration/wlan_multissid5G", { security1 = security[1], security2 = security[2], security3 = security[3]})
		return
	end --End Apply

        sys.exec("set_tmp_psk")
        tmppsk=sys.exec("cat /tmp/tmppsk")
        sys.exec("rm /tmp/tmppsk")	
	luci.template.render("expert_configuration/multissid_edit5G",{ifacename=iface, psk = tmppsk, wmm_choice=WMM_Choose})
end

function wlanmacfilter_5G()
	local apply = luci.http.formvalue("sysSubmit")
	local select_ap = luci.http.formvalue("ap_select")
	local changed = 0
	local filter
	if not select_ap then
		select_ap="0"
	end

	filter="general"..select_ap

	if apply then
		--filter on/of
		local MACfilter_ON = luci.http.formvalue("MACfilter_ON")
		MACfilter_ON_old = uci:get("wireless5G_macfilter", filter, "mac_state")
		if not (MACfilter_ON == MACfilter_ON_old) then
			changed = 1
			uci:set("wireless5G_macfilter", filter, "mac_state", MACfilter_ON)
		end
		--filter action
		local filter_act = luci.http.formvalue("filter_act")
		filter_act_old = uci:get("wireless5G_macfilter", filter, "filter_action")
		if not (filter_act == filter_act_old) then
			changed = 1
			uci:set("wireless5G_macfilter", filter, "filter_action", filter_act)
		end

		--mac address
                local MacAddr
                local Mac_field
                local MacAddr_old
                for i=1,32 do
                        Mac_field="MacAddr"..i
                        MacAddr_old = uci:get("wireless5G_macfilter", filter, Mac_field)
                        MacAddr = luci.http.formvalue(Mac_field)
                        if not ( MacAddr == MacAddr_old ) then

                                changed = 1
                                uci:set("wireless5G_macfilter", filter, Mac_field, MacAddr)
                        end
                end

		--new value need to be saved
		if (changed == 1) then
			local iface_reset="ath1"..select_ap
			local iface
			local iface_filter
			for i=0,3 do
				iface="ath1"..i
				iface_filter="general"..i
				if (iface == iface_reset) then
					uci:set("wireless5G_macfilter", iface_filter, "reset", "1")
				else
					uci:set("wireless5G_macfilter", iface_filter, "reset", "0")
				end
			end
			uci:commit("wireless5G_macfilter")
			uci:apply("wireless5G_macfilter")
		end
		if (MACfilter_ON == "1") then
			uci:set("wps5G","wps","enabled","0")
			uci:commit("wps5G")
			sys.exec("echo wifi1 >/tmp/WirelessDev")
			uci:apply("wireless")
		end
	end
	luci.template.render("expert_configuration/wlanmacfilter5G",{filter_iface=filter, ap=select_ap})	
end

function wlan_advanced_5G()
	local apply = luci.http.formvalue("sysSubmit")
	local changed = 0
	local wireless_mode = uci:get("wireless", "wifi1", "hwmode")
	local RTS_Set
	local Frag_Set

        if ( wireless_mode == "11an" or  wireless_mode == "11ac" ) then
			uci:set("wireless", "ath10", "rts",2346)
			uci:set("wireless", "ath10", "frag",2346)
			uci:commit("wireless")
			RTS_Set="disabled"
			Frag_Set="disabled"
        end

	if apply then
--rts_Threshold
		local rts_Threshold = luci.http.formvalue("rts_Threshold")
		local rts_Threshold_old = uci:get("wireless", "ath10","rts")
		if not (rts_Threshold) then
			changed = 1
			uci:set("wireless", "ath10","rts", "2354")
		else
			if not (rts_Threshold == rts_Threshold_old) then
			changed = 1
			uci:set("wireless", "ath10","rts", rts_Threshold)
			end
		end
--fr_threshold		
		local fr_threshold = luci.http.formvalue("fr_threshold")
		local fr_threshold_old = uci:get("wireless", "ath10","frag")
		if not (fr_threshold) then
			changed = 1
			uci:set("wireless", "ath10","frag", "2354")
		else
			if not (fr_threshold == fr_threshold_old) then
			changed = 1
			uci:set("wireless", "ath10","frag", fr_threshold)
			end
		end
--Intra-BSS Traffic
		local IntraBSS_state = luci.http.formvalue("IntraBSS_state")
		local IntraBSS_state_old = uci:get("wireless", "ath10","IntraBSS")
		if not (IntraBSS_state) then
			changed = 1
			uci:set("wireless", "ath10","IntraBSS", "0")
		else
			if not (IntraBSS_state == IntraBSS_state_old) then
			changed = 1
			uci:set("wireless", "ath10","IntraBSS", IntraBSS_state)
			end
		end
--tx power
		local txPower = luci.http.formvalue("TxPower_value")
		local txPower_old = uci:get("wireless", "wifi1", "txpower")
		if not (txPower) then
			changed = 1
			uci:set("wireless", "wifi1", "txpower","100")
		else
			if not (txPower == txPower_old) then 
			changed = 1
			uci:set("wireless", "wifi1", "txpower",txPower)
			end
		end
		if (changed == 1) then
			uci:commit("wireless")
			sys.exec("echo wifi1 >/tmp/WirelessDev")
			uci:apply("wireless")
		end
	end	

	luci.template.render("expert_configuration/wlanadvanced5G",{rts_set=RTS_Set, frag_set=Frag_Set})	
end

function wlan_qos_5G()
	local apply = luci.http.formvalue("sysSubmit")
	local wireless_mode = uci:get("wireless", "wifi1", "hwmode")
	local WMM_Choose
	if ( wireless_mode == "11an" or wireless_mode == "11ac"  ) then
		uci:set("wireless", "ath10", "wmm",1)
		uci:commit("wireless")
		WMM_Choose="disabled"
	end
	if apply then
		local wmm_enable = luci.http.formvalue("WMM_QoS")
		if (wmm_enable == "1") then
			uci:set("wireless", "ath10","wmm", wmm_enable)
		elseif (wmm_enable == "0") then
			uci:set("wireless", "ath10","wmm", wmm_enable)		
		end
		uci:commit("wireless")
		sys.exec("echo wifi1 >/tmp/WirelessDev")
		uci:apply("wireless")
	end
	luci.template.render("expert_configuration/wlanqos5G", {wmm_choice=WMM_Choose})	
end

function wlan_wps_5G()
	require("luci.model.uci")
	local releaseConf = luci.http.formvalue("Release")
	local genPin = luci.http.formvalue("Generate")
	local pincode = uci:get("wps5G","wps","appin")
	local apply = luci.http.formvalue("sysSubmit")
	local wps_enable = uci:get("wps5G","wps","enabled")
	local wps_choice = luci.http.formvalue("wps_function")
	local wps_set
	local pincode_enable = uci:get("wps5G","wps","PinEnable")
	local pincode_choice = luci.http.formvalue("pincode_function")
	local pincode_set
	local wps_change
	local wps_chk -- +
	local configured
	local apssid
	local radiomode
	local authmode
	local securemode
	local config_status
	local configfile
	local wps_enable_choose
	local security_mode

	local WPAPSKCompatible_5G = uci.get("wireless", "ath10", "WPAPSKCompatible")
    local WPACompatible_5G = uci.get("wireless", "ath10", "WPACompatible")
	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi1/ -i ath10 " -- +

	security_mode=uci:get("wireless","ath10","auth")

	if( security_mode=="WEPAUTO" or security_mode=="SHARED" or security_mode=="WPA" or security_mode=="WPA2" ) then
		wps_enable_choose="disabled"
	end

	if releaseConf then
		uci:set("wps5G","wps","conf",0)
		uci:commit("wps5G")
--		sys.exec("iwpriv ra0 set WscConfStatus=1")    -
		sys.exec("echo wifi1 >/tmp/WirelessDev")
		uci:apply("wireless")  -- +
		-- Re-generate the pin code when release configuration
		if(pincode_enable=="1") then
			pincode=sys.exec(hstapd_cli .. "wps_ap_pin random" )
			uci:set("wps5G","wps","appin",pincode)
			uci:commit("wps5G")
		end
		sys.exec("wps5G ath10 on")		
	end

	sys.exec(hstapd_cli .. "get_config" .. "" ..  "> /tmp/wps5G_config")
	configfile = io.open("/tmp/wps5G_config", "r")

	local tmp = configfile:read("*all")
	configfile:close()
	
	configured = tmp:match("wps_state=(%a+)")

	if ( configured == "configured" ) then
--		uci:set("wps5G","wps","conf",1)
--		uci:commit("wps5G")

		apssid = uci:get("wireless","ath10","ssid")
		radiomode = uci:get("wireless","wifi1","hwmode")
		radiomode = "802."..radiomode
		authmode = uci:get("wireless","ath10","encryption")

		if not apssid then
			local mac_5g=luci.sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12")
			local mac_ssid=string.match( mac_5g,"%x+")
			apssid="ZyXEL" .. mac_ssid .."5G"
		end
		
		if authmode == "WPAPSK" then
			securemode="WPA-PSK"
		elseif authmode == "WPA2PSK" then
		-- add by darren 2012.03.07
			if WPAPSKCompatible_5G == "0" then
				securemode="WPA2-PSK"
			elseif WPAPSKCompatible_5G == "1" then
				securemode="WPA-PSK / WPA2-PSK"
			end
                --
		elseif authmode == "WEPAUTO" or authmode == "SHARED" then
			securemode="WEP"
		elseif authmode == "NONE" then
			securemode="No Security"
		elseif authmode == "WPAPSKWPA2PSK" then
			securemode="WPA2-PSK"
		-- add by darren 2012.03.07
		elseif authmode == "WPA2" then
			if WPACompatible_5G == "0" then
				securemode=authmode
			elseif WPACompatible_5G == "1" then
				securemode="WPA / WPA2"
			end

		else
			securemode=authmode
		end

		config_status="Configured"
	else
		config_status="Unconfigured"
	end
	--Generate a new vendor pin code
	if genPin then
		pincode=sys.exec(hstapd_cli .. "wps_ap_pin random" )
		uci:set("wps5G","wps","appin",pincode)
		uci:commit("wps5G")
		sys.exec("wps5G ath10 on")
	end
	--Variable "wps_set" will be used in the GUI
	if (wps_enable == "1") then
		wps_set="enabled"
	elseif (wps_enable == "0") then
		wps_set="disabled"
	end

	--Variable "pincode_set" will be used in the GUI
        if (pincode_enable == "1") then
                pincode_set="enabled"
        elseif (pincode_enable == "0") then
                pincode_set="disabled"
        end

	if apply then

		wlan_btn=sys.exec("cat /tmp/wlan_on | tr -d '\n'")
		if (wlan_btn == "0") then

			if not(pincode_choice == nil) then
				uci:set("wps5G","wps", "PinEnable", pincode_choice)
				if (pincode_choice == "1") then
					pincode_set="enabled"
				else
					pincode_set="disabled"
				end
			end

			uci:set("wps5G","wps", "enabled", wps_choice)
			if (wps_choice == "1") then
				wps_set="enabled"
			else
				wps_set="disabled"
			end			
			uci:commit("wps5G")

		else

			if (wps_choice == "1") then
				config_status="Configured"
				apssid = uci:get("wireless","ath10","ssid")
				radiomode = uci:get("wireless","wifi1","hwmode")
				radiomode = "802."..radiomode
				authmode = uci:get("wireless","ath10","encryption")
				if not apssid then
					local mac_5g=luci.sys.exec("fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12")
					local mac_ssid=string.match( mac_5g,"%x+")
					apssid="ZyXEL" .. mac_ssid .."5G"
				end

				if authmode == "WPAPSK" then
					securemode="WPA-PSK"
				elseif authmode == "WPA2PSK" then
				-- add by darren 2012.03.07
					if WPAPSKCompatible_5G == "0" then
						securemode="WPA2-PSK"
					elseif WPAPSKCompatible_5G == "1" then
						securemode="WPA-PSK / WPA2-PSK"
					end
				--
				elseif authmode == "WEPAUTO" or authmode == "SHARED" then
					securemode="WEP"
				elseif authmode == "NONE" then
					securemode="No Security"
				elseif authmode == "WPAPSKWPA2PSK" then
					securemode="WPA2-PSK"
				-- add by darren 2012.03.07
				elseif authmode == "WPA2" then
					if WPACompatible_5G == "0" then
						securemode=authmode
					elseif WPACompatible_5G == "1" then
						securemode="WPA / WPA2"
					end
				--                
				else
					securemode=authmode
				end	


				if (wps_enable == "0") then --From disable wps to enable wps
					wps_chk="1"
					if (pincode_enable == "1") then
						pincode_enable=1
						pincode_set="enabled"
						wps_change = true

					elseif (pincode_enable == "0") then --PIN-code disable
						incode_enable=0
						pincode_set="disabled"
						wps_change = true
					end
				elseif(wps_enable == "1") then
					if (pincode_choice == "1") then
						if (pincode_enable == "0") then --From disable PIN-code to enable PIN-code
							pincode_enable=1
							pincode_set="enabled"
							wps_change = true
						end
					elseif (pincode_choice == "0") then --From enable PIN-code to disable PIN-code
						if (pincode_enable == "1") then
							pincode_enable=0
							pincode_set="disabled"
							wps_change = true
						end
					end
				end
			
				if wps_change then
					wps_enable=1
					wps_set="enabled"
					uci:set("wps5G","wps", "PinEnable", pincode_enable)
					uci:set("wps5G","wps", "enabled", wps_enable)
					uci:commit("wps5G")
					if (wps_chk == "1") then
						sys.exec("echo wifi1 >/tmp/WirelessDev")
						uci:apply("wireless")
					end
				end

				sys.exec("wps5G ath10 on")

			elseif (wps_choice == "0") then --From enable wps to disable wps
				config_status="Unconfigured"
				radiomode = " "
				apssid = " "
				securemode = " "

				if (wps_enable == "1") then
		            wps_chk="1"
				end
				wps_enable=0
				wps_set="disabled"

				uci:set("wps5G","wps", "PinEnable", pincode_enable)
				uci:set("wps5G","wps", "enabled", wps_enable)
				uci:commit("wps5G")

				if (wps_chk == "1") then
					sys.exec("echo wifi1 >/tmp/WirelessDev")
					uci:apply("wireless")
				end

				sys.exec("wps5G ath10 off")
			end

			local configuredx = uci:get("wps5G","wps","conf")
			if (configuredx == "0") then
				config_status="Unconfigured"
				radiomode = " "
				apssid = " "
				securemode = " "
			end

		end
	end

	luci.template.render("expert_configuration/wlanwps5G", {AP_PIN = pincode,
								SSID = apssid,
								RadioMode = radiomode,
								SecureMode = securemode,
								ConfigStatus = config_status,
								WPS_Enabled = wps_set,
								WPS_Enabled_Choose = wps_enable_choose,
								PINCode5G_Enabled = pincode_set})
end

function wlanwpsstation_5G()
	local wps_enable = uci:get("wps5G","wps","enabled")
	local wps_set
	local enable_wps_btn = luci.http.formvalue("wps_button")
	local enable_wps_pin = luci.http.formvalue("wps_pin")
	local PinWords_invalid = luci.http.formvalue("PinWords_invalid")	
	local configured = uci:get("wps5G","wps","conf")
	local config_status
	local valid = 1
	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi1/ -i ath10 "
	--Variable "wps_set" will be used in the GUI
	if (wps_enable == "1") then
		wps_set="enabled"
	elseif (wps_enable == "0") then
		wps_set="disabled"
	end

--	if (configured == "1") then
--		config_status = "conf"
--	else
--		config_status = "unconf"
--	end

	local fd
	if enable_wps_btn then
		sys.exec("killall -9 wps5G")
		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
		fd = io.popen("wps5G ath10 on wps_btn &")
		sys.exec("rm /tmp/pbc_overlap")
		sys.exec("rm /tmp/wps_success")
		sys.exec("rm /tmp/wps_timeout")
		for i=1,120 do
			sys.exec("sleep 1")
			if io.open( "/tmp/pbc_overlap", "r" ) then
				valid = 2
				sys.exec("killall wps5G")
				sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				break;
			end
			if io.open( "/tmp/wps_success", "r" ) then
				valid = 4
				sys.exec("killall wps5G")
				sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				break;
			end
			if io.open( "/tmp/wps_timeout", "r" ) then
				valid = 3
				sys.exec("killall wps5G")
				sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				break;
			end
		end
		luci.template.render("expert_configuration/wlanwpsstation5G",{WPS_Enabled = wps_set, pin_valid = valid})
		return
	end

	if enable_wps_pin then
		local pincode
		local pin_verify
		pincode = luci.http.formvalue("wps_pincode")
		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
		end
		pin_verify = sys.exec(hstapd_cli .. "wps_check_pin " .. pincode)

		if ( pin_verify == pincode ) then
			sys.exec("killall -9 wps5G")
			sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
			fd = io.popen("wps5G ath10 on wps_pin ".. pincode .. " &")
		else
			luci.template.render("expert_configuration/wlanwpsstation5G",{WPS_Enabled = wps_set, pin_valid = 0})
			return
		end
	end

	luci.template.render("expert_configuration/wlanwpsstation5G",{WPS_Enabled = wps_set, pin_valid = 1})
end

function wlanscheduling_5G()
	local apply = luci.http.formvalue("sysSubmit")

	if apply then
		uci:set("wifi_schedule5G", "wlan", "enabled", luci.http.formvalue("WLanSch5GRadio"))

		local schedulingNames = { "Everyday", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }

		for i, name in ipairs(schedulingNames) do
			local prefixStr = "WLanSch5G" .. name
			local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)

			uci:set("wifi_schedule5G", token, "status_onoff", luci.http.formvalue(prefixStr .. "Radio"))
			uci:set("wifi_schedule5G", token, "start_hour",   luci.http.formvalue(prefixStr .. "StartHour"))
			uci:set("wifi_schedule5G", token, "start_min",    luci.http.formvalue(prefixStr .. "StartMin"))
			uci:set("wifi_schedule5G", token, "end_hour",     luci.http.formvalue(prefixStr .. "EndHour"))
			uci:set("wifi_schedule5G", token, "end_min",      luci.http.formvalue(prefixStr .. "EndMin"))

			if "on" == luci.http.formvalue(prefixStr .. "Enabled") then
				uci:set("wifi_schedule5G", token, "enabled", "1")
			else
				uci:set("wifi_schedule5G", token, "enabled", "0")
			end
		end

		uci:commit("wifi_schedule5G")
		uci:apply("wifi_schedule5G")
	end
	luci.template.render("expert_configuration/wlanscheduling5G")	
end
--sendoh

--benson vpn
function action_vpn()
	local apply = luci.http.formvalue("sysSubmit")
	local netbios_allow = luci.http.formvalue("IPSecPassThrough")
	if apply then
		
		if not netbios_allow then
			netbios_allow="disable"
		else 
			netbios_allow="enable"
		end
		
		uci:set("ipsec_new","general",'netbiosAllow',netbios_allow)
		uci:commit("ipsec_new")
		uci:apply("ipsec_new")
	end
	luci.template.render("expert_configuration/vpn")
end

function action_samonitor()
        local remote_gw_ip
        local rule_status = {"","","","",""}
	local roadwarrior = {"0","0","0","0","0"}
	local record_number
	local rules
	local key_mode

	--for roadwarrior case
	record_number = luci.sys.exec("racoonctl show-sa isakmp | wc -l | awk '{printf $1}'")
	record_number = tonumber(record_number)
	record_number = record_number - 1

	for i=1,5 do
		rules="rule"..i
		key_mode = uci:get("ipsec", rules, "keyMode")
		remote_gw_ip = uci:get("ipsec", rules, "remote_gw_ip")
		if key_mode == "IKE" then
			if remote_gw_ip then
				if remote_gw_ip == "0.0.0.0" then
					roadwarrior[i]="1"
				else
					rule_status[i] = luci.sys.exec("racoonctl show-sa isakmp | grep -c "..remote_gw_ip)
					if ( rule_status[i] == "" ) then
						rule_status[i]="0"
					else
						--not roadwarrior case
						record_number = record_number - 1
					end
				end
			else
				rule_status[i]="0"
			end
		else
			rule_status[i]="0"
		end
	end

	--temporary method
        for i=1,5 do
                if roadwarrior[i] == "1" then
                        if record_number == 0 then
				rule_status[i]="0"
			else
                                rule_status[i]="1"
                        end
                end
        end	

	luci.template.render("expert_configuration/samonitor", {status_r1 = rule_status[1],
								status_r2 = rule_status[2],
								status_r3 = rule_status[3],
								status_r4 = rule_status[4],
								status_r5 = rule_status[5]})
end

function action_vpnEdit()
	local apply = luci.http.formvalue("sysSubmit")
	local rules = luci.http.formvalue("rules")
	local edit = luci.http.formvalue("edit")
	local delete = luci.http.formvalue("delete")

	if apply then
		local statusEnable = luci.http.formvalue("ssid_state")
		local IPSecKeepAlive = luci.http.formvalue("IPSecKeepAlive")

		if not IPSecKeepAlive then
			IPSecKeepAlive="off"
		end
		local IPSecNatTraversal = luci.http.formvalue("IPSecNatTraversal")
	
		if not IPSecNatTraversal then
			IPSecNatTraversal="off"
		end
	
		local s1 = luci.http.formvalue("keyModeSelect")
		local keyModeSelect

		if s1 == "00000000" then
			 keyModeSelect="IKE"
		else
			 keyModeSelect="manual"
		end
		
		local LocalAddrType = luci.http.formvalue("LocalAddressTypeSelect")
		local RemoteAddrType = luci.http.formvalue("RemoteAddressTypeSelect")
		local IPSecSourceAddrStart = luci.http.formvalue("IPSecSourceAddrStart")
		local IPSecSourceAddrMask = luci.http.formvalue("IPSecSourceAddrMask")
		local IPSecDestAddrStart = luci.http.formvalue("IPSecDestAddrStart")
		local IPSecDestAddrMask = luci.http.formvalue("IPSecDestAddrMask")
		local localPublicIP = luci.http.formvalue("localPublicIP")
		local s2 = luci.http.formvalue("localContentSelect")
		local localContentSelect

		if s2 == "00000000" then
			localContentSelect="address"
		elseif s2 == "00000001" then
			localContentSelect="fqdn"
		else
			localContentSelect="user_fqdn"
		end

		local localContent = luci.http.formvalue("localContent")
		local remotePublicIP = luci.http.formvalue("remotePublicIP")
		local s3 = luci.http.formvalue("remoteContentSelect")
		local remoteContentSelect

		if s3 == "00000000" then
			 remoteContentSelect="address"
		elseif s3 == "00000001" then
			 remoteContentSelect="fqdn"
		else
			 remoteContentSelect="user_fqdn"
		end

		local remoteContent = luci.http.formvalue("remoteContent")
		local IPSecPreSharedKey = luci.http.formvalue("IPSecPreSharedKey")
		local s8 = luci.http.formvalue("modeSelect")
		local modeSelect

		if s8 == "00000000" then
			modeSelect="main"
		elseif s8 == "00000001" then
			modeSelect="aggressive"
		else
			modeSelect="main, aggressive"
		end

		local authKey = luci.http.formvalue("authKey")
		local IPSecSPI = luci.http.formvalue("IPSecSPI")
		local s6 = luci.http.formvalue("encapAlgSelect")
		local encapAlgSelect

		if s6 == "00000000" then
			 encapAlgSelect="des-cbc"	
		else
			 encapAlgSelect="3des-cbc"
		end
	
		local encrypKey = luci.http.formvalue("encrypKey")
		local s7 = luci.http.formvalue("authAlgSelect")
		local authAlgSelect
		
		if s7 == "00000000" then
			 authAlgSelect="hmac-md5"
		else
			 authAlgSelect="hmac-sha1"
		end

		local authKey = luci.http.formvalue("authKey")
		local saLifeTime = luci.http.formvalue("saLifeTime")
		local s9 = luci.http.formvalue("keyGroup")
		local keyGroup
		
		if s9 == "00000000" then
			 keyGroup="modp768"
		else
			 keyGroup="modp1024"
		end
	
		local s4 = luci.http.formvalue("encapModeSelect")
		local encapModeSelect
		
		if s4 == "00000000" then
			 encapModeSelect="tunnel"
		else
			 encapModeSelect="transport"
		end
	
		local s5 = luci.http.formvalue("protocolSelect")
		local protocolSelect
		
		if s5 == "00000000" then
			 protocolSelect="esp"
		else
			 protocolSelect="ah"
		end

		local s10 = luci.http.formvalue("encapAlgSelect2")
		local encapAlgSelect2
		
		if s10 == "00000000" then
			 encapAlgSelect2="des-cbc"
		else
			 encapAlgSelect2="3des-cbc"
		end
	
		local s11 = luci.http.formvalue("authAlgSelect2")
		local authAlgSelect2
	
		if s11 == "00000000" then
			 authAlgSelect2="hmac-md5"
		else
			 authAlgSelect2="hmac-sha1"
		end

		local saLifeTime2 = luci.http.formvalue("saLifeTime2")
		local s11 = luci.http.formvalue("keyGroup2")
		local keyGroup2
		
		if s11 == "00000000" then
			keyGroup2="modp768"
		else
			keyGroup2="modp1024"
		end

	        uci:set("ipsec",rules,"ipsec")

		if LocalAddrType == "1" then
			uci:set("ipsec",rules,"LocalAddrType","1")
			uci:set("ipsec",rules,'localNetMask',IPSecSourceAddrMask)
		else
			uci:set("ipsec",rules,"LocalAddrType","0")
			uci:set("ipsec",rules,'localNetMask',"255.255.255.255")
		end

		if RemoteAddrType == "1" then
			uci:set("ipsec",rules,"RemoteAddrType","1")
			uci:set("ipsec",rules,"peerNetMask",IPSecDestAddrMask)
		else
			uci:set("ipsec",rules,"RemoteAddrType","0")
			uci:set("ipsec",rules,"peerNetMask","255.255.255.255")
		end

                uci:set("ipsec",rules,'statusEnable',statusEnable)
                uci:set("ipsec",rules,'KeepAlive',IPSecKeepAlive)
                uci:set("ipsec",rules,'NatTraversal',IPSecNatTraversal)
                uci:set("ipsec",rules,'keyMode',keyModeSelect)
                uci:set("ipsec",rules,'localIP',IPSecSourceAddrStart)
                --uci:set("ipsec",rules,'localNetMask',IPSecSourceAddrMask)
                uci:set("ipsec",rules,'peerIP',IPSecDestAddrStart)
                --uci:set("ipsec",rules,'peerNetMask',IPSecDestAddrMask)
                uci:set("ipsec",rules,'localGwIP',localPublicIP)
                uci:set("ipsec",rules,'my_identifier_type',localContentSelect)
                uci:set("ipsec",rules,'my_identifier',localContent)
                uci:set("ipsec",rules,'remoteGwIP',remotePublicIP)
                uci:set("ipsec",rules,'peers_identifier_type',remoteContentSelect)
                uci:set("ipsec",rules,'peers_identifier',remoteContent)
                uci:set("ipsec",rules,'preSharedKey',IPSecPreSharedKey)
                uci:set("ipsec",rules,'mode',modeSelect)
                uci:set("ipsec",rules,'spi',IPSecSPI)
                uci:set("ipsec",rules,'enAlgo',encapAlgSelect)
                uci:set("ipsec",rules,'enKey',encrypKey)
                uci:set("ipsec",rules,'authAlgo',authAlgSelect)
                uci:set("ipsec",rules,'authKey',authKey)
                uci:set("ipsec",rules,'lifeTime',saLifeTime)
                uci:set("ipsec",rules,'keyGroup',keyGroup)
		uci:set("ipsec",rules,'enMode',encapModeSelect)
                uci:set("ipsec",rules,'protocol',protocolSelect)
		uci:set("ipsec",rules,'enAlgo2',encapAlgSelect2)
		uci:set("ipsec",rules,'authAlgo2',authAlgSelect2)
		uci:set("ipsec",rules,'lifeTime2',saLifeTime2)
                uci:set("ipsec",rules,'keyGroup2',keyGroup2)
                uci:commit("ipsec")
                uci:apply("ipsec")

		luci.template.render("expert_configuration/vpn")
		return
	end --end apply

	if edit then
		local rules = edit
                local stEnable = uci:get("ipsec",rules,'statusEnable')
                local KeepAlive = uci:get("ipsec",rules,'KeepAlive')
                local NatTraversal = uci:get("ipsec",rules,'NatTraversal')
                local keyMode = uci:get("ipsec",rules,'keyMode')
                local localIP = uci:get("ipsec",rules,'localIP')
                local localNetMask = uci:get("ipsec",rules,'localNetMask')
                local peerIP = uci:get("ipsec",rules,'peerIP')
                local peerNetMask = uci:get("ipsec",rules,'peerNetMask')
                local localGwIP = uci:get("ipsec",rules,'localGwIP')
                local my_identifier_type = uci:get("ipsec",rules,'my_identifier_type')
                local my_identifier = uci:get("ipsec",rules,'my_identifier')
                local remoteGwIP = uci:get("ipsec",rules,'remoteGwIP')
                local peers_identifier_type = uci:get("ipsec",rules,'peers_identifier_type')
                local peers_identifier = uci:get("ipsec",rules,'peers_identifier')
                local preSharedKey = uci:get("ipsec",rules,'preSharedKey')
                local mode = uci:get("ipsec",rules,'mode')
                local spi = uci:get("ipsec",rules,'spi')
                local enAlgo = uci:get("ipsec",rules,'enAlgo')
                local enKeyy = uci:get("ipsec",rules,'enKey')
                local authAlgo = uci:get("ipsec",rules,'authAlgo')
                local authKeyy = uci:get("ipsec",rules,'authKey')
                local lifeTime = uci:get("ipsec",rules,'lifeTime')
                local keyyGroup = uci:get("ipsec",rules,'keyGroup')
		local enMode = uci:get("ipsec",rules,'enMode')
                local protocol = uci:get("ipsec",rules,'protocol')
		local enAlgo2 = uci:get("ipsec",rules,'enAlgo2')
		local authAlgo2 = uci:get("ipsec",rules,'authAlgo2')
		local lifeTime2 = uci:get("ipsec",rules,'lifeTime2')
                local keyyGroup2 = uci:get("ipsec",rules,'keyGroup2')
		local url = luci.dispatcher.build_url("expert","configuration","security","vpn","vpn_edit")
          	local paramStr = ""
          	
          	if stEnable then 	paramStr=paramStr .. "&stEnable=" .. stEnable end
          	if KeepAlive then 	paramStr=paramStr .. "&KeepAlive=" .. KeepAlive end
          	if NatTraversal then 	paramStr=paramStr .. "&NatTraversal=" .. NatTraversal end
		if keyMode then 	paramStr=paramStr .. "&keyMode=" .. keyMode end
		if localIP then 	paramStr=paramStr .. "&localIP=" .. localIP end
		if localNetMask then 	paramStr=paramStr .. "&localNetMask=" .. localNetMask end
		if peerIP then 	paramStr=paramStr .. "&peerIP=" .. peerIP end
		if peerNetMask then 	paramStr=paramStr .. "&peerNetMask=" .. peerNetMask end
		if localGwIP then 	paramStr=paramStr .. "&localGwIP=" .. localGwIP end
		if my_identifier_type then 	paramStr=paramStr .. "&my_identifier_type=" .. my_identifier_type end
		if my_identifier then 	paramStr=paramStr .. "&my_identifier=" .. my_identifier end
		if remoteGwIP then 	paramStr=paramStr .. "&remoteGwIP=" .. remoteGwIP end
		if peers_identifier_type then 	paramStr=paramStr .. "&peers_identifier_type=" .. peers_identifier_type end
		if peers_identifier then 	paramStr=paramStr .. "&peers_identifier=" .. peers_identifier end
		if preSharedKey then 	paramStr=paramStr .. "&preSharedKey=" .. preSharedKey end
		if mode then 	paramStr=paramStr .. "&mode=" .. mode end
		if spi then 	paramStr=paramStr .. "&spi=" .. spi end
		if enAlgo then 	paramStr=paramStr .. "&enAlgo=" .. enAlgo end
		if enKeyy then 	paramStr=paramStr .. "&enKeyy=" .. enKeyy end
		if authAlgo then 	paramStr=paramStr .. "&authAlgo=" .. authAlgo end
		if authKeyy then 	paramStr=paramStr .. "&authKeyy=" .. authKeyy end
		if lifeTime then 	paramStr=paramStr .. "&lifeTime=" .. lifeTime end
		if keyyGroup then 	paramStr=paramStr .. "&keyyGroup=" .. keyyGroup end
		if enMode then 	paramStr=paramStr .. "&enMode=" .. enMode end
		if protocol then 	paramStr=paramStr .. "&protocol=" .. protocol end
		if enAlgo2 then 	paramStr=paramStr .. "&enAlgo2=" .. enAlgo2 end
		if authAlgo2 then 	paramStr=paramStr .. "&authAlgo2=" .. authAlgo2 end
		if lifeTime2 then 	paramStr=paramStr .. "&lifeTime2=" .. lifeTime2 end
		if keyyGroup2 then 	paramStr=paramStr .. "&keyyGroup2=" .. keyyGroup2 end
		
		luci.http.redirect(url .. "?" .. "rules=" .. rules  .. paramStr)
		
		return
	end --end edit
	
	if delete then
		local rules2 = delete
	
		uci:delete("ipsec", rules2)
		uci:commit("ipsec")
		uci:apply("ipsec")
	
		luci.template.render("expert_configuration/vpn")
		return
	end
	luci.template.render("expert_configuration/vpn_edit")
end
--benson vpn

function action_int_grouping()
        
        local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
        local submitType = luci.http.formvalue("IGSubmitType")

	if apply then
		sys.exec("/bin/intfGrp_opt60 reset_group_all")

		if "edit" == submitType then
	                local editID = luci.http.formvalue("IGEditID")
			local Groupifname = luci.http.formvalue("group_name")
                        local grouped_wan = luci.http.formvalue("wan_select")

                        local available = luci.http.formvalue("Grouped_available")
                        local available_wlan = luci.http.formvalue("Grouped_available_wlan")
			
                        -- Check the available value is nil or not.
                        if ( "" == available ) then
                          available = " "
                        end

                        if ( "" ==  available_wlan ) then
                          available_wlan = " "
                        end

			local grouped_ports = luci.http.formvalue("Grouped_ports")
                        local grouped_wlan = luci.http.formvalue("Grouped_wlan")
                        --local grouped_vlan  = luci.http.formvalue("Grouped_vlan")                     
                        --local grouped_vlan_name  = uci:get("network",grouped_vlan,"ifname")
			local entryName = nil


			if "New" == editID then
                              -- Prepare to create new interface data Model
				wan_int = uci:get("network", grouped_wan, "ifname")
				editID = uci:get("intfGrp", "general", "group_count") + 3
				uci:set("intfGrp", "general", "group_count", editID -2 )
				wan_proto = uci:get("network", grouped_wan, "proto")

				-- get vlan id and then Create local vlan automatically 
				-- example: if Group2 not create yet, then the vid is 2. 
				for i = 4,7 do
				   vid_str = uci:get("intfGrp", "Group" .. i, "vlan")
				   if ( nil == vid_str ) then
						 entryName = "Group" .. i
						 uci:set("intfGrp", entryName, "interface")
						 vlan_vid = i
						 break
				   end
				end
				
            else
                                -- // interface Group can't be modified, just allowed Delete. 
                                --entryName = editID
				--uci:set("network", ifname, "edit", "1")
				--uci:set("network", entryName, "ifname_old", uci:get("network", entryName, "ifname"))
				--uci:set("network", entryName, "priority_old", uci:get("network", entryName, "priority"))
				--uci:set("network", entryName, "vid_old", uci:get("network", entryName, "vid"))
				--uci:set("network", entryName, "status_old", uci:get("network", entryName, "status"))
			end


                        -- if wan_proto is bridge, no vlan interface and dhcp server                       
--[[                        if "bridge" == wan_proto then
                        
                          entryName = "Group"..vlan_vid
                          -- Create interface data model
                          uci:set("intfGrp", entryName, "ifname" ,Groupifname)
                          uci:set("intfGrp", entryName, "wanint", grouped_wan)
                          uci:set("intfGrp", entryName, "vlanid", vlan_vid)

                          wan_vid = uci:get("network", grouped_wan, "vid")
                          vlan_tag_flag = uci:get("network",grouped_wan,"untag")
                          uci:set("network",grouped_wan,"grouped","1")

                          -- Handle Grouping ethernet ports
                          if not ( "" == Grouped_ports ) then 
                              uci:set("intfGrp", entryName, "lanport", grouped_ports)
                              uci:set("intfGrp", "general", "available", available)
                              uci:set("intfGrp", "Default", "lanport", available)
                              uci:set("intfGrp", entryName, "wlan", "")
                              uci:set("intfGrp", entryName, "vlan_tag", vlan_tag_flag)                         
                              
                              -- Ignore tag from lan or not. 
                              --if "1" == vlan_tag_flag then
                                --sys.exec("/bin/configure_vlan vlan_port "..wan_vid.." \""..grouped_ports.."\" 1 1")
                              --else
                                --sys.exec("/bin/configure_vlan vlan_port "..wan_vid.." \""..grouped_ports.."\" 1 0")
                              --end 
                          
                              --if not ( "" == available ) then
                                --sys.exec("/bin/configure_vlan vlan_port 20 ".."\""..available.."\" 0 1")
                              --end
                          else
                            uci:set("intfGrp", entryName, "lanport", " ")
                          end

                          -- Handle Grouping wlan interface
                          if not ( "" == grouped_wlan ) then
                              uci:set("intfGrp", entryName, "wlan", grouped_wlan)
                              uci:set("intfGrp", "Default", "wlan", available_wlan)
                              --sys.exec("/bin/configure_vlan wlan br-lan "..grouped_wlan)
                          else
                              uci:set("intfGrp", entryName, "wlan", " ")
                          end

                          
                          uci:save("network")
                          uci:commit("network")

                        else
]]--
                          -- *************  Routing mode START *******************
                          -- Create new vlan interface and dhcp server for route mode.
                          uci:set("network", "general", "vlan_count", vlan_vid -2)
                          uci:set("network",grouped_wan,"grouped","1")
                          entryName = "vlanth" .. vlan_vid
                          uci:set("network", entryName, "interface")

                          uci:set("network", entryName, "ifname" ,"vlan"..vlan_vid)
                          uci:set("network", entryName, "vlanname" ,"vlan"..vlan_vid)
                          uci:set("network", entryName, "vid", vlan_vid)
                          uci:set("network", entryName, "priority", "0")
                          uci:set("network", entryName, "type", "bridge")
                          uci:set("network", entryName, "proto", "static")

                          uci:set("network", entryName, "ipaddr", "192.168."..vlan_vid..".1")
                          uci:set("network", entryName, "netmask", "255.255.255.0")
                          uci:set("network", entryName, "stp", "0")
                          uci:set("network", entryName, "dns1", "ISP")
                          uci:set("network", entryName, "dns2", "ISP")
                          uci:set("network", entryName, "dns3", "ISP")
                          uci:set("network", entryName, "status", 1)

                          local vlan_int = "vlan"..vlan_vid
                          --sys.exec("/bin/configure_vlan add "..vlan_vid.." "..vlan_int)

                          -- Create DHCP interface
                          uci:set("dhcp", entryName, "dhcp")
                          uci:set("dhcp", entryName, "enabled", "1")
                          uci:set("dhcp", entryName, "interface", entryName)
                          uci:set("dhcp", entryName, "start", "2")
                          uci:set("dhcp", entryName, "limit", "253")
                          uci:set("dhcp", entryName, "lease", "720m")
                          uci:set("dhcp", entryName, "lan_dns", "dnsRelay,FromISP,FromISP")

                          uci:save("dhcp")
                          uci:commit("dhcp")
                          --uci:apply("dhcp")

                          uci:save("network")
                          uci:commit("network")
                          --uci:apply("network")
                          sys.exec("ubus call network reload")

                          --sys.exec("sleep 3")

                        -- *************  Interface Grouping START **************
                        local OP60VIDlist = luci.http.formvalue("OP60VID")

                        entryName = "Group"..vlan_vid
                        -- Create interface data model
                        uci:set("intfGrp", entryName, "ifname" ,Groupifname)
                        uci:set("intfGrp", entryName, "wanint", grouped_wan)
                        uci:set("intfGrp", entryName, "vlan", "vlanth"..vlan_vid)
                        uci:set("intfGrp", entryName, "vlan_name", "vlan"..vlan_vid)
                        uci:set("intfGrp", entryName, "vlanid", vlan_vid)
                        uci:set("intfGrp", entryName, "op60vidlist", OP60VIDlist)
                        uci:set("network", grouped_wan, "bind_LAN", "br-vlanth"..vlan_vid)
                        uci:commit("network")

                        --setup br-vlan interface
                        --sys.exec("/sbin/ifup vlanth"..vlan_vid)                        

                        -- Handle Grouping ethernet ports
                        if not ( "" == Grouped_ports ) then
                           uci:set("intfGrp", entryName, "lanport", grouped_ports)
                           uci:set("intfGrp", "general", "available", available)
                           uci:set("intfGrp", "Default", "lanport", available)                          
                           --sys.exec("/bin/configure_vlan vlan_port "..vlan_vid.." \""..grouped_ports.."\" 0 1") 
            
                           -- GroupING wan and vlan interface
                           local default_gw_ip=uci:get("network", grouped_wan, "isp_gw")
                           --sys.exec("/bin/configure_vlan int_group "..vlan_vid.." "..wan_int.." 192.168."..vlan_vid..".1 "..default_gw_ip)
                           --if not ( "" == available ) then
                               --sys.exec("/bin/configure_vlan vlan_port 20 ".."\""..available.."\" 0 1")
                           --end
                        else
                           uci:set("intfGrp", entryName, "lanport", " ")
                        end
                          
                        -- Handle Grouping wlan interface
                        if not ( "" == grouped_wlan ) then
                              uci:set("intfGrp", entryName, "wlan", grouped_wlan)
                              uci:set("intfGrp", "Default", "wlan", available_wlan)
                              --sys.exec("/bin/configure_vlan wlan br-vlanth" ..vlan_vid.. " " ..grouped_wlan)
                        else
                           uci:set("intfGrp", entryName, "wlan", " ")
                        end 
                        

                --end
            uci:save("intfGrp")
			uci:commit("intfGrp")
			uci:apply("intfGrp")
			sys.exec("wifi up")
			
			local qos_enable=uci:get("qos", "general", "enable")			
			if  "1" == qos_enable  then
				uci:apply("qos")
			end 


		elseif "table" == submitType then


		end

		uci:commit("intfGrp")		
	end
	
	if delete then
		sys.exec("/bin/intfGrp_opt60 reset_group_all")
                local grouped_vlan = uci:get("intfGrp",delete , "vlan")
		local group_table_num = uci:get("intfGrp",delete , "vlanid")
                if ( nil == group_table_num ) then
			luci.template.render("expert_configuration/intfGrp")				
			return;
                end
				
                local wan_entry_name = uci:get("intfGrp",delete , "wanint")
                local group_table_num = uci:get("intfGrp",delete , "vlanid")
                local wan_int = uci:get("network",wan_entry_name , "ifname")
                local wan_proto = uci:get("network", wan_entry_name, "proto")

                -- reset the vlan register and update UCI data
                local ret_ports = uci:get("intfGrp", delete, "lanport")
                local ret_wlan =  uci:get("intfGrp", delete, "wlan")
                local available_ports = uci:get("intfGrp", "Default", "lanport")
                local available_wlan = uci:get("intfGrp", "Default", "wlan")
                
                -- Avoid the nil value when ethernet or wireless interface not be assigned.
                if ( nil == ret_ports ) then
                 ret_ports = ""
                elseif ( nil == ret_wlan ) then 
                 ret_wlan = ""
                end

                uci:set("network",wan_entry_name,"grouped","0")
                uci:commit("network")

		if ( "" ~=  ret_ports ) and ( " " ~=  ret_ports ) and ( "" ~=  available_ports ) and ( " " ~=  available_ports ) then
			uci:set("intfGrp", "Default", "lanport",available_ports..","..ret_ports)
			uci:set("intfGrp", "general", "available",available_ports..","..ret_ports)
		elseif  ( "" ==  ret_ports ) or ( " " ==  ret_ports ) then
			if ( "" ~=  available_ports ) and ( " " ~=  available_ports ) then
			    uci:set("intfGrp", "Default", "lanport",available_ports)
			    uci:set("intfGrp", "general", "available",available_ports)
			end
		elseif  ( "" ==  available_ports ) or ( " " ==  available_ports ) then
			if ( "" ~=  ret_ports ) and ( " " ~=  ret_ports ) then
			    uci:set("intfGrp", "Default", "lanport",ret_ports)
			    uci:set("intfGrp", "general", "available",ret_ports)
			end
		end


		if ( "" ~=  ret_wlan ) and ( " " ~=  ret_wlan ) and ( "" ~=  available_wlan ) and ( " " ~=  available_wlan ) then
			uci:set("intfGrp", "Default", "wlan",available_wlan..","..ret_wlan)
		elseif  ( "" ==  ret_wlan ) or ( " " ==  ret_wlan ) then
			if ( "" ~=  available_wlan ) and ( " " ~=  available_wlan ) then
			    uci:set("intfGrp", "Default", "wlan",available_wlan)
			end
		elseif  ( "" ==  available_wlan ) or ( " " ==  available_wlan ) then
			if ( "" ~=  ret_wlan ) and ( " " ~=  ret_wlan ) then
			    uci:set("intfGrp", "Default", "wlan",ret_wlan)
			end
		end


                local new_available_ports = uci:get("intfGrp", "general", "available")

                sys.exec("/bin/configure_vlan vlan_port ")
                
                -- reset wlan
                sys.exec("/bin/configure_vlan wlan br-lan "..ret_wlan)

                -- reset iproute2 setting
                sys.exec("/bin/configure_vlan del_int_group "..group_table_num.." "..wan_int.." 192.168."..group_table_num..".1")
                 

                if "bridge" == wan_proto then
                     --sys.exec("ifconfig br-"..grouped_vlan.." down")
                     --sys.exec("brctl delif br-"..grouped_vlan.." "..wan_int)
                     --sys.exec("ifconfig br-"..wan_int.." up")                  
                else
                   -- Disable dhcp server on vlan interface
                   uci:delete("dhcp",grouped_vlan)
                   uci:commit("dhcp")
                   --uci:apply("dhcp")
                   
                   -- Delete vlan interface
                   vid = uci:get("network", grouped_vlan, "vid")
                   local vlan_int = "vlan"..vid
                   sys.exec("/bin/configure_vlan delete "..vlan_int)

                   uci:delete("network",grouped_vlan)
                   uci:commit("network")
                   --uci:apply("network")
                   sys.exec("ubus call network reload")
                end

                --sys.exec("/sbin/ifdown "..grouped_vlan)

                uci:set("intfGrp", "general", "group_count" , uci:get("intfGrp", "general", "group_count") - 1)
                uci:delete("intfGrp",delete)
		uci:commit("intfGrp")
		uci:apply("dhcp")
                io.popen("/etc/init.d/default_lan_radvd boot")
                uci:apply("intfGrp")
		sys.exec("wifi up")

		edit_qos_config = "0"
		--check classifity rule of QoS
		uci:foreach( "qos_classify", "class", function( section )
			if (section.fromInt == delete) then
				uci:set("qos_classify",section[ '.name' ], "delete", "1")
				edit_qos_config = "1"
			end
		end )
		
		uci:commit("qos_classify")
		
                if "1" == edit_qos_config then
	               sys.exec("/sbin/configure_qos edit")
                end


		
		--check qos state and reload if enable
		local qos_enable=uci:get("qos", "general", "enable")			
		if "1" == qos_enable then
			uci:apply("qos")
		end 
		
				
				
	end

	
   luci.template.render("expert_configuration/intfGrp")
end

--[[
function action_qos()
	apply = luci.http.formvalue("apply")
	
	if apply then
		local qosEnable = luci.http.formvalue("qosEnable")
		uci:set("qos","general","enable",qosEnable)

		if qosEnable == "0" then
			uci:set("qos","general","game_enable",qosEnable)
		end
		
		uci:commit("qos")
		uci:apply("qos") 
	end
	
	luci.template.render("expert_configuration/qos")
	return
end
]]--
function split(str, c)
	a = string.find(str, c)
	str = string.gsub(str, c, "", 1)
	aCount = 0
	start = 1
	array = {}
	last = 0
		
		while a do
		array[aCount] = string.sub(str, start, a - 1)
		start = a
		a = string.find(str, c)
		
		str = string.gsub(str, c, "", 1)
		aCount = aCount + 1
		end	
	return array
end


function action_qos_adv()
	apply = luci.http.formvalue("apply")
	apply_edit = luci.http.formvalue("apply_edit")
	edit = luci.http.formvalue("edit")
	delete = luci.http.formvalue("delete")

	apply_edit_AdvSet = luci.http.formvalue("apply_edit_AdvSet")	
	edit_AdvSet = luci.http.formvalue("edit_AdvSet")
	
	if apply then
		local upShapeRate = luci.http.formvalue("UploadBandwidth_value")
		local downShapeRate = luci.http.formvalue("DownloadBandwidth_value")
		local appPrio = split(luci.http.formvalue("app_prio"),",")
		local appEnable = split(luci.http.formvalue("app_enable"),",")
		local userCategory = split(luci.http.formvalue("user_category"),",")
		local userDir = split(luci.http.formvalue("user_dir"),",")
		local userEnable = split(luci.http.formvalue("user_enable"),",")
		local userName = split(luci.http.formvalue("user_name"),",")
		
		if upShapeRate ~= "" then
			uci:set("qos","shaper", "port_rate_eth0", upShapeRate)
		else
			uci:set("qos","shaper", "port_rate_eth0", 0)
		end
		
		if downShapeRate ~= "" then
			uci:set("qos","shaper", "port_rate_lan", downShapeRate)
		else
			uci:set("qos","shaper", "port_rate_lan", 0)
		end
		
		if appPrio[0] ~= "6" then
			uci:set("qos","general","game_enable",0)
		end
		
		uci:set("qos","app_policy_0","prio",appPrio[0])
		uci:set("qos","app_policy_1","prio",appPrio[0])
		uci:set("qos","app_policy_2","prio",appPrio[0])
		uci:set("qos","app_policy_3","prio",appPrio[0])		
		uci:set("qos","app_policy_4","prio",appPrio[1])
		uci:set("qos","app_policy_5","prio",appPrio[2])		
		uci:set("qos","app_policy_6","prio",appPrio[3])		
		uci:set("qos","app_policy_7","prio",appPrio[4])
		uci:set("qos","app_policy_8","prio",appPrio[4])
		uci:set("qos","app_policy_9","prio",appPrio[4])		
		uci:set("qos","app_policy_10","prio",appPrio[5])
		
		uci:set("qos","app_policy_0","enable", appEnable[0])
		uci:set("qos","app_policy_1","enable", appEnable[1])
		uci:set("qos","app_policy_2","enable", appEnable[2])
		uci:set("qos","app_policy_3","enable", appEnable[3])
		uci:set("qos","app_policy_4","enable", appEnable[4])
		uci:set("qos","app_policy_5","enable", appEnable[5])
		uci:set("qos","app_policy_6","enable", appEnable[6])
		uci:set("qos","app_policy_7","enable", appEnable[7])
		uci:set("qos","app_policy_8","enable", appEnable[8])
		uci:set("qos","app_policy_9","enable", appEnable[9])		
		uci:set("qos","app_policy_10","enable", appEnable[10])
		
		for i=1,8 do
			uci:set("qos","eg_policy_" .. i,"enable",userEnable[i-1])
			uci:set("qos","eg_policy_" .. i,"name",userName[i-1])
			uci:set("qos","eg_policy_" .. i,"to_intf",userDir[i-1])
			
			if userDir[i-1] == "lan" then

				local value = uci:get("qos","eg_policy_" .. i,"bw_value")
		
				uci:set("qos","eg_policy_" .. i,"bw_towan",0)
				uci:set("qos","eg_policy_" .. i,"bw_tolan",value)
			
			else

				local value = uci:get("qos","eg_policy_" .. i,"bw_value")
		
				uci:set("qos","eg_policy_" .. i,"bw_tolan",0)
				uci:set("qos","eg_policy_" .. i,"bw_towan",value)
			
			end
			
			uci:set("qos","eg_policy_" .. i,"apptype",userCategory[i-1])
			
			if userCategory[i-1] == "Game Console" then

				local prio = uci:get("qos","app_policy_0" ,"prio")

				uci:set("qos","eg_policy_" .. i,"prio",prio)
			
			elseif userCategory[i-1] == "VoIP" then

				local prio = uci:get("qos","app_policy_4" ,"prio")

				uci:set("qos","eg_policy_" .. i,"prio",prio)
			
			elseif userCategory[i-1] == "P2P/FTP" then

				local prio = uci:get("qos","app_policy_7" ,"prio")

				uci:set("qos","eg_policy_" .. i,"prio",prio)

			elseif userCategory[i-1] == "Web Surfing" then

				local prio = uci:get("qos","app_policy_6" ,"prio")

				uci:set("qos","eg_policy_" .. i,"prio",prio)

			elseif userCategory[i-1] == "Instant Messanger" then

				local prio = uci:get("qos","app_policy_5" ,"prio")

				uci:set("qos","eg_policy_" .. i,"prio",prio)
				
			else
			
				local prio = uci:get("qos","app_policy_10" ,"prio")

				uci:set("qos","eg_policy_" .. i,"prio",prio)
							
			end			
			
			
		end
		
		uci:commit("qos")
		uci:apply("qos")
		
		luci.template.render("expert_configuration/qos_adv")
		
	elseif apply_edit then
	
		local bwSelect = luci.http.formvalue("bwSelect")
	    local bwValue = luci.http.formvalue("bwValue")
		local srcAddrStart = luci.http.formvalue("srcAddrStart")
		local srcAddrEnd = luci.http.formvalue("srcAddrEnd")
		local srcPort = luci.http.formvalue("srcPort")
		local dstAddrStart = luci.http.formvalue("dstAddrStart")
		local dstAddrEnd = luci.http.formvalue("dstAddrEnd")
		local dstPort = luci.http.formvalue("dstPort")
		local proto = luci.http.formvalue("proto")
		
		uci:set("qos",apply_edit,"reserve_bw",bwSelect)
		uci:set("qos",apply_edit,"bw_value",bwValue)
		uci:set("qos",apply_edit,"inipaddr_start",srcAddrStart)
		uci:set("qos",apply_edit,"inipaddr_end",srcAddrEnd)
		uci:set("qos",apply_edit,"inport",srcPort)
		uci:set("qos",apply_edit,"outipaddr_start",dstAddrStart)
		uci:set("qos",apply_edit,"outipaddr_end",dstAddrEnd)
		uci:set("qos",apply_edit,"outport",dstPort)
		uci:set("qos",apply_edit,"proto",proto)
		
		local to_intf = uci:get("qos",apply_edit,"to_intf")
		
		if to_intf == "lan" then
		
			uci:set("qos",apply_edit,"bw_towan",0)
			uci:set("qos",apply_edit,"bw_tolan",bwValue)
			
		else

			uci:set("qos",apply_edit,"bw_tolan",0)
			uci:set("qos",apply_edit,"bw_towan",bwValue)
			
		end
		
		uci:commit("qos")
		uci:apply("qos")
		luci.template.render("expert_configuration/qos_adv")
		
	elseif edit then

		local ruleBwSelect = uci:get("qos",edit,"reserve_bw")
		local ruleBwValue = uci:get("qos",edit,"bw_value")	
		local ruleName = uci:get("qos",edit,"name")
		local ruleEnable = uci:get("qos",edit,"enable")
		local ruleSrcStart = uci:get("qos",edit,"inipaddr_start")
		local ruleSrcEnd = uci:get("qos",edit,"inipaddr_end")
		local ruleSrcPort = uci:get("qos",edit,"inport")
		local ruleDstStart = uci:get("qos",edit,"outipaddr_start")
		local ruleDstEnd = uci:get("qos",edit,"outipaddr_end")
		local ruleDstPort = uci:get("qos",edit,"outport")
		local ruleProto = uci:get("qos",edit,"proto")

		local LANsum = 0
		local WANsum = 0

		upstream = uci:get("qos","shaper","port_rate_eth0")
		downstream = uci:get("qos","shaper","port_rate_lan")
	
		my_enable=uci:get("qos",edit,"enable")
		my_value=uci:get("qos",edit,"bw_value")
		my_intf=uci:get("qos",edit,"to_intf")
		my_reserve=uci:get("qos",edit,"reserve_bw")

		if my_intf == "lan" then
		   my_intfs = "0"
		else
		   my_intfs = "1"
		end
			
		for i = 0, 10 do
				
			enable=uci:get("qos","app_policy_" .. i,"enable")
				
			lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
			lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
			wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
			wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
			lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
			lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
			wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
			wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
			lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
			lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
			wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
			wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

			if enable == "1" then
				
				if lan_tcp_enable == "1" then
						
					if lan_tcp_min == "1" then
						LANsum = LANsum + lan_tcp_bw
					end				

				end
					
				if lan_udp_enable == "1" then
						
					if lan_udp_min == "1" then
						LANsum = LANsum + lan_udp_bw
					end				

				end
				
				if wan_tcp_enable == "1" then
						
					if wan_tcp_min == "1" then
						WANsum = WANsum + wan_tcp_bw
					end				

				end
					
				if wan_udp_enable == "1" then
						
					if wan_udp_min == "1" then
						WANsum = WANsum + wan_udp_bw
					end				

				end
				
			end
				
		end			
			
		for i = 1, 8 do

			enable=uci:get("qos","eg_policy_" .. i,"enable")
			value=uci:get("qos","eg_policy_" .. i,"bw_value")			
			intf=uci:get("qos","eg_policy_" .. i,"to_intf")
			reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
			if	enable == "1" then
				
				if intf == "wan" then
						
					if reserve == "2" then
						WANsum = WANsum + value
					end				

				else
						
					if reserve == "2" then
						LANsum = LANsum + value
					end				
				
				end

			end
				
		end

		if	my_enable == "1" then
				
			if my_intf == "wan" then
						
				if my_reserve == "2" then
					WANsum = WANsum - my_value
				end				

			else
						
				if my_reserve == "2" then
					LANsum = LANsum - my_value
				end				
				
			end

		end		
		
		luci.template.render("expert_configuration/qos_cfg_edit", {
			My_enable = my_enable,
			My_intf = my_intfs,
			WAN_sum = WANsum,
			LAN_sum = LANsum,
			upstream_value = upstream,
			downstream_value = downstream,		
			section_name = edit,
			rule_bw_Select = ruleBwSelect,
			rule_bw_value = ruleBwValue,
			rule_name = ruleName,
			rule_enable = ruleEnable,
			rule_src_start = ruleSrcStart,
			rule_src_end = ruleSrcEnd,
			rule_src_port = ruleSrcPort,
			rule_dst_start = ruleDstStart,
			rule_dst_end = ruleDstEnd,
			rule_dst_port = ruleDstPort,
			rule_proto = ruleProto
		})
		
	elseif delete then
		uci:set("qos",delete,"name","")
		uci:set("qos",delete,"enable",0)
		uci:set("qos",delete,"reserve_bw",2)
		uci:set("qos",delete,"bw_value",10)
		uci:set("qos",delete,"inipaddr_start","0.0.0.0")
		uci:set("qos",delete,"inipaddr_end","0.0.0.0")
		uci:set("qos",delete,"inport",0)
		uci:set("qos",delete,"outipaddr_start","0.0.0.0")
		uci:set("qos",delete,"outipaddr_end","0.0.0.0")
		uci:set("qos",delete,"outport",0)
		uci:set("qos",delete,"apptype","Game Console")
		uci:set("qos",delete,"to_intf","lan")
		uci:set("qos",delete,"proto","")
		uci:set("qos",delete,"prio",1)
		
		uci:commit("qos")
		uci:apply("qos")
		luci.template.render("expert_configuration/qos_adv")

	elseif apply_edit_AdvSet then

		if apply_edit_AdvSet == "XBox_Live" then
			apply_edit_AdvSet = "app_policy_0"
		elseif apply_edit_AdvSet == "PlayStation" then
			apply_edit_AdvSet = "app_policy_1"
		elseif apply_edit_AdvSet == "MSN_Game_Zone" then
			apply_edit_AdvSet = "app_policy_2"
		elseif apply_edit_AdvSet == "Battlenet" then
			apply_edit_AdvSet = "app_policy_3"
		elseif apply_edit_AdvSet == "VoIP" then
			apply_edit_AdvSet = "app_policy_4"
		elseif apply_edit_AdvSet == "Instant_Messanger" then
			apply_edit_AdvSet = "app_policy_5"
		elseif apply_edit_AdvSet == "Web_Surfing" then
			apply_edit_AdvSet = "app_policy_6"
		elseif apply_edit_AdvSet == "FTP" then
			apply_edit_AdvSet = "app_policy_7"
		elseif apply_edit_AdvSet == "eMule" then
			apply_edit_AdvSet = "app_policy_8"
		elseif apply_edit_AdvSet == "BitTorrent" then
			apply_edit_AdvSet = "app_policy_9"
		else
			apply_edit_AdvSet = "app_policy_10"	
		end

		if apply_edit_AdvSet == "app_policy_0" then
			
			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")
		
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")
			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")
		
			local Bandwidth_enable3 = luci.http.formvalue("Bandwidth_enable3")
			local Bandwidth_select3 = luci.http.formvalue("Bandwidth_select3")
			local Bandwidth_value3 = luci.http.formvalue("Bandwidth_value3")
		
			local Bandwidth_enable4 = luci.http.formvalue("Bandwidth_enable4")
			local Bandwidth_select4 = luci.http.formvalue("Bandwidth_select4")
			local Bandwidth_value4 = luci.http.formvalue("Bandwidth_value4")		
		
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)
		
			uci:set("qos",apply_edit_AdvSet,"lan_udp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_bw",Bandwidth_value2)
		
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value3)
		
			uci:set("qos",apply_edit_AdvSet,"wan_udp_enable",Bandwidth_enable4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_min",Bandwidth_select4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_bw",Bandwidth_value4)

		elseif apply_edit_AdvSet == "app_policy_1" then

			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")
		
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")
			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")
		
			local Bandwidth_enable3 = luci.http.formvalue("Bandwidth_enable3")
			local Bandwidth_select3 = luci.http.formvalue("Bandwidth_select3")
			local Bandwidth_value3 = luci.http.formvalue("Bandwidth_value3")
		
			local Bandwidth_enable4 = luci.http.formvalue("Bandwidth_enable4")
			local Bandwidth_select4 = luci.http.formvalue("Bandwidth_select4")
			local Bandwidth_value4 = luci.http.formvalue("Bandwidth_value4")		
		
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)
		
			uci:set("qos",apply_edit_AdvSet,"lan_udp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_bw",Bandwidth_value2)
		
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value3)
		
			uci:set("qos",apply_edit_AdvSet,"wan_udp_enable",Bandwidth_enable4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_min",Bandwidth_select4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_bw",Bandwidth_value4)


		elseif apply_edit_AdvSet == "app_policy_2" then
			
			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")
		
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")
			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")
		
			local Bandwidth_enable3 = luci.http.formvalue("Bandwidth_enable3")
			local Bandwidth_select3 = luci.http.formvalue("Bandwidth_select3")
			local Bandwidth_value3 = luci.http.formvalue("Bandwidth_value3")
		
			local Bandwidth_enable4 = luci.http.formvalue("Bandwidth_enable4")
			local Bandwidth_select4 = luci.http.formvalue("Bandwidth_select4")
			local Bandwidth_value4 = luci.http.formvalue("Bandwidth_value4")		
		
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)
		
			uci:set("qos",apply_edit_AdvSet,"lan_udp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_bw",Bandwidth_value2)
		
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value3)
		
			uci:set("qos",apply_edit_AdvSet,"wan_udp_enable",Bandwidth_enable4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_min",Bandwidth_select4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_bw",Bandwidth_value4)
			
		elseif apply_edit_AdvSet == "app_policy_9" then
			
			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")
		
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")
			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")
		
			local Bandwidth_enable3 = luci.http.formvalue("Bandwidth_enable3")
			local Bandwidth_select3 = luci.http.formvalue("Bandwidth_select3")
			local Bandwidth_value3 = luci.http.formvalue("Bandwidth_value3")
		
			local Bandwidth_enable4 = luci.http.formvalue("Bandwidth_enable4")
			local Bandwidth_select4 = luci.http.formvalue("Bandwidth_select4")
			local Bandwidth_value4 = luci.http.formvalue("Bandwidth_value4")		
		
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)
		
			uci:set("qos",apply_edit_AdvSet,"lan_udp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_bw",Bandwidth_value2)
		
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value3)
		
			uci:set("qos",apply_edit_AdvSet,"wan_udp_enable",Bandwidth_enable4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_min",Bandwidth_select4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_bw",Bandwidth_value4)

		else		
			
			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")
		
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")
			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")
		
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)
		
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value2)
		
		end
		
		uci:commit("qos")
		uci:apply("qos")
		luci.template.render("expert_configuration/qos_adv")
				
	elseif edit_AdvSet then

        local section
		local upstream
		local downstream
		
		if edit_AdvSet == "app_policy_0" then
			section = "XBox_Live"
		elseif edit_AdvSet == "app_policy_1" then
			section = "PlayStation"
		elseif edit_AdvSet == "app_policy_2" then
			section = "MSN_Game_Zone"
		elseif edit_AdvSet == "app_policy_3" then
			section = "Battlenet"
		elseif edit_AdvSet == "app_policy_4" then
			section = "VoIP"
		elseif edit_AdvSet == "app_policy_5" then
			section = "Instant_Messanger"
		elseif edit_AdvSet == "app_policy_6" then
			section = "Web_Surfing"
		elseif edit_AdvSet == "app_policy_7" then
			section = "FTP"
		elseif edit_AdvSet == "app_policy_8" then
			section = "eMule"
		elseif edit_AdvSet == "app_policy_9" then
			section = "BitTorrent"
		else
			section = "E_Mail"	
		end
		
		upstream = uci:get("qos","shaper","port_rate_eth0")
		downstream = uci:get("qos","shaper","port_rate_lan")
		
		if "app_policy_0" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSet,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSet,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSet,"wan_udp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_0","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_0","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_0","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_0","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_0","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_0","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_0","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_0","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_0","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_0","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_0","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_0","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_0","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
			
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4			
			})
			
		elseif "app_policy_1" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSet,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSet,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSet,"wan_udp_bw")		

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_1","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_1","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_1","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_1","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_1","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_1","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_1","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_1","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_1","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_1","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_1","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_1","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_1","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
		
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,			
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4			
			})

		elseif "app_policy_2" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSet,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSet,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSet,"wan_udp_bw")		

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_2","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_2","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_2","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_2","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_2","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_2","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_2","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_2","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_2","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_2","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_2","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_2","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_2","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
		
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4			
			})
		
		elseif "app_policy_3" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_3","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_3","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_3","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_3","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_3","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_3","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_3","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_3","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_3","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_3","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_3","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_3","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_3","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})
		
		elseif "app_policy_4" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_4","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_4","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_4","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_4","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_4","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_4","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_4","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_4","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_4","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_4","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_4","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_4","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_4","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,		
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})
		
		elseif "app_policy_5" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_5","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_5","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_5","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_5","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_5","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_5","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_5","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_5","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_5","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_5","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_5","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_5","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_5","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,		
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})
		
		elseif "app_policy_6" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_6","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_6","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_6","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_6","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_6","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_6","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_6","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_6","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_6","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_6","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_6","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_6","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_6","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,			
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})
		
		elseif "app_policy_7" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_7","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_7","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_7","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_7","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_7","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_7","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_7","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_7","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_7","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_7","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_7","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_7","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_7","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,			
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})
		
		elseif "app_policy_8" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_0","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_8","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_8","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_8","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_8","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_8","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_8","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_8","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_8","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_8","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_8","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_8","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_8","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,		
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})
		
		elseif "app_policy_9" == edit_AdvSet then
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSet,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSet,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSet,"wan_udp_bw")		


			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_9","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_9","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_9","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_9","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_9","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_9","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_9","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_9","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_9","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_9","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_9","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_9","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_9","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
		
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,			
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4			
			})
			
		else
		
			local AdvSetEnable1 = uci:get("qos",edit_AdvSet,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSet,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSet,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSet,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSet,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSet,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0
			
			my_enable=uci:get("qos","app_policy_10","enable")
			
			my_lan_tcp_enable=uci:get("qos","app_policy_10","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_10","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_10","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_10","wan_udp_enable")				
				
			my_lan_tcp_min=uci:get("qos","app_policy_10","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_10","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_10","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_10","wan_udp_min")
				
			my_lan_tcp_bw=uci:get("qos","app_policy_10","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_10","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_10","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_10","wan_udp_bw")
			
			for i = 0, 10 do
				
				enable=uci:get("qos","app_policy_" .. i,"enable")
				
				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")				
				
				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")
				
				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then
				
					if lan_tcp_enable == "1" then
						
						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end				

					end
					
					if lan_udp_enable == "1" then
						
						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end				

					end
					
					if wan_tcp_enable == "1" then
						
						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end				

					end
					
					if wan_udp_enable == "1" then
						
						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end				

					end
				
				end
				
			end			
			
			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")			
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")
				
				if	enable == "1" then
				
					if intf == "wan" then
						
						if reserve == "2" then
							WANsum = WANsum + value
						end				

					else
						
						if reserve == "2" then
							LANsum = LANsum + value
						end				
				
					end

				end
				
			end
			
			if my_enable == "1" then
				
				if my_lan_tcp_enable == "1" then
							
					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end				

				end
						
				if my_lan_udp_enable == "1" then
							
					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end				

				end
						
				if my_wan_tcp_enable == "1" then
							
					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end				

				end
						
				if my_wan_udp_enable == "1" then
							
					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end				

				end			
			
			end
	
			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,			
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		end

		
	else
		luci.template.render("expert_configuration/qos_adv")
	end
	
end
--[[
function streamboost_bandwidth()
	apply = luci.http.formvalue("apply")
	
	if apply then
	
		local StreamboostEnable = luci.http.formvalue("StreamboostEnable")
		local StreamboostAuto = luci.http.formvalue("StreamboostAuto")
		local StreamboostAutoUpdate = luci.http.formvalue("StreamboostAutoUpdate")
		
		local StreamboostUpLimit = luci.http.formvalue("StreamboostUp")
		local StreamboostDownLimit = luci.http.formvalue("StreamboostDown")		
		
		uci:set("appflow","tccontroller","enable_streamboost",StreamboostEnable)
		uci:set("appflow","tccontroller","enable_auto",StreamboostAuto)
		uci:set("appflow", "tccontroller", "uplimit", StreamboostUpLimit * math.pow(10, 6) / 8.0)
		uci:set("appflow", "tccontroller", "downlimit", StreamboostDownLimit * math.pow(10, 6) / 8.0)		
		uci:set("appflow", "tccontroller","auto_update", StreamboostAutoUpdate)		
		
		uci:commit("appflow")
		uci:apply("appflow")
		
	end
		local uplimit_test = uci:get("appflow", "tccontroller", "uplimit")
		local downlimit_test = uci:get("appflow", "tccontroller", "downlimit")
		
	
	luci.template.render("expert_configuration/streamboost_bandwidth", {uplimit = uplimit_test * 8.0 / math.pow(10, 6), downlimit = downlimit_test * 8.0 / math.pow(10, 6)})

end
]]--
function Dec2Hex(nValue)
	local string = require("string")
	if type(nValue) == "string" then
		nValue = tonumber(nValue)
	end
	nHexVal = string.format("%X", nValue);  -- %X returns uppercase hex, %x gives lowercase letters
	sHexVal = nHexVal..""
	return sHexVal
end

function action_qos()

        apply = luci.http.formvalue("apply")

        if apply then
                local qosEnable = luci.http.formvalue("qosEnable")
                local UpstreamBandwidth = luci.http.formvalue("UpstreamBandwidth")
                local DownstreamBandwidth = luci.http.formvalue("DownstreamBandwidth")

		uci:set("qos","general","enable",qosEnable)
		uci:set("qos","general","upload",UpstreamBandwidth)
		uci:set("qos","general","download",DownstreamBandwidth)

                uci:commit("qos")
                uci:apply("qos")
        end

        luci.template.render("expert_configuration/qos")
end

function action_qos_queue()

	apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	local submitType = luci.http.formvalue("SubmitType")


	if apply then

		if "edit" == submitType then
			local editID = luci.http.formvalue("EditID")
			local enable = luci.http.formvalue("Active")

			if enable == nil then
				enable = "0"
			end

			local name = luci.http.formvalue("QueueName")
			local interface = luci.http.formvalue("Interface")
			local priority = luci.http.formvalue("Priority")
			local Weight = luci.http.formvalue("Weight")
			local rate = luci.http.formvalue("RateLimit")

			if "New" == editID then
				local wanQueue_count = uci:get("qos","general", "wanQueue_count")
				local lanQueue_count = uci:get("qos","general", "lanQueue_count")
				editID = wanQueue_count + lanQueue_count + 1
				entryName = editID
				classId = editID
				uci:set("qos", entryName, "queue")
				uci:set("qos", entryName, "enable",enable)
				uci:set("qos", entryName, "name",name)
				uci:set("qos", entryName, "interface",interface)
				uci:set("qos", entryName, "priority", priority)
				uci:set("qos", entryName, "weight", Weight)
				uci:set("qos", entryName, "rate", rate)
				uci:set("qos", entryName,"classid", classId )

				if "wan" == interface then
					--wanQueue_count = wanQueue_count + 1
					uci:set("qos","general","wanQueue_count",wanQueue_count+1)
				else
					--lanQueue_count = lanQueue_count + 1
					uci:set("qos","general","lanQueue_count",lanQueue_count+1)
				end

            else
				entryName = ( editID + 1 )
				old_interface=uci:get("qos", entryName, "interface")

				if not (old_interface == interface ) then

					local wanQueue_count = uci:get("qos","general", "wanQueue_count")
					local lanQueue_count = uci:get("qos","general", "lanQueue_count")

					if "wan" == interface  then
						uci:set("qos","general","wanQueue_count",wanQueue_count+1)
						uci:set("qos","general","lanQueue_count",lanQueue_count-1)
					else
						uci:set("qos","general","wanQueue_count",wanQueue_count-1)
						uci:set("qos","general","lanQueue_count",lanQueue_count+1)
					end

				end

				if not ( nil == enable )  then
					uci:set("qos", entryName, "enable",enable)
				end

				if not ( nil == name )  then
					uci:set("qos", entryName, "name",name)
				end

				if not ( nil == interface )  then
					uci:set("qos", entryName, "interface",interface)
				end

				if not ( nil == priority )  then
					uci:set("qos", entryName, "priority", priority)
				end

				if not ( nil == Weight )  then
					uci:set("qos", entryName, "weight", Weight)
				end

				if not ( nil == rate )  then
					uci:set("qos", entryName, "rate", rate)
				end

                        end
		end

		--if "enable" == submitType then
			--local editID = luci.http.formvalue("EditID")
			--local enable = luci.http.formvalue("Active")
			--if enable == nil then
			--       enable = "0"
			--end

			--entryName = "PriQ" .. ( editID + 1 )
			--uci:set("qos", entryName, "enable",enable)
		--end

		uci:save("qos")
		uci:commit("qos")
		uci:apply("qos")
	end


	if delete then
		--local queueName = "PriQ" .. delete
		--local queueInterfance = uci:get("qos", "PriQ"..delete, "interface")
		--local wanQueue_count = uci:get("qos","general", "wanQueue_count")
		--local lanQueue_count = uci:get("qos","general", "lanQueue_count")

		--uci:delete("qos", "PriQ" .. delete)
		--if "wan" == queueInterfance then
		--	uci:set("qos","general",wanQueue_count - 1)
		--else
		--	uci:set("qos","general",lanQueue_count - 1)
		--end
		uci:set("qos", delete, "delete", "1")
		uci:commit("qos")
		uci:apply("qos")
	end

	luci.template.render("expert_configuration/qos_queue")
end

function action_qos_classify()

	local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	local submitType = luci.http.formvalue("SubmitType")

	if apply then
		if "edit" == submitType then

			local editID = luci.http.formvalue("EditID")
			--local ClassOrder = luci.http.formvalue("editclassOrder")
			local ClassOrder=0
			local class_count=uci:get("qos_classify","general","class_count")
			local class_position=0
			
			if not (nil == editID) then	
				--adjust class order if user define			
				if "New" == editID then

					ClassOrder = luci.http.formvalue("classOrder")
					--add new class
					class_position = class_count+1
					
					--adjust class order if user define	
					if not (ClassOrder == class_position) then
						for i = class_count,1,-1 do
							if tonumber( i) >= tonumber( ClassOrder) then
								old_classid="class"..(i)
								new_classid="class"..(i+1)
								uci:rename( "qos_classify" , old_classid, new_classid )
							end
						end
					end

					--create user define class
					classid ="class"..ClassOrder
					uci:set("qos_classify", classid, "class")
					
				else

					--edit class
					ClassOrder = luci.http.formvalue("editclassOrder")
					class_position = editID+1
					classid ="class"..(editID+1)
					uci:delete("qos_classify",classid)
					
					--adjust class order if user define
					if  tonumber( ClassOrder)  < tonumber( class_position ) then
					
						for i = class_count,1,-1 do
							if tonumber( i) >= tonumber( ClassOrder ) then
								if tonumber( i) < tonumber( class_position) then

										new_classid="class"..(i+1)
										old_classid="class"..i
										uci:rename( "qos_classify" , old_classid, new_classid )
									
								end
							end
						end
					
					elseif tonumber( ClassOrder)  > tonumber( class_position ) then

						for i = 1,class_count,1 do
							if  tonumber( i ) >= tonumber( class_position ) then
								if  tonumber( i ) < tonumber( ClassOrder ) then

										new_classid="class"..i
										old_classid="class"..(i+1)
										uci:rename( "qos_classify" , old_classid, new_classid )
			
								end
							end
						end	
						
					end
					
					-- re-create user define class
					classid ="class"..ClassOrder
					uci:set("qos_classify", classid, "class")

				end	

				local enabled = luci.http.formvalue("classActive")
				if enabled == nil then
					enabled = "0"
				end

				--get common (na,ip,arp,802.1p ) config
				local queueName = luci.http.formvalue("queueName")
				local className = luci.http.formvalue("className")
				local order = luci.http.formvalue("order")
				local formInterface = luci.http.formvalue("formInterface")
				local etherType = luci.http.formvalue("etherType")

				local srcMac = luci.http.formvalue("srcMac")
				local srcMacMask = luci.http.formvalue("srcMacMask")
				local destMac = luci.http.formvalue("destMac")
				local destMacMask = luci.http.formvalue("destMacMask")					

				--8021p mark
				local prioMark = luci.http.formvalue("8021pMark")
				local vidMark_action = luci.http.formvalue("vidMark_action")	
				local setVlanId = luci.http.formvalue("setVlanId")  

				--exclude option for commmon 
				local srcMacExclude = luci.http.formvalue("srcMacExclude")
				local destMacExclude = luci.http.formvalue("destMacExclude")

				--save common (na,ip,arp,802.1p ) config
				if not ( nil == enabled )  then
					uci:set("qos_classify", classid, "enable", enabled)
				end

				if not ( nil == queueName )  then
					uci:set("qos_classify", classid, "queue", queueName)
				end

				if not ( nil == className )  then
					uci:set("qos_classify", classid, "name", className)
				end

				if not ( nil == order )  then
					uci:set("qos_classify", classid, "order", order )
				end

				if not ( nil == formInterface )  then
					uci:set("qos_classify", classid, "fromInt", formInterface)
				end

				if not ( nil == etherType )  then
					uci:set("qos_classify", classid, "ethType", etherType)
				end

				if not ( nil == srcMac )  then
					uci:set("qos_classify", classid, "srcMac", srcMac)
				end

				if not ( nil == srcMacMask) then
					uci:set("qos_classify", classid, "srcMacMask", srcMacMask)
				end

				if not( nil == destMac)  then
					uci:set("qos_classify", classid, "destMac", destMac)
				end

				if not ( nil == destMacMask )  then
					uci:set("qos_classify", classid, "destMacMask", destMacMask)
				end

				if not (nil == prioMark ) then
					uci:set("qos_classify", classid, "set_prio", prioMark)
				end

				if not ( nil == vidMark_action ) then
					uci:set("qos_classify", classid, "vidMark_action", vidMark_action)

					if ( not ( nil == setVlanId ) ) and ((vidMark_action =="Remark") or (vidMark_action =="Add")) then
					uci:set("qos_classify", classid, "set_vid", setVlanId)	
					end				
				end

				if  "1" == srcMacExclude   then
					uci:set("qos_classify", classid, "srcMacExclude", srcMacExclude)
				end

				if  "1" == destMacExclude   then
					uci:set("qos_classify", classid, "destMacExclude", destMacExclude)
				end

				--8021q only										
				if "8021q" == etherType  then

					--8021p	
					local prio = luci.http.formvalue("8021p")
					local vlanId = luci.http.formvalue("vlanId")
					--exclude option for 8021q
					local prioExclude = luci.http.formvalue("prioExclude")
					local vlanIdExclude = luci.http.formvalue("vlanIdExclude")

					if not( nil == prio ) then		
						uci:set("qos_classify", classid, "prio", prio)
					end

					if not ( nil == vlanId ) then
						uci:set("qos_classify", classid, "vlanId", vlanId)
					end

					if "1" == prioExclude then
						uci:set("qos_classify", classid, "prioExclude", prioExclude)
					end

					if "1" == vlanIdExclude then
						uci:set("qos_classify", classid, "vlanIdExclude", vlanIdExclude)
					end

				--ip only										
				elseif "ip" == etherType then	
						
					local srcIP = luci.http.formvalue("srcIp")
					local srcNetMask = luci.http.formvalue("srcNetMask")
					local destIP = luci.http.formvalue("destIp")
					local destNetMask = luci.http.formvalue("destNetMask")
					local service = luci.http.formvalue("Service")
					local protocol = luci.http.formvalue("protocol")
					local protocolPort = luci.http.formvalue("protocolPort")				
					local srcPort_min = luci.http.formvalue("srcPort_min")
					local srcPort_max = luci.http.formvalue("srcPort_max")
					local destPort_min = luci.http.formvalue("destPort_min")
					local destPort_max = luci.http.formvalue("destPort_max")

					local setDhcp = luci.http.formvalue("dhcpInput")
					local dhcp = luci.http.formvalue("dhcpOption")

					local pktLength_min = luci.http.formvalue("pktLength_min")		
					local pktLength_max = luci.http.formvalue("pktLength_max")	
					local Dscp = luci.http.formvalue("Dscp")	
					local dscpMark = luci.http.formvalue("dscpMark")
					local setDscp = luci.http.formvalue("setDscp")
					--exclude option for ip	
					local srcIpExclude = luci.http.formvalue("srcIpExclude")
					local srcPortExclude = luci.http.formvalue("srcPortExclude")
					local destIpExclude = luci.http.formvalue("destIpExclude")
					local destPortExclude = luci.http.formvalue("destPortExclude")
					local serviceExclude = luci.http.formvalue("serviceExclude")
					local protocolExclude = luci.http.formvalue("protocolExclude")
					local dhcpExclude = luci.http.formvalue("dhcpExclude")
					local pktLengthExclude = luci.http.formvalue("pktLengthExclude")
					local dscpExclude = luci.http.formvalue("dscpExclude")
					local tcpAckActive = luci.http.formvalue("tcpAckActive")
					local tcpAckExclude = luci.http.formvalue("tcpAckExclude")



					if not (nil == srcIP ) then
						uci:set("qos_classify", classid, "srcIp", srcIP)
					end

					if not ( nil == srcNetMask ) then
						uci:set("qos_classify", classid, "srcMask", srcNetMask)
					end

					if not ( nil == destIP ) then
						uci:set("qos_classify", classid, "destIp", destIP)
					end

					if not ( nil == destNetMask ) then
						uci:set("qos_classify", classid, "destMask", destNetMask)
					end

					if "UserDef" == protocol then
						uci:set("qos_classify", classid, "protocol", protocolPort)
					elseif not ( nil == protocol ) then
						uci:set("qos_classify", classid, "protocol", protocol)
					end

					if not ( nil == service ) then
						uci:set("qos_classify", classid, "service", service)
					end


					if not ( nil == srcPort_min ) then
						uci:set("qos_classify", classid, "srcPort_min", srcPort_min)
					end

					if not ( nil == srcPort_max) then
						uci:set("qos_classify", classid, "srcPort_max", srcPort_max)
					end

					if not ( nil == destPort_min ) then
						uci:set("qos_classify", classid, "destPort_min", destPort_min)
					end

					if not ( nil == destPort_max ) then
						uci:set("qos_classify", classid, "destPort_max", destPort_max)
					end

					if not ( nil == setDhcp ) then
						uci:set("qos_classify", classid, "setDhcp", setDhcp)
					end

					if not ( nil == dhcp ) then
						uci:set("qos_classify", classid, "dhcp", dhcp)
					end


					if not ( nil == pktLength_min ) then
						uci:set("qos_classify", classid, "pktLength_min", pktLength_min)
					end

					if not ( nil == pktLength_max ) then
						uci:set("qos_classify", classid, "pktLength_max", pktLength_max)
					end

					if not ( nil == Dscp ) then
						uci:set("qos_classify", classid, "dscp", Dscp)
					end

					if not ( nil == dscpMark ) then

						uci:set("qos_classify", classid, "set_dscpMark", dscpMark)

						if ( ( not ( nil == setDscp ) ) and ("mark" == dscpMark ) ) then
							uci:set("qos_classify", classid, "set_dscp", setDscp)
						end
					end

					if "1" == srcIpExclude   then
						uci:set("qos_classify", classid, "srcIpExclude", srcIpExclude)
					end

					if "1" == destIpExclude   then
						uci:set("qos_classify", classid, "destIpExclude", destIpExclude)
					end

					if "1" == srcPortExclude  then
						uci:set("qos_classify", classid, "srcPortExclude", srcPortExclude)
					end

					if "1" == destPortExclude   then
						uci:set("qos_classify", classid, "destPortExclude", destPortExclude)
					end

					if "1" == serviceExclude   then
						uci:set("qos_classify", classid, "serviceExclude", serviceExclude)
					end

					if "1" == protocolExclude   then
						uci:set("qos_classify", classid, "protocolExclude", protocolExclude)
					end

					if "1" == dhcpExclude   then
						uci:set("qos_classify", classid, "dhcpExclude", dhcpExclude)
					end

					if "1" == pktLengthExclude   then
						uci:set("qos_classify", classid, "pktLengthExclude", pktLengthExclude)
					end

					if "1" == dscpExclude   then
						uci:set("qos_classify", classid, "dscpExclude", dscpExclude)
					end

					if "1" == tcpAckActive   then

						uci:set("qos_classify", classid, "tcpAckActive", tcpAckActive)

						if "1" == tcpAckExclude   then
							uci:set("qos_classify", classid, "tcpAckExclude", tcpAckExclude)
						end

					end

				end

				if "New" == editID then
					--add  class num
					uci:set("qos_classify","general","class_count",(class_count+1))
				end


				uci:commit("qos_classify")
				uci:apply("qos")					
			end
		end
		
		if "switch" == submitType then

			local editID = luci.http.formvalue("EditID")

			if not (nil == editID) then	
			
				classid ="class"..(editID+1)
				local enabled = luci.http.formvalue("classActive")
				if enabled == nil then
					enabled = "0"
				end

				--save common (na,ip,arp,802.1p ) config
				if not ( nil == enabled )  then
				uci:set("qos_classify", classid, "enable", enabled)
				end

				uci:commit("qos_classify")
				uci:apply("qos")	
			
			end
		end
		
	end	

	--if apply then
		--local qosEnable = luci.http.formvalue("qosEnable")
		--uci:set("qos","general","enable",qosEnable)

		--if qosEnable == "0" then
		--       uci:set("qos","general","game_enable",qosEnable)
		--end

		--uci:commit("qos_classify")
		--uci:apply("qos")
	-- end

	if delete then
		uci:set("qos_classify", "class"..delete, "delete", "1")
		uci:commit("qos_classify")
		uci:apply("qos")
	end

	luci.template.render("expert_configuration/qos_classify")
end

function action_wol()
	local wolApply = luci.http.formvalue("wol_apply")
	local wolStart = luci.http.formvalue("wol_start")
	local mac = luci.http.formvalue("host_mac")
	local tmp = sys.exec("ifconfig br-lan | awk '/Bcast/{print $3}'")
	local lanBcast = tmp:match("Bcast:(%d+.%d+.%d+.%d+)")
	if not mac then
		mac = ""
	end
			
	if wolApply then
		local wolWanEnable = luci.http.formvalue("wol_wan_enable")
		local wolPort = luci.http.formvalue("wol_port")
		if not wolPort then
			wolPort = 9
		end
		if not ( "0" == wolWanEnable ) then
			uci:set("wol", "main", "enabled", 1)
		else
			uci:set("wol", "main", "enabled", 0)
		end
		if string.match(wolPort, "(%d+)") then
			wolPort = string.match(wolPort, "(%d+)")
			uci:set("wol", "main", "port", wolPort)
		end
		if string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac = string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("wol", "wol", "mac", mac)
		end
		uci:set("wol", "main", "broadcast", lanBcast)
		
		-- default we save mac addrerss but don't apply wol
		uci:set("wol", "wol", "enabled", "0")
		uci:commit("wol")
		uci:apply("wol")
	end
	
	if wolStart then
		wolStart = checkInjection(wolStart)
		if wolStart ~= false then
			uci:set("wol", "wol", "enabled", wolStart)
		end

		if string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac = string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("wol", "wol", "mac", mac)
		end

		uci:set("wol", "wol", "broadcast", lanBcast)
		uci:commit("wol")
		uci:apply("wol")
	end
	
	luci.template.render("expert_configuration/wol")
end

function action_dlna()
	local apply = luci.http.formvalue("apply")
	local rescan = luci.http.formvalue("rescan")

	if apply then
		local enabled = luci.http.formvalue("dlnaEnable")
		local usb1Photo = luci.http.formvalue("usb1Photo")
		local usb1Music = luci.http.formvalue("usb1Music")
		local usb1Video = luci.http.formvalue("usb1Video")
		local usb2Photo = luci.http.formvalue("usb2Photo")
		local usb2Music = luci.http.formvalue("usb2Music")
		local usb2Video = luci.http.formvalue("usb2Video")

		if enabled == "1" then
			uci:set("dlna", "main", "enabled", "1")
		else
			uci:set("dlna", "main", "enabled", "0")
		end

		if not usb1Photo then usb1Photo=0 end
		if not usb1Music then usb1Music=0 end 
		if not usb1Video then usb1Video=0 end 
		if not usb2Photo then usb2Photo=0 end
		if not usb2Music then usb2Music=0 end 
		if not usb2Video then usb2Video=0 end  

		uci:set("dlna", "main", "usb1_photo", usb1Photo )
		uci:set("dlna", "main", "usb1_music", usb1Music )
		uci:set("dlna", "main", "usb1_video", usb1Video )
		uci:set("dlna", "main", "usb2_photo", usb2Photo )
		uci:set("dlna", "main", "usb2_music", usb2Music )
		uci:set("dlna", "main", "usb2_video", usb2Video )

		uci:commit("dlna")
		uci:apply("dlna")
	end
	
	if rescan then
		sys.exec("wget http://127.0.0.1:9000/rpc/rescan > /tmp/dlnarescan")
	end

	luci.template.render("expert_configuration/dlna")
end

function action_samba()

	apply = luci.http.formvalue("apply")
	
	if apply then
	
		local enabled = luci.http.formvalue("sambaEnable")

		local name = luci.http.formvalue("sambaName")
		local workgroup = luci.http.formvalue("sambaWorkgroup")
		local description = luci.http.formvalue("sambaDescription")		
		local usb1 = luci.http.formvalue("usb1_types")
		local usb2 = luci.http.formvalue("usb2_types")
		
		if not (enabled)then
			enabled = "0"
			uci:set("system", "general", "enable", enabled)						
		else
			enabled = "1"
			uci:set("system", "general", "enable", enabled)
			
			if not ( "0" == usb1 ) then
				uci:set("system", "general", "usb1_types", 1)
			else
				uci:set("system", "general", "usb1_types", 0)
			end
			if not ( "0" == usb2 ) then
				uci:set("system", "general", "usb2_types", 1)
			else
				uci:set("system", "general", "usb2_types", 0)
			end
			
			name = checkInjection(name)
			if name ~= false then
				uci:set("samba", "general", "name", name)
			end
			
			workgroup = checkInjection(workgroup)
			if workgroup ~= false then
				uci:set("samba", "general", "workgroup", workgroup)
			end
			
			description = checkInjection(description)
			if description ~= false then
				uci:set("samba", "general", "description", description)
			end
			
		end
		
		local userEnable
		local userEnable_field
		local userName
		local userName_field
		local userPasswd
		local userPasswd_field
		local usb1
		local usb1_field
		local usb2
		local usb2_field
		
		local check_password
		local word
		local sum
		
		for i=1,5 do
			userEnable_field="userEnable"..i
			userEnable = luci.http.formvalue(userEnable_field)
			if not (userEnable)then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userName_field="userName"..i
			userName = luci.http.formvalue(userName_field)
			userPasswd_field="userPasswd"..i
			userPasswd = luci.http.formvalue(userPasswd_field)
			
			check_password = uci:get("system","samba_user_" .. i,"sum")
			if not( check_password == nil ) then	
				if ( check_password == userPasswd ) then	
					userPasswd = uci:get("system","samba_user_" .. i,"passwd")
				end
			end
			word = string.len( userPasswd ) - 1
			sum = math.pow(10,word)
			
			usb1_field="userUSB1"..i
			usb1 = luci.http.formvalue(usb1_field)
			if not (usb1)then
				usb1 = "0"
			else
				usb1 = "1"
			end
			
			usb2_field="userUSB2"..i
			usb2 = luci.http.formvalue(usb2_field)
			if not (usb2)then
				usb2 = "0"
			else
				usb2 = "1"
			end

			userName = checkInjection(userName)
			userPasswd = checkInjection(userPasswd)
			if userName ~= false and userPasswd ~= false then
				uci:set("system","samba_user_" .. i,"enable", userEnable)
				uci:set("system","samba_user_" .. i,"name",userName)
				uci:set("system","samba_user_" .. i,"passwd",userPasswd)
				if ( word > -1 ) then
					uci:set("system","samba_user_" .. i,"sum",sum)
				else
					uci:set("system","samba_user_" .. i,"sum","")
				end

				if not ( "1" == usb1 ) then
					uci:set("system","samba_user_" .. i,"enable_usb1",0)
				else
					uci:set("system","samba_user_" .. i,"enable_usb1",1)
				end
				if not ( "1" == usb2 ) then
					uci:set("system","samba_user_" .. i,"enable_usb2",0)
				else
					uci:set("system","samba_user_" .. i,"enable_usb2",1)
				end
			end
			
		end
		
		local useUSB1 = luci.http.formvalue("usb1_value")
		local useUSB2 = luci.http.formvalue("usb2_value")
		
		useUSB1 = checkInjection(useUSB1)
		if useUSB1 ~= false then
			uci:set("system", "general", "use_usb1", useUSB1)
		end
		
		useUSB2 = checkInjection(useUSB2)
		if useUSB2 ~= false then
			uci:set("system", "general", "use_usb2", useUSB2)
		end
		
		uci:commit("system")
		uci:commit("samba")				
		uci:apply("samba")
		
	end
	
	luci.template.render("expert_configuration/samba")
	
end

function action_ftp()

	apply = luci.http.formvalue("apply")
	
	if apply then
	
		local enabled = luci.http.formvalue("ftpEnable")
		if not (enabled)then
			enabled = "0"
		else
			enabled = "1"
		end
		
		local httpPort = luci.http.formvalue("httpPort")
		local max_connection = luci.http.formvalue("max_connection")
		local interface = luci.http.formvalue("interface")
	
		--add ftp start--------------------------------

		uci:set("proftpd", "global", "enable", enabled)
		uci:set("proftpd", "global", "port", httpPort)
		uci:set("proftpd", "global", "max_connection", max_connection)
		uci:set("proftpd", "global", "interface", interface)
			
		local userEnable
		local userEnable_field
		local userName
		local userName_field
		local userPasswd
		local userPasswd_field
		local usb1
		local usb1_field
		local usb2
		local usb2_field
		local upValue
		local upValue_field
		local downValue
		local downValue_field
		
		local check_password
		local word
		local sum		
		
		for i=1,5 do
			userEnable_field="userEnable"..i
			userEnable = luci.http.formvalue(userEnable_field)
			if not (userEnable)then
			userEnable = "0"
			else
			userEnable = "1"
			end

			userName_field="userName"..i
			userName = luci.http.formvalue(userName_field)
			userPasswd_field="userPasswd"..i
			userPasswd = luci.http.formvalue(userPasswd_field)
			usb1_field="usb1_types"..i
			usb1 = luci.http.formvalue(usb1_field)
			usb2_field="usb2_types"..i
			usb2 = luci.http.formvalue(usb2_field)
			upValue_field="upValue"..i
			upValue = luci.http.formvalue(upValue_field)
			downValue_field="downValue"..i
			downValue = luci.http.formvalue(downValue_field)

			check_password = uci:get("proftpd","profile" .. i,"sum")
			if not( check_password == nil ) then	
				if ( check_password == userPasswd ) then	
					userPasswd = uci:get("proftpd","profile" .. i,"password")
				end
			end
			word = string.len( userPasswd ) - 1
			sum = math.pow(10,word)			

			uci:set("proftpd","profile" .. i,"enable", userEnable)
			uci:set("proftpd","profile" .. i,"name",userName)
			uci:set("proftpd","profile" .. i,"password",userPasswd)
			if ( word > -1 ) then
				uci:set("proftpd","profile" .. i,"sum",sum)
			else
				uci:set("proftpd","profile" .. i,"sum","")
			end			
			uci:set("proftpd","profile" .. i,"usb1_rw",usb1)
			uci:set("proftpd","profile" .. i,"usb2_rw",usb2)
			uci:set("proftpd","profile" .. i,"uplo_speed",upValue)
			uci:set("proftpd","profile" .. i,"downlo_speed",downValue)
		end
		
		uci:commit("proftpd")
		uci:apply("proftpd")
		--uci:apply("qos")
		
	end
	
	luci.template.render("expert_configuration/ftp")
	
end

function action_port_config()

        local apply = luci.http.formvalue("sysSubmit")

        if apply then
                local port1speed  = luci.http.formvalue("port1speed")
                local port1duplex = luci.http.formvalue("port1duplex")
                local port2speed  = luci.http.formvalue("port2speed")
                local port2duplex = luci.http.formvalue("port2duplex")
                local port3speed  = luci.http.formvalue("port3speed")
                local port3duplex = luci.http.formvalue("port3duplex")
                local port4speed  = luci.http.formvalue("port4speed")
                local port4duplex = luci.http.formvalue("port4duplex")
                local port5speed  = luci.http.formvalue("port5speed")
                local port5duplex = luci.http.formvalue("port5duplex")

				if string.match(port1speed, "(%w+)") then
					port1speed = string.match(port1speed, "(%w+)")
					uci:set("port_status", "port1", "speed", port1speed )
				end	
				if string.match(port1duplex, "(%a+)") then
					port1duplex = string.match(port1duplex, "(%a+)")
					uci:set("port_status", "port1", "duplex", port1duplex )
				end	
				if string.match(port2speed, "(%w+)") then
					port2speed = string.match(port2speed, "(%w+)")
					uci:set("port_status", "port2", "speed", port2speed )
				end	
				if string.match(port2duplex, "(%a+)") then
					port2duplex = string.match(port2duplex, "(%a+)")
					uci:set("port_status", "port2", "duplex", port2duplex )
				end	
				if string.match(port3speed, "(%w+)") then
					port3speed = string.match(port3speed, "(%w+)")
					uci:set("port_status", "port3", "speed", port3speed )
				end	
				if string.match(port3duplex, "(%a+)") then
					port3duplex = string.match(port3duplex, "(%a+)")
					uci:set("port_status", "port3", "duplex", port3duplex )
				end	
				if string.match(port4speed, "(%w+)") then
					port4speed = string.match(port4speed, "(%w+)")
					uci:set("port_status", "port4", "speed", port4speed )
				end	
				if string.match(port4duplex, "(%a+)") then
					port4duplex = string.match(port4duplex, "(%a+)")
					uci:set("port_status", "port4", "duplex", port4duplex )
				end	
				if string.match(port5speed, "(%w+)") then
					port5speed = string.match(port5speed, "(%w+)")
					uci:set("port_status", "port5", "speed", port5speed )
				end	
				if string.match(port5duplex, "(%a+)") then
					port5duplex = string.match(port5duplex, "(%a+)")
					uci:set("port_status", "port5", "duplex", port5duplex )
				end	

                uci:commit("port_status")
                uci:apply("port_status")
        end

        luci.template.render("expert_configuration/PortConfig")

end

function action_remote_snmp()

        local snmp_enable = luci.http.formvalue("snmp_enable")
	
        if snmp_enable == "1" then
		
			local snmp_serverPort = luci.http.formvalue("snmp_serverPort")
			local ServerAccess = luci.http.formvalue("ServerAccess")
			local SecuredIP = luci.http.formvalue("SecuredIP")

			if not (SecuredIP) then
				SecuredIP = "0.0.0.0"
			end

			local snmp_getCommunity = luci.http.formvalue("snmp_getCommunity")
			local snmp_setCommunity = luci.http.formvalue("snmp_setCommunity")
			local snmp_sysLocation = luci.http.formvalue("snmp_sysLocation")
			local snmp_sysContact = luci.http.formvalue("snmp_sysContact")
			local trap_enable = luci.http.formvalue("trap_enable")

			uci:set("snmpd", "agent", "enable", snmp_enable)
			
			if string.match(snmp_serverPort, "(%d+)") then
				snmp_serverPort = string.match(snmp_serverPort, "(%d+)")
				uci:set("snmpd", "agent", "port", snmp_serverPort)
			end	
			if string.match(ServerAccess, "(%d)") then
				ServerAccess = string.match(ServerAccess, "(%d)")
				uci:set("snmpd", "agent", "serveraccess", ServerAccess)
			end	
			if string.match(SecuredIP, "(%d+.%d+.%d+.%d+)") then
				SecuredIP = string.match(SecuredIP, "(%d+.%d+.%d+.%d+)")
				uci:set("snmpd", "agent", "securedIP", SecuredIP)
			end
			
			uci:set("snmpd", "agent", "agentaddress", "UDP:"..snmp_serverPort)
			
			snmp_getCommunity = checkInjection(snmp_getCommunity)
			if snmp_getCommunity ~= false then
				uci:set("snmpd", "public", "community", snmp_getCommunity)
			end
			
			snmp_setCommunity = checkInjection(snmp_setCommunity)
			if snmp_setCommunity ~= false then
				uci:set("snmpd", "private", "community", snmp_setCommunity)
			end
			
			snmp_sysLocation = checkInjection(snmp_sysLocation)
			if snmp_sysLocation ~= false then
				uci:set("snmpd", "system", "sysLocation", snmp_sysLocation)
			end
			
			snmp_sysContact = checkInjection(snmp_sysContact)
			if snmp_sysContact ~= false then
				uci:set("snmpd", "system", "sysContact", snmp_sysContact)
			end
			
			if not ( "0" == trap_enable ) then
				uci:set("snmpd", "trapset", "enable", 1)
			else
				uci:set("snmpd", "trapset", "enable", 0)
			end

			if trap_enable == "1" then
			
				local snmp_trapIp = luci.http.formvalue("snmp_trapIp")
				local snmp_trapCommunity = luci.http.formvalue("snmp_trapCommunity")
				
				if string.match(snmp_trapIp, "(%d+.%d+.%d+.%d+)") then
					snmp_trapIp = string.match(snmp_trapIp, "(%d+.%d+.%d+.%d+)")
					uci:set("snmpd", "trapset", "trapip", snmp_trapIp)
				end
				
				snmp_trapCommunity = checkInjection(snmp_trapCommunity)
				if snmp_trapCommunity ~= false then
					uci:set("snmpd", "trapset", "community", snmp_trapCommunity)
				end

			end
			
			uci:commit("snmpd")
			uci:apply("snmpd")
	
        elseif snmp_enable == "0" then	
			local ServerAccess = luci.http.formvalue("ServerAccess")
			
			if string.match(ServerAccess, "(%d)") then
				ServerAccess = string.match(ServerAccess, "(%d)")
				uci:set("snmpd", "agent", "serveraccess", ServerAccess)
			end	
			sys.exec("kill `pidof snmpd`")
			uci:set("snmpd", "agent", "enable", snmp_enable)
			uci:set("snmpd", "trapset", "enable", 0)
			uci:commit("snmpd")
			uci:apply("snmpd")
        end
	luci.template.render("expert_configuration/snmp")
end

function checkInjection(str)

        if nil ~= string.match(str,"'") then
			return false
        end
	
        if nil ~= string.match(str,"`") then
			return false
        end

        if nil ~= string.match(str,"\"") then
			return false
        end

        if nil ~= string.match(str,"<") then
			return false
        end

        if nil ~= string.match(str,">") then
			return false
        end

        return str

end

function tran16to10(str , index)

		local  temp1
		local  temp2
		local sum  = 0
	
		temp1 = string.sub(str , 1,1)
		temp2 = string.sub(str , 2,2)


		if ( temp1 == "A") or ( temp1 == "a" ) then
			sum = 16 * 10			
		elseif  ( temp1 == "B") or ( temp1 == "b") then
			sum = 16 * 11
		elseif  ( temp1 == "C") or ( temp1 == "c") then
			sum = 16 * 12
		elseif  ( temp1 == "D") or ( temp1 == "d") then
			sum = 16 * 13
		elseif  ( temp1 == "E") or ( temp1 == "e") then
			sum = 16 * 14
		elseif  ( temp1 == "F") or ( temp1 == "f") then
			sum = 16 * 15
		else
			sum = temp1 * 16
		end 

		if ( temp2 == "A") or ( temp2 == "a") then
			sum =  sum +  10
		elseif  ( temp2 == "B") or ( temp2 == "b") then
			sum =  sum +  11
		elseif  ( temp2 == "C") or ( temp2 == "c") then
			sum =  sum +  12
		elseif  ( temp2 == "D") or ( temp2 == "d") then
			sum =  sum +  13
		elseif  ( temp2 == "E") or ( temp2 == "e") then
			sum =  sum +  14
		elseif  ( temp2 == "F") or ( temp2 == "f") then
			sum =  sum +  15	
		else
			sum = sum + temp2
		end 
	
		sum = sum + index
		sum = string.format("%02X" , sum)		
        return sum
end

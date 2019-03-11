--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 4040 2009-01-16 12:35:25Z Cyrus $
]]--
module("luci.controller.easy.easy", package.seeall)
local sys = require("luci.sys")
local uci = require("luci.model.uci").cursor()

function index()
	
	local root = node()
	if not root.lock then
		root.target = alias("easy")
		root.index = true
	end
	local libuci = require("luci.model.uci").cursor()
	local uinfo = libuci:get_all("account")
	local uname = {}
	local unum = 1
	for k in pairs(uinfo) do 
		if k ~= "general" then
			uname[unum]=k
			unum = unum + 1
		end
	end	
	
	--local uid = nixio.getuid()
	--local uname = nixio.getpw(uid)
	
	local page   = node("easy")
	page.target  = alias("easy", "networkmap")
	page.title   = "Easy Mode"
	page.sysauth = uname 
	page.sysauth_authenticator = "htmlauth"
	page.order   = 10
	page.index = true

	local page   = node("easy", "passWarning") --Darren
        page.target  = call("action_chgPwd")
        page.title   = "Change Password"
        page.order   = 11
--[[	
	local page   = node("easy", "agreement") --Darren
        page.target  = call("action_agreement")
        page.title   = "Agreement"
        page.order   = 12
]]--	
	local page   = node("easy", "passWarning", "streamboost_node")
	page.target  = template("streamboost_node")
	page.title   = "Streamboost node"
	page.order   = 12
	
	local page   = node("easy", "networkmap")
	page.target  = call("action_networkmap")
	page.title   = "Network Map"
	page.order   = 13
	
	local page   = node("easy", "networkmap", "streamboost_node")
	page.target  = template("streamboost_node")
	page.title   = "Streamboost node"
	page.order   = 13	
	
	local page   = node("easy", "game")
	page.target  = template("easy_game/game")
	page.title   = "Game Engine"
	page.order   = 14
	
	local page   = node("easy", "pwsaving")
	page.target  = call("action_wifi_schedule")
	page.title   = "Power Saving"
	page.order   = 15
	
	entry({"easy", "ctfilter"}, call("action_ctfilter"), "Parental Control", 16)
	entry({"easy", "internet"}, call("action_internet"), "Internet Set", 17)
	entry({"easy", "firewall"}, template("easy_firewall/firewall"), "Firewall", 18)
	entry({"easy", "wlan"}, call("action_wireless"), "Wireless Security", 19)
	entry({"easy", "logout"}, call("action_logout"), "Log Out", 20)
	
	entry({"easy", "scannetwork"}, call("action_scan_network"), "Scan Network", 21)
	entry({"easy", "easysetting"}, template("easy_set"), "Easy Setting", 22)
	entry({"easy", "easysetapply"}, call("action_easy_set_apply"), "Easy Setting", 23)

-- Modification for eaZy123 error, EMG2926-Q10A, WenHsiang, 2011/12/15	
	local page   = node("easy", "eaZy123")
	page.target  = template("genie")
	page.title   = "eaZy123"
	page.order   = 24

	local page   = node("easy", "eaZy123", "genie2")
    page.target  = call("action_eaZy123_flag")	
	page.title   = "eaZy123"
	page.order   = 25

    local page   = node("easy", "eaZy123", "genie2-1")
	page.target  = template("genie2-1")
    page.title   = "eaZy123"
    page.order   = 26

    local page   = node("easy", "eaZy123", "genie2-6")        
    page.target  = call("action_wan_internet_connection")
    page.title   = "eaZy123"
    page.order   = 27

    local page   = node("easy", "eaZy123", "genie2_error")
    page.target  = template("genie2_error")
    page.title   = "eaZy123"
    page.order   = 28

    local page   = node("easy", "eaZy123", "genie2_error2")
    page.target  = template("genie2_error2")
    page.title   = "eaZy123"
    page.order   = 29

    local page   = node("easy", "eaZy123", "genie3")
    page.target  = template("genie3")
    page.title   = "eaZy123"
    page.order   = 30

    local page   = node("easy", "eaZy123", "genie4")
    page.target  = call("action_password")
    page.title   = "eaZy123"
    page.order   = 31

    local page   = node("easy", "eaZy123", "genie5")
    page.target  = call("action_completion")	
    page.title   = "eaZy123"
    page.order   = 32
-- Modification for eaZy123 error, EMG2926-Q10A, WenHsiang, 2011/12/15

    local page   = node("easy","mobile")
	page.target  = template("mobile")
	page.target  = call("action_mobile")
	page.title   = "Mobile"
	page.order   = 33
-- Modification for mobile webpage, EMG2926-Q10A, Michael, 2012/2/16

-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/6
    local page   = node("easy","mobile_wizard02")
	page.target  = template("mobile_wizard02")
	page.title   = "mobile_wizard02"
	page.order   = 34

    local page   = node("easy","mobile_wizard03")
	page.target  = call("action_mobile_wizard03")
	page.title   = "mobile_wizard03"
	page.order   = 35

    local page   = node("easy","mobile_wirelessSecurity")
	page.target  = template("mobile_wirelessSecurity")
	page.title   = "mobile_wirelessSecurity"
	page.order   = 36

    local page   = node("easy","mobile_wirelessSecurity2")
	page.target  = call("action_mobile_wirelessSecurity2")
	page.title   = "mobile_wirelessSecurity2"
	page.order   = 37

    local page   = node("easy","mobile_mainMenu")
	page.target  = template("mobile_mainMenu")
	page.title   = "mobile_mainMenu"
	page.order   = 38

    local page   = node("easy","mobile_networkmap01")
	page.target  = template("mobile_networkmap01")
	page.title   = "mobile_networkmap01"
	page.order   = 39

    local page   = node("easy","mobile_routerinfo")
	page.target  = template("mobile_routerinfo")
	page.title   = "mobile_routerinfo"
	page.order   = 40

    local page   = node("easy","mobile_networkmap02")
	page.target  = template("mobile_networkmap02")
	page.title   = "mobile_networkmap02"
	page.order   = 41

    local page   = node("easy","mobile_networkmap03")
	page.target  = template("mobile_networkmap03")
	page.title   = "mobile_networkmap03"
	page.order   = 42

    local page   = node("easy","mobile_networkmap04")
	page.target  = template("mobile_networkmap04")
	page.title   = "mobile_networkmap04"
	page.order   = 43

    local page   = node("easy","mobile_personalM")
	page.target  = call("action_mobile_personalM")
	page.title   = "mobile_personalM"
	page.order   = 44

    local page   = node("easy","mobile_wireless")
	page.target  = call("action_mobile_wireless")
	page.title   = "mobile_wireless"
	page.order   = 45

    local page   = node("easy","mobile_powerSaving")
	--page.target  = template("mobile_powerSaving")
	page.target  = call("action_mobile_wifi_schedule")
	page.title   = "mobile_powerSaving"
	page.order   = 46

    local page   = node("easy","mobile_contentFiliter")
	page.target  = call("action_mobile_contentFiliter")
	page.title   = "mobile_contentFiliter"
	page.order   = 47

    local page   = node("easy","mobile_bandwidthMgmt")
	page.target  = call("mobile_bandwidth_easy_set_apply")
	page.title   = "mobile_bandwidthMgmt"
	page.order   = 48
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/6


entry({"easy", "mobile_easysetapply"}, call("mobile_action_easy_set_apply"), "Easy Setting", 49)
-- Addition for mobile_mainMenu, EMG2926-Q10A, Michael, 2012/3/13

end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())

	luci.http.redirect(luci.dispatcher.build_url())

end

-- After login, pop the change password page. Darren, 2012/01/02 
function action_chgPwd()
        local apply = luci.http.formvalue("apply")
        local ignore = luci.http.formvalue("ignore")
		local uname = luci.dispatcher.context.authuser
		
        if apply then

			local new_password = luci.http.formvalue("admpass")
			local password_len = string.len( new_password )
			
			if ( password_len > 30 ) then
				 luci.template.render("passWarning",{pwError = 2})
				 return
			end	

			local uname = luci.dispatcher.context.authuser
				
			new_password = checkInjection(new_password)
			if new_password ~= false then
				uci:set("account",uname ,"password",new_password)	
			end

			uci:commit("account")
			uci:apply("account")
			uci:commit("system")
			uci:apply("system")
			--luci.template.render("networkmap")
			local url = luci.dispatcher.build_url("expert","configuration")
			luci.http.redirect(url)				
				
        elseif ignore then

    	    --luci.template.render("networkmap")
			local url = luci.dispatcher.build_url("expert","configuration")
			luci.http.redirect(url)

        else
			local default_account = uci:get("account", uname ,"default")
			local password = uci:get("account", uname ,"password")
			
			if ( password == "supervisor" and uname == "supervisor" and default_account == "1" )
				or ( password == "1234" and uname == "admin" and default_account == "1" ) then
				 luci.template.render("passWarning")
			else
				local url = luci.dispatcher.build_url("expert","configuration")
				luci.http.redirect(url)
			end
		
        end

end
--[[
function action_agreement()

		local agreement = uci:get("system","main","agreement")
		
		if not agreement then
		
		    uci:set("system","main","agreement","1")	
			uci:commit("system")
			uci:apply("system")
			luci.template.render("agreement")
			
		else
		
			local apply = luci.http.formvalue("apply")
			
			if apply then
			
				local StreamboostAutoUpdate = luci.http.formvalue("StreamboostAutoUpdate")
			
				uci:set("appflow", "tccontroller","auto_update", StreamboostAutoUpdate)		
			
				uci:commit("appflow")
				uci:apply("appflow")
			end
				--luci.template.render("networkmap")
				local url = luci.dispatcher.build_url("expert","configuration")
				luci.http.redirect(url)
			
		end	
	
end
]]--
function action_networkmap()
	--luci.template.render("networkmap")
	local url = luci.dispatcher.build_url("expert","configuration")
	luci.http.redirect(url)
end

function action_scan_network()
	sys.exec("lltd.sh")
	sys.exec("ping 168.95.1.1 -c 1 > /var/ping_internet")
	return 1
end

function action_easy_set_apply()
	local job = luci.http.formvalue("easy_set_button_job")
	local mode = luci.http.formvalue("easy_set_button_mode")
	
	if job and mode then
		if job == "1" then
			uci:set("qos","general","game_enable",mode)			
			uci:commit("qos")
			--uci:apply("qos")
		elseif job == "2" then
			wifi_select = uci:get("system","main","power_saving_select")
			if wifi_select == "2.4G" then
				cfg = "wifi_schedule"
			else
				cfg = "wifi_schedule5G"
			end
			if mode == "1" then
				uci:set(cfg,"wlan","enabled","enable")
			else
				uci:set(cfg,"wlan","enabled","disable")
			end
			uci:commit(cfg)
			uci:apply(cfg)
		elseif job == "3" then
			uci:set("parental","general","enable",mode)
			uci:commit("parental")
			uci:apply("parental")
		elseif job == "4" then
			uci:set("firewall","general","dos_enable",mode)
			uci:commit("firewall")
			uci:apply("firewall")
		elseif job == "5" then			
			uci:set("appflow","tccontroller","enable_streamboost",mode)		
			if mode == "0" then
				uci:set("appflow","tccontroller","enable_streamboost",mode)
			end
			uci:commit("appflow")
			uci:apply("appflow")
		elseif job == "6" then
			uci:set("wireless","ath0","disabled",mode)
		else
			return 
		end
	end
	
	luci.template.render("networkmap")
end

function action_ctfilter()
	local keywords = luci.http.formvalue("url_str")
	if keywords then
		uci:set("parental","keyword","keywords",keywords)
		uci:commit("parental")
		uci:apply("parental")
	end
	
	luci.template.render("easy_ctfilter/parental_control")
end

function action_internet()
	local apply = luci.http.formvalue("apply")
	
	if apply then
	
		-- lock dns check, and it will be unlock after updating dns in update_sys_dns
		sys.exec("echo 1 > /var/update_dns_lock")
		local wan_proto = uci:get("network","wan","proto")
		sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")
	
        local connection_type = luci.http.formvalue("connectionType")                				

        if connection_type == "PPPOE" then

			local pppoeUser = luci.http.formvalue("pppoeUser")
			local pppoePass = luci.http.formvalue("pppoePass")
			local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
			local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")
					
			if not pppoeIdleTime then
				pppoeIdleTime=""
			end
					
			if not pppoeWanIpAddr then
				pppoeWanIpAddr=""
			end					
            	uci:set("network","wan","proto","pppoe")
           		uci:set("network","wan","username",pppoeUser)
            	uci:set("network","wan","password",pppoePass)
				uci:set("network","wan","demand",pppoeIdleTime)
				uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)

		elseif connection_type == "PPTP" then
		
			local pptpUser = luci.http.formvalue("pptpUser")
			local pptpPass = luci.http.formvalue("pptpPass")
			local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
			local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
			local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
			local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
			local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
			local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")

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
			uci:set("network","vpn","interface")
			
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
			uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
			uci:set("network","vpn","pptp_demand",pptpIdleTime)
			uci:set("network","vpn","pptp_serverip",pptp_serverIp)
			uci:set("network","vpn","pptpWanIPMode","1")
			uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)
			
		else			
			local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
			local Fixed_staticIp = luci.http.formvalue("staticIp")
			local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
			local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					
			if WAN_IP_Auto == "1" then
				uci:set("network","wan","proto","dhcp")
            else
				uci:set("network","wan","proto","static")
				uci:set("network","wan","ipaddr",Fixed_staticIp)
				uci:set("network","wan","netmask",Fixed_staticNetmask)
				uci:set("network","wan","gateway",Fixed_staticGateway)
            end
		end
			
		uci:set("network","general","config_section","wan")	
		uci:commit("network")	
        uci:apply("network")
				
	end
	
	luci.template.render("easy_internet/internet")
	
end

function action_wireless()
	require("luci.model.uci")
	local apply = luci.http.formvalue("apply")
	local enable_wps_btn = luci.http.formvalue("enable_wps_btn")
	local enable_wps_pin = luci.http.formvalue("enable_wps_pin")
	local wlanRadio = luci.http.formvalue("wlan_radio")
	local wpscfg="wps"
	local config_status
	local valid_pin="1"

	if apply then
		local cfg
		local section
		local wlanPwd = luci.http.formvalue("wlan_pwd")
		local wlanSSID = luci.http.formvalue("wlan_ssid")
		local wlanSec = luci.http.formvalue("wlan_sec")
		
		if wlanRadio == "2.4G" then
			cfg = "wireless"
			section = "ath0"
			wpscfg = "wps"
		elseif wlanRadio == "5G" then
			cfg = "wireless"
			section = "ath10"
			wpscfg = "wps5G"
		end

		wlanSSID = checkInjection(wlanSSID)
		if wlanSSID ~= false then
			uci:set(cfg,section,"ssid",wlanSSID)
		end

		if wlanSec == "none" then
			if section == "ath0" then
				uci:set("wireless", "wifi0","auth","OPEN") 
			end
			if section == "ath10" then
				uci:set("wireless", "wifi1","auth","OPEN") 
			end
			uci:set(cfg,section,"auth","NONE")
			uci:set(cfg,section,"encryption","NONE")
		elseif wlanSec == "WPA-PSK" then
			uci:set(cfg,section,"auth","WPAPSK")
			uci:set(cfg,section,"encryption","WPAPSK")

			wlanPwd = checkInjection(wlanPwd)
			if wlanPwd  ~= false then
				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
			end
		elseif wlanSec == "WPA2-PSK" then
			uci:set(cfg,section,"auth","WPA2PSK")
			uci:set(cfg,section,"encryption","WPA2PSK")
			
			wlanPwd = checkInjection(wlanPwd)
			if wlanPwd  ~= false then
				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
			end
		end

	        uci:commit(cfg)
                uci:apply(cfg)
		
		--Set wps conf with 1 here, the WPS status will be configured when you
		--execute "wps ath0/ath10 on"	
		uci:set(wpscfg,"wps","conf",1)
                uci:commit(wpscfg)

		local wps_enable = uci:get(wpscfg,"wps","enabled")

	        if (wps_enable == "1") then
                        sys.exec("wps "..section.." on")
                else
                        sys.exec("iwpriv "..section.." set WscConfStatus=2")
                end
	end

        local iface
        if wlanRadio then
                if wlanRadio == "2.4G" then
                       	iface = "ath0"
		       	wpscfg = "wps"
                elseif wlanRadio == "5G" then
                       	iface = "ath10"
			wpscfg = "wps5G"   
                end
        end

        local fd
        local wps_enable
	
	if enable_wps_btn then 
                wps_enable = uci:get(wpscfg,"wps","enabled")

                if (wps_enable == "0" ) then
                        fd = io.popen("wps "..iface.." on wps_btn &")
                        uci:set(wpscfg,"wps","enabled", 1)
						uci:commit(wpscfg)
                else
						fd = io.popen("wps "..iface.." on wps_btn &")
                end
	end
	
	if enable_wps_pin then
			wps_enable = uci:get(wpscfg,"wps","enabled")
		local pincode
		local pin_verify
			pincode = luci.http.formvalue("pin_code")
			if wlanRadio == "2.4G" then
				pin_verify = sys.exec("hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 " .. "wps_check_pin " .. pincode)
			elseif wlanRadio == "5G" then
				pin_verify = sys.exec("hostapd_cli -p /tmp/run/hostapd-wifi1/ -i ath10 " .. "wps_check_pin " .. pincode)
			end

		 if (wps_enable == "0" ) then	
				uci:set(wpscfg,"wps","enabled", 1)
				uci:commit(wpscfg)
				if ( pin_verify == pincode ) then
					fd = io.popen("wps "..iface.." on wps_pin ".. pincode .. " &")
				end
		 else
				if ( pin_verify == pincode ) then
					fd = io.popen("wps "..iface.." on wps_pin ".. pincode .. " &")
				end
		end
				
	end
	
	luci.template.render("easy_wireless/wireless_security", {
		SSID = uci:get("wireless","ath0","ssid"),
		security = uci:get("wireless","ath0","auth"),
		pwd = uci:get("wireless","ath0","WPAPSKkey"),
		SSID_5G = uci:get("wireless","ath10","ssid"),
		security_5G = uci:get("wireless","ath10","auth"),
		pwd_5G = uci:get("wireless","ath10","WPAPSKkey"),
		AP_PIN = uci:get(wpscfg,"wps","appin"),
		pin_valid = valid_pin
	})
end

function action_wifi_schedule()
	local cfg
	local apply = luci.http.formvalue("apply")
	local days = {"Everyday","Mon","Tue","Wed","Thu","Fri","Sat","Sun"}
	
	if apply then
		local radio = luci.http.formvalue("wlanRadio")
		
		if radio == "2.4G" then
			cfg = "wifi_schedule"
		else
			cfg = "wifi_schedule5G"
		end
		
		uci:set("system","main","power_saving_select",radio)
		uci:commit("system")
		
		for i, name in ipairs(days) do
			local prefixStr = "WLanSch" .. tonumber(i)-1
			local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)
			
			uci:set(cfg, token, "status_onoff", luci.http.formvalue(prefixStr .. "Radio"))
			uci:set(cfg, token, "start_hour",   luci.http.formvalue(prefixStr .. "StartHour"))
			uci:set(cfg, token, "start_min",    luci.http.formvalue(prefixStr .. "StartMin"))
			uci:set(cfg, token, "end_hour",     luci.http.formvalue(prefixStr .. "EndHour"))
			uci:set(cfg, token, "end_min",      luci.http.formvalue(prefixStr .. "EndMin"))

			if "1" == luci.http.formvalue(prefixStr .. "Enabled") then
				uci:set(cfg, token, "enabled", "1")
			else
				uci:set(cfg, token, "enabled", "0")
			end
		end
		
		uci:commit(cfg)
		uci:apply(cfg)
	end
	
	local wifi = {}
	local wifi5G = {}
	local wlan_radio = uci:get("system","main","power_saving_select")
	
	for i,v in ipairs(days) do
		local token = string.lower( v:sub( 1, 1 ) ) .. v:sub( 2, #v )

		wifi[i] = {status=uci:get("wifi_schedule",token,"status_onoff"),
					enabled=uci:get("wifi_schedule",token,"enabled"),
					start_hour=uci:get("wifi_schedule",token,"start_hour"),
					start_min=uci:get("wifi_schedule",token,"start_min"),
					end_hour=uci:get("wifi_schedule",token,"end_hour"),
					end_min=uci:get("wifi_schedule",token,"end_min")}
		wifi5G[i] = {status=uci:get("wifi_schedule5G",token,"status_onoff"),
					enabled=uci:get("wifi_schedule5G",token,"enabled"),
					start_hour=uci:get("wifi_schedule5G",token,"start_hour"),
					start_min=uci:get("wifi_schedule5G",token,"start_min"),
					end_hour=uci:get("wifi_schedule5G",token,"end_hour"),
					end_min=uci:get("wifi_schedule5G",token,"end_min")}
	end
	
	luci.template.render("easy_pwsave/power_saving", {
		wifi_radio = wlan_radio,
		wifi_sch = wifi,
		wifi5G_sch = wifi5G
	})
end

-- Modification for eaZy123 error, EMG2926-Q10A, WenHsiang, 2011/12/28
function action_eaZy123_flag()
    uci:set("system","main","eaZy123","1")		
	uci:commit("system")
	luci.template.render("genie2")
end

function action_wan_internet_connection()
    local genie2_1_apply = luci.http.formvalue("genie2-1_apply")

    if genie2_1_apply then
		-- lock dns check, and it will be unlock after updating dns in update_sys_dns
		sys.exec("echo 1 > /var/update_dns_lock")
		local wan_proto = uci:get("network","wan","proto")
		sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")
	
        local connection_type = luci.http.formvalue("connectionType")                				

        if connection_type == "PPPOE" then

			local pppoeUser = luci.http.formvalue("pppoeUser")
			local pppoePass = luci.http.formvalue("pppoePass")
			local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
			local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")
					
			if not pppoeIdleTime then
				pppoeIdleTime=""
			end
					
			if not pppoeWanIpAddr then
				pppoeWanIpAddr=""
			end
					
            		uci:set("network","wan","proto","pppoe")
           		uci:set("network","wan","username",pppoeUser)
            		uci:set("network","wan","password",pppoePass)
			uci:set("network","wan","demand",pppoeIdleTime)
			uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)

		elseif connection_type == "PPTP" then
		
			local pptpUser = luci.http.formvalue("pptpUser")
			local pptpPass = luci.http.formvalue("pptpPass")
			local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
			local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
			local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
			local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
			local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
			local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")

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
			uci:set("network","vpn","interface")
			
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
			uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
			uci:set("network","vpn","pptp_demand",pptpIdleTime)
			uci:set("network","vpn","pptp_serverip",pptp_serverIp)
			uci:set("network","vpn","pptpWanIPMode","1")
			uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)
			
		else			
			local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
			local Fixed_staticIp = luci.http.formvalue("staticIp")
			local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
			local Fixed_staticGateway = luci.http.formvalue("staticGateway")
			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			
			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
				if string.match(Server_dns1Type, "(%a+)") then
					Server_dns1Type = string.match(Server_dns1Type, "(%a+)")
					uci:set("network","wan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
				end
			elseif string.match(Server_dns1Type, "(%a+)") and string.match(Server_staticPriDns, "(%d+.%d+.%d+.%d+)") then
				Server_dns1Type = string.match(Server_dns1Type, "(%a+)")
				Server_staticPriDns = string.match(Server_staticPriDns, "(%d+.%d+.%d+.%d+)")
				uci:set("network","wan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			end
						
			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
				if string.match(Server_dns2Type, "(%a+)") then
					Server_dns2Type = string.match(Server_dns2Type, "(%a+)")
					uci:set("network","wan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
				end
			elseif string.match(Server_dns2Type, "(%a+)") and string.match(Server_staticSecDns, "(%d+.%d+.%d+.%d+)") then
				Server_dns2Type = string.match(Server_dns2Type, "(%a+)")
				Server_staticSecDns = string.match(Server_staticSecDns, "(%d+.%d+.%d+.%d+)")
				uci:set("network","wan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			end
					
			if WAN_IP_Auto == "1" then
				uci:set("network","wan","proto","dhcp")
            else
				uci:set("network","wan","proto","static")
				if string.match(Fixed_staticIp, "(%d+.%d+.%d+.%d+)") then
					Fixed_staticIp = string.match(Fixed_staticIp, "(%d+.%d+.%d+.%d+)")
					uci:set("network","wan","ipaddr",Fixed_staticIp)
				end
				if string.match(Fixed_staticNetmask, "(%d+.%d+.%d+.%d+)") then
					Fixed_staticNetmask = string.match(Fixed_staticNetmask, "(%d+.%d+.%d+.%d+)")
					uci:set("network","wan","netmask",Fixed_staticNetmask)
				end
				if string.match(Fixed_staticGateway, "(%d+.%d+.%d+.%d+)") then
					Fixed_staticGateway = string.match(Fixed_staticGateway, "(%d+.%d+.%d+.%d+)")
					uci:set("network","wan","gateway",Fixed_staticGateway)
				end
            end
		end
			
		uci:set("network","general","config_section","wan")	
		uci:commit("network")	
        uci:apply("network")
	end

    luci.template.render("genie2-6")
end

function action_password()
        local genie3_apply = luci.http.formvalue("genie3_apply")

        if genie3_apply then

           local new_password = luci.http.formvalue("new_password")
		   local uname = luci.dispatcher.context.authuser

			if not new_password then
				new_password = ""
			end

			new_password = checkInjection(new_password)
			if new_password ~= false then
				uci:set("account",uname ,"password",new_password)
			end
			
           --uci:set("system","main","pwd",new_password)
		   --uci:set("account",uname ,"password",new_password)
			uci:commit("account")
			uci:apply("account")
		   
           --uci:commit("system") 
           --uci:apply("system") 

        end

        local iface
        if wlanRadio then
                if wlanRadio == "2.4G" then
                       	iface = "ath0"
						wpscfg = "wps"
                elseif wlanRadio == "5G" then
                       	iface = "ath10"
						wpscfg = "wps5G"   
                end
        end
	
	luci.template.render("genie4", {
		SSID = uci:get("wireless","ath0","ssid"),
		security = uci:get("wireless","ath0","auth"),
		pwd = uci:get("wireless","ath0","WPAPSKkey"),
		SSID_5G = uci:get("wireless","ath10","ssid"),
		security_5G = uci:get("wireless","ath10","auth"),
		pwd_5G = uci:get("wireless","ath10","WPAPSKkey")
	})		

end

function action_completion()
	local genie4_apply = luci.http.formvalue("genie4_apply")
	local wlanRadio = luci.http.formvalue("wlanRadio")
	--local wps_enable = uci:get("wps","wps","enabled")
	--local wps5G_enable = uci:get("wps5G","wps","enabled")
	
	if genie4_apply then
		local cfg
		local section
		local wlanPwd = luci.http.formvalue("wlanPwd")
		local wlanSSID = luci.http.formvalue("wlanSSID")
		local wlanSec = luci.http.formvalue("wlanSec")
		
		if wlanRadio == "2.4G" then
			cfg = "wireless"
			section = "ath0"
			wpscfg = "wps"
		--elseif wlanRadio == "5G" then
			--cfg = "wireless"
			section5g = "ath10"
			wpscfg5g = "wps5G"
		end

		wlanSSID = checkInjection(wlanSSID)
		if wlanSSID ~= false then
			uci:set(cfg,section,"ssid",wlanSSID)
			uci:set(cfg,section5g,"ssid",wlanSSID)
		end
		
		if wlanSec == "none" then
			uci:set(cfg,section,"auth","OPEN")
			uci:set(cfg,section,"encryption","NONE")
			uci:set(cfg,section5g,"auth","OPEN")
			uci:set(cfg,section5g,"encryption","NONE")			
		elseif wlanSec == "WPA-PSK" then
			uci:set(cfg,section,"auth","WPAPSK")
			uci:set(cfg,section,"encryption","WPAPSK")
			uci:set(cfg,section5g,"auth","WPAPSK")
			uci:set(cfg,section5g,"encryption","WPAPSK")

			wlanPwd = checkInjection(wlanPwd)
			if wlanPwd  ~= false then
				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
				uci:set(cfg,section5g,"WPAPSKkey", wlanPwd)	
			end			
		elseif wlanSec == "WPA2-PSK" then
			uci:set(cfg,section,"auth","WPA2PSK")
			uci:set(cfg,section,"encryption","WPA2PSK")
			uci:set(cfg,section5g,"auth","WPA2PSK")
			uci:set(cfg,section5g,"encryption","WPA2PSK")

			wlanPwd = checkInjection(wlanPwd)
			if wlanPwd  ~= false then
				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
				uci:set(cfg,section5g,"WPAPSKkey", wlanPwd)	
			end			
		end
		
		uci:commit(cfg)
		uci:apply(cfg)
		--WPS function
		--Set wps conf with 1 here, the WPS status will be configured when you
		--execute "wps ath0 on"
		uci:set(wpscfg,"wps","conf","1")
		uci:commit(wpscfg)
		uci:set(wpscfg5g,"wps","conf","1")
		uci:commit(wpscfg5g)		

		--if wlanRadio == "2.4G" then
			--if (wps_enable == "1") then
                        	--sys.exec("wps ath0 on")
                	--else
                        	--sys.exec("iwpriv ath0 set WscConfStatus=2")
                	--end			
		--elseif wlanRadio == "5G" then
			--if (wps5G_enable == "1") then
                        	--sys.exec("wps ath10 on")
                	--else
                        	--sys.exec("iwpriv ath10 set WscConfStatus=2")
                	--end	
		--end                
	end
	
	luci.template.render("genie5")
end
-- Modification for eaZy123 error, EMG2926-Q10A, WenHsiang, 2011/12/28
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/7
function action_mobile()
   uci:set("system","main","eaZy123","1")
   uci:commit("system")
   luci.template.render("mobile")
end
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/6



-- Addition for mobile, EMG2926-Q10A, Michael, 2012/3/13 
function mobile_action_easy_set_apply()
	local job = luci.http.formvalue("easy_set_button_job")
	local mode = luci.http.formvalue("easy_set_button_mode")
	
	if job and mode then
		if job == "1" then
			uci:set("qos","general","game_enable",mode)
			
			local tbl = uci:get_all("qos","priority")
			local qostbl = {}
			qostbl[tbl["game"]] = "game"
			qostbl[tbl["voip"]] = "voip"
			qostbl[tbl["web"]] = "web"
			qostbl[tbl["media"]] = "media"
			qostbl[tbl["ftp"]] = "ftp"
			qostbl[tbl["mail"]] = "mail"
			qostbl[tbl["others"]] = "others"
				
			if mode == "1" then
				uci:set("qos","general","enable",mode)
				
				for k,name in pairs(qostbl) do
					if name == "game" then
						key = k
						break
					end
				end
				
				local idx = tonumber(key)
				if idx ~= 7 then
					for i=idx,6 do
						local tmp = qostbl[tostring(i+1)]
						qostbl[tostring(i)] = tmp
					end
					qostbl["7"] = "game"
					
					for i=idx,7 do
						uci:set("qos","priority", qostbl[tostring(i)], i)
					end
				end
				
				-- configure shapper
				if "0" == uci:get("qos","shaper","port_rate_eth0") then
					uci:set("qos","shaper", "port_status_eth0", 0)
				else
					uci:set("qos","shaper", "port_status_eth0", mode)
				end
				
				if "0" == uci:get("qos","shaper","port_rate_lan") then
					uci:set("qos","shaper", "port_status_lan", 0)
				else
					uci:set("qos","shaper", "port_status_lan", mode)
				end
			else
				local tmp = qostbl["7"]
				qostbl["7"] = qostbl["6"]
				qostbl["6"] = tmp
				
				uci:set("qos","priority", qostbl["7"], "7")
				uci:set("qos","priority", qostbl["6"], "6")
			end
			uci:commit("qos")
			uci:apply("qos")
		elseif job == "2" then
			wifi_select = uci:get("system","main","power_saving_select")
			if wifi_select == "2.4G" then
				cfg = "wifi_schedule"
			else
				cfg = "wifi_schedule5G"
			end
			if mode == "1" then
				uci:set(cfg,"wlan","enabled","enable")
			else
				uci:set(cfg,"wlan","enabled","disable")
			end
			uci:commit(cfg)
			uci:apply(cfg)
		elseif job == "3" then
			uci:set("parental","keyword","enable",mode)
			uci:commit("parental")
			uci:apply("parental")
		elseif job == "4" then
			uci:set("qos","general","enable",mode)
			uci:commit("qos")
			uci:apply("qos")
		elseif job == "5" then
			uci:set("firewall","general","dos_enable",mode)
			uci:commit("firewall")
			uci:apply("firewall")
		elseif job == "6" then
			uci:set("wireless","ath0","disabled",mode)
		else
			return 
		end
	end
	
	luci.template.render("mobile_mainMenu")
end

function action_mobile_wizard03()
    local mobile_wizard02_apply = luci.http.formvalue("mobile_wizard02_apply")

    if mobile_wizard02_apply then
		-- lock dns check, and it will be unlock after updating dns in update_sys_dns
		sys.exec("echo 1 > /var/update_dns_lock")
		local wan_proto = uci:get("network","wan","proto")
		sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")
	
        local connection_type = luci.http.formvalue("connectionType")                				

        if connection_type == "PPPOE" then

			local pppoeUser = luci.http.formvalue("pppoeUser")
			local pppoePass = luci.http.formvalue("pppoePass")
			local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
			local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")
					
			if not pppoeIdleTime then
				pppoeIdleTime=""
			end
					
			if not pppoeWanIpAddr then
				pppoeWanIpAddr=""
			end
					
            		uci:set("network","wan","proto","pppoe")
            		uci:set("network","wan","username",pppoeUser)
            		uci:set("network","wan","password",pppoePass)
			uci:set("network","wan","demand",pppoeIdleTime)
			uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)

		elseif connection_type == "PPTP" then
		
			local pptpUser = luci.http.formvalue("pptpUser")
			local pptpPass = luci.http.formvalue("pptpPass")
			local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
			local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
			local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
			local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
			local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
			local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")

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
			uci:set("network","vpn","interface")
			
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
			uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
			uci:set("network","vpn","pptp_demand",pptpIdleTime)
			uci:set("network","vpn","pptp_serverip",pptp_serverIp)
			uci:set("network","vpn","pptpWanIPMode","1")
			uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)
			
		else			
			local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
			local Fixed_staticIp = luci.http.formvalue("staticIp")
			local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
			local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					
			if WAN_IP_Auto == "1" then
				uci:set("network","wan","proto","dhcp")
            else
				uci:set("network","wan","proto","static")
				uci:set("network","wan","ipaddr",Fixed_staticIp)
				uci:set("network","wan","netmask",Fixed_staticNetmask)
				uci:set("network","wan","gateway",Fixed_staticGateway)
            end
		end
			
		uci:set("network","general","config_section","wan")	
		uci:commit("network")	
        uci:apply("network")
	end
	
	luci.template.render("mobile_wizard03")
end

function action_mobile_wirelessSecurity2()
	local mobile_wirelessSecurity_apply = luci.http.formvalue("mobile_wirelessSecurity_apply")
	local wlanRadio = luci.http.formvalue("wlanRadio")
	
	if mobile_wirelessSecurity_apply then
		local cfg
		local section
		local wlanPwd = luci.http.formvalue("wlanPwd")
		local wlanSSID = luci.http.formvalue("wlanSSID")
		local wlanSec
		
		if wlanRadio == "2.4G" then
			cfg = "wireless"
			section = "ath0"
			wpscfg = "wps"
			wlanSec = luci.http.formvalue("wlanSec")
		elseif wlanRadio == "5G" then
			cfg = "wireless5G"
			section = "ath10"
			wpscfg = "wps5G"
			wlanSec = luci.http.formvalue("wlanSec2")
		end

		uci:set(cfg,section,"ssid",wlanSSID)
		if wlanSec == "none" then
			uci:set(cfg,section,"auth","OPEN")
			uci:set(cfg,section,"encryption","NONE")
		elseif wlanSec == "WPA-PSK" then
			uci:set(cfg,section,"auth","WPAPSK")
			uci:set(cfg,section,"encryption","WPAPSK")
			uci:set(cfg,section,"WPAPSKkey", wlanPwd)
		elseif wlanSec == "WPA2-PSK" then
			uci:set(cfg,section,"auth","WPA2PSK")
			uci:set(cfg,section,"encryption","WPA2PSK")
			uci:set(cfg,section,"WPAPSKkey", wlanPwd)
		end
		
	    uci:commit(cfg)
        uci:apply(cfg)
	end
	
	luci.template.render("mobile_wirelessSecurity2")
end
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/7

-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/21
function action_mobile_wireless()
	local mobile_wireless_apply = luci.http.formvalue("mobile_wireless_apply")
	local wlanRadio = luci.http.formvalue("wlanRadio")
	
	if mobile_wireless_apply then
		local cfg
		local section
		local wlanPwd = luci.http.formvalue("wlanPwd")
		local wlanSSID = luci.http.formvalue("wlanSSID")
		local wlanSec
		
		if wlanRadio == "2.4G" then
			cfg = "wireless"
			section = "ath0"
			wpscfg = "wps"
			wlanSec = luci.http.formvalue("wlanSec")
		elseif wlanRadio == "5G" then
			cfg = "wireless"
			section = "ath10"
			wpscfg = "wps5G"
			wlanSec = luci.http.formvalue("wlanSec2")
		end

		uci:set(cfg,section,"ssid",wlanSSID)
		if wlanSec == "none" then
			uci:set(cfg,section,"auth","OPEN")
			uci:set(cfg,section,"encryption","NONE")
		elseif wlanSec == "WPA-PSK" then
			uci:set(cfg,section,"auth","WPAPSK")
			uci:set(cfg,section,"encryption","WPAPSK")
			uci:set(cfg,section,"WPAPSKkey", wlanPwd)
		elseif wlanSec == "WPA2-PSK" then
			uci:set(cfg,section,"auth","WPA2PSK")
			uci:set(cfg,section,"encryption","WPA2PSK")
			uci:set(cfg,section,"WPAPSKkey", wlanPwd)
		end
		
	    uci:commit(cfg)
        uci:apply(cfg)
	end
	
	luci.template.render("mobile_wireless")
end
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/21

-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/26
function action_mobile_contentFiliter()
	local keywords = luci.http.formvalue("url_str")
	if keywords then
		uci:set("parental","keyword","keywords",keywords)
		uci:commit("parental")
		uci:apply("parental")
	end
	
	luci.template.render("mobile_contentFiliter")
end
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/3/26

-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/4/2
function action_mobile_personalM()
	local current_mac = luci.http.formvalue("current_mac")
	local output_hostName
	local output_ipAdd
	local output_macAdd
	
	if current_mac then
		for line in io.lines("/tmp/dhcp.leases") do
			local sNum, macAdd, ipAdd, hostName, macAdd2 = line:match("(%d+) ([a-zA-F0-9:]+) ([0-9.]+)%s([a-zA-Z0-9-*]+)%s([a-zA-F0-9:*]+)")		
			if (macAdd == current_mac) then
				output_hostName = hostName
				output_ipAdd    = ipAdd
				output_macAdd   = macAdd
			end
		end
	end

	luci.template.render("mobile_personalM", {
		HOST = output_hostName,
		IP   = output_ipAdd,
		MAC  = output_macAdd
	})
end
-- Addition for mobile, EMG2926-Q10A, WenHsiang, 2012/4/2


function mobile_bandwidth_easy_set_apply()
         local service = luci.http.formvalue("easy_set_service")
         local stars = luci.http.formvalue("easy_set_bandwidth")	
                     local tbl = uci:get_all("qos","priority")
			local qostbl = {}
			qostbl[tbl["game"]] = "game"
			qostbl[tbl["voip"]] = "voip"
			qostbl[tbl["web"]] = "web"
			qostbl[tbl["media"]] = "media"
			qostbl[tbl["ftp"]] = "ftp"
			qostbl[tbl["mail"]] = "mail"
			qostbl[tbl["others"]] = "others"
 
                     if service and stars then
                       for i=1,7 do  
                         if stars == uci:get("qos","priority",qostbl[tostring(i)]) then
                         local pre_stars=uci:get("qos","priority",service)        
                         uci:set("qos","priority", service, stars)
                         uci:set("qos","priority", qostbl[tostring(i)], pre_stars)
                         end
		       end        
                            uci:commit("qos")
			    uci:apply("qos")   
                      end
                     luci.template.render("mobile_bandwidthMgmt")
end
-- Addition for mobile, EMG2926-Q10A, Michael, 2012/3/27


-- Addition for mobile, EMG2926-Q10A, Darren, 2012/4/04 --START--
function action_mobile_wifi_schedule()

	local cfg
        local apply = luci.http.formvalue("apply_str")
        local days = {"Everyday","Mon","Tue","Wed","Thu","Fri","Sat","Sun"}
	local job = luci.http.formvalue("pwSaving_job")
	local mode = luci.http.formvalue("pwSaving_mode")
	local setting = luci.http.formvalue("pwSaving_setting")
				
	if setting == "1" then
								
		if job and mode then						
			local radio = luci.http.formvalue("wlanRadio")

            		if radio == "2.4G" then
            		
                		cfg = "wifi_schedule"
                		uci:set("system","main","power_saving_select",radio)
                		uci:commit("system")
				local everyday_24g = uci:get(cfg, "everyday", "enabled")
				local tmp_status_24g				

                		for i, name in ipairs(days) do
                			local prefixStr = "WLanSch" .. tonumber(i)-1
                    			local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)
					
					tmp_status_24g = uci:get(cfg, token, "status_onoff")	
					if tmp_status_24g == "0" then
                    				uci:set(cfg, token, "status_onoff", "1")
					end
            			end
            			-- if mode(everyday) = 1; others value must set "0".	
            			if job == "1" then
					uci:set(cfg,"everyday","enabled",mode)
					if mode == "1" then
						uci:set(cfg,"mon","enabled","0")
						uci:set(cfg,"tue","enabled","0")
						uci:set(cfg,"wed","enabled","0")
        	       				uci:set(cfg,"thu","enabled","0")
						uci:set(cfg,"fri","enabled","0")
						uci:set(cfg,"sat","enabled","0")
						uci:set(cfg,"sun","enabled","0")
					end
				-- if everyday_24g=1 ; others could not set value.
				elseif job == "2" then
					if everyday_24g == "0" then
						uci:set(cfg,"mon","enabled",mode)
					end
				elseif job == "3" then
					if everyday_24g == "0" then
						uci:set(cfg,"tue","enabled",mode)
					end
				elseif job == "4" then
					if everyday_24g == "0" then
						uci:set(cfg,"wed","enabled",mode)	
					end
	            		elseif job == "5" then
					if everyday_24g == "0" then
						uci:set(cfg,"thu","enabled",mode)
					end
	            		elseif job == "6" then
					if everyday_24g == "0" then
						uci:set(cfg,"fri","enabled",mode)
					end
				elseif job == "7" then
					if everyday_24g == "0" then
						uci:set(cfg,"sat","enabled",mode)
					end
				elseif job == "8" then
					if everyday_24g == "0" then
						uci:set(cfg,"sun","enabled",mode)
					end
				end
                                
        		else
        				
            			cfg = "wifi_schedule5G"
                        
		                uci:set("system","main","power_saving_select",radio)
                		uci:commit("system")
				local everyday_5g = uci:get(cfg, "everyday", "enabled")
				local tmp_status_5g				

                		for i, name in ipairs(days) do
                			local prefixStr = "WLanSch" .. tonumber(i)-1
			                local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)

					tmp_status_5g = uci:get(cfg, token, "status_onoff")
                                        if tmp_status_5g == "0" then
		                    		uci:set(cfg, token, "status_onoff", "1")
					end
             			end
                		-- if mode(everyday) = 1; others value must set "0".		
                		if job == "1" then
					uci:set(cfg,"everyday","enabled",mode)
					if mode == "1" then
						uci:set(cfg,"mon","enabled","0")
						uci:set(cfg,"tue","enabled","0")
						uci:set(cfg,"wed","enabled","0")
        	       				uci:set(cfg,"thu","enabled","0")
						uci:set(cfg,"fri","enabled","0")
						uci:set(cfg,"sat","enabled","0")
						uci:set(cfg,"sun","enabled","0")
					end
				-- if everyday_24g=1 ; others could not set value.
				elseif job == "2" then
					if everyday_5g == "0" then
						uci:set(cfg,"mon","enabled",mode)
					end
				elseif job == "3" then
					if everyday_5g == "0" then
						uci:set(cfg,"tue","enabled",mode)
					end
				elseif job == "4" then
					if everyday_5g == "0" then
						uci:set(cfg,"wed","enabled",mode)
					end
            			elseif job == "5" then
					if everyday_5g == "0" then
						uci:set(cfg,"thu","enabled",mode)
					end
	            		elseif job == "6" then
					if everyday_5g == "0" then
						uci:set(cfg,"fri","enabled",mode)
					end
				elseif job == "7" then
					if everyday_5g == "0" then
						uci:set(cfg,"sat","enabled",mode)
					end
				elseif job == "8" then
					if everyday_5g == "0" then
						uci:set(cfg,"sun","enabled",mode)
					end
				end
            		end
                
            	uci:commit(cfg)
            	uci:apply(cfg)
												
		end
		
	end
		
    	if apply == "1" then
        
                local radio = luci.http.formvalue("wlanRadio")
								
                if radio == "2.4G" then
                				
                        cfg = "wifi_schedule"
                        uci:set("system","main","power_saving_select",radio)
                	uci:commit("system")
			local tmp_status_24g
                	for i, name in ipairs(days) do
                        	local prefixStr = "WLanSch" .. tonumber(i)-1
                        	local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)
		
				tmp_status_24g = uci:get(cfg, token, "status_onoff")
                                if tmp_status_24g == "0" then
                                	uci:set(cfg, token, "status_onoff", "1")
                                end		
                        	uci:set(cfg, token, "start_hour",   luci.http.formvalue(prefixStr .. "StartHour"))
                        	uci:set(cfg, token, "start_min",    luci.http.formvalue(prefixStr .. "StartMin"))
                        	uci:set(cfg, token, "end_hour",     luci.http.formvalue(prefixStr .. "EndHour"))
                        	uci:set(cfg, token, "end_min",      luci.http.formvalue(prefixStr .. "EndMin"))
                	end
                        
                else
                				
                        cfg = "wifi_schedule5G"
                        
                        uci:set("system","main","power_saving_select",radio)
                	uci:commit("system")
			local tmp_status_5g
                	for i, name in ipairs(days) do
                        	local prefixStr = "WLanSch" .. tonumber(i)-1
                        	local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)
			
				tmp_status_5g = uci:get(cfg, token, "status_onoff")
                                if tmp_status_5g == "0" then
                                	uci:set(cfg, token, "status_onoff", "1")
                                end
                        	uci:set(cfg, token, "start_hour",   luci.http.formvalue(prefixStr .. "StartHour_5G"))
                        	uci:set(cfg, token, "start_min",    luci.http.formvalue(prefixStr .. "StartMin_5G"))
                        	uci:set(cfg, token, "end_hour",     luci.http.formvalue(prefixStr .. "EndHour_5G"))
                        	uci:set(cfg, token, "end_min",      luci.http.formvalue(prefixStr .. "EndMin_5G"))
                	end
                end

                
                uci:commit(cfg)
                uci:apply(cfg)
    
	end

        local wifi = {}
        local wifi5G = {}
        local wlan_radio = uci:get("system","main","power_saving_select")

        for i,v in ipairs(days) do
                local token = string.lower( v:sub( 1, 1 ) ) .. v:sub( 2, #v )

                wifi[i] = {status=uci:get("wifi_schedule",token,"status_onoff"),
                                        enabled=uci:get("wifi_schedule",token,"enabled"),
                                        start_hour=uci:get("wifi_schedule",token,"start_hour"),
                                        start_min=uci:get("wifi_schedule",token,"start_min"),
                                        end_hour=uci:get("wifi_schedule",token,"end_hour"),
                                        end_min=uci:get("wifi_schedule",token,"end_min")}
                wifi5G[i] = {status=uci:get("wifi_schedule5G",token,"status_onoff"),
                                        enabled=uci:get("wifi_schedule5G",token,"enabled"),
                                        start_hour=uci:get("wifi_schedule5G",token,"start_hour"),
                                        start_min=uci:get("wifi_schedule5G",token,"start_min"),
                                        end_hour=uci:get("wifi_schedule5G",token,"end_hour"),
                                        end_min=uci:get("wifi_schedule5G",token,"end_min")}
        end
        
        luci.template.render("mobile_powerSaving", {
                wifi_radio = wlan_radio,
                wifi_sch = wifi,
                wifi5G_sch = wifi5G
        })
end
-- Addition for mobile, EMG2926-Q10A, Darren, 2012/4/04 --END--

function checkInjection(str)

        if nil ~= string.match(str,"'") then
			return false
        end

        if nil ~= string.match(str,"-") then
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

#!/bin/sh
. /etc/functions.sh
append DRIVERS "ar71xx"

wlanconfig() {
	[ -n "${DEBUG}" ] && echo wlanconfig "$@"
	/usr/sbin/wlanconfig "$@"
}

iwconfig() {
	[ -n "${DEBUG}" ] && echo iwconfig "$@"
	/usr/sbin/iwconfig "$@"
}

iwpriv() {
	[ -n "${DEBUG}" ] && echo iwpriv "$@"
	/usr/sbin/iwpriv "$@"
}

find_ar71xx_phy() {
	local device="$1"

	local macaddr="$(config_get "$device" macaddr | tr 'A-Z' 'a-z')"
	config_get phy "$device" phy
	[ -z "$phy" -a -n "$macaddr" ] && {
		cd /sys/class/net
		for phy in $(ls -d wifi* 2>&-); do
			[ "$macaddr" = "$(cat /sys/class/net/${phy}/address)" ] || continue
			config_set "$device" phy "$phy"
			break
		done
		config_get phy "$device" phy
	}
	[ -n "$phy" -a -d "/sys/class/net/$phy" ] || {
		echo "phy for wifi device $1 not found"
		return 1
	}
	[ -z "$macaddr" ] && {
		config_set "$device" macaddr "$(cat /sys/class/net/${phy}/address)"
	}
	return 0
}

guest_wlan () {
	local action=$1
	local iface=$2
	local iface="ath3"
	#Guest WLAN 2.4G use
	local ipaddr
	local ipmask
	local dnsmasq_pid
	#local bandwidth_manage
	#local max_bandwidth
	
	#Guest WLAN 5G use
	local ipaddr_5G
	local ipmask_5G
	local dnsmasq_pid_5G
	#local bandwidth_manage_5G=$(uci_get wireless ath13 guest_bandwidth_enable)
	#local max_bandwidth_5G=$(uci_get wireless ath13 guest_max_bandwidth)
	#max_bandwidth_5G=$max_bandwidth_5G"kbit"

	local ath13_disabled_5G=$(uci_get wireless ath13 disabled)
	local guest_wlan_5G_enabled=$(uci_get wireless ath13 enable_guest_wlan)

	local wan_iface
	local wan_proto

	if [ -f "/var/run/dnsmasq.pid.$iface" ]; then
		dnsmasq_pid=$(cat /var/run/dnsmasq.pid.$iface)
		kill $dnsmasq_pid
		rm /var/run/dnsmasq.pid.$iface
		rm /tmp/Guest_dnsmasq24G
	fi

	if [ -f "/var/run/dnsmasq.pid.ath13" ]; then
		dnsmasq_pid_5G=$(cat /var/run/dnsmasq.pid.ath13)
		kill $dnsmasq_pid_5G
		rm /var/run/dnsmasq.pid.ath13
	fi	

	defaultwan=$(uci get network.general.defaultWan)
	wan_proto=$(uci_get network $defaultwan proto)
	if [ "$wan_proto" == "pppoe" ] || [ "$wan_proto" == "pptp" ];then
		wan_iface="$proto"-"$defaultwan"
	else
		wan_iface=$(uci_get network $defaultwan ifname)
	fi

	#tc qdisc del dev $iface root 2>/dev/null
	#tc qdisc del dev ath13 root 2>/dev/null
        #tc qdisc del dev fc root 2>/dev/null
        #tc qdisc del dev pppoe-$defaultwan root 2>/dev/null
        #tc qdisc del dev pptp-$defaultwan root 2>/dev/null	

	if [ "$action" == "start" ]; then
		#bandwidth management
		#bandwidth_manage=$(uci_get wireless $iface guest_bandwidth_enable)
		#qos_bandwidth_manage=$(uci_get qos general enable)
		#if [ "$bandwidth_manage" == "1" ]; then
			#max_bandwidth=$(uci_get wireless $iface guest_max_bandwidth)
			#max_bandwidth=$max_bandwidth"kbit"
			##download##
			#echo "download -- Guest WLAN 2.4G enable." >> /tmp/debug_log
			#tc qdisc add dev $iface root handle 10: htb default 20
			#tc class add dev $iface parent 10: classid 10:1 htb rate $max_bandwidth ceil $max_bandwidth
			#tc class add dev $iface parent 10:1 classid 10:20 htb rate 1kbit ceil $max_bandwidth prio 1
			#tc qdisc add dev $iface parent 10:20 handle 102: pfifo limit 10000
			
			#if Guest WLAN 2.4G enable too.
			#if [ "$ath13_disabled_5G" == "0" ] && [ "$guest_wlan_5G_enabled" == "1" ] && [ "$bandwidth_manage_5G" == "1" ]; then
				
				#echo "download -- Guest WLAN 5G enable too." >> /tmp/debug_log
				#tc qdisc add dev ath13 root handle 20: htb default 20
				#tc class add dev ath13 parent 20: classid 20:1 htb rate $max_bandwidth_5G ceil $max_bandwidth_5G
				#tc class add dev ath13 parent 20:1 classid 20:20 htb rate 1kbit ceil $max_bandwidth_5G prio 1
				#tc qdisc add dev ath13 parent 20:20 handle 103: pfifo limit 10000
			#fi
			
			##upload##
			#if [ "$qos_bandwidth_manage" == "0" ]; then
				#only 2.4G
				#if [ "$ath13_disabled_5G" != "0" ] || [ "$guest_wlan_5G_enabled" != "1" ] || [ "$bandwidth_manage_5G" != "1" ]; then
				
					#echo "upload -- Guest WLAN only 2.4G enable." >> /tmp/debug_log
					#tc qdisc add dev $wan_iface root handle 20: htb default 20
					#tc class add dev $wan_iface parent 20: classid 20:1 htb rate 1024mbps ceil 1024mbps
					#tc class add dev $wan_iface parent 20:1 classid 20:10 htb rate 1kbit ceil $max_bandwidth prio 2
					#tc class add dev $wan_iface parent 20:1 classid 20:20 htb rate 1kbit ceil 1024mbps prio 1
					#tc qdisc add dev $wan_iface parent 20:10 handle 101: pfifo limit 10000
					#tc filter add dev $wan_iface parent 20: protocol ip prio 100 handle 10 fw classid 20:10
					#iptables -t mangle -D PREROUTING -i ath3 -j MARK --set-mark 10
					#iptables -t mangle -A PREROUTING -i ath3 -j MARK --set-mark 10
				
				#else 
				##if Guest WLAN 2.4G enable too. (2.4G & 5G both)
					
					#echo "upload -- Guest WLAN 2.4G & 5G both enable." >> /tmp/debug_log
					#tc qdisc add dev $wan_iface root handle 30: htb default 20
					#tc class add dev $wan_iface parent 30: classid 30:1 htb rate 1024mbps ceil 1024mbps
					#tc class add dev $wan_iface parent 30:1 classid 30:10 htb rate 1kbit ceil $max_bandwidth prio 2		#2.4G
					#tc class add dev $wan_iface parent 30:1 classid 30:20 htb rate 1kbit ceil $max_bandwidth_5G prio 2	#5G
					#tc class add dev $wan_iface parent 30:1 classid 30:30 htb rate 1kbit ceil 1024mbps prio 1
					#tc qdisc add dev $wan_iface parent 30:10 handle 101: pfifo limit 10000		#2.4G
					#tc qdisc add dev $wan_iface parent 30:20 handle 100: pfifo limit 10000		#5G
					#tc filter add dev $wan_iface parent 30: protocol ip prio 100 handle 10 fw classid 30:10		#2.4G
					#tc filter add dev $wan_iface parent 30: protocol ip prio 100 handle 20 fw classid 30:20		#5G
					#iptables -t mangle -D PREROUTING -i ath3 -j MARK --set-mark 10	#2.4G
					#iptables -t mangle -A PREROUTING -i ath3 -j MARK --set-mark 10
					#iptables -t mangle -D PREROUTING -i ath13 -j MARK --set-mark 20	#5G
					#iptables -t mangle -A PREROUTING -i ath13 -j MARK --set-mark 20	
									
				#fi
			#else
			#	/sbin/configure_qos restart
			#fi			
		#fi


		ipaddr=$(uci_get wireless $iface guest_ip)
		ipmask=$(uci_get wireless $iface guest_ip_mask)
		LAN_DHCP=$(uci get dhcp.lan.enabled)

		ifconfig $iface $ipaddr
		iwpriv $iface ap_bridge 1
		
		if [ "$LAN_DHCP" == "1" ]; then
			local args="-C /tmp/dnsmasq.conf -z -a $ipaddr"
			local start="10"
			local end="32"
			local leasetime="720m"
			eval "$(ipcalc.sh $ipaddr $ipmask $start $end)"
			append args "-K -F $START,$END,$NETMASK,$leasetime"
			dnsmasq $args
			echo $args >/tmp/Guest_dnsmasq24G
			dnsmasq_pid=$(ps | grep "dnsmasq -C /tmp/dnsmasq.conf -z -a $ipaddr" | grep -v "grep" | awk '{print $1}')
			echo $dnsmasq_pid > /var/run/dnsmasq.pid.$iface
		fi	
	fi

	#if Guest WLAN 5G enable too.
	if [ "$ath13_disabled_5G" == "0" ] && [ "$guest_wlan_5G_enabled" == "1" ]; then
		ipaddr_5G=$(uci_get wireless ath13 guest_ip)
		ipmask_5G=$(uci_get wireless ath13 guest_ip_mask)
		LAN_DHCP=$(uci get dhcp.lan.enabled)
		ifconfig ath13 $ipaddr_5G
		iwpriv ath13 ap_bridge 1
		
		if [ "$LAN_DHCP" == "1" ]; then
			local start="10"
			local end="32"
			local leasetime="720m"
			local args_5G="-C /tmp/dnsmasq.conf -z -a $ipaddr_5G"
			eval "$(ipcalc.sh $ipaddr_5G $ipmask_5G $start $end)"

			append args_5G "-K -F $START,$END,$NETMASK,$leasetime"
			dnsmasq $args_5G
			dnsmasq_pid_5G=$(ps | grep "dnsmasq -C /tmp/dnsmasq.conf -z -a $ipaddr_5G" | grep -v "grep" | awk '{print $1}')
			echo $dnsmasq_pid_5G > /var/run/dnsmasq.pid.ath13
		fi
	fi
		
	/lib/firewall/firewall_guest_wlan
}


guest_wlan_5G () {
	local action=$1
	local iface=$2
	local iface="ath13"
	#Guest WLAN 5G use
	local ipaddr
	local ipmask
	local dnsmasq_pid
	#local bandwidth_manage
	#local max_bandwidth
	
	#Guest WLAN 2.4G use
	local ipaddr_24G
	local ipmask_24G
	local dnsmasq_pid_24G
	#local bandwidth_manage_24G=$(uci_get wireless ath3 guest_bandwidth_enable)
	#local max_bandwidth_24G=$(uci_get wireless ath3 guest_max_bandwidth)
	#max_bandwidth_24G=$max_bandwidth_24G"kbit"

	local ath3_disabled_24G=$(uci_get wireless ath3 disabled)
	local guest_wlan_24G_enabled=$(uci_get wireless ath3 enable_guest_wlan)

	local wan_iface
	local wan_proto

	if [ -f "/var/run/dnsmasq.pid.$iface" ]; then
		dnsmasq_pid=$(cat /var/run/dnsmasq.pid.$iface)
		kill $dnsmasq_pid
		rm /var/run/dnsmasq.pid.$iface
		rm /tmp/Guest_dnsmasq5G
	fi

	if [ -f "/var/run/dnsmasq.pid.ath3" ]; then
		dnsmasq_pid_24G=$(cat /var/run/dnsmasq.pid.ath3)
		kill $dnsmasq_pid_24G
		rm /var/run/dnsmasq.pid.ath3
	fi

	defaultwan=$(uci get network.general.defaultWan)
	wan_proto=$(uci_get network $defaultwan proto)
	if [ "$wan_proto" == "pppoe" ] || [ "$wan_proto" == "pptp" ];then
		wan_iface="$proto"-"$defaultwan"
	else
		wan_iface=$(uci_get network $defaultwan ifname)
	fi


	#tc qdisc del dev $iface root 2>/dev/null
	#tc qdisc del dev ath3 root 2>/dev/null
        #tc qdisc del dev vlan10 root 2>/dev/null
        #tc qdisc del dev pppoe-$defaultwan root 2>/dev/null
        #tc qdisc del dev pptp-$defaultwan root 2>/dev/null

	if [ "$action" == "start" ]; then
		#bandwidth management
		#bandwidth_manage=$(uci_get wireless $iface guest_bandwidth_enable)
		#qos_bandwidth_manage=$(uci_get qos general enable)
		#if [ "$bandwidth_manage" == "1" ]; then
			#max_bandwidth=$(uci_get wireless $iface guest_max_bandwidth)
			#max_bandwidth=$max_bandwidth"kbit"
			##download##
			#echo "download -- Guest WLAN 5G enable." >> /tmp/debug_log
			#tc qdisc add dev $iface root handle 10: htb default 20
			#tc class add dev $iface parent 10: classid 10:1 htb rate $max_bandwidth ceil $max_bandwidth
			#tc class add dev $iface parent 10:1 classid 10:20 htb rate 1kbit ceil $max_bandwidth prio 1
			#tc qdisc add dev $iface parent 10:20 handle 102: pfifo limit 10000
			
			#if Guest WLAN 2.4G enable too.
			#if [ "$ath3_disabled_24G" == "0" ] && [ "$guest_wlan_24G_enabled" == "1" ] && [ "$bandwidth_manage_24G" == "1" ]; then
				
				#echo "download -- Guest WLAN 2.4G enable too." >> /tmp/debug_log
				#tc qdisc add dev ath3 root handle 20: htb default 20
				#tc class add dev ath3 parent 20: classid 20:1 htb rate $max_bandwidth_24G ceil $max_bandwidth_24G
				#tc class add dev ath3 parent 20:1 classid 20:20 htb rate 1kbit ceil $max_bandwidth_24G prio 1
				#tc qdisc add dev ath3 parent 20:20 handle 103: pfifo limit 10000
			#fi
			
			##upload##
			#if [ "$qos_bandwidth_manage" == "0" ]; then
				#only 5G
				#if [ "$ath3_disabled_24G" != "0" ] || [ "$guest_wlan_24G_enabled" != "1" ] || [ "$bandwidth_manage_24G" != "1" ]; then
				
					#echo "upload -- Guest WLAN only 5G enable." >> /tmp/debug_log
					#tc qdisc add dev $wan_iface root handle 20: htb default 20
					#tc class add dev $wan_iface parent 20: classid 20:1 htb rate 1024mbps ceil 1024mbps
					#tc class add dev $wan_iface parent 20:1 classid 20:10 htb rate 1kbit ceil $max_bandwidth prio 2
					#tc class add dev $wan_iface parent 20:1 classid 20:20 htb rate 1kbit ceil 1024mbps prio 1
					#tc qdisc add dev $wan_iface parent 20:10 handle 101: pfifo limit 10000
					#tc filter add dev $wan_iface parent 20: protocol ip prio 100 handle 20 fw classid 20:10
					#iptables -t mangle -D PREROUTING -i ath13 -j MARK --set-mark 20
					#iptables -t mangle -A PREROUTING -i ath13 -j MARK --set-mark 20
				
				#else 
				##if Guest WLAN 2.4G enable too. (2.4G & 5G both)
					
					#echo "upload -- Guest WLAN 2.4G & 5G both enable." >> /tmp/debug_log
					#tc qdisc add dev $wan_iface root handle 30: htb default 20
					#tc class add dev $wan_iface parent 30: classid 30:1 htb rate 1024mbps ceil 1024mbps
					#tc class add dev $wan_iface parent 30:1 classid 30:10 htb rate 1kbit ceil $max_bandwidth_24G prio 2	#2.4G
					#tc class add dev $wan_iface parent 30:1 classid 30:20 htb rate 1kbit ceil $max_bandwidth prio 2		#5G
					#tc class add dev $wan_iface parent 30:1 classid 30:30 htb rate 1kbit ceil 1024mbps prio 1
					#tc qdisc add dev $wan_iface parent 30:10 handle 101: pfifo limit 10000		#2.4G
					#tc qdisc add dev $wan_iface parent 30:20 handle 100: pfifo limit 10000		#5G
					#tc filter add dev $wan_iface parent 30: protocol ip prio 100 handle 10 fw classid 30:10		#2.4G
					#tc filter add dev $wan_iface parent 30: protocol ip prio 100 handle 20 fw classid 30:20		#5G
					#iptables -t mangle -D PREROUTING -i ath13 -j MARK --set-mark 10	#2.4G
					#iptables -t mangle -A PREROUTING -i ath13 -j MARK --set-mark 10
					#iptables -t mangle -D PREROUTING -i ath13 -j MARK --set-mark 20	#5G
					#iptables -t mangle -A PREROUTING -i ath13 -j MARK --set-mark 20	
									
				#fi
			#else
			#	/sbin/configure_qos start
			#fi			
		#fi

		ipaddr=$(uci_get wireless $iface guest_ip)
		ipmask=$(uci_get wireless $iface guest_ip_mask)
		LAN_DHCP=$(uci get dhcp.lan.enabled)

		ifconfig $iface $ipaddr

		iwpriv $iface set NoForwarding=1
		
		if [ "$LAN_DHCP" == "1" ]; then
			local args="-C /tmp/dnsmasq.conf -z -a $ipaddr"
			local start="10"
			local end="32"
			local leasetime="720m"
			eval "$(ipcalc.sh $ipaddr $ipmask $start $end)"
			append args "-K -F $START,$END,$NETMASK,$leasetime"
			dnsmasq $args
			echo $args >/tmp/Guest_dnsmasq5G
			dnsmasq_pid=$(ps | grep "dnsmasq -C /tmp/dnsmasq.conf -z -a $ipaddr" | grep -v "grep" | awk '{print $1}')
			echo $dnsmasq_pid > /var/run/dnsmasq.pid.$iface
		fi
	fi

	#if Guest WLAN 2.4G enable too.
	if [ "$ath3_disabled_24G" == "0" ] && [ "$guest_wlan_24G_enabled" == "1" ]; then
		ipaddr_24G=$(uci_get wireless ath3 guest_ip)
		ipmask_24G=$(uci_get wireless ath3 guest_ip_mask)
		LAN_DHCP=$(uci get dhcp.lan.enabled)
		ifconfig ath3 $ipaddr_24G
		iwpriv ath3 ap_bridge 1
		
		if [ "$LAN_DHCP" == "1" ]; then
			local start="10"
			local end="32"
			local leasetime="720m"
			local args_24G="-C /tmp/dnsmasq.conf -z -a $ipaddr_24G"
			eval "$(ipcalc.sh $ipaddr_24G $ipmask_24G $start $end)"
			
			append args_24G "-K -F $START,$END,$NETMASK,$leasetime"
			dnsmasq $args_24G	
			dnsmasq_pid_24G=$(ps | grep "dnsmasq -C /tmp/dnsmasq.conf -z -a $ipaddr_24G" | grep -v "grep" | awk '{print $1}')
			echo $dnsmasq_pid_24G > /var/run/dnsmasq.pid.ath3
		fi
	fi	
		
	/lib/firewall/firewall_guest_wlan
}


scan_ar71xx() {
	local device="$1"
	local wds
	local adhoc sta ap disabled

	[ ${device%[0-9]} = "wifi" ] && config_set "$device" phy "$device"

	local ifidx=0
	local radioidx=${device#wifi}

	config_get vifs "$device" vifs
	for vif in $vifs; do
		config_get_bool disabled "$vif" disabled 0
		[ $disabled = 0 ] || continue

		local vifname
		[ $radioidx -gt 0 ] && vifname="ath${radioidx}$ifidx" || vifname="ath${ifidx}"

		config_get ifname "$vif" ifname
		config_set "$vif" ifname "${ifname:-$vifname}"
		
		config_get mode "$vif" mode
		case "$mode" in
			adhoc|sta|ap)
				append $mode "$vif"
			;;
			wds)
				config_get ssid "$vif" ssid
				[ -z "$ssid" ] && continue

				config_set "$vif" wds 1
				config_set "$vif" mode sta
				mode="sta"
				addr="$ssid"
				${addr:+append $mode "$vif"}
			;;
			*) echo "$device($vif): Invalid mode, ignored."; continue;;
		esac

		ifidx=$(($ifidx + 1))
	done

	case "${adhoc:+1}:${sta:+1}:${ap:+1}" in
		# valid mode combinations
		1::) wds="";;
		1::1);;
		:1:1)config_set "$device" nosbeacon 1;; # AP+STA, can't use beacon timers for STA
		:1:);;
		::1);;
		::);;
		*) echo "$device: Invalid mode combination in config"; return 1;;
	esac

	config_set "$device" vifs "${sta:+$sta }${ap:+$ap }${adhoc:+$adhoc }${wds:+$wds }"
}


load_ar71xx() {
	#for mod in $(cat /etc/modules.d/25-qca-wifi); do
	#	[ -d /sys/module/${mod} ] || insmod ${mod}
	#done
	
	## set mac address to 2.4G and 5G interface
        mac24G=$(cat /tmp/AR71XX_24G.dat | awk -F '=' '{print $2}')
        macchanger wifi0 -m $mac24G >>/dev/null
        mac5G=$(cat /tmp/AR71XX_5G.dat | awk -F '=' '{print $2}')
        macchanger wifi1 -m $mac5G >>/dev/null

}


unload_ar71xx() {
	#for mod in $(cat /etc/modules.d/25-qca-wifi | sed '1!G;h;$!d'); do
	#	[ -d /sys/module/${mod} ] && rmmod ${mod}
	#done
	echo "Not to remove kernel module when disable wifi function"
}


disable_ar71xx() {
	local device="$1"
	local parent

	find_ar71xx_phy "$device" || return 0
	config_get phy "$device" phy

	set_wifi_down "$device"

	include /lib/network
	cd /sys/class/net
	for dev in *; do
		[ -f /sys/class/net/${dev}/parent ] && { \
			local parent=$(cat /sys/class/net/${dev}/parent)
			[ -n "$parent" -a "$parent" = "$device" ] && { \
				[ -f "/var/run/wifi-${dev}.pid" ] &&
					kill "$(cat "/var/run/wifi-${dev}.pid")"
				ifconfig "$dev" down
				unbridge "$dev"
				wlanconfig "$dev" destroy
			}
		}
	done


	[ "$device" = "wifi0" ] && {
		led_ctrl WiFi_2G off
	} || {
		led_ctrl WiFi_5G off
	}

	#if GUI wifi button both disable, wps led must be OFF.
	GUI_wifi24G_disabled=$(uci_get wireless ath0 disabled)
        GUI_wifi5G_disabled=$(uci_get wireless ath10 disabled)
        if [ "$GUI_wifi24G_disabled" == "1" ] && [ "$GUI_wifi5G_disabled" == "1" ]; then
                led_ctrl WPS off
        fi

	nrvaps=$(find /sys/class/net/ -name 'ath*'|wc -l)
	[ ${nrvaps} -gt 0 ] || unload_ar71xx

	return 0
}

enable_ar71xx() {

	local device="$1"
	iwpriv "$device" enable_ol_stats 0
	load_ar71xx

	find_ar71xx_phy "$device" || return 0
	config_get phy "$device" phy

	#Set country code##############################################
	countrycode=$(fw_printenv countrycode | awk -F"=" '{print $2}')
	##TEST--default US
	countryid="841"
	if [ "$countrycode" == "" ]; then
		echo "No country code, use default value 'ff'"
			countrycode=ff
	fi

	case "$countrycode" in
		ff|FF) countryid="841" ;;
		e1|E1) countryid="756" ;;
		ee|EE) countryid="158" ;;
		ce|CE) countryid="124" ;;
	esac
	iwpriv "$phy" setCountryID $countryid
	################################################################
	#set dcs default disabled
	iwpriv "$phy" dcs_enable 0

	config_get Autochannel "$device" AutoChannelSelect
	config_get channel "$device" channel
	config_get vifs "$device" vifs
	config_get txpower "$device" txpower
	
	[ "$device" == "wifi1" ] && iwpriv wifi1 burst 1
	[ "$device" == "wifi0" ] && iwpriv wifi0 disablestats 0
	[ "$Autochannel" = "1" ] && channel=0
	[ auto = "$channel" ] && channel=0

	config_get_bool antdiv "$device" diversity
	config_get antrx "$device" rxantenna
	config_get anttx "$device" txantenna
	config_get_bool softled "$device" softled
	config_get antenna "$device" antenna
	config_get distance "$device" distance

	[ -n "$antdiv" ] && echo "antdiv option not supported on this driver"
	[ -n "$antrx" ] && echo "antrx option not supported on this driver"
	[ -n "$anttx" ] && echo "anttx option not supported on this driver"
	[ -n "$softled" ] && echo "softled option not supported on this driver"
	[ -n "$antenna" ] && echo "antenna option not supported on this driver"
	[ -n "$distance" ] && echo "distance option not supported on this driver"

	# Advanced ar71xx wifi per-radio parameters configuration
	config_get txchainmask "$device" txchainmask
	[ -n "$txchainmask" ] && iwpriv "$phy" txchainmask "$txchainmask"

	config_get rxchainmask "$device" rxchainmask
	[ -n "$rxchainmask" ] && iwpriv "$phy" rxchainmask "$rxchainmask"

	config_get AMPDU "$device" AMPDU
	[ -n "$AMPDU" ] && iwpriv "$phy" AMPDU "$AMPDU"

	config_get AMPDULim "$device" AMPDULim
	[ -n "$AMPDULim" ] && iwpriv "$phy" AMPDULim "$AMPDULim"


	for vif in $vifs; do
		local start_hostapd= vif_txpower= nosbeacon=
		config_get ifname "$vif" ifname
		config_get enc "$vif" encryption
		config_get eap_type "$vif" eap_type
		config_get mode "$vif" mode
		
		case "$mode" in
			sta) config_get_bool nosbeacon "$device" nosbeacon;;
			adhoc) config_get_bool nosbeacon "$vif" sw_merge 1;;
		esac
		[ "$nosbeacon" = 1 ] || nosbeacon=""
		[ -n "${DEBUG}" ] && echo wlanconfig "$vif" create wlandev "$phy" wlanmode "$mode" ${nosbeacon:+nosbeacon}
		ifname=$(/usr/sbin/wlanconfig "$vif" create wlandev "$phy" wlanmode "$mode" ${nosbeacon:+nosbeacon})
		[ $? -ne 0 ] && {
			echo "enable_ar71xx($device): Failed to set up $mode vif $ifname" >&2
			continue
		}
		config_set "$vif" ifname "$ifname"
		config_get hwmode "$device" hwmode auto
		htmode=auto

		config_get channel_width "$device" channel_width
		case "$channel_width" in
		80) htmode=HT80 ;;
		20)
			htmode=HT20
			;;
		*|40)	
			config_get channel_ext "$device" channel_ext 0
			case "$channel" in
            8|9|10|11|40|48|56|64|104|112|120|128|136|153|161)
				htmode=HT40-
				;;
            1|2|3|4|36|44|52|60|100|108|116|124|132|149|157)
				htmode=HT40+
				;;
			140|165)
				htmode=HT20
				;;
			*)
				case "$channel_ext" in
				0)
					htmode=HT40-
					;;
				*|1)
					htmode=HT40+
					;;
				esac					
				;;
			esac					
			;;
		esac
		
		if [ "$hwmode" == "11ac" ] && [ "$channel_width" == "Auto" ] && [ "$channel" != "132" ] && [ "$channel" != "136" ] && [ "$channel" != "140" ] && [ "$channel" != "165" ]; then  
			htmode=HT80
		fi

		pureg=0
		case "$hwmode:$htmode" in
		# The parsing stops at the first match so we need to make sure
		# these are in the right orders (most generic at the end)
			*bgn:HT20) hwmode=11NGHT20;;
			*bgn:HT40-) hwmode=11NGHT40MINUS;;
			*bgn:HT40+) hwmode=11NGHT40PLUS;;
			*gn:HT20) hwmode=11NGHT20;;
			*gn:HT40-) hwmode=11NGHT40MINUS;;
			*gn:HT40+) hwmode=11NGHT40PLUS;;
			*gn:*) hwmode=11NGHT40;;
			*an:HT20) hwmode=11NAHT20;;
			*an:HT40-) hwmode=11NAHT40MINUS;;
			*an:HT40+) hwmode=11NAHT40PLUS;;
			*an:*) hwmode=11NAHT40;;
			*ac:HT20) hwmode=11ACVHT20;;
			*ac:HT40+) hwmode=11ACVHT40PLUS;;
			*ac:HT40-) hwmode=11ACVHT40MINUS;;
			*ac:HT80) hwmode=11ACVHT80;;
			*n:HT20) hwmode=11NGHT20;;
			*n:HT40+) hwmode=11NGHT40PLUS;;
			*n:HT40-) hwmode=11NGHT40MINUS;;
			*b:*) hwmode=11B;;
			*bg:*) hwmode=11G;;
			*g:*) hwmode=11G; pureg=1;;
			*a:*) hwmode=11A;;
			*) hwmode=AUTO;;
		esac
		iwpriv "$ifname" mode "$hwmode"
		[ $pureg -gt 0 ] && iwpriv "$ifname" pureg "$pureg"

		config_get puren "$vif" puren
		[ -n "$puren" ] && iwpriv "$ifname" puren "$puren"
		
		[ "$device" == "wifi1" ] && iwpriv ath10 amsdu 2
		# echo " iwpriv "$ifname" amsdu 2"
		
		iwconfig "$ifname" channel "$channel" >/dev/null 2>/dev/null 

		config_get_bool hidden "$vif" hidden 0
		iwpriv "$ifname" hide_ssid "$hidden"
		
           	if [ "$countryid" == "756" ]; then
			iwpriv "$ifname" blockdfschan 0
                else
                        iwpriv "$ifname" blockdfschan 1
		fi                

		config_get_bool shortgi "$vif" shortgi
		[ -n "$shortgi" ] && iwpriv "$ifname" shortgi "${shortgi}"

		[ "$channel_width" == "Auto" ] && iwpriv "$ifname" disablecoext 0 || iwpriv "$ifname" disablecoext 1

		## Enable ZyXEL Coexistence Value
		iwpriv "$ifname" zyxelcoext 1 
		
		config_get chwidth "$vif" chwidth
		[ -n "$chwidth" ] && iwpriv "$ifname" chwidth "${chwidth}"

		config_get wds "$vif" wds
		case "$wds" in
			1|on|enabled) wds=1;;
			*) wds=0;;
		esac
		iwpriv "$ifname" wds "$wds" >/dev/null 2>&1

		config_get shortgi "$vif" shortgi
		[ -n "$shortgi" ] && iwpriv "$ifname" shortgi "$shortgi"
		
		config_get keytype "$ifname" keytype
		case "$enc" in
                        NONE) 
					start_hostapd=1
			;;
			wep*)
				case "$enc" in
					*shared*) iwpriv "$ifname" authmode 2;;
					*)        iwpriv "$ifname" authmode 1;;
				esac
				for idx in 1 2 3 4; do
					config_get key "$vif" "key${idx}"
					if [ "$keytype" = "1" ]; then
						iwconfig "$ifname" enc "[$idx]" "${key:-off}"
					else
						iwconfig "$ifname" enc "[$idx]" s:"${key:-off}" 
					fi
				done
				config_get key "$vif" key
				key="${key:-1}"
				case "$key" in
					[1234]) iwconfig "$ifname" enc "[$key]";;
					*) iwconfig "$ifname" enc "$key";;
				esac
			;;
			WPAPSK|WPA2PSK|WPA|WPA2|psk*|wpa*|8021x)
				start_hostapd=1
				config_get key "$vif" key
			;;
		esac

		case "$mode" in
			sta|adhoc)
				config_get addr "$vif" bssid
				[ -z "$addr" ] || { 
					iwconfig "$ifname" ap "$addr"
				}
			;;
		esac

		config_get_bool uapsd "$vif" uapsd 1
		iwpriv "$ifname" uapsd "$uapsd"

		config_get mcast_rate "$vif" mcast_rate
		[ -n "$mcast_rate" ] && iwpriv "$ifname" mcast_rate "${mcast_rate%%.*}"

		iwpriv "$ifname" mcastenhance 2

		#support independent repeater mode
		config_get vap_ind "$vif" vap_ind
		[ -n "$vap_ind" ] && iwpriv "$ifname" vap_ind "${vap_ind}"

		#support extender ap & STA
		config_get extap "$vif" extap
		[ -n "$extap" ] && iwpriv "$ifname" extap "${extap}"

		if [ "$hwmode" == "11B" ] || [ "$hwmode" == "11G" ] || [ "$hwmode" == "11A" ];  then  
			config_get frag "$vif" frag
			[ -n "$frag" ] && iwconfig "$ifname" frag "${frag%%.*}"
	
			config_get rts "$vif" rts
			[ -n "$rts" ] && iwconfig "$ifname" rts "${rts%%.*}"
	
			config_get_bool wmm "$vif" wmm
			[ -n "$wmm" ] && iwpriv "$ifname" wmm "$wmm"
		fi

		config_get_bool doth "$vif" doth
		[ -n "$doth" ] && iwpriv "$ifname" doth "$doth"

		config_get_bool stafwd "$vif" stafwd 0
		[ -n "$stafwd" ] && iwpriv "$ifname" stafwd "$stafwd"

		config_get maclist "$vif" maclist
		[ -n "$maclist" ] && {
			# flush MAC list
			iwpriv "$ifname" maccmd 3
			for mac in $maclist; do
				iwpriv "$ifname" addmac "$mac"
			done
		}

		config_get macfilter "$vif" macfilter
		case "$macfilter" in
			allow)
				iwpriv "$ifname" maccmd 1
			;;
			deny)
				iwpriv "$ifname" maccmd 2
			;;
			*)
				# default deny policy if mac list exists
				[ -n "$maclist" ] && iwpriv "$ifname" maccmd 2
			;;
		esac

		config_get nss "$vif" nss
		[ -n "$nss" ] && iwpriv "$ifname" nss "$nss"

		config_get vhtmcs "$vif" vhtmcs
		[ -n "$vhtmcs" ] && iwpriv "$ifname" vhtmcs "$vhtmcs"

		config_get chwidth "$vif" chwidth
		[ -n "$chwidth" ] && iwpriv "$ifname" chwidth "$chwidth"

		config_get chbwmode "$vif" chbwmode
		[ -n "$chbwmode" ] && iwpriv "$ifname" chbwmode "$chbwmode"

		config_get ldpc "$vif" ldpc
		[ -n "$ldpc" ] && iwpriv "$ifname" ldpc "$ldpc"

		config_get rx_stbc "$vif" rx_stbc
		[ -n "$rx_stbc" ] && iwpriv "$ifname" rx_stbc "$rx_stbc"

		config_get tx_stbc "$vif" tx_stbc
		[ -n "$tx_stbc" ] && iwpriv "$ifname" tx_stbc "$tx_stbc"

		config_get cca_thresh "$vif" cca_thresh
		[ -n "$cca_thresh" ] && iwpriv "$ifname" cca_thresh "$cca_thresh"

		config_get set11NRates "$vif" set11NRates
		[ -n "$set11NRates" ] && iwpriv "$ifname" set11NRates "$set11NRates"

		config_get set11NRetries "$vif" set11NRetries
		[ -n "$set11NRetries" ] && iwpriv "$ifname" set11NRetries "$set11NRetries"

		ifconfig "$ifname" up

		local net_cfg bridge
		net_cfg="$(find_net_config "$vif")"
		[ -z "$net_cfg" ] || {
			bridge="$(bridge_interface "$net_cfg")"
			config_set "$vif" bridge "$bridge"
			start_net "$ifname" "$net_cfg"
		}

		config_get ssid "$vif" ssid
		[ -n "$ssid" ] && {
			iwconfig "$ifname" essid on
			iwconfig "$ifname" essid ${ssid:+-- }"$ssid"
		} || {
			#if [ "$vif" == "ath0" ]; then
			#	mac_ssid=$(fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12)
			#else
			#	mac_ssid=$(cat /tmp/AR71XX_5G.dat | grep MacAddress | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12)
			#fi
			
			mac_ssid=$(fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12)
			if [ "$vif" == "ath0" ]; then
				ssid=ZyXEL$mac_ssid	
			else
				ssid=ZyXEL${mac_ssid}_5G
			fi
			

			iwconfig "$ifname" essid on
			iwconfig "$ifname" essid $ssid
		}

		set_wifi_up "$vif" "$ifname"

		# TXPower settings only work if device is up already
		# while atheros hardware theoretically is capable of per-vif (even per-packet) txpower
		# adjustment it does not work with the current atheros hal/madwifi driver

		config_get vif_txpower "$vif" txpower
		# use vif_txpower (from wifi-iface) instead of txpower (from wifi-device) if
		# the latter doesn't exist
		txpower="${txpower:-$vif_txpower}"
		[ "$device" == "wifi0" ] && {
		case $txpower in
			100) TxPower=0;;
			90) TxPower=20;;
			75) TxPower=19;;			
			50) TxPower=17;;
			25) TxPower=14;;
			10) TxPower=10;;
		esac
		} || {
		case $txpower in
			100) TxPower=0;;
			90) TxPower=21;;
			75) TxPower=20;;			
			50) TxPower=17;;
			25) TxPower=15;;
			10) TxPower=11;;
		esac
		}
		[ -z "$TxPower" ] || iwconfig "$ifname" txpower $TxPower
	
		## GUEST WIRELESS LAN( move guest wlan bandwidth manage part to /sbin/configure_qos guest_wlan )
		local guest_wlan="0"
		if [ "$vif" == "ath3" ]; then
			guest_wlan=$(uci_get wireless ath3 enable_guest_wlan)
			local system_mode=$(uci_get system main system_mode)
			if [ "$guest_wlan" == "1" -a "$system_mode" == "1" ]; then
		#		if [ "`lsmod | grep 'sch_htb'`" == "" ]; then
		#			#for guest WLAN
		#			insmod sch_htb
		#		fi
				echo "guest_wlan start $vif" >> /tmp/debug_log
				guest_wlan start $vif
			else
				echo "guest_wlan stop $vif" >> /tmp/debug_log
				guest_wlan stop $vif
			fi
		fi
		if [ "$vif" == "ath13" ]; then
			guest_wlan=$(uci_get wireless ath13 enable_guest_wlan)
			local system_mode=$(uci_get system main system_mode)
			if [ "$guest_wlan" == "1" -a "$system_mode" == "1" ]; then
		#		if [ "`lsmod | grep 'sch_htb'`" == "" ]; then
		#			#for guest WLAN
		#			insmod sch_htb
		#		fi
				echo "guest_wlan_5G start $vif" >> /tmp/debug_log
				guest_wlan_5G start $vif
			else
				echo "guest_wlan_5G stop $vif" >> /tmp/debug_log
				guest_wlan_5G stop $vif
			fi
		fi

		bridge_if=$(brctl show | grep $vif)
		if [ "$bridge_if" == "" ]; then
			if [ "$guest_wlan" == "0" ]; then
				brctl addif br-lan $vif
			fi
		else
			local system_mode=$(uci_get system main system_mode)			
			if [ "$guest_wlan" == "1" -a "$system_mode" == "1" ]; then
				brctl delif br-lan $vif
			fi
		fi
		
		case "$mode" in
			ap)
				config_get forwarding $ifname IntraBSS
				if [ "$forwarding" == 1 ]; then
					iwpriv "$ifname" ap_bridge 0
				else
					iwpriv "$ifname" ap_bridge 1
				fi

				if [ -n "$start_hostapd" ] && eval "type hostapd_setup_vif" 2>/dev/null >/dev/null; then
					hostapd_setup_vif "$vif" atheros no_nconfig || {
						echo "enable_ar71xx($device): Failed to set up hostapd for interface $ifname" >&2
						# make sure this wifi interface won't accidentally stay open without encryption
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi
			;;
			wds|sta)
				if eval "type wpa_supplicant_setup_vif" 2>/dev/null >/dev/null; then
					wpa_supplicant_setup_vif "$vif" athr || {
						echo "enable_ar71xx($device): Failed to set up wpa_supplicant for interface $ifname" >&2
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi
			;;
			adhoc)
				if eval "type wpa_supplicant_setup_vif" 2>/dev/null >/dev/null; then
					wpa_supplicant_setup_vif "$vif" athr || {
						echo "enable_ar71xx($device): Failed to set up wpa"
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi
		esac
	done

	### set txqueuelen to 1000
	ifconfig $device txqueuelen 1000
	echo 1000 >/proc/sys/net/core/netdev_max_backlog

	[ "$device" = "wifi0" ] && {
		led_ctrl WiFi_2G on
	} || {
		led_ctrl WiFi_5G on
	}
	iwpriv "$device" enable_ol_stats 1


	## GUEST WIRELESS LAN bandwidth manage
	#check QoS state if enable need to reload QoS 
        local qos_enable=$(uci get qos.general.enable)
        if [ "$qos_enable" == "1" ]; then
                /sbin/configure_qos restart
	else
		/sbin/configure_qos guest_wlan
        fi

}

check_ar71xx_device() {
	[ ${1%[0-9]} = "wifi" ] && config_set "$1" phy "$1"
	config_get phy "$1" phy
	[ -z "$phy" ] && {
		find_ar71xx_phy "$1" >/dev/null || return 0
		config_get phy "$1" phy
	}
	[ "$phy" = "$dev" ] && found=1
}


detect_ar71xx() {
	devidx=0
	load_ar71xx
	config_load wireless
	while :; do
		config_get type "radio$devidx" type
		[ -n "$type" ] || break
		devidx=$(($devidx + 1))
	done
	cd /sys/class/net
	[ -d wifi0 ] || return
	for dev in $(ls -d wifi* 2>&-); do
		found=0
		config_foreach check_ar71xx_device wifi-device
		[ "$found" -gt 0 ] && continue

		hwcaps=$(cat ${dev}/hwcaps)
		case "${hwcaps}" in
			*11bgn) mode_11=ng;;
			*11abgn) mode_11=ng;;
			*11an) mode_11=na;;
			*11an/ac) mode_11=ac;;
			*11abgn/ac) mode_11=ac;;
		esac

	devidx=$(($devidx + 1))
	done
}

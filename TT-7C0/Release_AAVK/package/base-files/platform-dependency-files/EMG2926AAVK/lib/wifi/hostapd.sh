hostapd_set_bss_options() {
	local var="$1"
	local vif="$2"
	local enc wep_rekey wpa_group_rekey wpa_pair_rekey wpa_master_rekey wps_possible

	config_get enc "$vif" encryption
	config_get wep_rekey        "$vif" wep_rekey        # 300
	config_get wpa_group_rekey  "$vif" wpa_group_rekey  # 300
	config_get wpa_pair_rekey   "$vif" wpa_pair_rekey   # 300
	config_get wpa_master_rekey "$vif" wpa_master_rekey # 640
	config_get_bool ap_isolate "$vif" IntraBSS

	config_get device "$vif" device
	config_get hwmode "$device" hwmode
	config_get phy "$device" phy

	append "$var" "ctrl_interface=/var/run/hostapd-$phy" "$N"

	if [ "$ap_isolate" -gt 0 ]; then
		append "$var" "ap_isolate=$ap_isolate" "$N"
	fi

	# Examples:
	# psk-mixed/tkip 	=> WPA1+2 PSK, TKIP
	# wpa-psk2/tkip+aes	=> WPA2 PSK, CCMP+TKIP
	# wpa2/tkip+aes 	=> WPA2 RADIUS, CCMP+TKIP
	# ...

	# TODO: move this parsing function somewhere generic, so that
	# later it can be reused by drivers that don't use hostapd

	# crypto defaults: WPA2 vs WPA1
	case "$enc" in
		wpa2*|*psk2*)
			wpa=2
			crypto="CCMP"
		;;
		*mixed*)
			wpa=3
			crypto="CCMP TKIP"
		;;
		*)
			wpa=1
			crypto="TKIP"
		;;
	esac

	# explicit override for crypto setting
	case "$enc" in
		*tkip+aes|*tkip+ccmp|*aes+tkip|*ccmp+tkip) crypto="CCMP TKIP";;
		*aes|*ccmp) crypto="CCMP";;
		*tkip) crypto="TKIP";;
	esac

	# enforce CCMP for 11ng and 11na
	case "$hwmode:$crypto" in
		*ng:TKIP|*na:TKIP) crypto="CCMP TKIP";;
	esac

	# use crypto/auth settings for building the hostapd config
	case "$enc" in
		*psk*)
			config_get psk "$vif" WPAPSKkey
			if [ ${#psk} -eq 64 ]; then
				append "$var" "wpa_psk=$psk" "$N"
			else
				append "$var" "wpa_passphrase=$psk" "$N"
			fi
			wps_possible=1
			[ -n "$wpa_group_rekey"  ] && append "$var" "wpa_group_rekey=$wpa_group_rekey" "$N"
			[ -n "$wpa_pair_rekey"   ] && append "$var" "wpa_ptk_rekey=$wpa_pair_rekey"    "$N"
			[ -n "$wpa_master_rekey" ] && append "$var" "wpa_gmk_rekey=$wpa_master_rekey"  "$N"
		;;
		##################################
		NONE)
			auth_algs=1
			crypto=
			wpa=0
		;;
		wpapsk|WPAPSK)
			wpa=1
			key_mgmt=WPA-PSK
			case "$enc" in
#				tkip|TKIP) crypto="TKIP" ;;
#				aes|AES) crypto="CCMP" ;;
				*) crypto="TKIP" ;;
			esac
			ieee8021x="0"
			config_get wpa_group_rekey "$vif" RekeyInterval
			config_get WPAPSKkey "$vif" "WPAPSKkey"

			if [ "$WPAPSKkey" == "" ]; then
				set_tmp_psk
				WPAPSKkey=$(cat /tmp/tmppsk)
				rm /tmp/tmppsk
			fi
			auth_algs=1
			append hostapd_cfg "wpa_passphrase=$WPAPSKkey" "$N"
		;;
		wpa2psk|WPA2PSK)
			config_get wpapskcompatible "$vif" WPAPSKCompatible
			if [ "$wpapskcompatible" = "0" ]; then
				wpa=2
				key_mgmt=WPA-PSK
				case "$enc" in
					tkip|TKIP) crypto="TKIP" ;;
					aes|AES) crypto="CCMP" ;;
					*) crypto="CCMP" ;;
				esac
			else
				wpa=3
				key_mgmt=WPA-PSK
				crypto="CCMP TKIP"
			fi
			ieee8021x="0"
			config_get wpa_group_rekey "$vif" RekeyInterval
			config_get WPAPSKkey "$vif" "WPAPSKkey"
			
			if [ "$WPAPSKkey" == "" ]; then
				set_tmp_psk
				WPAPSKkey=$(cat /tmp/tmppsk)
				rm /tmp/tmppsk
			fi
	
			append "$var" "wpa_passphrase=$WPAPSKkey" "$N"	
		;;
		wpa|WPA)
			wpa=1
			crypto="TKIP"
			ieee8021x="1"
			config_get wpa_group_rekey "$ifname" RekeyInterval
			##radius server
			radius_server_ip=$(uci_get wireless $ifname RADIUS_Server)
			radius_server_port=$(uci_get wireless $ifname RADIUS_Port)
			radius_key=$(uci_get wireless $ifname RADIUS_Key)
			session_timeout=$(uci_get wireless $ifname session_timeout_interval)
			append hostapd_cfg "auth_server_addr=$radius_server_ip" "$N"
			append hostapd_cfg "auth_server_port=$radius_server_port" "$N"
			append hostapd_cfg "auth_server_shared_secret=$radius_key" "$N"
			append hostapd_cfg "wpa_key_mgmt=WPA-EAP" "$N"
			append hostapd_cfg "eapol_key_index_workaround=1" "$N"	
			[ "$session_timeout" -gt 0 ] && append hostapd_cfg "eap_reauth_period=$session_timeout" "$N"
      	;;
		wpa2|WPA2)
			config_get wpacompatible "$vif" WPACompatible
			if [ "$wpacompatible" = "0" ]; then
				wpa=2
				crypto="CCMP"
			else
				wpa=3
				crypto="CCMP TKIP"
			fi
			ieee8021x="1"
		config_get wpa_group_rekey "$ifname" RekeyInterval
		##radius server
		radius_server_ip=$(uci_get wireless $ifname RADIUS_Server)
		radius_server_port=$(uci_get wireless $ifname RADIUS_Port)
		radius_key=$(uci_get wireless $ifname RADIUS_Key)
		session_timeout=$(uci_get wireless $ifname session_timeout_interval)
		PMKCachePeriod=$(uci_get wireless $ifname PMKCachePeriod)
		append hostapd_cfg "auth_server_addr=$radius_server_ip" "$N"
		append hostapd_cfg "auth_server_port=$radius_server_port" "$N"
		append hostapd_cfg "auth_server_shared_secret=$radius_key" "$N"
		append hostapd_cfg "wpa_key_mgmt=WPA-EAP" "$N"
		append hostapd_cfg "eapol_key_index_workaround=1" "$N"
		[ "$session_timeout" -gt 0 ] && append hostapd_cfg "eap_reauth_period=$session_timeout" "$N"
		[ "$PMKCachePeriod" -gt 0 ] && append hostapd_cfg "r0_key_lifetime=$PMKCachePeriod" "$N"
		
		;;
		
			
		#######################
		*wpa*)
			# required fields? formats?
			# hostapd is particular, maybe a default configuration for failures
			config_get auth_server "$vif" auth_server
			[ -z "$auth_server" ] && config_get auth_server "$vif" server
			append "$var" "auth_server_addr=$auth_server" "$N"
			config_get auth_port "$vif" auth_port
			[ -z "$auth_port" ] && config_get auth_port "$vif" port
			auth_port=${auth_port:-1812}
			append "$var" "auth_server_port=$auth_port" "$N"
			config_get auth_secret "$vif" auth_secret
			[ -z "$auth_secret" ] && config_get auth_secret "$vif" key
			append "$var" "auth_server_shared_secret=$auth_secret" "$N"
			config_get acct_server "$vif" acct_server
			[ -n "$acct_server" ] && append "$var" "acct_server_addr=$acct_server" "$N"
			config_get acct_port "$vif" acct_port
			[ -n "$acct_port" ] && acct_port=${acct_port:-1813}
			[ -n "$acct_port" ] && append "$var" "acct_server_port=$acct_port" "$N"
			config_get acct_secret "$vif" acct_secret
			[ -n "$acct_secret" ] && append "$var" "acct_server_shared_secret=$acct_secret" "$N"
			config_get nasid "$vif" nasid
			append "$var" "nas_identifier=$nasid" "$N"
			append "$var" "eapol_key_index_workaround=1" "$N"
			append "$var" "ieee8021x=1" "$N"
			append "$var" "wpa_key_mgmt=WPA-EAP" "$N"
			[ -n "$wpa_group_rekey"  ] && append "$var" "wpa_group_rekey=$wpa_group_rekey" "$N"
			[ -n "$wpa_pair_rekey"   ] && append "$var" "wpa_ptk_rekey=$wpa_pair_rekey"    "$N"
			[ -n "$wpa_master_rekey" ] && append "$var" "wpa_gmk_rekey=$wpa_master_rekey"  "$N"
		;;
		*wep*)
			config_get key "$vif" key
			key="${key:-1}"
			case "$key" in
				[1234])
					for idx in 1 2 3 4; do
						local zidx
						zidx=$(($idx - 1))
						config_get ckey "$vif" "key${idx}"
						[ -n "$ckey" ] && \
							append "$var" "wep_key${zidx}=$(prepare_key_wep "$ckey")" "$N"
					done
					append "$var" "wep_default_key=$((key - 1))"  "$N"
				;;
				*)
					append "$var" "wep_key0=$(prepare_key_wep "$key")" "$N"
					append "$var" "wep_default_key=0" "$N"
					[ -n "$wep_rekey" ] && append "$var" "wep_rekey_period=$wep_rekey" "$N"
				;;
			esac
			case "$enc" in
				*shared*)
					auth_algs=2
				;;
				*mixed*)
					auth_algs=3
				;;
			esac
			wpa=0
			crypto=
		;;
		8021x)
			# For Dynamic WEP 802.1x,maybe need more fields
			config_get auth_server "$vif" auth_server
			[ -z "$auth_server" ] && config_get auth_server "$vif" server
			append "$var" "auth_server_addr=$auth_server" "$N"
			config_get auth_port "$vif" auth_port
			[ -z "$auth_port" ] && config_get auth_port "$vif" port
			auth_port=${auth_port:-1812}
			append "$var" "auth_server_port=$auth_port" "$N"
			config_get auth_secret "$vif" auth_secret
			[ -z "$auth_secret" ] && config_get auth_secret "$vif" key
			config_get nasid "$vif" nasid
			append "$var" "nas_identifier=$nasid" "$N"
			append "$var" "ieee8021x=1" "$N"
			append "$var" "auth_server_shared_secret=$auth_secret" "$N"
			append "$var" "wep_rekey_period=300" "$N"
			append "$var" "eap_server=0" "$N"
			append "$var" "eapol_version=2" "$N"
			append "$var" "eapol_key_index_workaround=0" "$N"
			append "$var" "wep_key_len_broadcast=13" "$N"
			append "$var" "wep_key_len_unicast=13" "$N"
			auth_algs=1
			wpa=0
			crypto=
		;;
		*)
			wpa=0
			crypto=
		;;
	esac
	append "$var" "auth_algs=${auth_algs:-1}" "$N"
	append "$var" "wpa=$wpa" "$N"
	[ -n "$crypto" ] && append "$var" "wpa_pairwise=$crypto" "$N"
	[ -n "$ieee8021x" ] && append hostapd_cfg "ieee8021x=$ieee8021x" "$N"
	[ -n "$wpa_group_rekey" ] && append "$var" "wpa_group_rekey=$wpa_group_rekey" "$N"

	config_get ssid "$vif" ssid

	#config_get bridge "$vif" bridge
	bridge=$(uci_get wireless $vif group)

	config_get ieee80211d "$vif" ieee80211d
	config_get iapp_interface "$vif" iapp_interface

	config_get_bool wps_pbc "$vif" wps_pushbutton 0
	config_get_bool wps_label "$vif" wps_label 0

	config_get config_methods "$vif" wps_config
	[ "$wps_pbc" -gt 0 ] && append config_methods push_button

	#####################	
	local wps_enable=0	
	[ "$vif" == "ath0" ] &&{
		local hide_ssid=$(uci_get wireless ath0 hidden)
		wps_enable=$(uci_get wps wps enabled)
		wps_configured=$(uci_get wps wps conf)
	} 
	[ "$vif" == "ath10" ] &&{
		local hide_ssid=$(uci_get wireless ath10 hidden)
		wps_enable=$(uci_get wps5G wps enabled)
		wps_configured=$(uci_get wps5G wps conf)
	}
	
	if [ "$wps_configured" = "0" ];then
		wps_state=1
		ap_setup_locked=0
	elif [ "$wps_configured" = "1" ];then
		wps_state=2
		ap_setup_locked=1
	fi

	if [ "$(uci_get wps wps enabled)" == "0" ] && [ "$(uci_get wps5G wps enabled)" == "0" ];then
		led_ctrl WPS off
	else
		led_ctrl WPS on
	fi

	[ "$wps_enable" == "1" ] && [ "$hide_ssid" == "0" ] && {
		append hostapd_cfg "##### WPS configurations ###########" "$N"
		config_get device_type "$vif" wps_device_type "6-0050F204-1"
		config_get device_name "$vif" wps_device_name "OpenWrt AP"
		config_get manufacturer "$vif" wps_manufacturer "openwrt.org"

		append "$var" "eap_server=1" "$N"
		append "$var" "wps_state=$wps_state" "$N"
		#append "$var" "ap_setup_locked=$ap_setup_locked" "$N"
		append "$var" "device_type=$device_type" "$N"
                [ "$vif" == "ath0" ] &&{
			append "$var" "device_name=ZyXEL EMG2926-Q10A 2.4G AP" "$N"	
		}
		[ "$vif" == "ath10" ] &&{
			append "$var" "device_name=ZyXEL EMG2926-Q10A 5G AP" "$N"
		}
		append "$var" "manufacturer=ZyXEL Communications Corp." "$N"
		append "$var" "wps_rf_bands=ag" "$N"
		append "$var" "model_name=EMG2926-Q10A" "$N"
		append "$var" "model_number=EMG2926-Q10A" "$N"
		append "$var" "serial_number=$(fw_printenv| grep serialnum| awk -F'=' '{print $(2)}')" "$N"
		#append "$var" "upnp_iface=$bridge" "$N"
		local system_mode=$(uci_get system main system_mode)
		[ "$system_mode" == "1" ] && append "$var" "upnp_iface=$bridge" "$N"
		append "$var" "friendly_name=WPS Access Point" "$N"
		append "$var" "model_description=Wireless Access Point" "$N"
		append "$var" "config_methods=push_button display virtual_display virtual_push_button physical_push_button" "$N"
		#append "$var" "ap_pin=12345670" "$N"
		# fix the overlap session of WPS PBC for dual band AP
		macaddr=$(cat /sys/class/net/${vif}/address)
		uuid=$(echo "$macaddr" | sed 's/://g')
		[ -n "$uuid" ] && {
			append "$var" "uuid=87654321-9abc-def0-1234-$uuid" "$N"
		}
	}

	[ -n "$ssid" ] && {
		append "$var" "ssid=$ssid" "$N"
	} || { 
		#if [ "$vif" == "ath0" ]; then
		#		#mac_ssid=$(fw_printenv| grep serialnum| awk -F'=' '{print $(2)}'| tail -c 5)
		#		#ssid=ZyXEL$mac_ssid
		#		mac_ssid=$(fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12)
		#	else
		#		#mac_ssid=$(fw_printenv| grep serialnum| awk -F'=' '{print $(2)}'| tail -c 5)
		#		#ssid=ZyXEL"$mac_ssid"_5GHz
		#		mac_ssid=$(cat /tmp/AR71XX_5G.dat | grep MacAddress | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12)
		#	fi
		#ssid=ZyXEL$mac_ssid
		mac_ssid=$(fw_printenv ethaddr | awk -F'=' '{print $2}' |sed 's/\"//g' | sed 's/://g'|cut -c 7-12)
		if [ "$vif" == "ath0" ]; then
			ssid=ZyXEL$mac_ssid
		else
			ssid=ZyXEL${mac_ssid}_5G
		fi
		
		append "$var" "ssid=$ssid" "$N"
	}
	
	[ -n "$bridge" ] && append "$var" "bridge=$bridge" "$N"
	[ -n "$ieee80211d" ] && append "$var" "ieee80211d=$ieee80211d" "$N"
	[ -n "$iapp_interface" ] && append "$var" iapp_interface=$(uci_get_state network "$iapp_interface" ifname "$iapp_interface") "$N"

	if [ "$wpa" -ge "2" ]
	then
		# RSN -> allow preauthentication
		config_get rsn_preauth "$vif" rsn_preauth
		if [ -n "$bridge" -a "$rsn_preauth" = 1 ]
		then
			append "$var" "rsn_preauth=1" "$N"
			append "$var" "rsn_preauth_interfaces=$bridge" "$N"
		fi
		
		# RSN -> allow management frame protection
		config_get pmf "$vif" pmf
		if [ "$pmf" == "1" ]; then
			ieee80211w=1  ##WPA2/WPA2PSK enable PMF
		fi

		case "$ieee80211w" in
			[012])
				append "$var" "ieee80211w=$ieee80211w" "$N"
				[ "$ieee80211w" -gt "0" ] && {
					config_get ieee80211w_max_timeout "$vif" ieee80211w_max_timeout
					config_get ieee80211w_retry_timeout "$vif" ieee80211w_retry_timeout
					[ -n "$ieee80211w_max_timeout" ] && \
						append "$var" "assoc_sa_query_max_timeout=$ieee80211w_max_timeout" "$N"
					[ -n "$ieee80211w_retry_timeout" ] && \
						append "$var" "assoc_sa_query_retry_timeout=$ieee80211w_retry_timeout" "$N"
				}
			;;
		esac
	fi
}

hostapd_set_log_options() {
	local var="$1"
	local cfg="$2"
	local log_level log_80211 log_8021x log_radius log_wpa log_driver log_iapp log_mlme

	config_get log_level "$cfg" log_level 2

	config_get_bool log_80211  "$cfg" log_80211  1
	config_get_bool log_8021x  "$cfg" log_8021x  1
	config_get_bool log_radius "$cfg" log_radius 1
	config_get_bool log_wpa    "$cfg" log_wpa    1
	config_get_bool log_driver "$cfg" log_driver 1
	config_get_bool log_iapp   "$cfg" log_iapp   1
	config_get_bool log_mlme   "$cfg" log_mlme   1

	local log_mask=$((       \
		($log_80211  << 0) | \
		($log_8021x  << 1) | \
		($log_radius << 2) | \
		($log_wpa    << 3) | \
		($log_driver << 4) | \
		($log_iapp   << 5) | \
		($log_mlme   << 6)   \
	))

	append "$var" "logger_syslog=$log_mask" "$N"
	append "$var" "logger_syslog_level=$log_level" "$N"
	append "$var" "logger_stdout=$log_mask" "$N"
	append "$var" "logger_stdout_level=$log_level" "$N"
}

hostapd_setup_vif() {
	local vif="$1" && shift
	local driver="$1" && shift
	local no_nconfig
	local ifname device channel hwmode

	hostapd_cfg=

	# These are flags that may or may not be used when calling
	# "hostapd_setup_vif()". These are not mandatory and may be called in
	# any order
	while [ $# -ne 0 ]; do
		local tmparg="$1" && shift
		case "$tmparg" in
		no_nconfig)
			no_nconfig=1
			;;
		esac
	done

	config_get ifname "$vif" ifname
	config_get device "$vif" device
	config_get channel "$device" channel
	config_get hwmode "$device" hwmode
	

	
	
	hostapd_set_log_options hostapd_cfg "$device"
	hostapd_set_bss_options hostapd_cfg "$vif"

	case "$hwmode" in
		*bg|*gdt|*gst|*fh) hwmode=g;;
		*adt|*ast) hwmode=a;;
	esac
	[ "$channel" = auto ] && channel=
	[ -n "$channel" -a -z "$hwmode" ] && wifi_fixup_hwmode "$device"
	cat > /var/run/hostapd-$ifname.conf <<EOF
driver=$driver
interface=$ifname
${channel:+channel=$channel}
$hostapd_cfg
EOF
	[ -z "${no_nconfig}" ] &&
		echo ${hwmode:+hw_mode=${hwmode#11}} >> /var/run/hostapd-$ifname.conf
	hostapd -P /var/run/wifi-$ifname.pid -B /var/run/hostapd-$ifname.conf
}


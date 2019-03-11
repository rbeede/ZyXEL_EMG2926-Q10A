#!/bin/sh
# 6rd.sh - IPv6-in-IPv4 tunnel backend
# Copyright (c) 2010-2012 OpenWrt.org

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_6rd_setup() {
	local cfg="$1"
	local iface="$2"
	local link="6rd-$cfg"

	local mtu ttl ipaddr peeraddr ip6prefix ip6prefixlen ip4prefixlen
	json_get_vars mtu ttl ipaddr peeraddr ip6prefix ip6prefixlen ip4prefixlen

	local ck6rdEnable=$(uci get network.general."$cfg"_enable)
        [ "$ck6rdEnable" == "0" ] && return

	[ -z "$ip6prefix" -o -z "$peeraddr" ] && {
		proto_notify_error "$cfg" "MISSING_ADDRESS"
		proto_block_restart "$cfg"
		return
	}

	( proto_add_host_dependency "$cfg" 0.0.0.0 )

	[ -z "$ipaddr" ] && {
		local wanif
		if ! network_find_wan wanif || ! network_get_ipaddr ipaddr "$wanif"; then
			proto_notify_error "$cfg" "NO_WAN_LINK"
			return
		fi
	}

	# Determine the relay prefix.
	local ip4prefixlen="${ip4prefixlen:-0}"
	local ip4prefix=$(ipcalc.sh "$ipaddr/$ip4prefixlen" | grep NETWORK)
	ip4prefix="${ip4prefix#NETWORK=}"

	# Determine our IPv6 address.
	local ip6subnet=$(6rdcalc "$ip6prefix/$ip6prefixlen" "$ipaddr/$ip4prefixlen")
	local ip6addr="${ip6subnet%%::*}::1"

	proto_init_update "$link" 1
	proto_add_ipv6_address "$ip6addr" "$ip6prefixlen"
	proto_add_ipv6_route "::" 0 "::$peeraddr" 4096

	proto_add_tunnel
	json_add_string mode sit
	json_add_int mtu "${mtu:-1280}"
	json_add_int ttl "${ttl:-64}"
	json_add_string local "$ipaddr"
	json_add_string 6rd-prefix "$ip6prefix/$ip6prefixlen"
	json_add_string 6rd-relay-prefix "$ip4prefix/$ip4prefixlen"
	proto_close_tunnel

	proto_send_update "$cfg"

	##Add for assign LAN ipv6 address
	local ipv6lan=
	local ipv6lanold=$(uci get network."$cfg".zyipv6lan)
	local oldIpv6Subnet=$(uci get network."$cfg".zyPd6rd)
	local ipv6lanprefix="${ip6subnet%%::*}"
	local config_section=$(echo "$cfg"| sed s/6rd//g)
	local lanIface=
	[ "${cfg:0:3}" == "wan" ] && {
		lanIface=$(uci get network."$config_section".bind_LAN)
		lanIface=$(echo $lanIface | cut -c 4-)	
		[ -z "$lanIface" ] && lanIface=lan		
	}
	
	##add 6rd CPE lan-ipv6 
	local mac=$(ifconfig br-$lanIface | sed -ne 's/[[:space:]]*$//; s/.*HWaddr //p')
	ipv6lan=$ipv6lanprefix:$(printf %02x $((0x${mac%%:*} ^ 2)))
	mac=${mac#*:}
	ipv6lan=$ipv6lan${mac%:*:*:*}ff:fe
	mac=${mac#*:*:}
	ipv6lan=$ipv6lan${mac%:*}${mac##*:}
	
	[ -n "$ipv6lanold" -a "$ipv6lanold" != "$ipv6lan" ] && ifconfig br-$lanIface del "$ipv6lanold"/64
	ifconfig br-$lanIface add "$ipv6lan"/64

	uci set network."$cfg".zyipv6lan=$ipv6lan

	##support GuestNetwork 
#	local macGuest=$(ifconfig br-lan:4 | sed -ne 's/[[:space:]]*$//; s/.*HWaddr //p')
#	local ck6rdGuestChange="0"
#	local ck6rdConfig=$(cat /var/etc/radvd_6rd.conf |grep "br-lan:4")
#	[ -n "$macGuest" ] && {
#		local guesLanEnable=$(uci get network.guest_network.guest_lan_enable)
#		local guest24gEnable=$(uci get wireless.ath3.enable_guest_wlan)
#		local guest5gEnable=$(uci get wireless.ath13.enable_guest_wlan)
#		[ "$guesLanEnable" == "1" -o "$guest24gEnable" == "1" -o "$guest5gEnable" == "1" ] && {
#			local ipv6lanGuestold=$(uci get network."$cfg".zyipv6lanGuest)
#			ipv6lanGuest=$ipv6lanprefix:$(printf %02x $((0x${macGuest%%:*} ^ 2)))
#			macGuest=${macGuest#*:}
#			ipv6lanGuest=$ipv6lanGuest${macGuest%:*:*:*}ff:fe
#			macGuest=${macGuest#*:*:}
#			ipv6lanGuest=$ipv6lanGuest${macGuest%:*}${macGuest##*:}
#
#			ifconfig br-lan:4 down
#			[ -n "$ipv6lanGuestold" -a "$ipv6lanGuestold" != "$ipv6lanGuest" ] && ifconfig br-lan:4 del "$ipv6lanGuestold"/64
#			ifconfig br-lan:4 add "$ipv6lanGuest"/64
#			ifconfig br-lan:4 up
#			uci set network."$cfg".zyipv6lanGuest=$ipv6lanGuest
#
#			[ -z "$ck6rdConfig" ] && ck6rdGuestChange="1"
#		} || {
#			[ -n "$ck6rdConfig" ] && ck6rdGuestChange="1"
#		}
#	} || {
#		[ -n "$ck6rdConfig" ] && ck6rdGuestChange="1"
#	}

	uci set network."$cfg".zyPd6rd=$ip6subnet
	uci commit network	

	echo 1 > /tmp/radvd_6rd
	
    /etc/init.d/radvd restart
#	local ckRadvd=$(ps |grep radvd_6rd.conf |grep -v "grep")
#	[ -z "$oldIpv6Subnet" -o "$oldIpv6Subnet" != "$ip6subnet" -o -z "$ckRadvd" -o "$ck6rdGuestChange" == "1" ] && /etc/init.d/radvd restart
#	[ -z "$oldIpv6Subnet" -o "$oldIpv6Subnet" != "$ip6subnet" -o -z "$ckRadvd" ] && /etc/init.d/radvd restart
	
	##END
}

proto_6rd_teardown() {
	local cfg="$1"
}

proto_6rd_init_config() {
	no_device=1
	available=1

	proto_config_add_int "mtu"
	proto_config_add_int "ttl"
	proto_config_add_string "ipaddr"
	proto_config_add_string "peeraddr"
	proto_config_add_string "ip6prefix"
	proto_config_add_string "ip6prefixlen"
	proto_config_add_string "ip4prefixlen"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol 6rd
}

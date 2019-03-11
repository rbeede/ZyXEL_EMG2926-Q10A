#!/bin/sh
# Copyright (C) 2009 OpenWrt.org

setup_ACL(){
	##Drop ICMP type 3 code 3
	ssdk_sh rate aclpolicer set 0 no yes no no no 128 32768 0 0 1ms
	ssdk_sh acl status set enable
	ssdk_sh acl list create 1 1
	ssdk_sh acl rule add 1 0 1 ip4 no no no no no no no no no no no no no no no no no no no no no no no no yes 3 0xf yes 3 0xf no no yes no no no no no no no no no no 0 0 no no no no no no no yes 0 no no no no no

	##LAN
	ssdk_sh acl list bind 1 0 0 1
	ssdk_sh acl list bind 1 0 0 2
	ssdk_sh acl list bind 1 0 0 3
	ssdk_sh acl list bind 1 0 0 4

	##WAN
	ssdk_sh acl list bind 1 0 0 5
}

setup_switch_dev() {
	config_get name "$1" name
	name="${name:-$1}"
	[ -d "/sys/class/net/$name" ] && ifconfig "$name" up
	swconfig dev "$name" load network
}

setup_switch() {
	config_load network
	config_foreach setup_switch_dev switch

	setup_ACL
}

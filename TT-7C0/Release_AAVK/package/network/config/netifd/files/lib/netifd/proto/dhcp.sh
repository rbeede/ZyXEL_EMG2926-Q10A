#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_dhcp_init_config() {
	proto_config_add_string "ipaddr"
	proto_config_add_string "netmask"
	proto_config_add_string "hostname"
	proto_config_add_string "clientid"
	proto_config_add_string "vendorid"
	proto_config_add_boolean "broadcast"
	proto_config_add_string "reqopts"
	proto_config_add_string "iface6rd"
	proto_config_add_string "sendopts"
}

proto_dhcp_setup() {
	local config="$1"
	local iface="$2"

	local ipaddr hostname clientid vendorid broadcast reqopts iface6rd sendopts
	json_get_vars ipaddr clientid vendorid broadcast reqopts iface6rd sendopts
	hostname=$(uci get system.main.hostname)

	local opt dhcpopts
	for opt in $reqopts; do
		append dhcpopts "-O $opt"
	done

	for opt in $sendopts; do
		append dhcpopts "-x $opt"
	done

	##support option60 121
	local ckOption60=$(uci get network."$config".dhcp60)
	local ckOption121=$(uci get network."$config".dhcp121)
	local ckOption125=$(uci get network."$config".dhcp125)

	[ "$ckOption60" == "0" ] && clientid=
	[ "$ckOption121" == "1" ] && append dhcpopts "-O 121"
	[ "$ckOption125" == "1" ] && {
	##option 125 support
	#####entprise(4 bytes) + dataLen(1 byte) + code1(1 byte) + len1(1 byte) + oui(string) + code2 + len2 + sn(string) + code3 + len3 + product(string) 

		local OUI=$(be_ctltr98 DeviceInfo get ManufacturerOUI)
		local serialNumber=$(be_ctltr98 DeviceInfo get SerialNumber)
		local productClass=$(be_ctltr98 DeviceInfo get ProductClass)
		local optionLen=$((4+1+1+1+$(expr length $OUI)+1+1+$(expr length $serialNumber)+1+1+$(expr length $productClass)))
		local dataLen=$(($optionLen-4-1)) ##(-entiprise(4 bytes) - dataLen(1 byte))
		##include option-code & option-len
#		local option125Value=$(printf %x 125)$(printf %02x $optionLen)$(printf %04x 3561)$(printf %02x $dataLen)$(printf %02x 1)$(printf %02x $(expr length $OUI))$(echo -n $OUI | hexdump -ve '/1 "%02x"')$(printf %02x 2)$(printf %02x $(expr length $serialNumber))$(echo -n $serialNumber | hexdump -ve '/1 "%02x"')$(printf %02x 3)$(printf %02x $(expr length $productClass))$(echo -n $productClass | hexdump -ve '/1 "%02x"')
		##not inclide option-code & option-len
		local option125Value=$(printf %08x 3561)$(printf %02x $dataLen)$(printf %02x 1)$(printf %02x $(expr length $OUI))$(echo -n $OUI | hexdump -ve '/1 "%02x"')$(printf %02x 2)$(printf %02x $(expr length $serialNumber))$(echo -n $serialNumber | hexdump -ve '/1 "%02x"')$(printf %02x 3)$(printf %02x $(expr length $productClass))$(echo -n $productClass | hexdump -ve '/1 "%02x"')

		append dhcpopts "-x 0x7d:$option125Value"

	}

	[ "$broadcast" = 1 ] && broadcast="-B" || broadcast=
	[ -n "$clientid" ] && clientid="-x 0x3d:${clientid//:/}" || clientid="-C"
	[ -n "$iface6rd" ] && proto_export "IFACE6RD=$iface6rd"
	

	#Steven 2016.0602 If IP_version != IPv6_Only, run udhcpc command.
	 local IP_version=$(uci get network.wan.IP_version)
	 local system_mode=$(uci get system.main.system_mode)

	 #echo "$IP_version" > /dev/console
	 proto_export "INTERFACE=$config"
	
	 if [ "$IP_version" != "IPv6_Only" ] || [ "$system_mode" == "2" ]; then
		proto_run_command "$config" udhcpc \
		-p /var/run/udhcpc-$iface.pid \
		-s /lib/netifd/dhcp.script \
		-f -t 0 -i "$iface" \
		${ipaddr:+-r $ipaddr} \
		${hostname:+-H $hostname} \
		${vendorid:+-V $vendorid} \
		$clientid $broadcast $dhcpopts
	 fi
	
}

proto_dhcp_teardown() {
	local interface="$1"
	proto_kill_command "$interface"
}

add_protocol dhcp


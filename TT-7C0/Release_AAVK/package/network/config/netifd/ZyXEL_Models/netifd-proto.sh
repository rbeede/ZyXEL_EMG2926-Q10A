. /usr/share/libubox/jshn.sh

append() {
	local var="$1"
	local value="$2"
	local sep="${3:- }"

	eval "export -- \"$var=\${$var:+\${$var}\${value:+\$sep}}\$value\""
}

proto_config_add_generic() {
	json_add_array ""
	json_add_string "" "$1"
	json_add_int "" "$2"
	json_close_array
}

proto_config_add_int() {
	proto_config_add_generic "$1" 5
}

proto_config_add_string() {
	proto_config_add_generic "$1" 3
}

proto_config_add_boolean() {
	proto_config_add_generic "$1" 7
}

add_default_handler() {
	case "$(type $1 2>/dev/null)" in
		*function*) return;;
		*) eval "$1() { return; }"
	esac
}

_proto_do_teardown() {
	json_load "$data"
	eval "proto_$1_teardown \"$interface\" \"$ifname\""
}

_proto_do_setup() {
	json_load "$data"
	_EXPORT_VAR=0
	_EXPORT_VARS=
	
	#Set 802.1Q tag
	local vlan_pri=$(uci get network.$interface.pri)     
	[ ! -z "$vlan_pri" ] && vconfig set_egress_map "$ifname" "0" "$vlan_pri"
	
	eval "proto_$1_setup \"$interface\" \"$ifname\""
}

proto_init_update() {
	local ifname="$1"
	local up="$2"
	local external="$3"

	PROTO_KEEP=0
	PROTO_INIT=1
	PROTO_TUNNEL_OPEN=
	PROTO_IPADDR=
	PROTO_IP6ADDR=
	PROTO_ROUTE=
	PROTO_ROUTE6=
	PROTO_DNS=
	PROTO_DNS_SEARCH=
	json_init
	json_add_int action 0
	[ -n "$ifname" -a "*" != "$ifname" ] && json_add_string "ifname" "$ifname"
	json_add_boolean "link-up" "$up"
	[ -n "$3" ] && json_add_boolean "address-external" "$external"
}

proto_set_keep() {
	PROTO_KEEP="$1"
}

proto_close_nested() {
	[ -n "$PROTO_NESTED_OPEN" ] && json_close_object
	PROTO_NESTED_OPEN=
}

proto_add_nested() {
	PROTO_NESTED_OPEN=1
	json_add_object "$1"
}

proto_add_tunnel() {
	proto_add_nested "tunnel"
}

proto_close_tunnel() {
	proto_close_nested
}

proto_add_data() {
	proto_add_nested "data"
}

proto_close_data() {
	proto_close_nested
}

proto_add_dns_server() {
	local address="$1"

	append PROTO_DNS "$address"
}

proto_add_dns_search() {
	local address="$1"

	append PROTO_DNS_SEARCH "$address"
}

proto_add_ipv4_address() {
	local address="$1"
	local mask="$2"
	local broadcast="$3"
	local ptp="$4"

	append PROTO_IPADDR "$address/$mask/$broadcast/$ptp"
}

proto_add_ipv6_address() {
	local address="$1"
	local mask="$2"

	append PROTO_IP6ADDR "$address/$mask"
}

proto_add_ipv4_route() {
	local target="$1"
	local mask="$2"
	local gw="$3"

	append PROTO_ROUTE "$target/$mask/$gw"
}

proto_add_ipv6_route() {
	local target="$1"
	local mask="$2"
	local gw="$3"

	append PROTO_ROUTE6 "$target/$mask/$gw"
}

_proto_push_ipv4_addr() {
	local str="$1"
	local address mask broadcast ptp

	address="${str%%/*}"
	str="${str#*/}"
	mask="${str%%/*}"
	str="${str#*/}"
	broadcast="${str%%/*}"
	str="${str#*/}"
	ptp="$str"

	json_add_object ""
	json_add_string ipaddr "$address"
	[ -n "$mask" ] && json_add_string mask "$mask"
	[ -n "$broadcast" ] && json_add_string broadcast "$broadcast"
	[ -n "$ptp" ] && json_add_string ptp "$ptp"
	json_close_object
}

_proto_push_ipv6_addr() {
	local str="$1"
	local address mask

	address="${str%%/*}"
	str="${str#*/}"
	mask="$str"

	json_add_object ""
	json_add_string ipaddr "$address"
	[ -n "$mask" ] && json_add_string mask "$mask"
	json_close_object
}

_proto_push_string() {
	json_add_string "" "$1"
}

_proto_push_route() {
	local str="$1";
	local target="${str%%/*}"
	str="${str#*/}"
	local mask="${str%%/*}"
	local gw="${str#*/}"

	json_add_object ""
	json_add_string target "$target"
	json_add_string netmask "$mask"
	[ -n "$gw" ] && json_add_string gateway "$gw"
	json_close_object

}

_proto_push_array() {
	local name="$1"
	local val="$2"
	local cb="$3"

	[ -n "$val" ] || return 0
	json_add_array "$name"
	for item in $val; do
		eval "$cb \"\$item\""
	done
	json_close_array
}

_proto_notify() {
	local interface="$1"
	local options="$2"
	ubus $options call network.interface."$interface" notify_proto "$(json_dump)"
}

proto_send_update() {
	local interface="$1"

	proto_close_nested
	json_add_boolean keep "$PROTO_KEEP"
	_proto_push_array "ipaddr" "$PROTO_IPADDR" _proto_push_ipv4_addr
	_proto_push_array "ip6addr" "$PROTO_IP6ADDR" _proto_push_ipv6_addr
	_proto_push_array "routes" "$PROTO_ROUTE" _proto_push_route
	_proto_push_array "routes6" "$PROTO_ROUTE6" _proto_push_route
	_proto_push_array "dns" "$PROTO_DNS" _proto_push_string
	_proto_push_array "dns_search" "$PROTO_DNS_SEARCH" _proto_push_string
	_proto_notify "$interface"

}

proto_export() {
	local var="VAR${_EXPORT_VAR}"
	_EXPORT_VAR="$(($_EXPORT_VAR + 1))"
	export -- "$var=$1"
	append _EXPORT_VARS "$var"
}

proto_run_command() {
	local interface="$1"; shift

	json_init
	json_add_int action 1
	json_add_array command
	while [ $# -gt 0 ]; do
		json_add_string "" "$1"
		shift
	done
	json_close_array
	[ -n "$_EXPORT_VARS" ] && {
		json_add_array env
		for var in $_EXPORT_VARS; do
			eval "json_add_string \"\" \"\${$var}\""
		done
		json_close_array
	}
	_proto_notify "$interface"
}

proto_kill_command() {
	local interface="$1"; shift

	json_init
	json_add_int action 2
	[ -n "$1" ] && json_add_int signal "$1"
	_proto_notify "$interface"
}

proto_notify_error() {
	local interface="$1"; shift

	json_init
	json_add_int action 3
	json_add_array error
	while [ $# -gt 0 ]; do
		json_add_string "" "$1"
		shift
	done
	json_close_array
	_proto_notify "$interface"
}

proto_block_restart() {
	local interface="$1"; shift

	json_init
	json_add_int action 4
	_proto_notify "$interface"
}

proto_set_available() {
	local interface="$1"
	local state="$2"
	json_init
	json_add_int action 5
	json_add_boolean available "$state"
	_proto_notify "$interface"
}

proto_add_host_dependency() {
	local interface="$1"
	local host="$2"

	# execute in subshell to not taint callers env
	# see tickets #11046, #11545, #11570
	(
		json_init
		json_add_int action 6
		json_add_string host "$host"
		_proto_notify "$interface" -S
	)
}

proto_setup_failed() {
	local interface="$1"
	json_init
	json_add_int action 7
	_proto_notify "$interface"
}

init_proto() {
	proto="$1"; shift
	cmd="$1"; shift

	case "$cmd" in
		dump)
			add_protocol() {
				no_device=0
				available=0

				add_default_handler "proto_$1_init_config"

				json_init
				json_add_string "name" "$1"
				json_add_array "config"
				eval "proto_$1_init_config"
				json_close_array
				json_add_boolean no-device "$no_device"
				json_add_boolean available "$available"
				json_dump
			}
		;;
		setup|teardown)
			interface="$1"; shift
			data="$1"; shift
			ifname="$1"; shift

			add_protocol() {
				[[ "$proto" == "$1" ]] || return 0

				case "$cmd" in
					setup) _proto_do_setup "$1";;
					teardown) _proto_do_teardown "$1" ;;
					*) return 1 ;;
				esac
			}
		;;
	esac
}

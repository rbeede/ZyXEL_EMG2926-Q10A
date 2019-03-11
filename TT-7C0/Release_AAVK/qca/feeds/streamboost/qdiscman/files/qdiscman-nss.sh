EXTRA_CMD_ARGS="--nss"

# sets up the qdisc structures on an interface
# Note: this only sets a default rate on the root class, not necessarily the
#	correct rate; qdiscman handles this when it starts up
#
# $1: dev
setup_iface() {
	tc qdisc add dev $1 root \
		handle ${PRIO_HANDLE_MAJOR}: \
		nssprio bands 3
	[ $? = 0 ] || return $?
	# interactive for localhost OUTPUT
	add_interactive_qdisc $1 \
		"${PRIO_HANDLE_MAJOR}:3" \
		"${OUTPUT_HANDLE_MAJOR}:" "nsscodel"
	[ $? = 0 ] || return $?
	# base nsstbl under which all streamboost classes appear
	tc qdisc add dev $1 \
		parent ${PRIO_HANDLE_MAJOR}:2 \
		handle ${TBF_HANDLE_MAJOR}: \
		nsstbl rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?

	# subprio
	tc qdisc add dev $1 \
		parent ${TBF_HANDLE_MAJOR}:1 \
		handle ${SUBPRIO_HANDLE_MAJOR}: \
		nssprio bands 2

	# schroot
	tc qdisc add dev $1 \
		parent ${SUBPRIO_HANDLE_MAJOR}:1 \
		handle ${SCHROOT_HANDLE_MAJOR}: \
		nssbf
	[ $? = 0 ] || return $?

	# classified
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_CLASSIFIED} \
		nssbf rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?
	tc qdisc add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}:${CLASSID_CLASSIFIED} \
		handle ${BF_HANDLE_MAJOR}: \
		nssbf
	[ $? = 0 ] || return $?

	# background
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_BACKGROUND} \
		nssbf rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?
	tc qdisc add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}:${CLASSID_BACKGROUND} \
		handle ${BGROOT_HANDLE_MAJOR}: \
		nssbf
	[ $? = 0 ] || return $?

	# default for unclassified flows
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_DEFAULT} \
		nssbf rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${SCHROOT_HANDLE_MAJOR}:${CLASSID_DEFAULT}" \
		"${CLASSID_DEFAULT}:" "nsscodel" "set_default" # TODO: we should not need this
	[ $? = 0 ] || return $?
	# localhost class for traffic originating from the router
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_LOCALHOST} \
		nssbf rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${SCHROOT_HANDLE_MAJOR}:${CLASSID_LOCALHOST}" \
		"${CLASSID_LOCALHOST}:" "nsscodel"
	[ $? = 0 ] || return $?

	# "cheat" is for things like ICMP acceleration
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_ELEVATED_CHEAT} \
		nssbf rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${SCHROOT_HANDLE_MAJOR}:${CLASSID_ELEVATED_CHEAT}" \
		"${CLASSID_ELEVATED_CHEAT}:" "nsscodel"
	[ $? = 0 ] || return $?
	# browser
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_ELEVATED_BROWSER} \
		nssbf rate 1000mbit burst 1000kb mtu 1514
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${SCHROOT_HANDLE_MAJOR}:${CLASSID_ELEVATED_BROWSER}" \
		"${CLASSID_ELEVATED_BROWSER}:" "nsscodel"
	[ $? = 0 ] || return $?
	# dns
	tc class add dev $1 \
		parent ${SCHROOT_HANDLE_MAJOR}: \
		classid ${SCHROOT_HANDLE_MAJOR}:${CLASSID_ELEVATED_DNS} \
		nssbf rate 1000mbit burst 1000kb
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${SCHROOT_HANDLE_MAJOR}:${CLASSID_ELEVATED_DNS}" \
		"${CLASSID_ELEVATED_DNS}:" "nsscodel"
	[ $? = 0 ] || return $?

	# guest network
	tc qdisc add dev $1 \
		parent ${SUBPRIO_HANDLE_MAJOR}:2 \
		handle ${GUEST_HANDLE_MAJOR}: \
		nsstbl burst 500kbit mtu 1514 rate ${GUEST_BANDWIDTH_LIMIT:-5mbit}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${GUEST_HANDLE_MAJOR}:1" \
		"${CLASSID_GUEST}:" "nsscodel"
	[ $? = 0 ] || return $?
}

#
#  sets up iptables rules
#
#  $1: iptables executable, e.g., 'iptables' or 'ip6tables'
#  $2: 'A' or 'D' depending on whether to add all rules or delete them
generic_iptables() {
	local ipt=$1
	local cmd=$2
	local guest_rules=no

	[ "${ipt}" = "iptables" ] && [ "$GUEST_DHCP_ENABLE" = "yes" -o "$2" = "D" ] && guest_rules="yes"

	# All packets from localhost to LAN are marked to skip BWC
	${ipt} -t mangle -${cmd} OUTPUT -o $LAN_IFACE -j CLASSIFY \
		--set-class ${OUTPUT_HANDLE_MAJOR}:0

	# If this is from localhost AND is using the aperture source
	# ports, set the class to avoid BWC.
	${ipt} -t mangle -${cmd} OUTPUT ! -o $LAN_IFACE -p tcp -m multiport \
		--source-ports 321:353 -j CLASSIFY \
		--set-class ${OUTPUT_HANDLE_MAJOR}:0
	${ipt} -t mangle -${cmd} OUTPUT ! -o $LAN_IFACE -p tcp -m multiport \
		--source-ports 321:353 -j RETURN

	# All packets from localhost to WAN are marked
	# Note the !LAN_IFACE logic allows us to catch any potential
	# PPPoE interface as well
	${ipt} -t mangle -${cmd} OUTPUT ! -o $LAN_IFACE -j CLASSIFY \
		--set-class ${CLASSID_LOCALHOST}:0

	# Guest network traffic goes somewhere else - only IPv4 is supported
	[ "${guest_rules}" = "yes" ] && {
		local bypass=$(ipaddr_netmask_to_cidr ${GUEST_DHCP_IPADDR} ${GUEST_DHCP_NETMASK})
		local mark=$(printf "0x%04x%04x" 0x${BF_HANDLE_MAJOR} 0x${CLASSID_GUEST})
		${ipt} -t mangle -${cmd} FORWARD ! -o $LAN_IFACE -s ${bypass} \
			-j CLASSIFY --set-class "${CLASSID_GUEST}":0
		${ipt} -t mangle -${cmd} FORWARD ! -o $LAN_IFACE -s ${bypass} \
			-j RETURN
		${ipt} -t mangle -${cmd} FORWARD -o $LAN_IFACE -d ${bypass} \
			-j CLASSIFY --set-class "${CLASSID_GUEST}":0
		${ipt} -t mangle -${cmd} FORWARD -o $LAN_IFACE -d ${bypass} \
			-j RETURN
	}

	# Mark all forwarded packets with the global default
	# XXX - This is not compatible with the inter-op concessions for our
	# CS release.  ANY mark set from another source will cause SB to not
	# perform marking. - BenM
	# ${ipt} -t mangle -${cmd} FORWARD -j CLASSIFY \
	#	--set-class ${CLASSID_DEFAULT}:0

	# Forwarded ICMP packets go to their own queue
	${ipt} -t mangle -${cmd} FORWARD -p icmp -m limit --limit 2/second \
		-j CLASSIFY --set-class ${CLASSID_ELEVATED_CHEAT}:0

	# DNS Elevation
	${ipt} -t mangle -${cmd} POSTROUTING -p udp --dport 53 \
		-j CLASSIFY --set-class ${CLASSID_ELEVATED_DNS}:0
	${ipt} -t mangle -${cmd} POSTROUTING -p udp --dport 53 \
		-j RETURN

	# Restore the CONNMARK to the packet
	${ipt} -t mangle -${cmd} POSTROUTING -j CONNMARK --restore-mark
	# Further, restore the mark to priority since filters don't work.
	# Note, mark2prio only overwrites prio with the connmark if the prio
	# is zero so that it won't stomp on the CLASSIFY target.
	${ipt} -t mangle -${cmd} POSTROUTING -j mark2prio
}

setup_iptables () {
	# call iptables to add rules
	generic_iptables iptables A
	generic_iptables ip6tables A
}

teardown_iptables () {
	# call iptables to delete rules
	generic_iptables iptables D
	generic_iptables ip6tables D
}

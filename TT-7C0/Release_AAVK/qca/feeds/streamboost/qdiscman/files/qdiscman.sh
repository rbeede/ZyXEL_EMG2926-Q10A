KERNEL_MODULES="sch_sfq sch_prio sch_codel sch_fq_codel sch_hfsc cls_fw sch_tbf"

# sets up the qdisc structures on an interface
# Note: this only sets a default rate on the root class, not necessarily the
#	correct rate; qdiscman handles this when it starts up
#
# $1: dev
setup_iface() {
	# ####################################################################
	# configure the root prio
	# ####################################################################
	tc qdisc add dev $1 root \
		handle ${PRIO_HANDLE_MAJOR}: \
		prio bands 3 priomap 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
	[ $? = 0 ] || return $?
	# interactive for localhost OUTPUT
	add_interactive_qdisc $1 \
		"${PRIO_HANDLE_MAJOR}:3" \
		"${OUTPUT_HANDLE_MAJOR}:"
	[ $? = 0 ] || return $?
	# base hfsc under which all streamboost classes appear
	tc qdisc add dev $1 \
		parent ${PRIO_HANDLE_MAJOR}:2 \
		handle ${BF_HANDLE_MAJOR}: \
		hfsc default ${CLASSID_DEFAULT}
	[ $? = 0 ] || return $?

	# ###################################################################
	# configure the base hfsc
	# ###################################################################

	#
	# the main hfsc class is where adjusted global bandwidth is enforced
	#
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:0 \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_ROOT} \
		hfsc ls m1 0 d 0 m2 ${COMMITTED_WEIGHT} ul m1 0 d 0 m2 1000mbit
	[ $? = 0 ] || return $?

	#
	# default classifier for the main hfsc classifies on fwmark
	#
	tc filter add dev $1 parent ${BF_HANDLE_MAJOR}: fw
	[ $? = 0 ] || return $?

	#
	# classified
	#
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ROOT} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_CLASSIFIED} \
		hfsc ls m1 0 d 0 m2 ${COMMITTED_WEIGHT}
	[ $? = 0 ] || return $?

	#
	# prioritized
	#
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ROOT} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_PRIORITIZED} \
		hfsc ls m1 0 d 0 m2 ${PRIORITIZED_WEIGHT}
	[ $? = 0 ] || return $?

	#
	# background
	#
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ROOT} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_BACKGROUND} \
		hfsc ls m1 0 d 0 m2 ${BACKGROUND_WEIGHT}
	[ $? = 0 ] || return $?
	# default for unclassified flows
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_BACKGROUND} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_DEFAULT} \
		hfsc ls m1 0 d 0 m2 ${INTERACTIVE_WEIGHT}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${BF_HANDLE_MAJOR}:${CLASSID_DEFAULT}" \
		"${CLASSID_DEFAULT}:"
	[ $? = 0 ] || return $?
	# localhost class for traffic originating from the router
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_BACKGROUND} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_LOCALHOST} \
		hfsc ls m1 0 d 0 m2 ${BACKGROUND_WEIGHT}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${BF_HANDLE_MAJOR}:${CLASSID_LOCALHOST}" \
		"${CLASSID_LOCALHOST}:"
	[ $? = 0 ] || return $?

	#
	# elevated
	#
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ROOT} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED} \
		hfsc ls m1 0 d 0 m2 ${ELEVATED_WEIGHT}
	[ $? = 0 ] || return $?
	# "cheat" is for things like ICMP acceleration
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_CHEAT} \
		hfsc ls m1 0 d 0 m2 ${ELEVATED_WEIGHT}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_CHEAT}" \
		"${CLASSID_ELEVATED_CHEAT}:"
	[ $? = 0 ] || return $?
	# browser
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_BROWSER} \
		hfsc ls m1 0 d 0 m2 ${ELEVATED_WEIGHT}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_BROWSER}" \
		"${CLASSID_ELEVATED_BROWSER}:"
	[ $? = 0 ] || return $?
	# dns
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_DNS} \
		hfsc ls m1 0 d 0 m2 ${ELEVATED_WEIGHT}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_DNS}" \
		"${CLASSID_ELEVATED_DNS}:"
	[ $? = 0 ] || return $?

	#
	# guest network
	#
	tc class add dev $1 \
		parent ${BF_HANDLE_MAJOR}:${CLASSID_ROOT} \
		classid ${BF_HANDLE_MAJOR}:${CLASSID_GUEST} \
		hfsc ls m1 0 d 0 m2 ${GUEST_WEIGHT} \
		ul rate ${GUEST_BANDWIDTH_LIMIT:-5mbit}
	[ $? = 0 ] || return $?
	add_interactive_qdisc $1 \
		"${BF_HANDLE_MAJOR}:${CLASSID_GUEST}" \
		"${CLASSID_GUEST}:"
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

	[ "${ipt}" = "iptables" ] && [ "$GUEST_DHCP_ENABLE" = "yes" -o "$2" = "D" ] && guest_rules=yes

	# All packets from localhost to LAN are marked as 2:3 so
	# that they skip BWC
	${ipt} -t mangle -${cmd} OUTPUT -o $LAN_IFACE \
		-j CLASSIFY --set-class ${PRIO_HANDLE_MAJOR}:3

	# If this is from localhost AND is using the aperture source
	# ports, set the class to avoid BWC.
	${ipt} -t mangle -${cmd} OUTPUT ! -o $LAN_IFACE -p tcp -m multiport \
		--source-ports 321:353 -j CLASSIFY \
		--set-class ${PRIO_HANDLE_MAJOR}:3
	${ipt} -t mangle -${cmd} OUTPUT ! -o $LAN_IFACE -p tcp -m multiport \
		--source-ports 321:353 -j RETURN

	# All packets from localhost to WAN are marked, but not in
	# such a way that they skip BWC
	# Note the !LAN_IFACE logic allows us to catch any potential
	# PPPoE interface as well
	${ipt} -t mangle -${cmd} OUTPUT ! -o $LAN_IFACE -j CLASSIFY \
		--set-class ${BF_HANDLE_MAJOR}:${CLASSID_LOCALHOST}

	# Guest network traffic goes somewhere else - only IPv4 is supported
	[ "${guest_rules}" = "yes" ] && {
		local bypass=$(ipaddr_netmask_to_cidr ${GUEST_DHCP_IPADDR} ${GUEST_DHCP_NETMASK})
		local mark=$(printf "0x%04x%04x" 0x${BF_HANDLE_MAJOR} 0x${CLASSID_GUEST})
		${ipt} -t mangle -${cmd} FORWARD ! -o $LAN_IFACE -s ${bypass} \
			-j CONNMARK --set-mark ${mark}
		${ipt} -t mangle -${cmd} FORWARD ! -o $LAN_IFACE -s ${bypass} \
			-j RETURN
		${ipt} -t mangle -${cmd} FORWARD -o $LAN_IFACE -d ${bypass} \
			-j CONNMARK --set-mark ${mark}
		${ipt} -t mangle -${cmd} FORWARD -o $LAN_IFACE -d ${bypass} \
			-j RETURN
	}

	# For the LAN side, we set the default to be the parent of the
	# HTB, so that when ct_mark is copied to nf_mark, by
	# CONNMARK --restore mark, priority will be unset, and filter fw
	# will read the mark and set the class correctly.  In the WAN
	# direction, the root is the HTB, so we do not need to set the
	# class; it will just work.
	${ipt} -t mangle -${cmd} FORWARD -o $LAN_IFACE \
		-j CLASSIFY --set-class ${PRIO_HANDLE_MAJOR}:2

	# Forwarded ICMP packets in their own queue
	${ipt} -t mangle -${cmd} FORWARD -p icmp -m limit --limit 2/second \
		-j CLASSIFY \
		--set-class ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_CHEAT}

	# DNS Elevation
	${ipt} -t mangle -${cmd} POSTROUTING -p udp --dport 53 \
		-j CLASSIFY \
		--set-class ${BF_HANDLE_MAJOR}:${CLASSID_ELEVATED_DNS}
	${ipt} -t mangle -${cmd} POSTROUTING -p udp --dport 53 \
		-j RETURN

	# Restore the CONNMARK to the packet
	${ipt} -t mangle -${cmd} POSTROUTING -j CONNMARK --restore-mark
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

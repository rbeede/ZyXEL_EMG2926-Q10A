#!/bin/sh
#
# MediaServer Control File written by Itzchak Rehberg
# Modified for fedora/redhat by Landon Bradshaw <phazeforward@gmail.com>
# Adapted to Twonky 3.0 by TwonkyVision GmbH
# Adapted to Twonky 4.0 by TwonkyVision GmbH
# Adapted to Twonky 5.0 by PacketVideo
#
# This script is intended for SuSE and Fedora systems.
#
#
###############################################################################
#
### BEGIN INIT INFO
# Provides:       twonkyserver
# Required-Start: $network $remote_fs
# Default-Start:  3 5
# Default-Stop:   0 1 2 6
# Description:    Twonky UPnP server
### END INIT INFO
#
# Comments to support chkconfig on RedHat/Fedora Linux
# chkconfig: 345 71 29
# description: Twonky UPnP server
#
#==================================================================[ Setup ]===

WORKDIR1="/usr/local/twonky"
WORKDIR2="`dirname $0`"
PIDFILE=/var/run/mediaserver.pid

#change this to 0 to disable the twonky proxy service
START_PROXY=0

#change this to 0 to disable the twonky tuner service
START_TUNER=0

#=================================================================[ Script ]===


stop_support_daemon() {
SUPPORT_DAEMON=$1
	if [ "${SUPPORT_DAEMON}" = "" ]; then
		return 12
	fi
	if [ "${SUPPORT_DAEMON}" = "none" ]; then
		return 13
	fi
	
	echo "Stopping ${SUPPORT_DAEMON}"
	killall ${SUPPORT_DAEMON}
}

check_support_daemon() {
	SUPPORT_DAEMON=$1
	if [ "${SUPPORT_DAEMON}" = "" ]; then
		return 12
	fi
	if [ "${SUPPORT_DAEMON}" = "none" ]; then
		return 13
	fi

	SD_PID=`ps --no-headers -o pid -C ${SUPPORT_DAEMON}`
	if [ "${SD_PID}" = "" ]; then
		return 0
	else
		return 1
	fi
}

start_support_daemon() {
SUPPORT_DAEMON=$1
SUPPORT_DAEMON_WORKDIR=$2
	if [ "${SUPPORT_DAEMON}" = "" ]; then
		return 12
	fi
	if [ "${SUPPORT_DAEMON}" = "none" ]; then
		return 13
	fi

	check_support_daemon "${SUPPORT_DAEMON}"
	DSTATUS=$?
	if [ "${DSTATUS}" = "1" ]; then
		echo "${SUPPORT_DAEMON} is already running."
		return
	fi

	if [ -x "${SUPPORT_DAEMON_WORKDIR}/${SUPPORT_DAEMON}" ]; then
		echo -n "Starting ${SUPPORT_DAEMON} ... "
      		"${SUPPORT_DAEMON_WORKDIR}/${SUPPORT_DAEMON}" &
	else
		echo "Warning: support deamon ${SUPPORT_DAEMON_WORKDIR}/${SUPPORT_DAEMON} not found." 
	fi
}

status_support_daemon() {
        SUPPORT_DAEMON=$1
        if [ "${SUPPORT_DAEMON}" = "" ]; then
                return 12
        fi
	if [ "${SUPPORT_DAEMON}" = "none" ]; then
		return 13
	fi

	check_support_daemon "${SUPPORT_DAEMON}"
	DSTATUS=$?
	if [ "${DSTATUS}" = "0" ]; then
		echo "${SUPPORT_DAEMON} is not running."
		return;
	fi
	if [ "${DSTATUS}" = "1" ]; then
		echo "${SUPPORT_DAEMON} is running."
		return;
	fi
	echo "Error checking status of ${SUPPORT_DAEMON}"
}

# Source function library.
if [ -f /etc/rc.status ]; then
  # SUSE
  . /etc/rc.status
  rc_reset
else
  # Reset commands if not available
  rc_status() {
    case "$1" in
	-v)
	    true
	    ;;
	*)
	    false
	    ;;
    esac
    echo
  }
  alias rc_exit=exit
fi


if [ -x "$WORKDIR1" ]; then
WORKDIR="$WORKDIR1"
else
WORKDIR="$WORKDIR2"
fi

DAEMON=twonkystarter
TWONKYSRV="${WORKDIR}/${DAEMON}"

#cd $WORKDIR

# see if we need to start the twonky proxy service
PROXY_DAEMON=none
if [ "${START_PROXY}" = "1" ]; then
PROXY_DAEMON=twonkyproxy
fi

# see if we need to start the twonky tuner service
TUNER_DAEMON=none
if [ "${START_TUNER}" = "1" ]; then
TUNER_DAEMON=twonkytuner
fi

case "$1" in
  start)
    if [ -e $PIDFILE ]; then
      PID=`cat $PIDFILE`
      echo "Twonky server seems already be running under PID $PID"
      echo "(PID file $PIDFILE already exists). Checking for process..."
      running=`ps --no-headers -o "%c" -p $PID`
      if ( [ "${DAEMON}" = "${running}" ] ); then
        echo "Process IS running. Not started again."
      else
        echo "Looks like the daemon crashed: the PID does not match the daemon."
        echo "Removing flag file..."
        rm $PIDFILE
        $0 start
        exit $?
      fi
      exit 0
    else
      if [ ! -x "${TWONKYSRV}" ]; then
	  echo "Twonky server not found".
	  rc_status -u
	  exit $?
      fi
      start_support_daemon "${TUNER_DAEMON}" "${WORKDIR}"
      echo -n "Starting $TWONKYSRV ... "
      "$TWONKYSRV"
      rc_status -v
    fi
    start_support_daemon "${PROXY_DAEMON}" "${WORKDIR}"
  ;;
  stop)
    if [ ! -e $PIDFILE ]; then
      echo "PID file $PIDFILE not found, stopping server anyway..."
      killall -s TERM ${DAEMON}
      rc_status -u
      stop_support_daemon "${PROXY_DAEMON}" 
      stop_support_daemon "${TUNER_DAEMON}" 
      exit 3
    else
      echo -n "Stopping Twonky MediaServer ... "
      PID=`cat $PIDFILE`
      kill -s TERM $PID
      rm -f $PIDFILE
      rc_status -v
      stop_support_daemon "${PROXY_DAEMON}" 
      stop_support_daemon "${TUNER_DAEMON}" 
    fi
  ;;
  reload)
    if [ ! -e $PIDFILE ]; then
      echo "PID file $PIDFILE not found, stopping server anyway..."
      killall -s TERM ${DAEMON}
      rc_status -u
      exit 3
    else
      echo -n "Reloading Twonky server ... "
      PID=`cat $PIDFILE`
      kill -s HUP $PID
      rc_status -v
    fi
  ;;
  restart)
    $0 stop
    $0 start
  ;;
  status)
    if [ ! -e $PIDFILE ]; then
      running="`ps --no-headers -o pid -C ${DAEMON}`"
      if [ "${running}" = "" ]; then
        echo "No Twonky server is running"
      else
        echo "A Twonky server seems to be running with PID ${running}, but no PID file exists."
        echo "Probably no write permission for ${PIDFILE}."
      fi
    status_support_daemon "${PROXY_DAEMON}" 
    status_support_daemon "${TUNER_DAEMON}" 
      exit 0
    fi
    PID=`cat $PIDFILE`
    running=`ps --no-headers -o "%c" -p $PID`
    if ( [ "${DAEMON}" = "${running}" ] ); then
      echo "Twonky server IS running."
    else
      echo "Looks like the daemon crashed: the PID does not match the daemon."
    fi
    status_support_daemon "${PROXY_DAEMON}" 
    status_support_daemon "${TUNER_DAEMON}" 
  ;;
  *)
    echo ""
    echo "Twonky server"
    echo "------------------"
    echo "Syntax:"
    echo "  $0 {start|stop|restart|reload|status}"
    echo ""
    exit 3
  ;;
esac

rc_exit


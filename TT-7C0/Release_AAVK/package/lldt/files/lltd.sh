#!/bin/sh
#
# $Id: lltd.sh,v 1.1 2009-01-06 02:02:21 winfred Exp $
#
# usage: lltd.sh
#

echo "Run LLTD Script"
PID_FILE=/var/run/lld2test-br-lan.pid

TIME_SEC=10
DEVICE_INF=br-lan


if [ $# -eq 1 ]; then
	TIME_SEC=$1
fi

rm -rf /var/lltd_info*

opmode=`nvram_get 2860 OperationMode`
if [ "$opmode" = "2" ]; then
	DEVICE_INF=br-lan
	PID_FILE=/var/run/lld2test-br-lan.pid
else
	DEVICE_INF=br-lan
	PID_FILE=/var/run/lld2test-br-lan.pid
fi

if [ "$TIME_SEC" = "1" ]; then

if [ -f /var/llrun ] ; then
    echo "reset = on"  > /etc/lld2dtest.conf
	
	lld2test $DEVICE_INF
    echo "Run Sleep $TIME_SEC"
    sleep $TIME_SEC
    echo "After Sleep $TIME_SEC"
    if [ -f $PID_FILE ] ; then
	   echo "Stopping lld2test"
	   PID=`cat $PID_FILE`
	   kill -9 $PID	
	   rm -rf $PID_FILE	
    else
	   echo "lld2test is not running"
    fi
    
    echo "rm -rf /etc/lld2dtest.conf"
	rm -rf /etc/lld2dtest.conf
	
	rm -rf /var/llrun
fi

else
  lld2test $DEVICE_INF
  echo "Run Sleep $TIME_SEC"
  sleep $TIME_SEC
  echo "After Sleep $TIME_SEC"
  if [ -f $PID_FILE ] ; then
	echo "Stopping lld2test"
	PID=`cat $PID_FILE`
	kill -9 $PID	
	rm -rf $PID_FILE	
  else
	echo "lld2test is not running"
  fi
  
  echo 1 > /var/llrun
fi

echo "End LLTD Script"


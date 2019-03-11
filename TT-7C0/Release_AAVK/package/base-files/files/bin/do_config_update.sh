#!/bin/sh
. /lib/functions.sh
include /lib/upgrade
v "Config Switching to ramdisk..."
kill_remaining TERM
sleep 3
kill_remaining KILL

run_ramfs_config


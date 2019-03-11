#!/bin/sh

BF_HANDLE_MAJOR=1
PRIO_HANDLE_MAJOR=2
OUTPUT_HANDLE_MAJOR=3
SUBPRIO_HANDLE_MAJOR=4
TBF_HANDLE_MAJOR=FFD4
SCHROOT_HANDLE_MAJOR=FFD5
BGROOT_HANDLE_MAJOR=FFD6
GUEST_HANDLE_MAJOR=FFD9
# Note: the block qdiscs are added by the qdiscman daemon, not the init script
BLOCK_TBF_HANDLE_MAJOR=FFD7
BLOCK_HANDLE_MAJOR=FFD8

CLASSID_RESERVED_START=FFC0
CLASSID_ROOT=FFFF
CLASSID_CLASSIFIED=FFF0
CLASSID_PRIORITIZED=FFC0
CLASSID_LOCALHOST=FFF1
CLASSID_INTERACTIVE=FFFA
CLASSID_BACKGROUND=FFFB
CLASSID_DEFAULT=FFFD
CLASSID_ELEVATED=FFFE
CLASSID_ELEVATED_BROWSER=FFEB
CLASSID_ELEVATED_CHEAT=FFEC
CLASSID_ELEVATED_DNS=FFED
CLASSID_GUEST=FFB2

# weight needs to be specified in bits
DEFAULT_CLASS_WEIGHT=160000
DEDICATED_CLASS_WEIGHT=8000
PRIORITIZED_WEIGHT=320000
COMMITTED_WEIGHT=160000
INTERACTIVE_WEIGHT=32000
BACKGROUND_WEIGHT=8000
ELEVATED_WEIGHT=320000
GUEST_WEIGHT=4000
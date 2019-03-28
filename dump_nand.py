__author__ = 'Rodney Beede'

# Date created      : 2019-03-26
#
# Revision History  : See source control history at https://github.com/rbeede/ZyXel_EMG2926-Q10A

# Copyright (C) 2019 Rodney Beede
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# https://www.gnu.org/licenses/agpl-3.0.en.html


# Strict code checking (in-case cli option -W error wasn't used)
import warnings
warnings.simplefilter('error')

# Minimum version check
import sys
MIN_VERSION_PY = (3, 6)
if sys.version_info < MIN_VERSION_PY:
	sys.exit("Python %s.%s or later is required." % MIN_VERSION_PY)

# Always a good security practice as a default
import os
os.umask(0o077)


#---------------------------------
# Your library/module imports here
import serial

# Third party Python libraries.


# Global constants
DEVICE_COMMAND_PROMPT = 'AAVK-EMG2926Q10A#'


#----------
def main():
	if(len(sys.argv) != 2):  # 0 is program name, 1..(n-1) are passed args
		sys.exit(f"Usage:  python3 {sys.argv[0]} /dev/ttyUSB0")

	ser = serial.Serial(
		sys.argv[1],
		baudrate=115200,
		bytesize=8,
		parity='N',
		stopbits=1,
		timeout=3,
		xonxoff=0,
		rtscts=0)

	print(f"Using serial port:  {ser.name}")

	ser.write(b"\n")  # Send newlin (enter) to wakeup current serial line

	line = ser.readline()

	if(DEVICE_COMMAND_PROMPT != line):
		print(f"Did not see {DEVICE_COMMAND_PROMPT} from serial device even after sending newline key", file=sys.stderr)
		print("Perhaps you need to get the device to the proper unlocked state first?", file=sys.stderr)
		sys.exit(1)
	else:
		print("Found expected command prompt and beginning nand dump")

	for page_addr in range(0x0, 0x8000000, 0x800):
		print(f"Looking at page # {:08x} ...".format(page_addr))
		
		ser.write(b"send nand dump {:08x}\n".format(page_addr))

		# Check our starting line header meets expectations
		line = ser.readline()
		
		if("Page {} dump:".format(hex(page_addr)) != line):
			print(f"Did not see page response for page # {:08x}".format(page_addr), file=sys.stderr)
			sys.exit(255)
		
		# Next 128 lines (2048 bytes per page, 16 bytes per line)
		for lineNumber in range(128):
			line = ser.readline()
			
			# expecting tab 8 hex bytes space sep, then two spaces, then 8 hex bytes, then \n
			print('TODO')
			
		# Next line should be OOB data
		line = ser.readline()
		
		if("OOB:" != line):
			print(f"Did not see page response of OOB for page # {:08x}".format(page_addr), file=sys.stderr)
			sys.exit(254)
			
		# Next 8 lines are OOB data which we just ignore
		for _ in range(8):
			ser.readline()
			
		# Finally expect our next command prompt
		line = ser.readline()

		if(DEVICE_COMMAND_PROMPT != line):
			print(f"Did not see {DEVICE_COMMAND_PROMPT} from serial device after page read", file=sys.stderr)
			sys.exit(1)
		else:
			print("Found expected command prompt and beginning next nand page dump")		

	ser.close()


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if __name__ == "__main__": # Scoping
	main()

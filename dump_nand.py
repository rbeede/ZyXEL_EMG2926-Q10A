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
	if(len(sys.argv) != 3):  # 0 is program name, 1..(n-1) are passed args
		sys.exit(f"Usage:  python3 {sys.argv[0]} /dev/ttyUSB0 output-file")

	ser = serial.Serial(
		sys.argv[1],
		baudrate=115200,
		bytesize=8,
		parity='N',
		stopbits=1,
		timeout=3,  # seconds
		xonxoff=0,
		rtscts=0)

	print(f"Using serial port:  {ser.name}")

	print("Writing output to canonical path:  {}".format(os.path.realpath(sys.argv[2])))

	f = open(os.path.realpath(sys.argv[2]), 'wb')

	for page_addr in range(0x0, 0x8000000, 0x800):
		for attempt in range(3):
			try:
				page_bytes = _get_nand_page(ser, page_addr)
			except:
				if(2 != attempt):
					print(f"Failed on attempt {attempt}.  Will retry", file=sys.stderr)
				else:
					print(f"Failed on attempt {attempt}.  Giving up", file=sys.stderr)
					f.close()
					ser.close()
					sys.exit(101)
			else:
				print(f"Success page read on attempt # {attempt}")
				break

		# Write current page to our file
		f.write(page_bytes)


	# All done
	f.close()
	ser.close()
	print("Completed nand dump")


# Consumes and discards all existing unread lines in ser
# Sends a newline character to trigger a prompt response
# Will verify that it can get a prompt
def _get_nand_page(ser, page_addr):
	print("Looking for page # {:08x} ...".format(page_addr))

	# Discard anything in the buffer
	while ser.in_waiting > 0:
		ser.read(ser.in_waiting)

	ser.write(b"\n")  # Send newline (enter) to wakeup current serial line and get a prompt

	line = ser.readline()

	if(DEVICE_COMMAND_PROMPT != line):
		error_message = f"Did not see {DEVICE_COMMAND_PROMPT} from serial device even after sending newline key."
		error_message += "  "
		error_message += "Perhaps you need to get the device to the proper unlocked state first?"
		error_message += "  "
		error_message += f"Line seen was {line}"

		print(error_message, file=sys.stderr)
		raise ConnectionError(error_message)
	else:
		print("\tFound expected command prompt and sending nand dump command")


	ser.write(b"send nand dump {:08x}\n".format(page_addr))

	# Check our starting line header meets expectations
	line = ser.readline()

	if("Page {:08x} dump:".format(page_addr) != line):
		error_message = "Did not see page response header for page # {:08x}".format(page_addr)
		print(error_message, file=sys.stderr)
		raise RuntimeError(error_message)

	# Next 128 lines (2048 bytes per page, 16 bytes per line)
	page_bytes = bytearray()
	for lineNumber in range(128):
		line = ser.readline()

		# expecting tab 8 hex bytes space sep, then two spaces, then 8 hex bytes, then \n
		line_bytes = bytes.fromhex(line[1:-1])  # drop first char (tab) an last char (newline)

		assert len(line_bytes) == 16, f"Incomplete line from input lacks 16 bytes:  {line}"

		page_bytes.extend(line_bytes)

	# Next line should be OOB data
	line = ser.readline()

	if("OOB:" != line):
		error_message = "Did not see page response of OOB for page # {:08x}".format(page_addr)
		print(error_message, file=sys.stderr)
		raise RuntimeWarning(error_message)


	# Next 8 lines are OOB data which we just ignore
	for _ in range(8):
		ser.readline()

	# Last line would be our DEVICE_COMMAND_PROMPT but we don't read it to allow future loops to have it

	return page_bytes

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if __name__ == "__main__": # Scoping
	main()

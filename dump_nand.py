__author__ = "Rodney Beede"

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
warnings.simplefilter("error")

# Minimum version check
import sys
MIN_VERSION_PY = (3, 6)
if sys.version_info < MIN_VERSION_PY:
	sys.exit("Python %s.%s or later is required." % MIN_VERSION_PY)  # old style for python2 compatibility

# Always a good security practice as a default
import os
os.umask(0o077)


#---------------------------------
# Your library/module imports here
import serial
import time

# Third party Python libraries.


# Global constants
DEVICE_COMMAND_PROMPT = bytes("AAVK-EMG2926Q10A# ", "utf_8")
DEVICE_LINE_SEPARATOR = bytes("\r\n", "utf_8")


#----------
def main():
	if(len(sys.argv) != 3):  # 0 is program name, 1..(n-1) are passed args
		sys.exit(f"Usage:  python3 {sys.argv[0]} /dev/ttyUSB0 output-file")

	ser = serial.Serial(
		sys.argv[1],
		baudrate=115200,
		bytesize=8,
		parity="N",
		stopbits=1,
		timeout=1,  # seconds
		xonxoff=0,
		rtscts=0)

	print(f"Using serial port:  {ser.name}")

	print("Writing output to canonical path:  {}".format(os.path.realpath(sys.argv[2])))

	f = open(os.path.realpath(sys.argv[2]), "wb")

	for page_addr in range(0x0, 0x8000000, 0x800):
		print("Dumping page # {:08x} ...".format(page_addr))

		for attempt in range(3):
			try:
				page_bytes = _get_nand_page(ser, page_addr)
			except:
				print("Unwanted error detail:", sys.exc_info())

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
	print(f"Completed nand dump to {sys.argv[2]}")


# Consumes and discards all existing unread lines in ser
# Sends a line separator to trigger a prompt response
# Will verify that it can get a prompt
def _get_nand_page(ser, page_addr):
	print("\t{}\tStarting buffer clear".format(time.ctime()))
	# Discard anything in the buffer
	while ser.in_waiting > 0:
		ser.read(ser.in_waiting)

	print("\t{}\tSending newlines to wakeup terminal".format(time.ctime()))
	ser.write(DEVICE_LINE_SEPARATOR)  # Send to wakeup current serial line and get a prompt
	ser.write(DEVICE_LINE_SEPARATOR)  # Repeat twice to get good char read
	time.sleep(1)  # Allow device time to send response

	# Read all lines and save the last line which should be our prompt
	print("\t{}\tLooking for device prompt".format(time.ctime()))
	line = ""
	while ser.in_waiting > 0:
		line = ser.readline()
	print("\t{}\tChecking for correct device prompt".format(time.ctime()))

	if(DEVICE_COMMAND_PROMPT != line):
		error_message = f"Did not see {DEVICE_COMMAND_PROMPT} from serial device even after sending newline key."
		error_message += "  "
		error_message += "Perhaps you need to get the device to the proper unlocked state first?"
		error_message += "  "
		error_message += f"Line seen was {line}"

		print(error_message, file=sys.stderr)
		raise ConnectionError(error_message)
	else:
		print("\t{}\tFound expected command prompt and sending nand dump command".format(time.ctime()))

	ser.write("nand dump {:08x}".format(page_addr).encode())
	ser.write(DEVICE_LINE_SEPARATOR)

	
	line = ser.readline()  # Next line is echo back of what we just sent, so ignore

	# Check our starting line header meets expectations
	line = ser.readline()  # remember that this is a bytes sequence still, not a string

	if("Page {:08x} dump:{}".format(page_addr, DEVICE_LINE_SEPARATOR.decode('utf_8')) != line.decode('utf_8')):
		error_message = "Did not see page response header for page # {:08x}".format(page_addr)
		error_message += "\t"
		error_message += f"Saw line:  {line}"

		print(error_message, file=sys.stderr)
		raise RuntimeError(error_message)

	# Next 128 lines (2048 bytes per page, 16 bytes per line)
	page_bytes = bytearray()
	for lineNumber in range(128):
		line = ser.readline()
		line_as_string = line.decode("utf_8")

		# expecting tab -> 8 hex bytes (with space sep 7 times) -> two spaces -> 8 hex bytes (with space sep 7 times) -> \n
		line_hex_to_bytes = bytes.fromhex(line_as_string[1:-2])  # drop first char (tab) and last 2 chars (\r\n)

		assert len(line_hex_to_bytes) == 16, f"Incomplete line because input lacks 16 bytes:  {line}"

		page_bytes.extend(line_hex_to_bytes)

	# Next line should be OOB data
	print("\t{}\tLooking for OOB".format(time.ctime()))
	line = ser.readline()

	if("OOB:{}".format(DEVICE_LINE_SEPARATOR.decode('utf_8')) != line.decode("utf_8")):
		error_message = "Did not see page response of OOB for page # {:08x}".format(page_addr)
		error_message += f"\tInstead saw:  {line}"
		print(error_message, file=sys.stderr)
		raise RuntimeWarning(error_message)


	# Next 8 lines are OOB data which we just ignore
	for _ in range(8):
		ser.readline()

	# Last line would be our DEVICE_COMMAND_PROMPT but we just ignore it (it is not line separator terminated so readline() would timeout)

	return page_bytes

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if __name__ == "__main__": # Scoping
	main()

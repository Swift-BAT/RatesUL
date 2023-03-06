import sys
import math

T0 = float(sys.argv[1])
search_time_window = float(sys.argv[2])
filename = sys.argv[3]

if 'quad' in filename:
	flag_lc = 'quad_lc:'
if '64ms' in filename:
	flag_lc = '64ms_lc:'

f_input = open(filename,'r')

for line in f_input.readlines():
	if '!' not in line[0]:
		column = line.split()
		time = float(column[0])
		dt = abs(time-T0)
		if (dt < search_time_window):
			print flag_lc, line.strip()

f_input.close

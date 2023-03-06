import sys
import math

info_filename = sys.argv[1]

f_info = open(info_filename,'r')

for line in f_info.readlines():
	if 'output_dir:' in line:
		column = line.split()
		output_dir = column[1]
		break

f_info.close

f_input = open(output_dir + '/raw_lc_detection.txt', 'r')

max_snr = 0.0
for line in f_input.readlines():
	if '#' not in line[0]:
		column = line.split()
		fg_start = float(column[1])
		fg_dur = float(column[2])
		snr = float(column[7])
		if (snr > max_snr):
			max_snr = snr
			max_fg_start = fg_start
			max_fg_stop = fg_start + fg_dur

f_input.close

print "max_snr:", max_snr, max_fg_start, max_fg_stop

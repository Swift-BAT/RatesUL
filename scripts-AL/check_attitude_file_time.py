import sys
import math
from astropy.io import fits
import os

## check the time in attitude file to make sure that
## it covers the burst time

obsid = sys.argv[1]
T0 = float(sys.argv[2])
search_time_window = float(sys.argv[3])
xmin = -1.0*search_time_window
xmax = search_time_window
output_dir = sys.argv[4]

output_temp = open('att_check_temp.txt','w')
flag_att_check = 0


#print "Checking attitude file from pass data...."	

#att_file = output_dir + '/pass_data/pass_combine/fits/sw99999999000b1e5x001.att'

print "Checking attitude file from Hans' file...."

att_file = output_dir + '/pass_data/pass_combine/fits/sw' + obsid + '.att'

#if not os.path.exists(att_file):
#	att_file = output_dir + '/pass_data/sw00767028000sat.fits'

att_fits = fits.open(att_file)
att_fits_data = att_fits[2].data
 
flag_in_time_window = 1
flag_gap = 0
for i in range(len(att_fits_data)):
	time = att_fits_data[i][0] - T0

	if (i == 0):
		time_old = time

	## first, check if there are data within the search time window
	if(xmin <= time <= xmax):
		flag_in_time_window = 0
		## 2nd, check if there are gaps in att data
		if ((time - time_old) > 5.01):
			flag_gap = 1
	time_old = time
		

att_fits.close

if (flag_in_time_window == 0) and (flag_gap == 0):
#	print "Attitude file from pass data is okay."
	flag_att_check = 0	
else:
#	print flag_in_time_window, flag_gap
#	print "Attitude file from pass data is not okay, end event analysis process for", obsid, "."
	flag_att_check = 1

output_temp.write('flag_att_check: ' + str(flag_att_check) + '\n')

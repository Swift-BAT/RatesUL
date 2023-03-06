import sys
import math
import pyfits
import os

T0 = float(sys.argv[1])
year = sys.argv[2]
day_of_year = sys.argv[3]
burst_pass_data_folder = sys.argv[4]
att_folder = sys.argv[5]

#output_temp = open('att_check_temp.txt','w')
att_filename = att_folder + '/attitude_' + year + '_' + day_of_year + '.att'

flag_att = 0
if os.path.exists(att_filename):

	att_fits = pyfits.open(att_filename)
	att_fits_data = att_fits[1].data

	for i in range(len(att_fits_data)):
		time = att_fits_data[i][0]
		pointing_RA = att_fits_data[i][2][0]
		pointing_DEC = att_fits_data[i][2][1]
		pointing_ROLL = att_fits_data[i][2][2]

		#print time, pointing_RA, pointing_DEC, pointing_ROLL
		
		dt = abs(time - T0)

		if (dt < 2.5):
			flag_att = 1
			print 'BAT_RA:', pointing_RA
			print 'BAT_DEC:', pointing_DEC
			print 'BAT_ROLL:', pointing_ROLL
			break

	att_fits.close

if (flag_att == 0):
	print "Hans' attitude file does not include T0."
	print "Checking attitude file from pass data...."

	att_filename = burst_pass_data_folder + '/sw99999999000b1e5x001.att'

	if os.path.exists(att_filename):

		att_fits = pyfits.open(att_filename)
		att_fits_data = att_fits[1].data

		flag_att = 0
		for i in range(len(att_fits_data)):
			time = att_fits_data[i][0]
			pointing_RA = att_fits_data[i][2][0]
			pointing_DEC = att_fits_data[i][2][1]
			pointing_ROLL = att_fits_data[i][2][2]

		#print time, pointing_RA, pointing_DEC, pointing_ROLL

			dt = abs(time - T0)

			if (dt < 2.5):
				flag_att = 1
				print 'BAT_RA:', pointing_RA
				print 'BAT_DEC:', pointing_DEC
				print 'BAT_ROLL:', pointing_ROLL
				print 'BAT_RA_from_HANS:', pointing_RA
				print 'BAT_DEC_from_HANS:', pointing_DEC
				print 'BAT_ROLL_from_HANS:', pointing_ROLL
				print 'BAT_pointing_from_HANS:time_min:', dt
				break

		att_fits.close	

if (flag_att == 0):
	print "No attitude file found."

print "flag_att:", flag_att

#output_temp.write('flag_att_check: ' + str(flag_att) + '\n')

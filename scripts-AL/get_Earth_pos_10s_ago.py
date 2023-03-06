import sys
import math
import pyfits
import os

## This script get the Earth position

filename_info = sys.argv[1]

f_info = open(filename_info,'r')

for line in f_info.readlines():
	if 'att_folder:' in line:
                column = line.split()
                att_folder = column[1]
	if 'T0_10s_ago:' in line:
                column = line.split()
                T0 = float(column[1])
	if 'Year:' in line:
                column = line.split()
                year = column[1]
	if 'DOY:' in line:
                column = line.split()
                day_of_year = column[1]
	

f_info.close

sao_filename = att_folder + '/saofile_' + year + '_' + day_of_year + '.att'

flag_sao = 0
if os.path.exists(sao_filename):

	sao_fits = pyfits.open(sao_filename)
	sao_fits_data = sao_fits[1].data

	for i in range(len(sao_fits_data)):
		time = sao_fits_data[i][0]
		Earth_RA = sao_fits_data[i][29]
		Earth_DEC = sao_fits_data[i][30]

		#print time, pointing_RA, pointing_DEC, pointing_ROLL
		
		dt = abs(time - T0)

		if (dt < 2.5):
			flag_sao = 1
			print 'Earth_RA_10s_ago:', Earth_RA
			print 'Earth_DEC_10s_ago:', Earth_DEC
			break

	sao_fits.close

#if (flag_sao == 0):
#	print "Hans' saoitude file does not include T0."
#	print "Checking saoitude file from pass data...."
#
#	sao_filename = burst_pass_data_folder + '/sw99999999000b1e5x001.sao'
#
#	if os.path.exists(sao_filename):
#
#		sao_fits = pyfits.open(sao_filename)
#		sao_fits_data = sao_fits[1].data
#
#		flag_sao = 0
#		for i in range(len(sao_fits_data)):
#			time = sao_fits_data[i][0]
#			pointing_RA = sao_fits_data[i][2][0]
#			pointing_DEC = sao_fits_data[i][2][1]
#			pointing_ROLL = sao_fits_data[i][2][2]
#
#		#print time, pointing_RA, pointing_DEC, pointing_ROLL
#
#			dt = abs(time - T0)
##
#			if (dt < 2.5):
#				flag_sao = 1
#				print 'BAT_RA:', pointing_RA
#				print 'BAT_DEC:', pointing_DEC
#				print 'BAT_ROLL:', pointing_ROLL
#				print 'BAT_RA_from_HANS:', pointing_RA
#				print 'BAT_DEC_from_HANS:', pointing_DEC
#				print 'BAT_ROLL_from_HANS:', pointing_ROLL
#				print 'BAT_pointing_from_HANS:time_min:', dt
#				break
#
#		sao_fits.close	

if (flag_sao == 0):
	print "SAO file found."
	print 'Earth_RA: N/A'
        print 'Earth_DEC: N/A'

import sys
import math

## This script get the obsid listed in match_evt_list*.txt

filename_info = sys.argv[1]

f_info = open(filename_info,'r')

for line in f_info.readlines():
	if 'output_dir:' in line:
		column = line.split()
		output_dir = column[1]
	if 'Year:' in line:
		column = line.split()
                year = column[1]
	if 'DOY:' in line:
		column = line.split()
                doy = column[1]

f_info.close

f_evt_list = open(output_dir + '/match_evt_list_' + year + '_' + doy + '.txt', 'r')

obsid_array = []
for line in f_evt_list.readlines():
	if '#' not in line[0]:
		column = line.split()
		filename = column[2]
		column_filename = filename.split('/')
		for i in range(len(column_filename)):
			if 'evt' in column_filename[i]:
				obsid = column_filename[i][2:13]
				flag = 0
				for i_obsid in range(len(obsid_array)):
					if (obsid == obsid_array[i_obsid]):
						flag = 1
				if (flag == 0):
					obsid_array.append(obsid)

f_evt_list.close

## do it again for the next day
day_of_year = int(doy) + 1
if(day_of_year < 10):
        day_of_year_name = '00' + str(day_of_year)
if(10 <= day_of_year < 100):
        day_of_year_name = '0' + str(day_of_year)
if(day_of_year >= 100):
        day_of_year_name = str(day_of_year)

doy = day_of_year_name

f_evt_list = open(output_dir + '/match_evt_list_' + year + '_' + doy + '.txt', 'r')

for line in f_evt_list.readlines():
        if '#' not in line[0]:
                column = line.split()
                filename = column[2]
                column_filename = filename.split('/')
                for i in range(len(column_filename)):
                        if 'evt' in column_filename[i]:
                                obsid = column_filename[i][2:13]
                                flag = 0
                                for i_obsid in range(len(obsid_array)):
                                        if (obsid == obsid_array[i_obsid]):
                                                flag = 1
                                if (flag == 0):
                                        obsid_array.append(obsid)

f_evt_list.close

for i in range(len(obsid_array)):
	print obsid_array[i]

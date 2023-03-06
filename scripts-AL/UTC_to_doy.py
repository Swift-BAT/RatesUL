import sys
import math
import datetime

time_UTC = sys.argv[1]
at = sys.argv[2]
sec_input = sys.argv[3]

year = int(time_UTC[:4])
month_name = time_UTC[4:7]
day_name = time_UTC[7:9]
day = int(time_UTC[7:9])
sec = sec_input[:12]

month_array = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

for i in range(len(month_array)):
	if (month_name == month_array[i]):
		month = i+1
		if (i < 9):
			month_newname = '0' + str(i+1)
		else:
			month_newname = str(i+1)	
		#	print month_name, month_array[i], month
		break

doy = datetime.date(year, month, day).strftime("%j")
print 'Year:', year
print 'Month:', month_newname
print 'Day:', day_name
print 'DOY:', doy

time_UTC_good_form = str(year) + '-' + str(month_newname) + '-' + str(day_name) + 'T' + sec + ' UTC'
print "time_UTC:", time_UTC_good_form

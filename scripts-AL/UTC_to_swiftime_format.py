import sys
import math
import datetime

time_UTC = sys.argv[1]

year = int(time_UTC[:4])
month = int(time_UTC[5:7])
day_name = time_UTC[8:10]
time_rest = time_UTC[11:]

month_array = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

month_name = month_array[month-1]
time_UTC_swifttime = str(year) + month_name + day_name + ' at ' + time_rest

print "time_UTC_swifttime:", time_UTC_swifttime

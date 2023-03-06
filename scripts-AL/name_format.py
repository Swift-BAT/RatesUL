import sys
import math

day_of_year = int(sys.argv[1])
if(day_of_year < 10):
	day_of_year_name = '00' + str(day_of_year)
if(10 <= day_of_year < 100):
	day_of_year_name = '0' + str(day_of_year)
if(day_of_year >= 100):
	day_of_year_name = str(day_of_year)
print day_of_year_name


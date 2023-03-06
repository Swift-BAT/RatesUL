import sys
import math
import pyfits
from matplotlib import pyplot as plt
plt.switch_backend('agg')

T0 = float(sys.argv[1])
home = sys.argv[2]

xmin = -500.0
xmax = 500.0

filename = home + '/1s_rate_sort.lc'

lc_fits = pyfits.open(filename)
lc_fits_data = lc_fits[1].data

time = []
count = []
flag_1s_rate = 0
for i in range(len(lc_fits_data)):
	if(xmin <= lc_fits_data[i][0]-T0 <= xmax):
		flag_1s_rate = 1
		count_tot = 0.0
		count_tot += lc_fits_data[i][1]

		time.append(lc_fits_data[i][0]-T0)
		time.append(lc_fits_data[i][0]-T0+1.0) ## create fake 1s bin plot

		count.append(count_tot)
		count.append(count_tot)

lc_fits.close

#for i in range(len(time)):
#	print time[i], rate_15_25[i], rate_25_50[i], rate_50_100[i], rate_100_350[i], rate_15_350[i]

### set fig size
fig = plt.figure(1, figsize=(10,16))

plt.plot(time,count,color='k')
plt.title('1s-rate data')
plt.xlabel('Time since T0 (T0 = ' + str(T0) + 's) [s]')
plt.ylabel('Count Rate [s$^{-1}$]')
#plt.legend()

plt.xlim(xmin,xmax)


#plt.savefig('/batfsw/burst/amytest/test.png')
plt.savefig(home + '/1s_rate_lc.png',bbox_inches='tight')
#plt.show()

print 'flag_1s_rate:', flag_1s_rate

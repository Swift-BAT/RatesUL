import sys
import math
import pyfits
from matplotlib import pyplot as plt
plt.switch_backend('agg')

#GRBname = sys.argv[1]
#obsid = sys.argv[2]
T0 = float(sys.argv[1])
home = sys.argv[2]

xmin = -500.0
xmax = 500.0


filename = home + '/64ms_rate_sort.lc'


lc_fits = pyfits.open(filename)
lc_fits_data = lc_fits[1].data


time = []
count_15_350 = []
count_15_25 = []
count_25_50 = []
count_50_100 = []
count_100_350 = []
#count_err = []
dummy = 0
flag_ms_rate = 0
for i in range(len(lc_fits_data)):
	#if(dummy != 1):
	if(xmin <= lc_fits_data[i][0]-T0 <= xmax):
		flag_ms_rate = 1
		count_tot = 0.0
		count_15_25_tot = 0.0
		count_25_50_tot = 0.0
		count_50_100_tot = 0.0
		count_100_350_tot = 0.0
		for i_band in range(0,4):
			count_tot += lc_fits_data[i][1][i_band]
			if(i_band == 0):
				count_15_25_tot += lc_fits_data[i][1][i_band]
			if(i_band == 1):
				count_25_50_tot += lc_fits_data[i][1][i_band]
			if(i_band == 2):
				count_50_100_tot += lc_fits_data[i][1][i_band]
			if(i_band == 3):
				count_100_350_tot += lc_fits_data[i][1][i_band]

		time.append(lc_fits_data[i][0]-T0)
		time.append(lc_fits_data[i][0]-T0+0.064) ## create fake 0.064s bin plot

		count_15_350.append(count_tot)
		count_15_350.append(count_tot)

		count_15_25.append(count_15_25_tot)
		count_15_25.append(count_15_25_tot)

		count_25_50.append(count_25_50_tot)
		count_25_50.append(count_25_50_tot)

		count_50_100.append(count_50_100_tot)
		count_50_100.append(count_50_100_tot)

		count_100_350.append(count_100_350_tot)
		count_100_350.append(count_100_350_tot)
		#count.append(count_tot)
		#count_err.append(lc_fits_data[i][2])


lc_fits.close

#for i in range(len(time)):
#	print time[i], rate_15_25[i], rate_25_50[i], rate_50_100[i], rate_100_350[i], rate_15_350[i]

### set fig size
fig = plt.figure(1, figsize=(10,16))

## 1st figure
fig1 = fig.add_subplot(5,1,1)

plt.plot(time,count_15_25,color='k', label='15-25 keV')
#plt.xlim(-1000.0,300.0)
plt.title('64ms-rate data')
#plt.ylim(9500.0,1.2e+4)
#plt.xlabel('Time since T0 (T0 = ' + str(T0) + 's) [s]')
plt.ylabel('Counts')
plt.legend()

## 2st figure
fig2 = fig.add_subplot(5,1,2,sharex=fig1)

plt.plot(time,count_25_50,color='r', label='25-50 keV')
#plt.xlim(-1000.0,300.0)
#plt.ylim(9500.0,1.2e+4)
#plt.xlabel('Time since T0 (T0 = ' + str(T0) + 's) [s]')
plt.ylabel('Counts')
plt.legend()

## 3st figure
fig3 = fig.add_subplot(5,1,3,sharex=fig1)

plt.plot(time,count_50_100,color='g', label='50-100 keV')
#plt.xlim(-1000.0,300.0)
#plt.ylim(9500.0,1.2e+4)
#plt.xlabel('Time since T0 (T0 = ' + str(T0) + 's) [s]')
plt.ylabel('Counts')
plt.legend()

## 4st figure
fig4 = fig.add_subplot(5,1,4,sharex=fig1)

plt.plot(time,count_100_350,color='b', label='100-350 keV')
#plt.xlim(-1000.0,300.0)
#plt.ylim(9500.0,1.2e+4)
#plt.xlabel('Time since T0 (T0 = ' + str(T0) + 's) [s]')
plt.ylabel('Counts')
plt.legend()

## 5st figure
fig5 = fig.add_subplot(5,1,5,sharex=fig1)

#plt.errorbar(time,rate, yerr=rate_err,linestyle="None", marker="o", markersize=3, color="k")
plt.plot(time,count_15_350,color='purple', label='15-350 keV')
#plt.xlim(-1000.0,300.0)
#plt.title(GRBname)
#plt.ylim(9500.0,1.2e+4)
plt.xlabel('Time since T0 (T0 = ' + str(T0) + 's) [s]')
plt.ylabel('Counts')
plt.legend()

#plt.xlim(-20.0,60.0)

plt.xlim(xmin,xmax)

#plt.savefig('/batfsw/burst/amytest/test.png')
plt.savefig(home + '/64ms_rate_lc.png',bbox_inches='tight')
#plt.savefig('test.png',bbox_inches='tight')
#plt.savefig('/local/data/bat1/alien/Swift_3rdBATcatalog/event/batevent_reproc/trigger' + trigid + '/00' + trigid + '000-results/lc/' + trigid + '_quad.png')
#plt.show()

print 'flag_ms_rate:', flag_ms_rate

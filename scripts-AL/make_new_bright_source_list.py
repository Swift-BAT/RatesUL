import sys
import math
import pyfits

#######################################################################################
## This code attach the ra and dec of the GRB to the bright source list
#######################################################################################

trigid = sys.argv[1]
theGRB = sys.argv[2]
list = sys.argv[3]

## read in original data
source_fits = pyfits.open(list)

source_fits_data = source_fits[1].data

for i in range(len(source_fits_data)):
		name = source_fits_data[i][1]
	 	## change the GRB role
		if ('TRIG' in name):
			source_fits_data[i][1] = 'deleted-GRB'
			source_fits_data[i][40] = '0.0'  ## set snr to 0.0 to make sure the GRB will not be cleaned (only sources with snr above cleansnr will be cleaned)
			

source_fits.writeto(list + '.noGRB')

source_fits.close()

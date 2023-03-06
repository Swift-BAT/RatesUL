#### This script is modified from David Palmer's code: batfov.py,
#### with some functions copied from swinfo.py (also David Palmer's code)
####
#### This script check whether a healpix image overlaps with the BAT FOV.

import os,sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

#import swiftanal.swinfo
#from swiftanal.swinfo import batExposure,source

from astropy.io import fits
from astropy import wcs

from numpy import *
import numpy as np
import healpy as hp

import ephem
import math

GW_source_name = sys.argv[1]
src_RA = float(sys.argv[2])
src_DEC = float(sys.argv[3])


filename = '/local/data/bat2/batusers/batgroup/BAT_GW/results/' + GW_source_name + '/bayestar.fits.gz'

## read in LIGO prob map
#hpx, header = hp.read_map('../bayestar.fits', h=True, verbose=False) ## I think this is the real file name of the prob map
hpx, header = hp.read_map(filename, h=True, verbose=False)
npix = len(hpx)
nside = hp.npix2nside(npix)

hpx_sort_by_prob = sorted(hpx)
prob_tot = 0.0
flag_10percent = 0
flag_50percent = 0
flag_90percent = 0
for i in range(len(hpx)):
	prob_tot += hpx_sort_by_prob[i]
	if (prob_tot >= 0.1) and (flag_50percent == 0):
                prob_threshold_10percent = hpx_sort_by_prob[i]
                flag_10percent = 1
	if (prob_tot >= 0.5) and (flag_50percent == 0):
		prob_threshold_50percent = hpx_sort_by_prob[i]
		flag_50percent = 1
	if (prob_tot >= 0.9) and (flag_90percent == 0):
                prob_threshold_90percent = hpx_sort_by_prob[i]
		flag_90percent = 1

## find out which pixel contains a the source RA and DEC
theta = 0.5 * np.pi - np.deg2rad(src_DEC)
phi = np.deg2rad(src_RA)
ipix_at_source = hp.ang2pix(nside, theta, phi)
prob_at_source = hpx[ipix_at_source]
print src_RA, src_DEC, ipix_at_source, prob_at_source

print "10%:", prob_threshold_10percent
print "50%:", prob_threshold_50percent
print "90%", prob_threshold_90percent


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

import numpy as np
import healpy as hp

import ephem
import math

filename = sys.argv[1]
BAT_RA = float(sys.argv[2])
BAT_DEC = float(sys.argv[3])
BAT_ROLL = float(sys.argv[4])
output_dir = sys.argv[5]

## telescope ra, dec, and roll
radecroll = (BAT_RA, BAT_DEC, BAT_ROLL)

#### functions from swinfo.py #####################

def batExposure(theta, phi) :
    """ Given theta,phi in radians, returns (open_coded_area_in_cm^2, cosfactor)"""
    if math.sin(theta) < 0 :
        return (0.0,math.cos(theta))
    # BAT dimensions
    detL = 286*4.2e-3 ## Amynote: each det element is has lenghth 4.2e-3 m 
    detW = 173*4.2e-3 ## Amynote: each det element is has lenghth 4.2e-3 m
    maskL = 96*2.54e-2 ## Amynote: each det element is has lenghth 2.54e-2 m
    maskW = 48*2.54e-2 ## Amynote: each det element is has lenghth 2.54e-2 m 
    efl = 1.00 ## Amynote: the distance from mask to the detector plan is 1 m
    # Calculate dx, but reverse it if necessary to put projected detector to left of mask center
    dx = (maskL - detL)/2 - efl * math.tan(theta) * abs(math.cos(phi))
    dy = (maskW - detW)/2 + efl * math.tan(theta) * math.sin(phi)
    # Boundaries of the detector as clipped to rectangle of mask
    x1 = max(0,-dx)
    x2 = min(detL, maskL - dx)
    deltaX = x2 - x1
    y1 = max(0,-dy)
    y2 = min(detW, maskW - dy)
    deltaY = y2 - y1
    # Now adjust for the cut corners, which first attacks the upper left detector corner
    # as described by the (if-necessary-reversed) coord. system
    xint = (y1 + dy) - maskW/2 - (dx + x1)   # line of corner clip extends through (x1 + xint, y1)
    if deltaX < 0 or deltaY < 0 :
        area = 0
    elif xint <= - deltaY :               # no clipping
        area = deltaX * deltaY
    elif xint <= 0 :                    # upper left corner clipped along left edge
        if deltaY <= deltaX - xint :    # clip from left edge, to top edge
            area = deltaX * deltaY - ((deltaY + xint) ** 2)/2
        else :                          # clip from left edge to right edge
            area = deltaX * -xint + (deltaX ** 2)/2
    elif xint <= deltaX :               # clipped at bottom edge
        if xint <= deltaX - deltaY :    # clipped bottom and top
            area = (deltaX - xint) * deltaY - (deltaY ** 2)/2
        else :                          # clipped bottom and right
            area = ((deltaX - xint) ** 2)/2
    else :
        area = 0
    # if you want to see what the corners do: area = max(0,deltaX * deltaY) - area
    # multiply by 1e4 for cm^2, 1/2 for open area
    return (area*1e4/2, math.cos(theta))

class source :
    def __init__(self, initstring) :
        if initstring in ephem.__dict__ :
            self.needs_computing = True
            self.computable = ephem.__dict__[initstring]()
        else :
            self.needs_computing = False
            s = initstring.split("|")
            self.name = s[3].strip().replace(" ", "_")
            self.catnum = int(s[5])
            self.eq = ephem.Equatorial(ephem.degrees(float(s[9]) * ephem.degree),ephem.degrees(float(s[10]) * ephem.degree))
        # All input is in degrees, output is in ephem angles
    @classmethod
    def source(cls, ra, dec, name="anonymous", catnum=-1):
        return cls("|||{}||{}||||{}|{}".format(name, catnum, ra, dec))
    def exposure(self, ra,dec,roll) :
        # returns (projected_area, cos(theta))
        (thetangle,phi) = self.thetangle_phi(ra,dec,roll)
        if thetangle.norm >= ephem.halfpi :
            return 0.0,0.0
        return batExposure(thetangle,phi)
    def distance(self,ra,dec) :
        return ephem.separation((self.eq.ra,self.eq.dec), (ephem.degrees(ra * ephem.degree ),ephem.degrees(dec * ephem.degree)))
    def posang_from(self,ra,dec) :
        """ Position angle East of North from the given location to self """
        # Stolen from idl posang.pro, with self as point 2
        decrad = ephem.degrees(dec * ephem.degree)
        radiff = self.eq.ra - ephem.degrees( ra * ephem.degree)
        ang = ephem.degrees(math.atan2(math.sin(radiff),math.cos(decrad)*math.tan(self.eq.dec)-math.sin(decrad)*math.cos(radiff)))
        return ang
    def thetangle_phi(self, ra,dec,roll) :
        """ Source position in instrument FOV given instrument pointing direction
            returns (thetangle,phi) where thetangle is the angular distance from
            the boresight and phi is the angle from the phi=0 axis of BAT.
            
            theta = tan(thetangle) gives the theta we use, which is the projected distance to a flat plane,
            but it is not useful for thetangle > 90 degrees
        """
        thetangle = self.distance(ra,dec)
        # roll is 'roll right', posang is CCW, phi is CCW from +Y so roll + posang gives phi
        phi = self.posang_from(ra,dec) - ephem.degrees( roll * ephem.degree) - ephem.halfpi
        # print("posang = %f E of N, roll = %f" % (self.posang_from(ra,dec),0+ephem.degrees( roll * ephem.degree)))
        return (thetangle,phi)

    def compute(self, t) :
        if self.needs_computing :
            obs=ephem.Observer()
            obs.elev = -6378137.0     # equatorial radius of WGS84
            obs.date = t
            # print(obs, self.computable)
            self.computable.compute(obs)
            self.name = self.computable.name
            self.catname = 0
            # print(self.computable)
            self.eq = ephem.Equatorial(self.computable)
    def __str__(self) :
        return "|||%s||%d||||%f|%f|" % (self.name, self.catnum, self.eq.ra/ephem.degree, self.eq.dec/ephem.degree)

###################################################

# radecroll = (0.0, 0.0, 0.0)

#radecroll = (332.760, -48.531, 267.96)

## read in LIGO prob map
#hpx, header = hp.read_map('../bayestar.fits', h=True, verbose=False) ## I think this is the real file name of the prob map
hpx, header = hp.read_map(filename, h=True, verbose=False)
npix = len(hpx)
nside = hp.npix2nside(npix)

## write data to normal fits file (doesn't work....)
#hp.fitsfunc.write_map('../lalinference.fits','test_healpy.fits',coord='C',fits_IDL='True')

## find out the highest probability
ipix_max = np.argmax(hpx)
print 'Max_probability_in_Phil_convolved_map:', hpx[ipix_max]

total_pcode = 0
total_pcode_prob = 0
i_healpix = 0
prob_in_BAT_FOV = 0
prob_tot = 0
for ipix in range(0, len(hpx)):
	prob = hpx[ipix]
	prob_tot += prob
	## get ra and dec of a certain pixel
	theta, phi = hp.pix2ang(nside, ipix)
	ra = np.rad2deg(phi)
	dec = np.rad2deg(0.5 * np.pi - theta)	
	src = source.source(ra,dec)
	openarea,costheta = src.exposure(*radecroll)
	effarea = openarea * costheta

	effarea_100percent = 4363.9596
	pcode = effarea/effarea_100percent
	#pcode_array[i,j] = pcode*prob

	## calculate pcode*prob of the total area
	## (can ignore the pcode=0 region since the product is zero anyway)
	if (pcode > 0.0):
		#print prob, pcode
		total_pcode_prob += pcode*prob
		#total_pcode_prob += prob
		#print prob, pcode, pcode*prob, total_pcode_prob

	if (pcode >= 0.1):
                prob_in_BAT_FOV += prob


## writhe pcode to new fits image
#header = w.to_header()
#header['BAT_RA'] = radecroll[0]
#header['BAT_DEC'] = radecroll[1]
#header['BAT_ROLL'] = radecroll[2]

#hdu = fits.PrimaryHDU(header=header)
#hdu.data = pcode_array
#hdu.writeto(output_dir + '/image_pcode.fits', clobber=True)

## find out whether there is any overlap between the input image and BAT FOV
if (total_pcode > 1.0e-3):
	fov_flag = 1
else:
	fov_flag = 0	

print 'input_img_FOV_flag_Phil:', fov_flag
print 'input_img_pcode_prob_Phil:', total_pcode_prob
print 'Phil_prob_in_BAT_FOV:', prob_in_BAT_FOV
print 'test, prob_tot:', prob_tot

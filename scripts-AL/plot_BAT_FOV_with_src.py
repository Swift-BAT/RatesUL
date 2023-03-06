import numpy
import sys
from astropy.io import fits
import matplotlib
matplotlib.use('Agg')
from kapteyn import maputils
from matplotlib.pyplot import show, figure, savefig
from matplotlib import pyplot as plt
from kapteyn import tabarray
from astropy import wcs
import healpy as hp
import numpy as np
import ephem

filename = sys.argv[1]
input_src_RA = float(sys.argv[2])
input_src_DEC = float(sys.argv[3])
output_dir = sys.argv[4]
T0 = sys.argv[5]
Earth_RA = sys.argv[6]
Earth_DEC = sys.argv[7]

Earth_limb_region_x = []
Earth_limb_region_y = []
## make Earth region
for ra in range(0,360):
	for dec in range(-90,90):
		if ('N/A' not in str(Earth_RA)):
			Earth_RA = float(Earth_RA)
			Earth_DEC = float(Earth_DEC)
			## calculate the angular separation between ra, dec and the pointing position
			## (to remove area of earth limb -- in this case, anytyhing within 69 degree of the Earth)
			deg2str = 3.141582654/180.0
			Earth_pos = (Earth_RA*deg2str, Earth_DEC*deg2str)
			dist_from_Earth = float(ephem.separation(Earth_pos, (ra*deg2str, dec*deg2str)))*(180.0/3.141582654)
			if (dist_from_Earth <= 69.0):
				Earth_limb_region_x.append(ra)
				Earth_limb_region_y.append(dec)
		


## plot BAT FOV

bat_img = fits.open(filename)
#w = wcs.WCS(bat_img[0].header)

bat_img = filename

#fig = plt.figure()
#frame = fig.add_subplot(1,1,1)
#annim = f.Annotatedimage(frame)
#grat = annim.Graticule()
#fig = plt.figure()
		
#annim.Marker(x=xp, y=yp, mode='pixels', marker=',', color='b')
#annim.plot()
#plt.show()

#sys.exit(0)

### plot bat_img

#blankcol = "#334455"                  # Represent undefined values by this color
blankcol = "gray"
epsilon = 0.0000000001
figsize = (9,7)                       # Figure size in inches
plotbox = (0.1,0.05,0.8,0.8)
fig = figure(figsize=figsize)
frame = fig.add_axes(plotbox)

# Basefits = maputils.FITSimage("point_20153410145_2.img", hdunr=0)
Basefits = maputils.FITSimage(bat_img, hdunr=0)

# Use some header values to define reprojection parameters
cdelt1 = Basefits.hdr['CDELT1']
cdelt2 = Basefits.hdr['CDELT2']
naxis1 = Basefits.hdr['NAXIS1']
naxis2 = Basefits.hdr['NAXIS2']

# extract obs start/stop header info
#obs_start = Basefits.hdr['DATE-OBS']
#obs_stop  = Basefits.hdr['DATE-END']

# Header works only with a patched wcslib 4.3
# Note that changing CRVAL1 to 180 degerees, shifts the plot 180 deg.
# header = {'NAXIS'  : 2, 'NAXIS1': naxis1, 'NAXIS2': naxis2,
#          'CTYPE1' : 'RA---MOL',
#          'CRVAL1' : 0, 'CRPIX1' : naxis1//2, 'CUNIT1' : 'deg', 'CDELT1' : cdelt1,
#          'CTYPE2' : 'DEC---MOL',
#          'CRVAL2' : 30.0, 'CRPIX2' : naxis2//2, 'CUNIT2' : 'deg', 'CDELT2' : cdelt2,
#          'LONPOLE' :60.0,
#          'PV1_1'  : 0.0, 'PV1_2' : 90.0,  # IMPORTANT. This is a setting from Cal.section 7.1, p 1103
#         }
header = {'NAXIS'  : 2, 'NAXIS1': 100, 'NAXIS2': 80,
'CTYPE1' : 'RA---MOL',
'CRVAL1' : 0.0, 'CRPIX1' : 50, 'CUNIT1' : 'deg', 'CDELT1' : -4.0,
'CTYPE2' : 'DEC--MOL',
'CRVAL2' : 0.0, 'CRPIX2' : 40, 'CUNIT2' : 'deg', 'CDELT2' : 4.0,
      }

Reprojfits = Basefits.reproject_to(header)
annim_rep = Reprojfits.Annotatedimage(frame, cmap="binary")
#annim_rep.set_colormap("gist_gray")               # Set color map before creating Image object
annim_rep.set_colormap("gist_heat")               # Set color map before creating Image object
annim_rep.set_blankcolor(blankcol)               # Background are NaN's (blanks). Set color here
#annim_rep.Image(vmin=30000, vmax=150000)         # Just a selection of two clip levels
annim_rep.Image()
annim_rep.plot()

# Draw the graticule, but do not cover near -90 to prevent ambiguity
X = numpy.arange(0,390.0,15.0);
Y = numpy.arange(-75,90,15.0)
f = maputils.FITSimage(externalheader=header)
annim = f.Annotatedimage(frame)
grat = annim.Graticule(axnum= (1,2), wylim=(-90,90.0), wxlim=(0,360),
	       startx=X, starty=Y)
grat.setp_lineswcs0(0, color='w', lw=2)
grat.setp_lineswcs1(0, color='w', lw=2)

# Draw border with standard graticule, just to make the borders look smooth
header['CRVAL1'] = 0.0
header['CRVAL2'] = 0.0
# del header['PV1_1']
# del header['PV1_2']
header['LONPOLE'] = 0.0
header['LATPOLE'] = 0.0
border = annim.Graticule(header, axnum= (1,2), wylim=(-90,90.0), wxlim=(-180,180),
		 startx=(180-epsilon, -180+epsilon), skipy=True)
border.setp_lineswcs0(color='w', lw=2)   # Show borders in arbitrary color (e.g. background color)
border.setp_lineswcs1(color='w', lw=2)

# Plot the 'inside' graticules
lon_constval = 0.0
lat_constval = 0.0
lon_fmt = 'Hms'; lat_fmt = 'Dms'  # Only Degrees must be plotted
# lon_fmt = 'hh:mm'; lat_fmt = 'dd:mm'
addangle0 = addangle1=0.0
deltapx0 = deltapx1 = 1.0
labkwargs0 = {'color':'w', 'va':'center', 'ha':'center'}
labkwargs1 = {'color':'w', 'va':'center', 'ha':'center'}
lon_world = range(0,360,30)
lat_world = [-60, -30, 30, 60]

ilabs1 = grat.Insidelabels(wcsaxis=0,
	       world=lon_world, constval=lat_constval,
	       deltapx=1.0, deltapy=1.0,
	       addangle=addangle0, fmt=lon_fmt, **labkwargs0)
ilabs2 = grat.Insidelabels(wcsaxis=1,
	       world=lat_world, constval=lon_constval,
	       deltapx=1.0, deltapy=1.0,
     	       addangle=addangle1, fmt=lat_fmt, **labkwargs1)

# Plot a title
titlepos = 1.02
# title = r"""All sky map in Hammer Aitoff projection (AIT) oblique with:
# $(\alpha_p,\delta_p) = (0^\circ,30^\circ)$, $\phi_p = 75^\circ$ also:
# $(\phi_0,\theta_0) = (0^\circ,90^\circ)$."""
title = r"""BAT FOV"""
t = frame.set_title(title, color='g', fontsize=13, linespacing=1.5)
t.set_y(titlepos)


## plot the input source location
annim.Marker(x=input_src_RA, y=input_src_DEC, mode='world', marker='*', color='g', markersize=15)

## plot Earth
annim.Marker(x=Earth_limb_region_x, y=Earth_limb_region_y, mode='world', marker='o', color='yellow', markeredgecolor='yellow', markersize=0.2, alpha=0.5)

annim.plot()
#annim.interact_toolbarinfo()
#annim_rep.interact_imagecolors()
show()
outfile = output_dir + "/bat_fov.png"
savefig(outfile)

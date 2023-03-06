import sys
import math
import pyfits

#######################################################################################
## This code attach the ra and dec of the GRB to the bright source list 
## for recent GRB that is not in the summary file yet
#######################################################################################

theGRB = sys.argv[1]
ra_info = float(sys.argv[2])
dec_info = float(sys.argv[3])
output_dir = sys.argv[4]

## read in original data
source_fits = pyfits.open('bat_bright_src_catalog_sort.fits')

source_fits_data = source_fits[1].data


time = []
name = []
s = []
catnum = []
dspclean = []
src_ty = []
merit = []
ra_obj = []
dec_obj = []
threshold = []
orig_ra = []
orig_dec = []
for i in range(len(source_fits_data)):
		time.append(source_fits_data[i][0])
		name.append(source_fits_data[i][1])
		s.append(source_fits_data[i][2])
		catnum.append(source_fits_data[i][3])
		dspclean.append(source_fits_data[i][4])
		src_ty.append(source_fits_data[i][5])
		merit.append(source_fits_data[i][6])
		ra_obj.append(source_fits_data[i][7])
		dec_obj.append(source_fits_data[i][8])
		threshold.append(source_fits_data[i][9])
		orig_ra.append(source_fits_data[i][10])
		orig_dec.append(source_fits_data[i][11])

	
## add GRBs

GRB_time = 0.0
GRB_name = 'Input_source'
#GRB_name = theGRB
GRB_s = 'NULL'
GRB_catnum = 0.0
GRB_dspclean = [False]
GRB_src_ty = 0
GRB_merit = 0
GRB_ra_obj = ra_info
GRB_dec_obj = dec_info
GRB_threshold = 0.0
GRB_orig_ra = ra_info
GRB_orig_dec = dec_info

time.append(GRB_time)
name.append(GRB_name)
s.append(GRB_s)
catnum.append(GRB_catnum)
dspclean.append(GRB_dspclean)
src_ty.append(GRB_src_ty)
merit.append(GRB_merit)	
ra_obj.append(GRB_ra_obj)
dec_obj.append(GRB_dec_obj)
threshold.append(GRB_threshold)
orig_ra.append(GRB_orig_ra)
orig_dec.append(GRB_orig_dec)


## make new fits file	
col1 = pyfits.Column(name='TIME', format='1D', unit='s',array=time)
col2 = pyfits.Column(name='NAME', format='15A', array=name)
col3 = pyfits.Column(name='SCRIPT', format='1A', array=s)
col4 = pyfits.Column(name='CATNUM', format='1J', unit='        ', null=-1, array=catnum)
col5 = pyfits.Column(name='DSPCLEAN', format='1X', array=dspclean)
col6 = pyfits.Column(name='SRC_TYPE', format='1I', array=src_ty)
col7 = pyfits.Column(name='MERIT', format='1I', array=merit)
col8 = pyfits.Column(name='RA_OBJ', format='1E', unit='deg', array=ra_obj)
col9 = pyfits.Column(name='DEC_OBJ', format='1E', unit='deg', array=dec_obj)
col10 = pyfits.Column(name='THRESHOLD', format='1E', array=threshold)
col11 = pyfits.Column(name='ORIG_RA', format='1D', array=orig_ra)
col12 = pyfits.Column(name='ORIG_DEC', format='1D', array=orig_dec)

cols = pyfits.ColDefs([col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12])
new_source_fits_table = pyfits.new_table(cols)

## header
#new_source_fits_header = source_fits[0].header

new_source_fits_header = pyfits.PrimaryHDU(header=source_fits[0].header)

new_source_fits = pyfits.HDUList([new_source_fits_header,new_source_fits_table])

new_source_fits.writeto(output_dir + '/bat_bright_src_and_' + theGRB + '.fits')

source_fits.close()

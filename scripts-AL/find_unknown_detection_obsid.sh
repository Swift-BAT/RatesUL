#!/bin/tcsh -f

#############################################################################################
## This script
## 1) makes an image for specific time range
## 2) runs batcelldetect on that image
## 3) has options of doing batclean and/or background subtraction using pre-burst image
#############################################################################################

if ("$#" < 10) then
        echo "Inputs: obsid T0_gcn tstart_sinceT0 tstop_sinceT0 ra dec pcodethresh aperture energybin output_dir"
	echo "####################################################"
	echo "obsid: the observational ID of this event data"
	echo "T0_gcn: the trigger time from GCN circular in MET"
	echo "tstart_sinceT0: image start time since T0_gcn"
	echo "tstop_sinceT0: image stop time since T0_gcn"
	echo "pcodethresh: partial coding threshold"
	echo "ra: RA for the source of interests (this is the location that will be added to the input catalog)"
	echo "dec: DEC for the source of interests (this is the location that will be added to the input catalog)"
	echo "aperture: which aperture map to use (FLUX or DETECTION)"
	echo "energybin: energy band of the image (e.g., 15-150)"
	echo "output_dir: directory of the GW results (e.g., /local/data/bat2/batusers/batgroup/BAT_GW/results/S190510g)"
	echo "####################################################"
        exit 0
endif

# set up battools and batcaldb
source $HOME/headas_caldb_setup.csh

set obsid = $argv[1]
set T0 = $argv[2]
set tstart_sincetrig = $argv[3]
set tstop_sincetrig = $argv[4]
set ra_src = $argv[5]
set dec_src = $argv[6]
set pcodethresh = $argv[7]
set aperture = $argv[8]
set energy_band = $argv[9]
set output_dir = $argv[10]

#echo ${obsid} ${T0} ${tstart_sincetrig} ${tstop_sincetrig} ${ra_src} ${dec_src} ${pcodethresh}  ${aperture} ${energy_band} ${output_dir}


set data_folder = ${output_dir}/event_data_analysis/${obsid}-results-detection-mask

set GRB_folder = ${output_dir}/event_data_analysis/${obsid}_image_search

if (! -d ${GRB_folder}) then
        mkdir ${GRB_folder}
endif

set tstart_MET = `echo ${tstart_sincetrig} ${T0} | awk '{printf("%lf\n", $1+$2)}'`
set tstop_MET = `echo ${tstop_sincetrig} ${T0} | awk '{printf("%lf\n", $1+$2)}'`

## make source catalog with the GRB
if (! -e ${GRB_folder}/bat_bright_src_and_input_source.fits) then
	python make_GRB_fits_table_recentGRB.py input_source ${ra_src} ${dec_src} ${GRB_folder}
endif

## set case options
set flag_bgd = 0
set flag_clean = 0
set flag_copy = 0

## set flag; for each case, remove pre-existing summary files and write comments to summary files
while ($#argv > 0)
        switch($1)

        ## case use background
        case --bgd
        set flag_bgd = 1
	set bgd_start_sinceT0 = -
        set bgd_stop_sinceT0 = -
	if ($#argv < 2) then
        	echo "Enter background start and end time (relative to T0) after --bgd"
	        exit 0
	else
		set bgd_start_sinceT0 = $2
		set bgd_stop_sinceT0 = $3
	endif
        shift
        breaksw

	## case use batclean
        case --clean
        set flag_clean = 1
        shift
        breaksw

	## set help
        case --help
        echo "options: --bgd -- clean"
        exit 0
        shift
        breaksw

        default:
        shift
        endsw
end

echo "flag_bgd = ${flag_bgd}"
echo "flag_clean = ${flag_clean}"

## get slew time
#set slew_file = ${data_folder}/gti/sw${obsid}b_acs_slew.gti
#python get_slew_time.py ${slew_file} ${T0}

#### make image for the specific time range
## make the dpi file at the specific time range
batbinevt infile=${data_folder}/events/sw${obsid}b_all.evt outfile=${GRB_folder}/refined_position.dpi outtype=DPI timedel=0 timebinalg=u energybins=$energy_band detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits ecol=ENERGY weighted=NO outunits=COUNTS tstart=${tstart_MET} tstop=${tstop_MET} clobber=yes

## Computing partial coding maps...
batfftimage infile=${GRB_folder}/refined_position.dpi outfile=${GRB_folder}/refined_position.pcodeimg attitude=${data_folder}/auxil/sw${obsid}sat.fits bkgfile='NONE' bat_z=0 origin_z=0 teldef='CALDB' aperture=CALDB:${aperture} pcodethresh=${pcodethresh} corrections=autocollim,flatfield,ndets,pcode,maskwt detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits clobber=yes pcodemap=YES


## determined whether to substract background using preburst image based on flag_bgd
if (${flag_bgd} == 0) then
	batfftimage infile=${GRB_folder}/refined_position.dpi outfile=${GRB_folder}/refined_position_bgd${flag_bgd}.img attitude=${data_folder}/auxil/sw${obsid}sat.fits bkgfile='NONE' bat_z=0 origin_z=0 teldef='CALDB' aperture=CALDB:${aperture} pcodethresh=${pcodethresh} corrections=autocollim,flatfield,ndets,pcode,maskwt detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits clobber=yes pcodemap=NO
else if (${flag_bgd} == 1) then
	## make the background dpi file at the specific time range
	set tstart_MET_bgd = `echo ${bgd_start_sinceT0} ${T0} | awk '{printf("%lf\n", $1+$2)}'`
	set tstop_MET_bgd = `echo ${bgd_stop_sinceT0} ${T0} | awk '{printf("%lf\n", $1+$2)}'`
	
	batbinevt infile=${data_folder}/events/sw${obsid}b_all.evt outfile=${GRB_folder}/background.dpi outtype=DPI timedel=0 timebinalg=u energybins=$energy_band detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits ecol=ENERGY weighted=NO outunits=COUNTS tstart=${tstart_MET_bgd} tstop=${tstop_MET_bgd} clobber=yes
        batfftimage infile=${GRB_folder}/refined_position.dpi outfile=${GRB_folder}/refined_position_bgd${flag_bgd}.img attitude=${data_folder}/auxil/sw${obsid}sat.fits bkgfile=${GRB_folder}/background.dpi bat_z=0 origin_z=0 teldef='CALDB' aperture=CALDB:${aperture} pcodethresh=${pcodethresh} corrections=autocollim,flatfield,ndets,pcode,maskwt detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits clobber=yes pcodemap=NO
else
    echo "flag_bgd=${flag_bgd} is neither 0 nor 1, this should never happen..."
endif

batcelldetect infile=${GRB_folder}/refined_position_bgd${flag_bgd}.img outfile=${GRB_folder}/sw${obsid}b_output.cat snrthresh=4.0 incatalog=${GRB_folder}/bat_bright_src_and_input_source.fits clobber=yes sortcolumns=-KNOWN,RA_OBJ srcfit=YES posfit=NO pcodethresh=${pcodethresh} pcodefile=${GRB_folder}/refined_position.pcodeimg


## If cleaning is not required, end the process;
## if cleaning is required, run batcelldetect again only for known source to make bright source list
## and do the cleaning
if (${flag_clean} == 0) then
	exit 0
	## fine refined position
	#python find_refined_position_with_bright_src_list.py ${obsid} ${ra_src} ${dec_src} ${GRB_folder}
else if (${flag_clean} == 1) then
	
	echo "##################################################################################################"
	echo "## do batclean"
	echo "##################################################################################################"	

	if (-e ${GRB_folder}/sw${obsid}b_output.cat.noGRB) then
		/bin/rm ${GRB_folder}/sw${obsid}b_output.cat.noGRB
	endif

	## rewrite the batcelldetect list so the GRB won't be cleaned
	python make_new_bright_source_list.py ${obsid} input_source ${GRB_folder}/sw${obsid}b_output.cat

	echo 'incat' ${GRB_folder}/sw${obsid}b_output.cat.noGRB

	batclean infile=${GRB_folder}/refined_position.dpi outfile=${GRB_folder}/refined_position_clean.dpi incatalog=${GRB_folder}/sw${obsid}b_output.cat.noGRB srcclean='YES' clobber='YES' detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits cleansnr=5.0

	## determined whether to substract background using preburst image based on flag_bgd
	if (${flag_bgd} == 0) then
        	batfftimage infile=${GRB_folder}/refined_position_clean.dpi outfile=${GRB_folder}/refined_position_bgd${flag_bgd}_clean.img attitude=${data_folder}/auxil/sw${obsid}sat.fits bkgfile='NONE' bat_z=0 origin_z=0 teldef='CALDB' aperture=CALDB:${aperture} pcodethresh=${pcodethresh} corrections=autocollim,flatfield,ndets,pcode,maskwt detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits clobber=yes pcodemap=NO
	else if (${flag_bgd} == 1) then
		echo "batfftimage infile=${GRB_folder}/refined_position_clean.dpi outfile=${GRB_folder}/refined_position_bgd${flag_bgd}_clean.img attitude=${data_folder}/auxil/sw${obsid}sat.fits bkgfile=${GRB_folder}/background.dpi bat_z=0 origin_z=0 teldef='CALDB' aperture=CALDB:${aperture} pcodethresh=${pcodethresh} corrections=autocollim,flatfield,ndets,pcode,maskwt detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits clobber=yes pcodemap=NO"
        	batfftimage infile=${GRB_folder}/refined_position_clean.dpi outfile=${GRB_folder}/refined_position_bgd${flag_bgd}_clean.img attitude=${data_folder}/auxil/sw${obsid}sat.fits bkgfile=${GRB_folder}/background.dpi bat_z=0 origin_z=0 teldef='CALDB' aperture=CALDB:${aperture} pcodethresh=${pcodethresh} corrections=autocollim,flatfield,ndets,pcode,maskwt detmask=${data_folder}/auxil/sw${obsid}b_qmap.fits clobber=yes pcodemap=NO
	else
    		echo "flag_bgd=${flag_bgd} is neither 0 nor 1, this should never happen..."
	endif

	## run batcelldetect
	batcelldetect infile=${GRB_folder}/refined_position_bgd${flag_bgd}_clean.img outfile=${GRB_folder}/sw${obsid}b_output_clean.cat snrthresh=4.0 incatalog=${GRB_folder}/bat_bright_src_and_input_source.fits clobber=yes sortcolumns=-KNOWN,RA_OBJ srcfit=YES posfit=NO  pcodethresh=${pcodethresh} pcodefile=${GRB_folder}/refined_position.pcodeimg

else
	echo "flag_bgd=${flag_clean} is neither 0 nor 1, this should never happen..."
endif

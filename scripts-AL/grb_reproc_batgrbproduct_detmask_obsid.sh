#!/bin/tcsh -f

set obsid = $argv[1]
set trigtime = $argv[2]
set ra = $argv[3] 
set dec = $argv[4]
set output_dir = $argv[5]

set burst_dir = ${output_dir}/event_data_analysis
set datadir = ${burst_dir}/${obsid}
set resultdir = ${burst_dir}/${obsid}-results-detection-mask

echo "Running event analysis for ${obsid} ..."

if(-d ${burst_dir}) then
        echo ${burst_dir} already exist
else
        echo create folder ${burst_dir}
        mkdir ${burst_dir}
endif

if (-d ${resultdir}) then
        echo The folder ${resultdir} already exist
else 
        echo create folder ${resultdir}
        mkdir ${resultdir}
endif

# set up battools and batcaldb
source $HOME/headas_caldb_setup.csh

## set up specific pfile location for this run
mkdir -p ${burst_dir}/pfiles
setenv PFILES "${burst_dir}/pfiles;$HEADAS/syspfiles"

##make data from pass data (need to run /local/data/bat1/alien/useful_code/cp_failed_event_data_attitude_file_current_year.sh first)
./do_batburst2sdc_obsid.sh ${obsid} ${output_dir} ${burst_dir} ${datadir}

## cp quad-rate data
if (! -d ${datadir}/bat/rate) then
        mkdir ${datadir}/bat/rate
endif
/bin/cp ${output_dir}/quad_rate_sort.lc ${datadir}/bat/rate/sw${obsid}brtqd.lc

## fake a tdrss message (needed for batgrbproduct)
./make_fake_tdrss_message.sh ${obsid} ${trigtime} ${ra} ${dec} ${burst_dir}

cd ${burst_dir}

## unzip event file so that bateconvert can rewrite it
set list = temp_evt_gz_list.txt
ls -1 ${datadir}/bat/event/sw${obsid}*.evt* >! ${list}
set tot = `wc $list | awk '{print $1}'`
@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
while ($i_list <= $tot)
        set evt_file = `awk '{if (NR == '$i_list') print $1}' $list`
	set last_two_word = `echo ${evt_file} | awk '{print substr($1, length($1)-1, length($1))}'`
	if ('gz' == ${last_two_word}) then
		gzip -d ${evt_file}
		set evt_file = `echo ${evt_file} | awk '{print substr($1, 1, length($1)-3)}'`
	endif
	bateconvert ${evt_file} calfile=${datadir}/bat/hk/sw${obsid}bgocb.hk.gz residfile=CALDB pulserfile=CALDB fltpulserfile=CALDB

@ i_list++
end ## end i_list

/bin/rm ${list}

## run batgrbproduct
batgrbproduct ${datadir} ${resultdir} pcodethresh=0.01 imgpcodethresh=0.01 extractor=fextract-events aperture=CALDB:DETECTION

## remove pfile folder
/bin/rm -r ${burst_dir}/pfiles


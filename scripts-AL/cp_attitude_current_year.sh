#!/bin/tcsh -f

## This code simply copy the Hans' attitude files
## in order to make it easier to tar and scp to batevent1
## Note: this code will have problem if burst happen on Jan 1 or Dec 31 
## because it search through T-1 day to T+1 day.

set obsid = $argv[1]
set year = $argv[2]
set day_of_year = $argv[3]
set output_dir = $argv[4]
set script_dir = ./

set burst_folder = ${output_dir}/pass_data/pass_combine/fits

if (! -d ${burst_folder}) then
	mkdir ${burst_folder}
endif

set day_of_year_minus_num = `echo ${day_of_year} | awk '{print $1-1}'`
set day_of_year_plus_num = `echo ${day_of_year} | awk '{print $1+1}'`
set day_of_year_minus = `python ${script_dir}/name_format.py ${day_of_year_minus_num} | awk '{print $1}'`
set day_of_year_plus = `python ${script_dir}/name_format.py ${day_of_year_plus_num} | awk '{print $1}'`

set attitude_folder = /local/data/bat2/transient_monitor/attitude
if (! -e ${attitude_folder}/attitude_${year}_${day_of_year_plus}.att) then
	ftmerge ${attitude_folder}/attitude_${year}_${day_of_year_minus}.att,${attitude_folder}/attitude_${year}_${day_of_year}.att ${burst_folder}/att_merge_tmp.att clobber=yes
	#ftmerge ${attitude_folder}/attitude_${year}_${day_of_year}.att ${burst_folder}/att_merge_tmp.att clobber=yes
	ftsort ${burst_folder}/att_merge_tmp.att ${burst_folder}/sw${obsid}sat.fits TIME unique=yes clobber=yes
	ftappend ${burst_folder}/sw${obsid}sat.fits"[col #EXTNAME='ACS_DATA']" ${burst_folder}/sw${obsid}sat.fits
	/bin/rm ${burst_folder}/att_merge_tmp.att
endif
if (-e ${attitude_folder}/attitude_${year}_${day_of_year_plus}.att) then
	ftmerge ${attitude_folder}/attitude_${year}_${day_of_year_minus}.att,${attitude_folder}/attitude_${year}_${day_of_year}.att,${attitude_folder}/attitude_${year}_${day_of_year_plus}.att ${burst_folder}/att_merge_tmp.att clobber=yes
	#ftmerge ${attitude_folder}/attitude_${year}_${day_of_year}.att ${burst_folder}/att_merge_tmp.att clobber=yes
	ftsort ${burst_folder}/att_merge_tmp.att ${burst_folder}/sw${obsid}sat.fits TIME unique=yes clobber=yes
	ftappend ${burst_folder}/sw${obsid}sat.fits"[col #EXTNAME='ACS_DATA']" ${burst_folder}/sw${obsid}sat.fits
	/bin/rm ${burst_folder}/att_merge_tmp.att	
endif


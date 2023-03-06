#!/bin/tcsh -f

set info_file = $argv[1]

echo "Checking raw light curve..."

set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
set T0_year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set T0_doy = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set search_time_window = `cat ${info_file} | grep "search_time_window:" | awk '{print $2}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`

## check Taka's ground-trigger output
## (use Carlo's Spiffy trigger and print out everything above 4.0 sigma)
set grd_trigger_folder = /local/data/bat1/bat_grd_trigger/data/

### list all the pass within T0 +/- search_time_window
set temp_passlist = ${output_dir}/temp_passlist.txt
ls -1d ${grd_trigger_folder}/pass_${T0_year}${T0_doy}* >! ${temp_passlist}

set output_file = ${output_dir}/raw_lc_detection.txt

echo "## fg_start fg_dur bg1_start bg1_dur bg2_start bg2_dur snr" >! ${output_file}

set tot = `wc $temp_passlist | awk '{print $1}'`
@ i_list = 2  ## starting from 2 to skip to comment line in list.dat
while ($i_list <= $tot)
        set passname = `awk '{if (NR == '$i_list') print $1}' $temp_passlist`
	set lc_quad_summary = ${passname}/quad_rate/spiffy_trigger_summary.txt
	set lc_64ms_summary = ${passname}/64ms_rate/spiffy_trigger_summary.txt

	python check_Taka_raw_lightcurve_results.py ${T0} ${search_time_window} ${lc_quad_summary} >> ${output_file}

	python check_Taka_raw_lightcurve_results.py ${T0} ${search_time_window} ${lc_64ms_summary} >> ${output_file}

@ i_list++
end ## end i_list

/bin/rm ${temp_passlist}

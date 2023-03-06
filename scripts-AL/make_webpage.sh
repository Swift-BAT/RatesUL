#!/bin/tcsh -f

set info_file = $argv[1]

set pass_data_flag = `cat ${info_file} | grep "pass_data_flag:" | awk '{print $2}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`
set Year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set Month = `cat ${info_file} | grep "Month:" | awk '{print $2}'`
set Day = `cat ${info_file} | grep "Day:" | awk '{print $2}'`
set source_name = `cat ${info_file} | grep "source_name:" | awk '{print $2}'`

#set public_webpage = /batfsw/burst/BAT_transient_search/
set public_webpage = /batfsw/burst/team_web/${source_name}
set web_dir = ${output_dir}/web/

if (! -d ${web_dir}) then
	mkdir ${web_dir}
endif

if (! -d ${public_webpage}) then
        mkdir ${public_webpage}
endif

#set webpage = ${output_dir}/web/source_${Year}${Month}${Day}.html
set webpage = ${output_dir}/web/source.html

echo "<\!DOCTYPE html>" >! ${webpage}
echo "<html>" >> ${webpage}
echo "<title>Transient Analysis Summary</title>" >> ${webpage}
echo "<body>" >> ${webpage}
echo "<body bgcolor=white>" >> ${webpage}

echo "<h2>Transient Analysis Summary</h2>" >> ${webpage}

## basic info
echo "<h3>Summary of the Input Information</h3>" >> ${webpage}

set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
set search_time_window = `cat ${info_file} | grep "search_time_window:" | awk '{print $2}'`
set time_UTC = `cat ${info_file} | grep "time_UTC:" | awk '{print $2}'`
set src_RA = `cat ${info_file} | grep "src_RA:" | awk '{print $2}'`
set src_DEC = `cat ${info_file} | grep "src_DEC:" | awk '{print $2}'`
set source_select_flag = `cat ${info_file} | grep "source_select_flag:" | awk '{print $2}'`

echo "<ul>" >> ${webpage}
echo "<li>T0: ${T0} [MET] (${time_UTC} UTC)" >> ${webpage}
echo "<li>Search time window: T0 +/- ${search_time_window} s" >> ${webpage}
if (${source_select_flag} == 0) then
	echo "<li>Input source: RA=${src_RA}, DEC=${src_DEC} (source location is randomly seleected, since the true location is unknown.)" >> ${webpage}
else
	echo "<li>Input source: RA=${src_RA}, DEC=${src_DEC}" >> ${webpage}
endif

set input_img = `cat ${info_file} | grep "input_img:" | awk '{print $2}'`
if (${%input_img} != 0) then
	echo "<li>Input image: ${input_img}" >> ${webpage}
endif

echo "</ul>" >> ${webpage}

## fov check
echo "<h3>FOV Check</h3>" >> ${webpage}

set input_src_FOV_flag = `cat ${info_file} | grep "input_src_FOV_flag:" | awk '{print $2}'`
#set input_img_FOV_flag = `cat ${info_file} | grep "input_img_FOV_flag:" | awk '{print $2}'`
set input_src_pcode = `cat ${info_file} | grep "input_src_pcode:" | awk '{print $2}'`
set max_prob_LIGO_map = `cat ${info_file} | grep "Max_probability_in_LIGO_map:" | awk '{print $2}'`
set input_img_pcode_prob = `cat ${info_file} | grep "input_img_pcode_prob:" | awk '{print $2}'`
set healpy_flag = `cat ${info_file} | grep "healpy_flag:" | awk '{print $2}'`
set LIGO_prob_in_BAT_FOV = `cat ${info_file} | grep "LIGO_prob_in_BAT_FOV:" | awk '{print $2}'`
set Phil_prob_in_BAT_FOV = `cat ${info_file} | grep "Phil_prob_in_BAT_FOV:" | awk '{print $2}'`
set input_img_phil = `cat ${info_file} | grep "input_img_Phil:" | awk '{print $2}'`
set prob_out_BAT_FOV_not_in_Earth_limb = `cat ${info_file} | grep "prob_out_BAT_FOV_not_in_Earth_limb:" | awk '{print $2}'`

echo "<ul>" >> ${webpage}
## if cannot get BAT pointings in attitude file (i.e., no pass data yet)
## make a notice that current FOV is from GCN notice
set flag_att = `cat ${info_file} | grep "flag_att:" | awk '{print $2}'`

if (${flag_att} == 0) then
	set time_diff = `cat ${info_file} | grep "BAT_pointing_from_GCN:time_diff:" | awk '{print $2}'`
	echo "<li> Special note: attitude file is not available yet, current BAT pointing position is from GCN notice with time difference from T0 = ${time_diff}" >> ${webpage}
endif

if (${input_src_FOV_flag} == 1) then
	echo "<li> The input source is in the BAT FOV with partial coding = ${input_src_pcode}" >> ${webpage}
else
	echo "<li> The input source is out of the BAT FOV" >> ${webpage}
endif
#if (${input_img_FOV_flag} == 1) then
#        echo "<li> The input image overlaps with the BAT FOV." >> ${webpage}
#else
#        echo "<li> The input image does not overlaps with the BAT FOV" >> ${webpage}
endif
if (${healpy_flag} == 0) then
	echo "<li> Max probability in LIGO map: ${max_prob_LIGO_map}" >> ${webpage}
	echo "<li> Sum of (BAT pcode)*(LIGO probability) of the entire LIGO map: ${input_img_pcode_prob}" >> ${webpage}
	echo "<li> The integrated LIGO localization probability that are in BAT FOV (with pcode > 10%): ${LIGO_prob_in_BAT_FOV}" >> ${webpage}
	if ($input_img_phil != NONE) then
		echo "<li> The integrated probability of Phil's convolved map that are in BAT FOV (with pcode > 10%): ${Phil_prob_in_BAT_FOV}" >> ${webpage}
	endif
	echo "<li> The integrated LIGO localization probability that are outside of the BAT FOV (with pcode > 10%) but above the Earth's limb: ${prob_out_BAT_FOV_not_in_Earth_limb}" >> ${webpage}
endif

echo "</ul>" >> ${webpage}

## fov plot
set FOV_plot = `cat ${info_file} | grep "FOV_plot:" | awk '{print $2}'`
echo "<img src=${FOV_plot}>" >> ${webpage}
echo "<li>RED: BAT FOV (the brighter/whiter color refers to higher partial coding fraction)." >> ${webpage}
echo "<li>YELLOW: Earth" >> ${webpage}
if (${healpy_flag} == 0) then
	echo "<li>BLUE: LIGO probability map" >> ${webpage}
endif
echo "<li>GREEN STAR: Input source (location is randomly seleected unless the true source location is available.)" >> ${webpage}

echo "<p>" >> ${webpage}

## GCN
./make_GCN.sh ${info_file}
/bin/cp ${output_dir}/GCN_circ.txt ${web_dir}
echo "<li><a href=./GCN_circ.txt> Click here for the BAT GCN circular template </a>" >> ${webpage}

## copy BAT FOV image
/bin/cp ${output_dir}/*.png ${web_dir}

## raw light curve
if (${pass_data_flag} == 0) then
	echo "<p> No pass data yet </p>" >> ${webpage}
else
	echo "<h3>Raw Light Curves</h3>" >> ${webpage}

	/bin/cp ${output_dir}/lc*.html ${web_dir}

	echo "<h4> Quad-rate light curves (with 1.6 s time bin)</h4>" >> ${webpage}
	## check whether the rate data exist
	set flag_quad_rate = `cat ${info_file} | grep "flag_quad_rate:" | awk '{print $2}'`
	if (${flag_quad_rate} == 1) then
		echo "<!---#include virtual="lc_quad.html" -->" >> ${webpage}
#		echo "<img src=quad_rate_lc.png>" >> ${webpage}	
		echo "<pre>" >> ${webpage}
		cat ${output_dir}/detection_quadrate.txt  >> ${webpage}
		echo "</pre>" >> ${webpage}
	else
		echo "Quad rate data do not exist yet." >> ${webpage}
	endif

	echo "<h4> 64-ms light curves</h4>" >> ${webpage}
	## check whether the rate data exist
	set flag_ms_rate = `cat ${info_file} | grep "flag_ms_rate:" | awk '{print $2}'`
        if (${flag_ms_rate} == 1) then
		echo "<!---#include virtual="lc_64ms.html" -->" >> ${webpage}
#		echo "<img src=64ms_rate_lc.png>" >> ${webpage}
		echo "<pre>" >> ${webpage}
		cat ${output_dir}/detection_64ms.txt  >> ${webpage}
		echo "</pre>" >> ${webpage}
	else
                echo "64ms rate data do not exist yet." >> ${webpage}
        endif

	echo "<h4> 1-s light curves</h4>" >> ${webpage}
	## check whether the rate data exist
	set flag_1s_rate = `cat ${info_file} | grep "flag_1s_rate:" | awk '{print $2}'`
        if (${flag_1s_rate} == 1) then
		echo "<!---#include virtual="lc_1s.html" -->" >> ${webpage}
#		echo "<img src=1s_rate_lc.png>" >> ${webpage}
		echo "<pre>" >> ${webpage}
		cat ${output_dir}/detection_1s.txt  >> ${webpage}
		echo "</pre>" >> ${webpage}
	else
                echo "1s rate data do not exist yet." >> ${webpage}
        endif

	## event image search

	echo "<h3>Event data image search</h3>" >> ${webpage}
	echo "<pre>" >> ${webpage}
	ls -1d ${output_dir}/event_data_analysis/*_image_search  >! evt_list.txt
	set list = evt_list.txt
	set tot = `wc $list | awk '{print $1}'`

	if ($tot > 0) then
		echo "Event data found. The analysis results are listing below." >> ${webpage}
	else
		echo "No event data found." >> ${webpage}
	endif

	echo "<br> " >> ${webpage}

	@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
	while ($i_list <= $tot)
		set folder_name = `awk '{if (NR == '$i_list') print $1}' $list`
		#set obsid = `echo ${folder_name} | | awk -F'/' '{print substr($NF,1,11)}'`
		#set evt_file = ${output_dir}/event_data_analysis/${obsid}-results-detection-mask/events/${obsid}_all.evt
		#set evt_start = `ftlist ${evt_file}+2 colheader=no rownum=no T | awk '{print $1-'$T0'}'`
		#set evt_stop = `ftlist ${evt_file}+2 colheader=no rownum=no T | awk '{print $2-'$T0'}'` 	

		#echo "### results from obsid: ${obsid}:" >> ${webpage}
		#echo "event data time: ${evt_start} to ${evt_stop} since T0"
		
		cat ${folder_name}/detect_source_list.txt >> ${webpage}
		
		echo ""
		
	@ i_list++
	end ## end i_list
	echo "</pre>" >> ${webpage}

	/bin/rm evt_list.txt
endif

echo "Last update:" >> ${webpage}
date >> ${webpage}

## copy webpage to the public site 
/bin/cp -r ${web_dir} ${public_webpage}

## add the source to the index page
## (only add it the first time, i.e., the first run from run_trigger_BAT_transient_search_cron.sh)
if (! -e ${output_dir}/processed_pass.txt) then
	./add_source_web_to_index_page.sh ${info_file}
endif


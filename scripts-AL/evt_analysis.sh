#!/bin/tcsh -f

## event data analysis from pass data

set info_file = $argv[1]

set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
set src_RA = `cat ${info_file} | grep "src_RA:" | awk '{printf("%lf\n", $2)}'`
set src_DEC = `cat ${info_file} | grep "src_DEC:" | awk '{printf("%lf\n", $2)}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`
set search_time_window = `cat ${info_file} | grep "search_time_window:" | awk '{print $2}'`

set list = ${output_dir}/temp_obsid_list.txt

## 1. collect obsid from the event data that are within the search time window
python get_evt_obsid.py ${info_file} >! ${list}

set tot = `wc $list | awk '{print $1}'`
@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
while ($i_list <= $tot)
        set obsid = `awk '{if (NR == '$i_list') print $1}' $list`

	## cp event data (and other relevant) from pass data
	./cp_failed_event_data_attitude_file_current_year.sh ${info_file} ${obsid}

	## check if the attitude file covers the search time window around T0
        python check_attitude_file_time.py ${obsid} ${T0} ${search_time_window} ${output_dir}
        set flag_att_check = `grep "flag_att_check" att_check_temp.txt | awk '{print $2}'`
        /bin/rm att_check_temp.txt

        if (${flag_att_check} == 1) then
                echo "${obsid}: Attitude file doesn't cover the event time, skip this one."
	else
		## event data analysis (using the src RA and DEC for now, because this step is just to create an image and search for unknown sources, I just use the batgrbproduct to make things simpler).
		#./grb_reproc_batgrbproduct_obsid.sh ${obsid} ${T0} ${src_RA} ${src_DEC} ${output_dir}
		./grb_reproc_batgrbproduct_detmask_obsid.sh ${obsid} ${T0} ${src_RA} ${src_DEC} ${output_dir} ## use detection mask, since we do not want to miss a detection, even if it is at the edge of the FOV (we will figure out the detection authentication manually).

		set flag_rate_trigger = `cat ${output_dir}/raw_lc_detection.txt | wc | awk '{print $1}'`

		if (! -d ${output_dir}/event_data_analysis/${obsid}_image_search) then
			mkdir ${output_dir}/event_data_analysis/${obsid}_image_search
		endif

		set det_list = ${output_dir}/event_data_analysis/${obsid}_image_search/detect_source_list.txt
		echo "## list of detected sources for ${obsid}" >! ${det_list}
		echo " " >> ${det_list}

		## make image to find new unknown source
		if (${flag_rate_trigger} == 0) then
			echo "########################################" >> ${det_list}
	
			set tstart_since_trig = `python find_highest_rate_snr.py ${info_file} | awk '{print $3-'$T0'}'`
                        set tstop_since_trig = `python find_highest_rate_snr.py ${info_file} | awk '{print $4-'$T0'}'`
                        set pcodethresh = 0.01
                        set aperture = DETECTION
                        set energy_band = 15-350
                        echo "## tstart_since_T0: ${tstart_since_trig}" >> ${det_list}
                        echo "## tstop_since_T0: ${tstop_since_trig}" >> ${det_list}
                        ./find_unknown_detection_obsid.sh ${obsid} ${T0} ${tstart_since_trig} ${tstop_since_trig} ${src_RA} ${src_DEC} ${pcodethresh} ${aperture} ${energy_band} ${output_dir}

                        ## print the output catalog file                
                        ftlist ${output_dir}/event_data_analysis/${obsid}_image_search/sw${obsid}b_output.cat'[1][col TIME; NAME; RA_OBJ; DEC_OBJ; THETA; PHI; SNR]' T >> ${det_list}

		else
			echo "No rate trigger found."
		endif

		echo "########################################" >> ${det_list}
		echo " " >> ${det_list}
		echo "########################################" >> ${det_list}

		## (1) T0-0.1 to T0+0.1 s
                set evt_start_since_trig = `ftlist ${output_dir}/event_data_analysis/${obsid}-results-detection-mask/events/sw${obsid}b_all.evt+2 colheader=no rownum=no T | head -1 | awk '{print $1-'$T0'}'`
                set evt_stop_since_trig = `ftlist ${output_dir}/event_data_analysis/${obsid}-results-detection-mask/events/sw${obsid}b_all.evt+2 colheader=no rownum=no T | tail -1 | awk '{print $2-'$T0'}'`
                set tstart_since_trig = -0.1
                set tstop_since_trig = 0.1
                set pcodethresh = 0.01
                set aperture = DETECTION
                set energy_band = 15-350
                echo "## tstart_since_T0: ${tstart_since_trig}" >> ${det_list}
                echo "## tstop_since_T0: ${tstop_since_trig}" >> ${det_list}

                set flag_start = `echo ${evt_start_since_trig} | awk '{if ($1 >= '$tstart_since_trig' && $1 <= '${tstop_since_trig}') print 1; else print 0}'`
                set flag_stop = `echo ${evt_stop_since_trig} | awk '{if ($1 >= '$tstart_since_trig' && $1 <= '$tstop_since_trig') print 1; else print 0}'`
                set flag_include = `echo ${evt_start_since_trig} ${evt_stop_since_trig} | awk '{if ($1 < 0.0 && $2 > 0.0) print 1; else print 0}'`

                ## this flag is here because I can't make the "or" in the shell script if statement works....
                set flag_tot = `echo ${flag_start} ${flag_stop} ${flag_include} | awk '{if ($1 == 1 || $2 == 1 || $3 == 1) print 1; else print 0}'`


                if (${flag_tot} == 1) then
                         ./find_unknown_detection_obsid.sh ${obsid} ${T0} ${tstart_since_trig} ${tstop_since_trig} ${src_RA} ${src_DEC} ${pcodethresh} ${aperture} ${energy_band} ${output_dir}
                        ## print the output catalog file                
                        ftlist ${output_dir}/event_data_analysis/${obsid}_image_search/sw${obsid}b_output.cat'[1][col TIME; NAME; RA_OBJ; DEC_OBJ; THETA; PHI; SNR]' T >> ${det_list}
                else
                        echo "event data don't cover the request time" >> ${det_list}
                endif

		## (1) T0-2 to T0+8 s
		set evt_start_since_trig = `ftlist ${output_dir}/event_data_analysis/${obsid}-results-detection-mask/events/sw${obsid}b_all.evt+2 colheader=no rownum=no T | head -1 | awk '{print $1-'$T0'}'`
		set evt_stop_since_trig = `ftlist ${output_dir}/event_data_analysis/${obsid}-results-detection-mask/events/sw${obsid}b_all.evt+2 colheader=no rownum=no T | tail -1 | awk '{print $2-'$T0'}'`
		set tstart_since_trig = -2.0
		set tstop_since_trig = 8.0
		set pcodethresh = 0.01
		set aperture = DETECTION
		set energy_band = 15-350
		echo "## tstart_since_T0: ${tstart_since_trig}" >> ${det_list}
		echo "## tstop_since_T0: ${tstop_since_trig}" >> ${det_list}

		set flag_start = `echo ${evt_start_since_trig} | awk '{if ($1 >= '$tstart_since_trig' && $1 <= '${tstop_since_trig}') print 1; else print 0}'`
		set flag_stop = `echo ${evt_stop_since_trig} | awk '{if ($1 >= '$tstart_since_trig' && $1 <= '$tstop_since_trig') print 1; else print 0}'`
		set flag_include = `echo ${evt_start_since_trig} ${evt_stop_since_trig} | awk '{if ($1 < 0.0 && $2 > 0.0) print 1; else print 0}'`

		## this flag is here because I can't make the "or" in the shell script if statement works....
		set flag_tot = `echo ${flag_start} ${flag_stop} ${flag_include} | awk '{if ($1 == 1 || $2 == 1 || $3 == 1) print 1; else print 0}'`


		if (${flag_tot} == 1) then
			 ./find_unknown_detection_obsid.sh ${obsid} ${T0} ${tstart_since_trig} ${tstop_since_trig} ${src_RA} ${src_DEC} ${pcodethresh} ${aperture} ${energy_band} ${output_dir}
			## print the output catalog file                
			ftlist ${output_dir}/event_data_analysis/${obsid}_image_search/sw${obsid}b_output.cat'[1][col TIME; NAME; RA_OBJ; DEC_OBJ; THETA; PHI; SNR]' T >> ${det_list}	
		else
			echo "event data don't cover the request time" >> ${det_list}
		endif

		echo "########################################" >> ${det_list}
		echo " " >> ${det_list}
                echo "########################################" >> ${det_list}

		## (2) the whole event data range
		set tstart_since_trig = ${evt_start_since_trig}
		set tstop_since_trig = ${evt_stop_since_trig}
		set pcodethresh = 0.01
		set aperture = DETECTION
		set energy_band = 15-350
		echo "## tstart_since_T0: ${tstart_since_trig}" >> ${det_list}
		echo "## tstop_since_T0: ${tstop_since_trig}" >> ${det_list}

		./find_unknown_detection_obsid.sh ${obsid} ${T0} ${tstart_since_trig} ${tstop_since_trig} ${src_RA} ${src_DEC} ${pcodethresh} ${aperture} ${energy_band} ${output_dir}

		## print the output catalog file                
		ftlist ${output_dir}/event_data_analysis/${obsid}_image_search/sw${obsid}b_output.cat'[1][col TIME; NAME; RA_OBJ; DEC_OBJ; THETA; PHI; SNR]' T >> ${det_list}

		echo "########################################" >> ${det_list}

		### make a sky plot of event image detections
		./make_FOV_plot_with_evt_src.sh ${info_file} ${obsid}

	endif

@ i_list++
end ## end i_list

/bin/rm ${list}
 

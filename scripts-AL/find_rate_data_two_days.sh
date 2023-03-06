#!/bin/tcsh -f

## This code find event data around the search time window of T0

set info_file = $argv[1]

set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
set year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set day_of_year = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
#set search_time_window = `cat ${info_file} | grep "search_time_window:" | awk '{print $2}'`
set search_time_window = 900.0
set burst_folder = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`
set pass_data_dir = `cat ${info_file} | grep "pass_data_dir:" | awk '{print $2}'`
set script_dir = ./

## search T0 day
./find_rate_data_current_year.sh ${T0} ${year} ${day_of_year} ${search_time_window} ${burst_folder} ${pass_data_dir}

set day_of_year_next_num = `echo ${day_of_year} | awk '{print $1+1}'`
set day_of_year_next = `python ${script_dir}/name_format.py ${day_of_year_next_num} | awk '{print $1}'`

## search the next day of T0 (because sometime there are delay in data downlink)
./find_rate_data_current_year.sh ${T0} ${year} ${day_of_year_next} ${search_time_window} ${burst_folder} ${pass_data_dir}

## merge the light curve from two days

## quad
ls -1 ${burst_folder}/quad_rate_sort*.lc >! temp_merge_rate.txt

ftmerge @temp_merge_rate.txt ${burst_folder}/quad_rate_unsort.lc clobber=yes
ftsort ${burst_folder}/quad_rate_unsort.lc ${burst_folder}/quad_rate_sort.lc TIME unique=yes clobber=yes

/bin/rm ${burst_folder}/quad_rate_unsort.lc
/bin/rm temp_merge_rate.txt

## 1s
ls -1 ${burst_folder}/1s_rate_sort*.lc >! temp_merge_rate.txt

ftmerge @temp_merge_rate.txt ${burst_folder}/1s_rate_unsort.lc clobber=yes
ftsort ${burst_folder}/1s_rate_unsort.lc ${burst_folder}/1s_rate_sort.lc TIME unique=yes clobber=yes

/bin/rm ${burst_folder}/1s_rate_unsort.lc
/bin/rm temp_merge_rate.txt

## 64ms
ls -1 ${burst_folder}/64ms_rate_sort*.lc >! temp_merge_rate.txt

ftmerge @temp_merge_rate.txt ${burst_folder}/64ms_rate_unsort.lc clobber=yes
ftsort ${burst_folder}/64ms_rate_unsort.lc ${burst_folder}/64ms_rate_sort.lc TIME unique=yes clobber=yes

/bin/rm ${burst_folder}/64ms_rate_unsort.lc
/bin/rm temp_merge_rate.txt

## plot rate light curve
python bokeh_plot/lc_quad.py ${T0} ${burst_folder} >> ${info_file}
python bokeh_plot/lc_64ms.py ${T0} ${burst_folder} >> ${info_file}
python bokeh_plot/lc_1s.py ${T0} ${burst_folder} >> ${info_file}

#### old way of plotting light curve (non-interactive)
#python plot_qdrt_all_count.py ${T0} ${burst_folder} >> ${info_file}
#python plot_msrt_all_count.py ${T0} ${burst_folder} >> ${info_file}
#python plot_1s_all_count.py ${T0} ${burst_folder} >> ${info_file}

## fint 5-sigma upper limit (or detection) if rate data exist
## check whether the rate data exist
set flag_quad_rate = `cat ${info_file} | grep "flag_quad_rate:" | awk '{print $2}'`
if (${flag_quad_rate} == 1) then
	cd flux_limit/
	./find_flux_limit.sh ${info_file}
	## find redshift/distance limit corresponds to the flux limit
	cd ../find_redshift_limit/
	./find_distance_limit.sh ${info_file}
	cd ../
endif

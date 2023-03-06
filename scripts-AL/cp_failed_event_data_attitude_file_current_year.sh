#!/bin/tcsh -f

## This script find and copy the failed event data passes to designated folder
## The data will be copied to a folder "pass_data" under the current directory
## (this folder will be created if does not exist)

set info_file = $argv[1]

set year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set day_of_year = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set search_time_window = `cat ${info_file} | grep "search_time_window:" | awk '{print $2}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`
set pass_data_dir = `cat ${info_file} | grep "pass_data_dir:" | awk '{print $2}'`
set obsid = $argv[2]

set script_dir = ./


set day_of_year_minus_num = `echo ${day_of_year} | awk '{print $1-1}'`
set day_of_year_plus_num = `echo ${day_of_year} | awk '{print $1+1}'`
set day_of_year_minus = `python ${script_dir}/name_format.py ${day_of_year_minus_num} | awk '{print $1}'`
set day_of_year_plus = `python ${script_dir}/name_format.py ${day_of_year_plus_num} | awk '{print $1}'`

#echo ${day_of_year_minus} ${day_of_year_plus}

${script_dir}/cp_failed_event_data_current_year.sh ${obsid} ${year} ${day_of_year} ${output_dir} ${pass_data_dir}
${script_dir}/cp_failed_event_data_current_year.sh ${obsid} ${year} ${day_of_year_minus} ${output_dir} ${pass_data_dir}
${script_dir}/cp_failed_event_data_current_year.sh ${obsid} ${year} ${day_of_year_plus} ${output_dir} ${pass_data_dir}

## 3rd day
#set day_of_year_plus_num = `echo ${day_of_year} | awk '{print $1+2}'
#set day_of_year_plus = `python ${script_dir}/name_format.py ${day_of_year_plus_num} | awk '{print $1}'`
#${script_dir}/cp_failed_event_data_current_year.sh ${obsid} ${year} ${day_of_year_plus} ${output_dir} ${pass_data_dir}

### comment out the following line because not using Hans' att file in this process
${script_dir}/cp_attitude_current_year.sh ${obsid} ${year} ${day_of_year} ${output_dir}

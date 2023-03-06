#!/bin/tcsh -f

## This code find event data around the search time window of T0

set info_file = $argv[1]

set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
set year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set day_of_year = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set search_time_window = `cat ${info_file} | grep "search_time_window:" | awk '{print $2}'`
set burst_folder = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`
set pass_data_dir = `cat ${info_file} | grep "pass_data_dir:" | awk '{print $2}'`
set script_dir = ./

## search T0 day
./find_failed_evt_data_current_year.sh ${T0} ${year} ${day_of_year} ${search_time_window} ${burst_folder} ${pass_data_dir}

set day_of_year_next_num = `echo ${day_of_year} | awk '{print $1+1}'`
set day_of_year_next = `python ${script_dir}/name_format.py ${day_of_year_next_num} | awk '{print $1}'`

## search the next day of T0 (because sometime there are delay in data downlink)
./find_failed_evt_data_current_year.sh ${T0} ${year} ${day_of_year_next} ${search_time_window} ${burst_folder} ${pass_data_dir}

### 3rd day occationally
#set day_of_year_next_num = `echo ${day_of_year} | awk '{print $1+2}'`
#set day_of_year_next = `python ${script_dir}/name_format.py ${day_of_year_next_num} | awk '{print $1}'`

## search the next day of T0 (because sometime there are delay in data downlink)
./find_failed_evt_data_current_year.sh ${T0} ${year} ${day_of_year_next} ${search_time_window} ${burst_folder} ${pass_data_dir}


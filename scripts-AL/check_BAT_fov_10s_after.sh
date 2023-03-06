#!/bin/tcsh -f

set info_file = $argv[1]
set input_img = `cat ${info_file} | grep "input_img:" | awk '{print $2}'`
set input_img_phil = `cat ${info_file} | grep "input_img_Phil:" | awk '{print $2}'`
set healpy_flag = `cat ${info_file} | grep "healpy_flag:" | awk '{print $2}'` ## 0: healpy map; 1:normal (i.e., BAT-image-like) fits file
set T0_10s_after = `cat ${info_file} | grep "T0_10s_after:" | awk '{print $2}'`
set T0_year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set T0_doy = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`
set att_folder = `cat ${info_file} | grep "att_folder:" | awk '{print $2}'`

## if T0 is within the past 12 hours, get BAT pointing from GCN, else get BAT pointing from Hans' attitude file
## we usually get att file within 12 hours, so let's always try attitude in pass data first
#set now_date = `date -u +%Y%b%d | awk '{print $1}'`
#echo ${now_date}
#set now_time = `date -u +%Y%b%d%t%H:%M:%S | awk '{print $2}'`
#echo ${now_time}
#set now_full = "${now_date} at ${now_time}"
#s
#t now_met = `swifttime "${now_full}" UTC c MET s | grep "Converted time:" | awk '{print $3}'`
#set T0_current_time_diff_flag = `echo ${now_met} ${T0} | awk '{if (($1-$2) <= 12.0*60.0*60.0) print 1; else print 0#}'`
#
#echo ${T0_current_time_diff_flag}
#set T0_current_time_diff_flag = 0

python get_BAT_attitude_10s_after.py ${T0_10s_after} ${T0_year} ${T0_doy} ${output_dir}/pass_data ${att_folder} >> ${info_file}
python get_Earth_pos_10s_after.py ${info_file} >> ${info_file}

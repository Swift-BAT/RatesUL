#!/bin/tcsh -f

set info_file = $argv[1]
set input_img = `cat ${info_file} | grep "input_img:" | awk '{print $2}'`
set input_img_phil = `cat ${info_file} | grep "input_img_Phil:" | awk '{print $2}'`
set healpy_flag = `cat ${info_file} | grep "healpy_flag:" | awk '{print $2}'` ## 0: healpy map; 1:normal (i.e., BAT-image-like) fits file
set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
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

python get_BAT_attitude.py ${T0} ${T0_year} ${T0_doy} ${output_dir}/pass_data ${att_folder} >> ${info_file}

## if cannot get BAT pointings in attitude file (i.e., no pass data yet)
## get BAT pointing from Scott's gcn notice
set flag_att = `cat ${info_file} | grep "flag_att:" | awk '{print $2}'`

if (${flag_att} == 0) then
	./get_BAT_attitude_from_GCN.sh ${info_file}
endif

set BAT_RA = `cat ${info_file} | grep "BAT_RA:" | awk '{printf("%lf\n", $2)}'`
set BAT_DEC = `cat ${info_file} | grep "BAT_DEC:" | awk '{printf("%lf\n", $2)}'`
set BAT_ROLL = `cat ${info_file} | grep "BAT_ROLL:" | awk '{printf("%lf\n", $2)}'`

set Earth_RA = `cat ${info_file} | grep "Earth_RA:" | awk '{print $2}'`
set Earth_DEC = `cat ${info_file} | grep "Earth_DEC:" | awk '{print $2}'`

set src_RA = `cat ${info_file} | grep "src_RA:" | awk '{print $2}'`
set src_DEC = `cat ${info_file} | grep "src_DEC:" | awk '{print $2}'`

set input_img = `cat ${info_file} | grep "input_img:" | awk '{print $2}'`

echo "Checking if the input source is in the BAT FOV...."
python batfov_one_src.py ${src_RA} ${src_DEC} ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} >> ${info_file}

if ($input_img != 'NONE') then
	echo "Checking if the input image overlaps with the BAT FOV..."
	if (${healpy_flag} == 1) then
		python batfov_check_img.py ${input_img} ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} ${output_dir} >> ${info_file}
	endif
	if (${healpy_flag} == 0) then
		echo ${input_img} ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} ${Earth_RA} ${Earth_DEC}
                python batfov_check_img_healpix.py ${input_img} ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} ${Earth_RA} ${Earth_DEC} >> ${info_file}
		if (${input_img_phil} != 'NONE') then
			echo "${input_img_phil} ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} ${output_dir}"
			python batfov_check_img_healpix_Phil_map.py ${input_img_phil} ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} ${output_dir} >> ${info_file}
		endif
        endif
	
endif

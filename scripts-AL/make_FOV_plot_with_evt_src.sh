#!/bin/tcsh -f

set info_file = $argv[1]
set obsid = $argv[2]

set T0 = `cat ${info_file} | grep "T0:" | awk '{printf("%lf\n", $2)}'`
set T0_year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set T0_doy = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`

set Earth_RA = `cat ${info_file} | grep "Earth_RA:" | awk '{print $2}'`
set Earth_DEC = `cat ${info_file} | grep "Earth_DEC:" | awk '{print $2}'`

set input_img = `cat ${info_file} | grep "input_img:" | awk '{print $2}'`

set BAT_FOV_img = `cat ${info_file} | grep "BAT_FOV_img:" | awk '{print $2}'`

set detection_list = ${output_dir}/event_data_analysis/${obsid}_image_search/detect_source_list.txt

echo $input_img
echo $detection_list

if ($input_img != 'NONE') then
	if (-e ${detection_list}) then
		echo "python plot_BAT_FOV_healpix_img_with_src_from_evt.py ${BAT_FOV_img} ${input_img} ${output_dir} ${T0} ${Earth_RA} ${Earth_DEC} ${obsid}"
                python plot_BAT_FOV_healpix_img_with_src_from_evt.py ${BAT_FOV_img} ${input_img} ${output_dir} ${T0} ${Earth_RA} ${Earth_DEC} ${obsid} >> ${info_file}
        endif

endif

#!/bin/tcsh -f

set info_file = $argv[1]

set T0 = `cat ${info_file} | grep "T0:" | awk '{printf("%lf\n", $2)}'`
set T0_year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set T0_doy = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`

set BAT_RA = `cat ${info_file} | grep "BAT_RA:" | awk '{printf("%lf\n", $2)}'`
set BAT_DEC = `cat ${info_file} | grep "BAT_DEC:" | awk '{printf("%lf\n", $2)}'`
set BAT_ROLL = `cat ${info_file} | grep "BAT_ROLL:" | awk '{printf("%lf\n", $2)}'`

set src_RA = `cat ${info_file} | grep "src_RA:" | awk '{print $2}'`
set src_DEC = `cat ${info_file} | grep "src_DEC:" | awk '{print $2}'`

set Earth_RA = `cat ${info_file} | grep "Earth_RA:" | awk '{print $2}'`
set Earth_DEC = `cat ${info_file} | grep "Earth_DEC:" | awk '{print $2}'`

set input_img = `cat ${info_file} | grep "input_img:" | awk '{print $2}'`
set healpy_flag = `cat ${info_file} | grep "healpy_flag:" | awk '{print $2}'`

## making BAT FOV fits file
python batfov_mod.py ${BAT_RA} ${BAT_DEC} ${BAT_ROLL} ${output_dir}
set BAT_FOV_img = ${output_dir}/batfov.fits
echo "BAT_FOV_img: ${BAT_FOV_img}" >> ${info_file}

if ($input_img != 'NONE') then
	if (${healpy_flag} == 1) then
		python plot_BAT_FOV_with_src.py ${BAT_FOV_img} ${input_img} ${src_RA} ${src_DEC} ${output_dir} >> ${info_file} ## need to modify this (currently the code does not plot the input img)
	endif
	if (${healpy_flag} == 0) then
		echo "python plot_BAT_FOV_healpix_img_with_src.py ${BAT_FOV_img} ${input_img} ${src_RA} ${src_DEC} ${output_dir} ${T0} ${Earth_RA} ${Earth_DEC}"
                python plot_BAT_FOV_healpix_img_with_src.py ${BAT_FOV_img} ${input_img} ${src_RA} ${src_DEC} ${output_dir} ${T0} ${Earth_RA} ${Earth_DEC}>> ${info_file}
        endif

else
	python plot_BAT_FOV_with_src.py ${BAT_FOV_img} ${src_RA} ${src_DEC} ${output_dir} ${T0} ${Earth_RA} ${Earth_DEC} >> ${info_file}
	
endif
echo "FOV_plot: bat_fov.png" >> ${info_file}

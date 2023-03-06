#!/bin/tcsh -f

set info_file = $argv[1]

## for swifttime we need to use the FTP caldb for the most updated time correction
unsetenv CALDB
#setenv CALDB https://heasarc.gsfc.nasa.gov/FTP/caldb
#setenv CALDBCONFIG /software/lheasoft/develop/caldb.config
#setenv CALDBALIAS /software/lheasoft/develop/alias_config.fits
source $HOME/headas_caldb_setup_FTP.csh 

set Swift_pointing_folder = `cat ${info_file} | grep "Swift_pointing_folder:" | awk '{print $2}'`
set T0 = `cat ${info_file} | grep "T0:" | awk '{print $2}'`
set Year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set Month = `cat ${info_file} | grep "Month:" | awk '{print $2}'`
set Day = `cat ${info_file} | grep "Day:" | awk '{print $2}'`

ls -1t ${Swift_pointing_folder}/${Year}-${Month}-${Day}* >! att_temp.txt

set list_temp = att_temp.txt

set tot_temp = `wc $list_temp | awk '{print $1}'`
set time_min = 3600.0
@ i_list_temp = 1  ## starting from 2 to skip to comment line in list.dat
while ($i_list_temp <= $tot_temp)
	echo $i_list_temp
	set email = `awk '{if (NR == '$i_list_temp') print $1}' $list_temp`
	echo ${email}
	set notice_date_year = `cat ${email} | grep "NOTICE_DATE:" | awk '{print 20$5}'`
	set notice_date_month = `cat ${email} | grep "NOTICE_DATE:" | awk '{print $4}'`
	set notice_date_date = `cat ${email} | grep "NOTICE_DATE:" | awk '{print $3}'`
	set notice_date_time = `cat ${email} | grep "NOTICE_DATE:" | awk '{print $6}'`

	set notice_time_UTC = "${notice_date_year}${notice_date_month}${notice_date_date} at ${notice_date_time}"

        set notice_time_met = `swifttime "${notice_time_UTC}" UTC c MET s | grep "Converted time:" | awk '{print $3}'`

	set time_diff = `echo ${notice_time_met} ${T0} | awk '{printf("%lf\n", $1-$2)}'`

	## skip the first file we are finding time right before T0, and these files are in reverse-time order.
	if ($i_list_temp == 1) then
		set time_diff_flag = 0
	else
		set time_diff_flag = `echo ${time_diff} ${time_diff_new} | awk '{if ($1 < 0 && $2 > 0 || $1 == 0 || $2 == 0) print 1; else print 0}'`
		set time_diff_flag_equal_1 = `echo ${time_diff} ${time_diff_new} | awk '{if ($1 == 0) print 1; else print 0}'`
		set time_diff_flag_equal_2 = `echo ${time_diff} ${time_diff_new} | awk '{if ($2 == 0) print 1; else print 0}'`
		echo ${time_diff} ${time_diff_new} ${time_diff_flag} ${time_diff_flag_equal_1} ${time_diff_flag_equal_2}
	endif

	if (${time_diff_flag} == 1) then
		set time_min = ${time_diff}
		set time_min_notice = "${notice_time_UTC}"
		set BAT_RA = `cat ${email} | grep "CURR_POINT_RA:" | awk '{print $2}' | awk -F "d" '{print $1}'`
		set BAT_DEC = `cat ${email} | grep "CURR_POINT_DEC:" | awk '{print $2}' | awk -F "d" '{print $1}'`
		set BAT_ROLL = `cat ${email} | grep "CURR_POINT_ROLL:" | awk '{print $2}' | awk -F "d" '{print $1}'`
		break
	endif

	set time_diff_new = ${time_diff}
@ i_list_temp++
end
/bin/rm att_temp.txt


echo "BAT_pointing_from_GCN:time_diff: ${time_min}" >> ${info_file}
echo "BAT_pointing_from_GCN:time_min_notice: ${time_min_notice}" >> ${info_file}
echo "BAT_RA_from_GCN: ${BAT_RA}" >> ${info_file}
echo "BAT_DEC_from_GCN: ${BAT_DEC}" >> ${info_file}
echo "BAT_ROLL_from_GCN: ${BAT_ROLL}" >> ${info_file}
echo "BAT_RA: ${BAT_RA}" >> ${info_file}
echo "BAT_DEC: ${BAT_DEC}" >> ${info_file}
echo "BAT_ROLL: ${BAT_ROLL}" >> ${info_file}

## After finished, set CALDB back to normal
source $HOME/headas_caldb_setup.csh

#!/bin/tcsh -f

## This is a cron job that trigger on Phil's email, download Phil's file from the links in emails, 
##  and then start the transient_search.sh
## Amy (2019.02.02)

date

## if lockfile exist, wait until last process finished
set lockfile = /local/data/bat2/batusers/batgroup/BAT_GW/code/cron_log/trigger_BAT_transient_search_cron_lockfile
if (-e $lockfile) then
	echo "Last process is still running....wait until it is finished."
	exit 0
endif

touch $lockfile

ls -l --full-time /Home/eud/batgroup/Mail/Phil_SwiftLV_notice/msg* >! /Home/eud/batgroup/Mail/Phil_SwiftLV_notice/temp.txt

set list = /Home/eud/batgroup/Mail/Phil_SwiftLV_notice/temp.txt

set GW_result_folder = /local/data/bat2/batusers/batgroup/BAT_GW/results

set GW_code_folder = /local/data/bat2/batusers/batgroup/BAT_GW/code 

set tot = `wc $list | awk '{print $1}'`
@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
while ($i_list <= $tot)

	set process_start_time = `date`

	echo "Found GW trigger message! Start processing at ${process_start_time}"
	
	set msg_name = `awk '{if (NR == '$i_list') print $9}' $list`
        set name_date = `awk '{if (NR == '$i_list') print $6}' $list`
	set name_time = `awk '{if (NR == '$i_list') print $7}' $list`

	## Get the name
	set name = `grep "LVC_TRIGGER:" ${msg_name} | awk '{print $2}' | head -1`
	
	echo "Processing ${name}..."
		
	## create result dir
	set result_dir = ${GW_result_folder}/${name}
	if (! -d ${result_dir}) then
		mkdir ${result_dir}
	endif

	## get LIGO map and Phil's galaxy convolve map
	echo "Downloading maps..."

	set Phil_image_web = `grep "CONV_FILE:" ${msg_name} | awk '{print $2}'`
	set Phil_image_name_short = `echo ${Phil_image_web} | awk -F "_convolved" '{print $1}'`
	set LIGO_image_web = ${Phil_image_name_short}.fits.gz

	set swiftlv_page = `grep "URL:" ${msg_name} | awk '{print $2}'`
	echo ${swiftlv_page}
	curl -u gwplanner:gw_sw1ft_pl@nn3r ${Phil_image_web} -o ${result_dir}/bayestar_convolved.fits.gz
	curl -u gwplanner:gw_sw1ft_pl@nn3r ${LIGO_image_web} -o ${result_dir}/bayestar.fits.gz

	echo "finish download"

	set LIGO_image = ${result_dir}/bayestar.fits.gz
	set Phil_image = ${result_dir}/bayestar_convolved.fits.gz

	if (! -e ${LIGO_image}) then
		set LIGO_image = NONE
	endif

	if (! -e ${Phil_image}) then
                set Phil_image = NONE
        endif
	
	## get trigger time (UTC)
	set trigger_time_UTC = `grep "TRIGGER_DATE:" ${msg_name} | awk '{print $2}' | head -1`

	## move message to the GW folder
	/bin/mv ${msg_name}  /local/data/bat2/batusers/batgroup/BAT_GW/Phil_SwiftLV_notice/${name_date}_${name_time}.txt

	## run BAT data search	
	cd /local/data/bat2/batusers/batgroup/BAT_GW/code/
	pwd
	echo "./transient_search.sh ${name} ${trigger_time_UTC} UTC 0.0 0.0 ${LIGO_image} ${Phil_image}"
	./transient_search.sh ${name} ${trigger_time_UTC} UTC 0.0 0.0 ${LIGO_image} ${Phil_image}

	set process_end_time = `date`

        echo "Process finished at ${process_end_time}"

	## get the current list of pass_dir (for BAT_transient_search_cron.sh to check if there are new pass show up)

	set T0_doy_today = `date +%j`
	set T0_year = `date +%Y`

	ls -1d /local/data/bat2/pass_data/current_year/pass_${T0_year}${T0_doy_today}*/fits/ >! ${result_dir}/pass_data_dir_list_old.txt

	## send notice to my phone
	set mail_txt = mailing_trigger.txt
	set mailing_list = 2172996019@msg.fi.google.com
	set Phil_msg_subject = `grep "Subject:" ${msg_name} | awk '{print $2 $3 $4}'`

	echo "LIGO detected a new source ${name}" >! ${mail_txt}
	echo ${Phil_msg_subject} >> ${mail_txt}

	mail -s "${name}: LIGO new source" ${mailing_list} < ${mail_txt}

@ i_list++
end ## end i_list

/bin/rm ${list}
/bin/rm $lockfile

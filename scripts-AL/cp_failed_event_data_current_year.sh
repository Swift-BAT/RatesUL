#!/bin/tcsh -f

## This code simply copy the failed event data from the pass data
## in order to make it easier to tar and scp to batevent1

set obsid = $argv[1] 
set year = $argv[2]
set day_of_year = $argv[3]
set output_dir = $argv[4]

set home_dir = $argv[5]
set burst_folder = ${output_dir}/pass_data

if (! -d ${burst_folder}) then
	mkdir ${burst_folder}
endif

if (-e ${burst_folder}/list_${year}_${day_of_year}.txt) then
	/bin/rm ${burst_folder}/list_${year}_${day_of_year}.txt
endif

find ${home_dir}/pass_${year}${day_of_year}* -name \*${obsid}\* >&! ${burst_folder}/list_${year}_${day_of_year}.txt


set find_no_match_flag = `grep "find: No match." ${burst_folder}/list_${year}_${day_of_year}.txt | wc | awk '{print $1}'`

if (${find_no_match_flag} == 0) then 

	find ${home_dir}/pass_${year}${day_of_year}* -name \*${obsid}\* | grep -o '.*/' | sort | uniq >! ${burst_folder}/list_${year}_${day_of_year}.txt  ## get only folder name, and folders with same name are printed only once

	set foldername = 'pass_combine'

	if (! -d ${burst_folder}/${foldername}) then
		mkdir ${burst_folder}/${foldername}
	endif

	if (! -d ${burst_folder}/${foldername}/fits) then
		mkdir ${burst_folder}/${foldername}/fits
	endif

	## merge event data first (because there could be event data with the same name but different time in each pass data)
	find ${home_dir}/pass_${year}${day_of_year}* -name \*${obsid}\*bevsh\*evt\* >&! ${burst_folder}/events.lis
	if (-e $burst_folder/gti.lis) then
		/bin/rm $burst_folder/gti.lis
	endif

	set find_no_match_flag = `grep "find: No match." ${burst_folder}/events.lis | wc | awk '{print $1}'`

	## do the following if event fiel exist
	if (${find_no_match_flag} == 0) then
		foreach file (`cat $burst_folder/events.lis`)
		  echo $file"[GTI]" >> $burst_folder/gti.lis
		end
		ftmerge @${burst_folder}/gti.lis $burst_folder/events.gti clobber=yes
		# Remove any stray EVENTS extensions
		ftdelhdu $burst_folder/events.gti'[EVENTS]' none confirm=YES

		extractor @${burst_folder}/events.lis ${burst_folder}/pass_combine/fits/sw${obsid}bevsh_merge_${day_of_year}.evt timefile=$burst_folder/events.gti gti=GTI \
		    imgfile=NONE phafile=NONE fitsbinlc=NONE regionfile=NONE gtinam=GTI \
		    xcolf=DETX ycolf=DETY tcol=TIME ecol=PI xcolh=DETX ycolh=DETY

	endif

	if (-e $burst_folder/events.gti) then
		/bin/rm $burst_folder/events.gti 
	endif
	if (-e {burst_folder}/events.lis) then
		/bin/rm ${burst_folder}/events.lis
	endif
	#ftmerge @${burst_folder}/temp_evt_list.txt ${burst_folder}/pass_combine/fits/merge_evt_unsort.fits clobber=yes
	#ftsort ${burst_folder}/pass_combine/fits/merge_evt_unsort.fits ${burst_folder}/pass_combine/fits/sw${obsid}bevsh_merge_${day_of_year}.evt TIME unique=yes clobber=yes
	#/bin/rm ${burst_folder}/pass_combine/fits/merge_evt_unsort.fits


	set list = ${burst_folder}/list_${year}_${day_of_year}.txt

	set tot = `wc $list | awk '{print $1}'`
	@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
	while ($i_list <= $tot)
		#set pass_folder = `awk '{if (NR == '$i_list') print substr($1,1,62)}' $list`
		#set foldername = `awk '{if (NR == '$i_list') print substr($1,47,16)}' $list`
		set pass_folder = `awk '{if (NR == '$i_list') print $1}' $list`		

		echo ${foldername} ${pass_folder}


		## copy the rest of the file
		/bin/cp ${pass_folder}/*${obsid}* ${burst_folder}/${foldername}/fits
		/bin/cp ${pass_folder}/*sw99999999000b1e5x001.hk* ${burst_folder}/${foldername}/fits
		/bin/cp ${pass_folder}/*bcbo* ${burst_folder}/${foldername}/fits   
		/bin/cp ${pass_folder}/*cbde* ${burst_folder}/${foldername}/fits   
		/bin/cp ${pass_folder}/*decb* ${burst_folder}/${foldername}/fits   
		/bin/cp ${pass_folder}/*att* ${burst_folder}/${foldername}/fits	
	
		## (the attitude file is created in earlier steps)

	@ i_list++
	end ## end i_list
endif

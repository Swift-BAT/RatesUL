#!/bin/tcsh -f

## This code find event data around the search time window of T0

set T0 = $argv[1]
set year = $argv[2]
set day_of_year = $argv[3]
set search_time_window = $argv[4]
set search_time_window_neg = `echo ${search_time_window} | awk '{print -1.0*$1}'`
set burst_folder = $argv[5]
set home_dir = $argv[6]

echo "Searching for pass data on ${year}/${day_of_year}..."


# set up battools and batcaldb
source $HOME/headas_caldb_setup.csh

## set up specific pfile location for this run
mkdir -p ${burst_folder}/pfiles
setenv PFILES "${burst_folder}/pfiles;$HEADAS/syspfiles"


## delete previous existing list
if (-e ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt) then
	/bin/rm ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt
endif
if (-e ${burst_folder}/merge_64ms_rate_list_${year}_${day_of_year}.txt) then
        /bin/rm ${burst_folder}/merge_64ms_rate_list_${year}_${day_of_year}.txt
endif
if (-e ${burst_folder}/merge_1s_rate_list_${year}_${day_of_year}.txt) then
        /bin/rm ${burst_folder}/merge_1s_rate_list_${year}_${day_of_year}.txt
endif


find ${home_dir}/pass_${year}${day_of_year}* -name \*brtqd\*.gz >! ${burst_folder}/list_${year}_${day_of_year}.txt

echo "## list of quad-rate data with time match with the source (T0 = ${T0})" >! ${burst_folder}/match_quad_rate_list_${year}_${day_of_year}.txt

set list = ${burst_folder}/list_${year}_${day_of_year}.txt

set match_flag = 0
set tot = `wc $list | awk '{print $1}'`
@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
while ($i_list <= $tot)
	set ratefile = `awk '{if (NR == '$i_list') print $1}' $list`

	set rate_stop_row = `fstruct ${ratefile} | grep "BINTABLE RATE" | awk '{print $6}'`

	set rate_start = `ftlist ${ratefile}'[col TIME]' T colheader=no rownum=no rows=1 | awk '{print $1}'`
	set rate_stop = `ftlist ${ratefile}'[col TIME]' T colheader=no rownum=no rows=${rate_stop_row} | awk '{print $1}'` 

	set rate_start_sinceT0 = `echo ${rate_start} ${T0} | awk '{print $1-$2}'`
	set rate_stop_sinceT0 = `echo ${rate_stop} ${T0} | awk '{print $1-$2}'`

	set flag_start = `echo ${rate_start_sinceT0} | awk '{if ($1 >= '$search_time_window_neg' && $1 <= '$search_time_window') print 1; else print 0}'`
	set flag_stop = `echo ${rate_stop_sinceT0} | awk '{if ($1 >= '$search_time_window_neg' && $1 <= '$search_time_window') print 1; else print 0}'`
	set flag_include = `echo ${rate_start_sinceT0} ${rate_stop_sinceT0} | awk '{if ($1 < 0.0 && $2 > 0.0) print 1; else print 0}'`

	echo ${rate_start_sinceT0} ${rate_stop_sinceT0}, ${flag_start} ${flag_stop} ${flag_include}

	if (${flag_start} == 1) then
		set match_flag = 1
		echo ${rate_start_sinceT0} ${rate_stop_sinceT0} ${ratefile}>> ${burst_folder}/match_quad_rate_list_${year}_${day_of_year}.txt
		echo ${ratefile}>> ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt
	
	else if (${flag_stop} == 1) then
		set match_flag = 1
		echo ${rate_start_sinceT0} ${rate_stop_sinceT0} ${ratefile}>> ${burst_folder}/match_quad_rate_list_${year}_${day_of_year}.txt
		echo ${ratefile}>> ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt

	else if (${flag_include} == 1) then
		set match_flag = 1
		echo ${rate_start_sinceT0} ${rate_stop_sinceT0} ${ratefile}>> ${burst_folder}/match_quad_rate_list_${year}_${day_of_year}.txt
		echo ${ratefile}>> ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt
	endif
	

@ i_list++
end ## end i_list

## make light curve if there are matched data

if (${match_flag} == 1) then
	## quad rate
	ftmerge @${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt ${burst_folder}/quad_rate_unsort.lc clobber=yes
	ftsort ${burst_folder}/quad_rate_unsort.lc ${burst_folder}/quad_rate_sort_${year}_${day_of_year}.lc TIME unique=yes clobber=yes

	/bin/rm ${burst_folder}/quad_rate_unsort.lc

	## 64ms
	/bin/cp ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt ${burst_folder}/merge_64ms_rate_list_${year}_${day_of_year}.txt
	sed -i 's/brtqd/brtms/g' ${burst_folder}/merge_64ms_rate_list_${year}_${day_of_year}.txt

	ftmerge @${burst_folder}/merge_64ms_rate_list_${year}_${day_of_year}.txt ${burst_folder}/64ms_rate_unsort.lc clobber=yes
	ftsort ${burst_folder}/64ms_rate_unsort.lc ${burst_folder}/64ms_rate_sort_${year}_${day_of_year}.lc TIME unique=yes clobber=yes

	/bin/rm ${burst_folder}/64ms_rate_unsort.lc
	/bin/rm ${burst_folder}/merge_64ms_rate_list_${year}_${day_of_year}.txt

	## 1s
	/bin/cp ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt ${burst_folder}/merge_1s_rate_list_${year}_${day_of_year}.txt
	sed -i 's/brtqd/brt1s/g' ${burst_folder}/merge_1s_rate_list_${year}_${day_of_year}.txt

	ftmerge @${burst_folder}/merge_1s_rate_list_${year}_${day_of_year}.txt ${burst_folder}/1s_rate_unsort.lc clobber=yes
	ftsort ${burst_folder}/1s_rate_unsort.lc ${burst_folder}/1s_rate_sort_${year}_${day_of_year}.lc TIME unique=yes clobber=yes

	/bin/rm ${burst_folder}/1s_rate_unsort.lc
	/bin/rm ${burst_folder}/merge_1s_rate_list_${year}_${day_of_year}.txt

	/bin/rm ${burst_folder}/list_${year}_${day_of_year}.txt
	/bin/rm ${burst_folder}/merge_quad_rate_list_${year}_${day_of_year}.txt	

#else
#	echo "No matched rate data on ${year}/${day_of_year}"
endif


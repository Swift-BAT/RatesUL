#!/bin/tcsh -f

## This code find event data around the search time window of T0

set T0 = $argv[1]
set year = $argv[2]
set day_of_year = $argv[3]
set search_time_window = $argv[4]
set search_time_window_neg = `echo ${search_time_window} | awk '{print -1.0*$1}'`
set burst_folder = $argv[5]
set home_dir = $argv[6]

echo "Searching for event data on ${year}/${day_of_year}...."


# set up battools and batcaldb
#source /software/lheasoft/release/lhea.csh
source $HOME/headas_caldb_setup_GW.csh ## special one because need to refer to old xspec...

## set up specific pfile location for this run
mkdir -p ${burst_folder}/pfiles
setenv PFILES "${burst_folder}/pfiles;$HEADAS/syspfiles"

echo ${home_dir}

find ${home_dir}/pass_${year}${day_of_year}* -name \*evt.gz >&! ${burst_folder}/list_${year}_${day_of_year}.txt

echo "## list of event files with time match with the event (T0 = ${T0})" >! ${burst_folder}/match_evt_list_${year}_${day_of_year}.txt

set list = ${burst_folder}/list_${year}_${day_of_year}.txt

set find_no_match_flag = `cat ${list} | grep "find: No match." | wc | awk '{print $1}'`

if (${find_no_match_flag} == 0) then
	set tot = `wc $list | awk '{print $1}'`
	@ i_list = 1  ## starting from 2 to skip to comment line in list.dat
	while ($i_list <= $tot)
		set evtfile = `awk '{if (NR == '$i_list') print $1}' $list`

		#set evt_start = `ftlist ${evtfile}+2 colheader=no rownum=no T | awk '{print $1}'`
		#set evt_stop = `ftlist ${evtfile}+2 colheader=no rownum=no T | awk '{print $2}'`

		ftlist ${evtfile}+2 colheader=no rownum=no T | awk '{print $1, $2}' >! temp_evtlist.txt

		set list_temp = temp_evtlist.txt	

		set tot_temp = `wc $list_temp | awk '{print $1}'`
		@ i_list_temp = 1  ## starting from 2 to skip to comment line in list.dat
		while ($i_list_temp <= $tot_temp)
			set evt_start = `awk '{if (NR == '$i_list_temp') print $1}' $list_temp`
			set evt_stop = `awk '{if (NR == '$i_list_temp') print $2}' $list_temp`

			set evt_start_sinceT0 = `echo ${evt_start} ${T0} | awk '{print $1-$2}'`
			set evt_stop_sinceT0 = `echo ${evt_stop} ${T0} | awk '{print $1-$2}'`

			set flag_start = `echo ${evt_start_sinceT0} | awk '{if ($1 >= '$search_time_window_neg' && $1 <= '$search_time_window') print 1; else print 0}'`
			set flag_stop = `echo ${evt_stop_sinceT0} | awk '{if ($1 >= '$search_time_window_neg' && $1 <= '$search_time_window') print 1; else print 0}'`
			set flag_include = `echo ${evt_start_sinceT0} ${evt_stop_sinceT0} | awk '{if ($1 < 0.0 && $2 > 0.0) print 1; else print 0}'`

			#set obsid = `echo ${evtfile} | awk '{print substr($1,85,11)}'`

			echo ${evt_start_sinceT0} ${evt_stop_sinceT0}, ${flag_start} ${flag_stop} ${flag_include}

			if (${flag_start} == 1) then
				echo ${evt_start_sinceT0} ${evt_stop_sinceT0} ${evtfile}>> ${burst_folder}/match_evt_list_${year}_${day_of_year}.txt
			
			else if (${flag_stop} == 1) then
				echo ${evt_start_sinceT0} ${evt_stop_sinceT0} ${evtfile}>> ${burst_folder}/match_evt_list_${year}_${day_of_year}.txt
			else
				if (${flag_include} == 1) then
					echo ${evt_start_sinceT0} ${evt_stop_sinceT0} ${evtfile}>> ${burst_folder}/match_evt_list_${year}_${day_of_year}.txt
				endif
			endif

		@ i_list_temp++
		end
		/bin/rm ${list_temp}

	@ i_list++
	end ## end i_list


endif

/bin/rm ${burst_folder}/list_${year}_${day_of_year}.txt

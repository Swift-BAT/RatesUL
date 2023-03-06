#!/bin/tcsh -f

## search through LIGO notice for the specific trigger
## and download the skypmap

set source_name = $argv[1]

set LIGO_notice_folder = /local/data/bat2/batusers/batgroup/BAT_GW/LIGO_notice
set output_dir = /local/data/bat2/batusers/batgroup/BAT_GW/results/${source_name}
#set source_date: = `cat ${info_file} | grep "time_UTC:" | awk '{printf("%lf\n", $2)}'`

if (! -d ${output_dir}) then
        mkdir ${output_dir}
endif
  
set sky_map_link = `grep ${source_name} ${LIGO_notice_folder}/* | grep SKYMAP_BASIC_URL: | tail -1 | awk '{print $2}'`

set sky_map_name = `echo ${sky_map_link} | awk -F'/' '{print $NF}'`

echo ${sky_map_link} ${sky_map_name}

curl --netrc -O ${sky_map_link}
/bin/mv ${sky_map_name} ${output_dir}

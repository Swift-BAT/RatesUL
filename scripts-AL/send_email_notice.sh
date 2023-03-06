#!/bin/tcsh -f

set info_file = $argv[1]

set Year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set Month = `cat ${info_file} | grep "Month:" | awk '{print $2}'`
set Day = `cat ${info_file} | grep "Day:" | awk '{print $2}'`
set source_name = `cat ${info_file} | grep "source_name:" | awk '{print $2}'`

set mail_txt = mailing.txt
set mailing_list = `cat mailing_list.txt`
echo "${source_name}: BAT GW search process is finished." >! ${mail_txt}
echo "Results are available at" >> ${mail_txt}
echo "https://swift.gsfc.nasa.gov/results/BATbursts/team_web/${source_name}/web/source.html" >> ${mail_txt}

mail -s "${source_name}: BAT GW search results" ${mailing_list} < ${mail_txt}

/bin/rm ${mail_txt}


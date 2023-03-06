#!/bin/tcsh -f

## get necessary time (e.g., year, doy...etc) of T0
set info_file = $argv[1]

## for swifttime we need to use the FTP caldb for the most updated time correction
#unsetenv CALDB
#setenv CALDB http://heasarc.gsfc.nasa.gov/FTP/caldb
#setenv CALDBCONFIG /software/lheasoft/develop/caldb.config
#setenv CALDBALIAS /software/lheasoft/develop/alias_config.fits
source $HOME/headas_caldb_setup_FTP.csh

set T0_input_flag = `cat ${info_file} | grep "T0_input_flag:" | awk '{print $2}'`

if (${T0_input_flag} == "MET") then
	set T0 = `cat ${info_file} | grep "T0_input:" | awk '{print $2}'`
	echo "T0: ${T0}" >> ${info_file}

	set T0_UTC_swifttime = `swifttime ${T0} MET s UTC c | grep "Converted time:" | awk '{print $3, $4, $5}'`
endif

if (${T0_input_flag} == "UTC") then
        set T0_UTC = `cat ${info_file} | grep "T0_input:" | awk '{print $2}'`

	set T0_UTC_swifttime = `python UTC_to_swiftime_format.py ${T0_UTC} | grep "time_UTC_swifttime:" | awk '{printf("%s %s %s\n", $2, $3, $4)}'`

        set T0 = `swifttime "${T0_UTC_swifttime}" UTC c MET s | grep "Converted time:" | awk '{print $3}'`
	echo "T0: ${T0}" >> ${info_file}
endif

python UTC_to_doy.py ${T0_UTC_swifttime} >> ${info_file}

## After finished, set CALDB back to normal
source $HOME/headas_caldb_setup.csh

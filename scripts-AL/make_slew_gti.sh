#!/bin/tcsh -f

set info_file = $argv[1]

set flag_att = `cat ${info_file} | grep "flag_att:" | awk '{print $2}'`

## only create slew gti when Hans' attitude file exist
if (${flag_att} == 1) then
	set att_folder = `cat ${info_file} | grep "att_folder:" | awk '{print $2}'`
	set year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
	set DOY = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`

	set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`

	set att_file = ${att_folder}/attitude_${year}_${DOY}.att

	set outfile = ${output_dir}/acs_slew.gti

	maketime infile=${att_file}+1 outfile=${outfile} expr='FLAGS == b00xxxxxx' name=NONE value=NONE time=TIME compact=no prefr=0.5 postfr=0.5 clobber=yes

endif

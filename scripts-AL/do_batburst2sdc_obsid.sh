#!/bin/tcsh

set obsid = $argv[1]
set output_dir = $argv[2]
set burst_dir = $argv[3]
set data_dir = $argv[4]

# set up battools and batcaldb
source $HOME/headas_caldb_setup.csh

## set up specific pfile location for this run
mkdir -p ${burst_dir}/pfiles
setenv PFILES "${burst_dir}/pfiles;$HEADAS/syspfiles"

set pass_dir = ${output_dir}/pass_data

batburst2sdc_obsid ${obsid} -failed extractor=fextract-events ${pass_dir}/pass_combine ${data_dir}


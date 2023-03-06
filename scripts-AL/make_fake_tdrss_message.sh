#!/bin/tcsh -f

## make fake tdrss message (code copied from Taka's code /net/raid16/BAT_GRB_process_2009/tools/batss_grb_proc.sh)

set obsid    = $argv[1]
set trigtime = $argv[2]
set ra       = $argv[3]
set dec      = $argv[4]
set burst_dir = $argv[5]

set trigid   = `echo $obsid | awk '{print substr($1,3,6)}'`
set trigstop = `echo $trigtime | awk '{printf("%lf\n", $1+64)}'`


# set up battools and batcaldb
source $HOME/headas_caldb_setup.csh

## set up specific pfile location for this run
mkdir -p ${burst_dir}/pfiles
setenv PFILES "${burst_dir}/pfiles;$HEADAS/syspfiles"

set datadir = ${burst_dir}/${obsid}

if (! -d ${datadir}/tdrss) then
    mkdir ${datadir}/tdrss
endif

/bin/cp -f sw00090078001msbce.fits ${datadir}/tdrss/sw${obsid}msbce.fits

set fake_tdrss_file = ${datadir}/tdrss/sw${obsid}msbce.fits

echo "OBS_ID"
fparkey "$obsid" ${fake_tdrss_file}+0 OBS_ID
echo "TARG_ID"
fparkey "$trigid" ${fake_tdrss_file}+0 TARG_ID
echo "TRIGGER"
fparkey "$trigid" ${fake_tdrss_file}+0 TRIGGER
echo "TRIGTIME"
fparkey "$trigtime" ${fake_tdrss_file}+0 TRIGTIME
echo "BRA_OBJ"
fparkey "$ra" ${fake_tdrss_file}+0 BRA_OBJ
echo "BDEC_OBJ"
fparkey "$dec" ${fake_tdrss_file}+0 BDEC_OBJ
echo "TRIGSTOP"
fparkey "$trigstop" ${fake_tdrss_file}+0 TRIGSTOP
echo "BACKSTAT"
fparkey 0.0 ${fake_tdrss_file}+0 BACKSTRT
echo "BACKSTOP"
fparkey 0.0 ${fake_tdrss_file}+0 BACKSTOP
echo "IMAGETRG"
fparkey T ${fake_tdrss_file}+0 IMAGETRG

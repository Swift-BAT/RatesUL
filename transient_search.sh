#!/bin/tcsh -f

## This script search for possible BAT coincidental detection with other triggers
## This script is heavily adapted from Amy Lien's code from https://arxiv.org/abs/1311.4567.
## MC, last update: Mar 6, 2023.  


if ($#argv != 7) then
        echo "./transient_search.sh source_name T0 T0_type src_RA src_DEC input_img input_img_Phil"
	echo "source_name: the source name. This will be the folder name in the result directory"
        echo "T0: enter either UTC or Swift MET"
        echo "T0_type: enter the word "UTC" or "MET", depends on which T0 you entered."
        echo "src_RA: RA for an input source to be searched in the event data."
        echo "src_DEC: DEC for an input source to be searched in the event data"
        echo "input_img: An input image to be searched whether it overlaps with BAT FOV (e.g., LIGO probability map). Enter "NONE" if unavailable."
        echo "input_ima_Phil: Phil's probability map (covolving the LIGO map with nearby galaxies). Enter "NONE" if unavailable."
        echo "########"
        echo "Example1:"
	echo "./transient_search.sh S190510g 2019-05-10T02:59:39.292 UTC 0.0 0.0 /local/data/bat2/batusers/batgroup/BAT_GW/results/S190510g/bayestar.fits.gz /local/data/bat2/batusers/batgroup/BAT_GW/results/S190510g/bayestar_convolved.fits.gz"
	echo "Example2:"
	echo "./transient_search.sh S190510g 579150002.200999975 MET 0.0 0.0 /local/data/bat2/batusers/batgroup/BAT_GW/results/S190510g/bayestar.fits.gz /local/data/bat2/batusers/batgroup/BAT_GW/results/S190510g/bayestar_convolved.fits.gz"
	exit 0
endif

set source_name = $argv[1]
set T0_input = $argv[2]
set T0_input_flag = $argv[3]
set src_RA = $argv[4]
set src_DEC = $argv[5]
set input_img = $argv[6] ## put in "NONE" of not available
set input_img_Phil = $argv[7] ## put in "NONE" of not available
set recent_source_flag = 1 ## 0: not a recent source (i.e., not using pass data att file and GCN Swift location); 1: recent source
set search_time_window = 30.0 ## [s]
set output_dir = /local/data/bat1/batusers/mcrnog/results/${source_name}
set healpy_flag = 0 ## 0: healpy map; 1:normal (i.e., BAT-image-like) fits file
set source_select_flag = 0 ## 0: randomly selected; 1: the true position of interest

# set up battools and batcaldb
#source /software/lheasoft/release/lhea.csh
source /local/data/bat1/batusers/mcrnog/headas_caldb_setup_GW.csh ## special one because need to refer to old xspec...

# set up anaconda environment
source /local/data/bat1/batusers/mcrnog/anaconda_setup.sh

## set special python path for kapteyn (installed locally, no glob permission)
source /local/data/bat1/batusers/mcrnog/code_Amy/code_copy_from_bat2/code/kapteyn-2.3

## Need to do this otherwise gets weird error about unable to write to /dev/tty when running in cron jobs
## Error message: Unable to redirect prompts to the /dev/tty (at headas_stdio.c:152)
setenv HEADASNOQUERY
setenv HEADASPROMPT /dev/null

## set up specific pfile location for this run
mkdir -p ${output_dir}/pfiles
setenv PFILES "${output_dir}/pfiles;${output_dir}/syspfiles"

## check if the script for this source is already running
## if so, need to wait until it's done
if (-e ${output_dir}/transient_search_running) then
	echo "transient_search for ${source_name} is still running....skip this run"
	exit 0
endif

touch ${output_dir}/transient_search_running

set info_file = ${output_dir}/info.txt

if ( -e ${info_file}) then
	/bin/rm ${info_file}
endif

if (! -d ${output_dir}) then
        mkdir ${output_dir}
endif

## add the nessary paths to the info files
echo "## This is a temporary file to store intermediate info of the script" >! ${info_file}
echo "pass_data_dir: /local/data/bat2/pass_data/2019" >> ${info_file} # change for different yrs
echo "att_folder: /local/data/bat2/transient_monitor/attitude" >> ${info_file}
echo "Swift_pointing_folder: /local/data/bat2/batusers/batgroup/BAT_GW/Swift_pointing" >> ${info_file}
echo "LIGO_notice_folder: /local/data/bat2/batusers/batgroup/BAT_GW/LIGO_notice" >> ${info_file}

echo "source_name: ${source_name}" >> ${info_file}

## (0.1) get necessary time
echo "Checking time...."
echo "T0_input: ${T0_input}" >> ${info_file}
echo "T0_input_flag: ${T0_input_flag}" >> ${info_file}
./get_time.sh ${info_file}

source /local/data/bat1/batusers/mcrnog/headas_caldb_setup_GW.csh ## special one because need to refer to old xspec...

## (0.2) see if pass data around T0 exist
## check if the pass data exist
set pass_data_dir = `cat ${info_file} | grep "pass_data_dir:" | awk '{print $2}'`
set year = `cat ${info_file} | grep "Year:" | awk '{print $2}'`
set day_of_year = `cat ${info_file} | grep "DOY:" | awk '{print $2}'`
set pass_data_flag = `ls -1d ${pass_data_dir}/pass_${year}${day_of_year}* | wc | awk '{print $1}'`
echo "pass_data_flag: ${pass_data_flag}" >> ${info_file}

echo "src_RA:" ${src_RA} >> ${info_file}
echo "src_DEC:" ${src_DEC} >> ${info_file}
echo "search_time_window:" ${search_time_window} >> ${info_file}
echo "output_dir:" ${output_dir} >> ${info_file}
echo "input_img:" ${input_img} >> ${info_file}
echo "input_img_Phil:" ${input_img_Phil} >> ${info_file}
echo "healpy_flag:" ${healpy_flag} >> ${info_file}
echo "source_select_flag:" ${source_select_flag} >> ${info_file}

#set T0_10s_ago = `cat ${info_file} | grep "T0:" | awk '{printf("%lf\n", $2-10.0)}'`
#echo "T0_10s_ago: ${T0_10s_ago}" >> ${info_file}
#set T0_10s_after = `cat ${info_file} | grep "T0:" | awk '{printf("%lf\n", $2+10.0)}'`
#echo "T0_10s_after: ${T0_10s_after}" >> ${info_file}

## (1) check whether the source is in the BAT FOV
echo "Updating Hans' attitude file...."
## (This is a cron job that runs every 10 min, and it takes < 1 min to finish, so let's just rerun it to make sure it's up-to-date)
/local/data/bat2/transient_monitor/monitor_software/get_attitude_WORK_cron.sh
/local/data/bat2/transient_monitor/monitor_software/get_attitude_WORK_cron.sh
##(somehow I seem to need to run it twice so the result be copied over to the final attitude folder, should double check this later)

python get_Earth_pos.py ${info_file} >> ${info_file}
echo "Checking BAT FOV..."
./check_BAT_fov.sh ${info_file}
#./check_BAT_fov_10s_ago.sh ${info_file}
#./check_BAT_fov_10s_after.sh ${info_file}

echo "Making FOV plot...."
#./make_FOV_plot_10s_ago.sh ${info_file}
#/bin/mv ${output_dir}/bat_fov.png ${output_dir}/bat_fov_10s_ago.png
#/bin/mv ${output_dir}/batfov.fits ${output_dir}/batfov_10s_ago.fits
#./make_FOV_plot_10s_after.sh ${info_file}
#/bin/mv ${output_dir}/bat_fov.png ${output_dir}/bat_fov_10s_after.png
#/bin/mv ${output_dir}/batfov.fits ${output_dir}/batfov_10s_after.fits
./make_FOV_plot.sh ${info_file}

set input_src_fov_flag = `cat ${info_file} | grep "input_src_FOV_flag:" | awk '{print $2}'`
set input_src_pcode = `cat ${info_file} | grep "input_src_pcode:" | awk '{print $2}'`
set input_img_fov_flag = `cat ${info_file} | grep "input_img_FOV_flag:" | awk '{print $2}'`

echo "Partial Coding Fraction of the input source = " ${input_src_pcode}

if (${input_src_fov_flag} == 0) then
	echo "Input source is out of the BAT FOV."
else
	echo "Input source is in the BAT FOV"
endif

if (${input_img_fov_flag} == 0) then
	echo "Input image does not overlap with the BAT FOV."
else
	echo "Input image overlaps with the BAT FOV."
endif

## (2) Do the data search (regardless of whether the the source/image are in the BAT FOV).

if (${pass_data_flag} == 0) then
        echo "No pass data yet"
else
	## (0) Make slew time interval
	./make_slew_gti.sh ${info_file}

	## check the raw light curve
	## (1) Taka's search using Carlo's trigger code
	./check_raw_lc.sh ${info_file}
	## (2) make rate light curve and find 5-sigma upper limit or detection
	## (for raw data, always set the search windwo to 900.0)
	./find_rate_data_two_days.sh ${info_file}

	## if rate data does not exist, print message
	set rate_flag = `cat ${output_dir}/match_quad_rate_list*.txt | wc | awk '{if ($1>3) print 1; else print 0}'`
	if (${rate_flag} == 0) then
		echo "WARNING: No rate data found."
	endif

	## check if event files exist
	./find_failed_evt_data_two_days.sh ${info_file}
	## writhe the evt_flag so the code knows whether evt file exist
	set evt_flag = `python get_evt_obsid.py ${info_file} | wc | awk '{if ($1>0) print 1; else print 0}'`

	## if event file exit, do evt analysis
	if (evt_flag == 0) then
		echo "No event file."
	else
		./evt_analysis.sh ${info_file}
	endif
endif

/bin/rm ${output_dir}/transient_search_running

#/bin/rm temp.txt

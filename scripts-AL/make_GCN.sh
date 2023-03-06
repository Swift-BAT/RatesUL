#!/bin/tcsh -f

set info_file = $argv[1]

set output_dir = `cat ${info_file} | grep "output_dir:" | awk '{print $2}'`

/bin/cp GCN_circ_template.txt ${output_dir}/GCN_circ.txt
set GCN = ${output_dir}/GCN_circ.txt

set source_name = `cat ${info_file} | grep "source_name:" | awk '{print $2}'`
sed -i -e "s/Xsource_nameX/${source_name}/g" ${GCN}

set T0_UTC = `cat ${info_file} | grep "time_UTC:" | awk '{print $2}'`
sed -i -e "s/XT0_UTCX/${T0_UTC}/g" ${GCN}

set BAT_RA = `cat ${info_file} | grep "BAT_RA:" | awk '{printf("%.3lf\n", $2)}'`
set BAT_DEC = `cat ${info_file} | grep "BAT_DEC:" | awk '{printf("%.3lf\n", $2)}'`
set BAT_ROLL = `cat ${info_file} | grep "BAT_ROLL:" | awk '{printf("%.3lf\n", $2)}'`

sed -i -e "s/XRAX/${BAT_RA}/g" ${GCN}
sed -i -e "s/XDECX/${BAT_DEC}/g" ${GCN}
sed -i -e "s/XROLLX/${BAT_ROLL}/g" ${GCN}

set FOV_OVERLAP = `cat ${info_file} | grep "LIGO_prob_in_BAT_FOV:" | awk '{printf("%.2lf\n", $2*100.0)}'`

sed -i -e "s/XFOV_OVERLAPX/${FOV_OVERLAP}/g" ${GCN}

set FOV_GALAXY = `cat ${info_file} | grep "Phil_prob_in_BAT_FOV:" | awk '{printf("%.2lf\n", $2*100.0)}'`

sed -i -e "s/XFOV_GALAXYX/${FOV_GALAXY}/g" ${GCN}

set FLUX_LIMIT = `cat ${info_file} | grep "flux_upper_limit:" | awk '{printf("%.2e\n", $2)}'`
set FLUX_LIMIT_NUM = `echo ${FLUX_LIMIT} | awk -F "e" '{print $1}'`
set FLUX_LIMIT_POW = `echo ${FLUX_LIMIT} | awk -F "e" '{printf("%d\n", $2)}'`
sed -i -e "s/XFLUX_LIMIT_NUMX/${FLUX_LIMIT_NUM}/g" ${GCN}
sed -i -e "s/XFLUX_LIMIT_POWX/${FLUX_LIMIT_POW}/g" ${GCN}

set DIST_LIMIT = `cat ${info_file} | grep "Luminosity distance for flux limit (low Liso):" | awk '{print $8}'`
sed -i -e "s/XDIST_LIMITX/${DIST_LIMIT}/g" ${GCN}

set OUT_OF_FOV = `cat ${info_file} | grep "prob_out_BAT_FOV_not_in_Earth_limb:" | awk '{printf("%.2lf\n", $2*100.0)}'`
sed -i -e "s/XOUT_OF_FOVX/${OUT_OF_FOV}/g" ${GCN}

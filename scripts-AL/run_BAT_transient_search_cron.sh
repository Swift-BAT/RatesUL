#!/bin/tcsh -f

## This is a cron job search for new GW source in the result folder (created by run_trigger_BAT_transient_search_cron.sh)
## and run transient_search for 10 passes
## Amy (2019.03.31)

set filetime = `date +%F`

set log = /local/data/bat2/batusers/batgroup/BAT_GW/code/cron_log/run_BAT_transient_search_cron_${filetime}.log

/local/data/bat2/batusers/batgroup/BAT_GW/code/BAT_transient_search_cron.sh >>& $log


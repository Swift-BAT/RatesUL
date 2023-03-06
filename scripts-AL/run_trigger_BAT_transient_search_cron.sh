#!/bin/tcsh -f

## This is a cron job that trigger on Phil's email, download Phil's file from the links in emails, 
##  and then start the transient_search.sh
## Amy (2019.02.02)

set filetime = `date +%F`

set log = /local/data/bat2/batusers/batgroup/BAT_GW/code/cron_log/run_trigger_BAT_transient_search_cron_${filetime}.log

/local/data/bat2/batusers/batgroup/BAT_GW/code/trigger_BAT_transient_search_cron.sh >>& $log


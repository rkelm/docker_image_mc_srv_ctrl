#!/bin/bash
# Stops a running server, saves active map to repository and clears data.

# Error handler.
errchk() {
  if [ ! $1 == 0 ] ; then
    echo '*** ERROR ***' 1>&2
    echo $2 1>&2
    echo 'Exiting.' 1>&2
    exit 1
  fi
}

path=$(dirname $0)

if [ ! -e ${path}/config.sh ] ; then
  echo Configuration file ${path}/config.sh not found.
  exit 1
fi

set -a
. $path/config.sh
set +a

# *** Check parameters / show usage. ***

if [ "$1" == "-h" ] ; then
    echo "usage: $(basename $0) [--dont_clear_dns] ";
    echo 'Stops currently active map and stores it in the repository.'
    echo 'Clears map_data, map_logs and data_store (subdomain.txt, map_id.txt).'
    echo '    --dont_clear_dns    Skips resetting subdomain in dns.'
    exit 1;
fi

_dont_clear_dns="$2"

if [ ! -e ${data_store}/map_id.txt ] ; then
    echo 'No map active. No map to stop or save.'
    exit 0
fi

_map_id=$( cat ${data_store}/map_id.txt )
_subdomain=$( cat ${data_store}/subdomain.txt )

# Test if app is running.
ps_id=$( map_data_dir=${map_data_dir} map_logs_dir=${map_logs_dir} ${docker_compose} -f "${map_data_dir}/docker-compose.yml" ps -q mc )

if [ -n "$ps_id" ]; then
    echo "Saving map $_map_id."
#    "$docker_compose" -f "${map_data_dir}/docker-compose.yml" exec  

    _command_cmd="${bin_dir}/app_cmd.sh"
    
    $_command_cmd "say Server_shutting_down_in_10_seconds!!"
    sleep 5
    $_command_cmd "say Server_shutting_down_in_5_seconds!!"
    sleep 2
    $_command_cmd "say Server_shutting_down_in_3_seconds!!"
    sleep 1
    $_command_cmd "say Server_shutting_down_in_2_seconds!!"
    sleep 1
    $_command_cmd "say Server_shutting_down_in_1_second!!"
    sleep 1
    $_command_cmd "save-all"

    echo 'Stopping Server.'
    $_command_cmd "stop"

    echo 'Terminating Server.'
    ${bin_dir}/compose_down.sh
else
    echo 'Server not running.'
fi

echo "Storing map $_map_id."
${bin_dir}/save_map.sh 
#${bin_dir}/map2s3.sh "${_map_id}" "${_subdomain}"
errchk $? "Error saving map $_map_id to s3."

echo Storing logs.
${bin_dir}/logs2s3.sh "${_map_id}"

${bin_dir}/clear_data.sh "$_dont_clear_dns"
errchk $? 'Could not clear old map data, logs and dns.'

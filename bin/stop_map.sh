#!/bin/bash
# Stops a running server, saves active map to repository and clears data.

# Copy stdout and stderr via named pipe to stdout of container for logging.
_fifo="/container_stdout"
exec >  >(tee -ia "$_fifo")
exec 2> >(tee -ia "$_fifo" >&2)

# Log call and parameters.
echo "\"$0 $@\" called" > "$_fifo"

# Error hangdler.
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
    echo 'Clears map_data and data_store (subdomain.txt, map_id.txt).'
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
ps_id=$( map_data_dir=${map_data_dir} ${docker_compose} -f "${map_data_dir}/docker-compose.yml" ps -q mc )

if [ -n "$ps_id" ]; then
    echo "Announcing stop of world to players ($_map_id)."
#    "$docker_compose" -f "${map_data_dir}/docker-compose.yml" exec  

    _command_cmd="${bin_dir}/app_cmd.sh"
    $_command_cmd 'say Server shutting down in 10 seconds!!'
    echo 'say Server shutting down in 10 seconds!!'
    sleep 5
    $_command_cmd 'say Server shutting down in 5 seconds!!'
    echo 'say Server shutting down in 5 seconds!!'
    sleep 2
    $_command_cmd 'say Server shutting down in 3 seconds!!'
    echo 'say Server shutting down in 3 seconds!!'
    sleep 1
    $_command_cmd 'say Server shutting down in 2 seconds!!'
    echo 'say Server shutting down in 2 seconds!!'
    sleep 1
    $_command_cmd 'say Server shutting down in 1 second!!'
    echo 'say Server shutting down in 1 second!!'
    sleep 1
    
    $_command_cmd "save-all"

    echo 'Terminating Server.'
    ${bin_dir}/compose_down.sh
else
    echo 'Server not running.'
fi

echo "Storing map with map id $_map_id."
${bin_dir}/save_map.sh 
#${bin_dir}/map2s3.sh "${_map_id}" "${_subdomain}"
errchk $? "Error saving map with map id $_map_id to s3."

${bin_dir}/clear_data.sh "$_dont_clear_dns"
errchk $? 'Could not clear old map data and dns.'

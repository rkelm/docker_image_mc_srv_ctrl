#!/bin/bash
# Script to save an active map.

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

if [ ! -e ${path}/../config.sh ] ; then
  echo Configuration file ${path}/../config.sh not found.
  exit 1
fi

set -a
. $path/../config.sh
set +a

# *** Check parameters / show usage. ***

if [ "$1" == "-h" ] ; then
    echo "usage: $(basename $0)";
    echo 'Saves currently active map to the repository.'
    exit 1;
fi

_stopserver="$2"

if [ ! -e ${data_store}/map_id.txt ] ; then
    echo 'No map active. No map to stop or save.'
    exit 0
fi

_command_cmd="${bin_dir}/app_cmd.sh"

# Get current map infos.
_map_id=$( cat ${data_store}/map_id.txt )
_subdomain=$( cat ${data_store}/subdomain.txt )

# Test if app is running.
ps_id=$( map_data_dir=${map_data_dir} map_logs_dir=${map_logs_dir} ${docker_compose} -f "${map_data_dir}/docker-compose.yml" ps -q mc )

# Is server running?
if [ -n "$ps_id" ]; then
    echo "Server is running. Saving and deactivating auto-save."    
    $_command_cmd "save-all"
    $_command_cmd "save-off"
else
    echo 'Server not running.'
fi

echo "Storing map $_map_id."
${bin_dir}/map2s3.sh "${_map_id}" "${subdomain}"
_rc=$?
if [ -n "$ps_id" ]; then
    echo "Reactivating auto-save."
    $_command_cmd "save-on"
fi

errchk $_rc "Error saving map $_map_id to s3."

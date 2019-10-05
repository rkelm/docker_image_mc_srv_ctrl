#!/bin/bash
# if [ -z $1 ] ; then
#   echo "usage: sudo $(basename $0)"' <path to compose file>'
#   exit 1
# fi

path=$(dirname $0)

# Copy stdout and stderr via named pipe to stdout of container for logging.
_fifo="/container_stdout"
exec >  >(tee -ia "$_fifo")
exec 2> >(tee -ia "$_fifo" >&2)

_timing_sec_start=${SECONDS}
# Log call and parameters.
echo "[DEBUG] \"$0 $@\" called" > "$_fifo"

set -a
. $path/config.sh
set +a
# sudo map_data_dir="$map_data_dir" /usr/local/bin/docker-compose -f "${map_data_dir}/docker-compose.yml" down
"$docker_compose" -f "${map_data_dir}/docker-compose.yml" down &> "$_fifo"
echo "[DEBUG] $0 ending, exec time:" $(( SECONDS - _timing_sec_start )) "seconds"

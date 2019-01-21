#!/bin/bash
# if [ -z $1 ] ; then
#   echo "usage: sudo $(basename $0)"' <path to compose file>'
#   exit 1
# fi
path=$(dirname $0)
set -a
. $path/../config.sh
set +a
# sudo map_data_dir="$map_data_dir" map_logs_dir="$map_logs_dir" /usr/local/bin/docker-compose -f "${map_data_dir}/docker-compose.yml" down
"$docker_compose" -f "${map_data_dir}/docker-compose.yml" down

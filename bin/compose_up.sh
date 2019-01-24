#!/bin/bash
# if [ -z $1 ] ; then
#   echo "usage: sudo $(basename $0)"' <path to compose file>'
#   exit 1
# fi
path=$(dirname $0)
set -a
. $path/config.sh
set +a

# Login to private repository. Only when necessary?
docker_login=$(aws ecr get-login --region eu-central-1 --no-include-email)
$docker_login
if [ "$?" != "0" ]; then
  echo "Login to private respository failed."
fi

# Pass environment variables to sudo environment.
# sudo map_data_dir="$map_data_dir" map_logs_dir="$map_logs_dir" /usr/local/bin/docker-compose -f "${map_data_dir}/docker-compose.yml" up -d 
"$docker_compose" -f "${map_data_dir}/docker-compose.yml" up -d


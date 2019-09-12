#!/bin/bash
# Sends console command to map
# Error handler.
path=$(dirname $0)

# Copy stdout and stderr via named pipe to stdout of container for logging.
_fifo="/container_stdout"
exec >  >(tee -ia "$_fifo")
exec 2> >(tee -ia "$_fifo" >&2)

# Log call and parameters.
echo "\"$0 $@\" called" > "$_fifo"

if [ -z "$1" -o "$1" == "-h" ] ; then
    echo "usage: $(basename $0) <mc_cmd1> [<mc_cmd2>] [<mc_cmd3>] ..."
    echo "Sends commands to minecraft server."
    echo "Each command and its parameters MUST be enclosed by SINGLE QUOTES."
    exit
fi

if [ ! -e ${path}/config.sh ] ; then
  echo Configuration file ${path}/config.sh not found.
  exit 1
fi
set -a
. $path/config.sh
set +a

# ${map_data_dir}/bin/app_cmd.sh "$@"
#"$docker_compose" -f "${map_data_dir}/docker-compose.yml" exec -T mc app_cmd.sh "$@"

# Send each command with its parameters in a single call to the server.
for cmd in "$@" ; do
    "$docker_compose" -f "${map_data_dir}/docker-compose.yml" exec -T mc app_cmd.sh "$cmd"
done

# docker-compose exec always returns exit code 1 even though command succeeded.
# Overwrite with success code
w=1

#!/bin/ash
# Starts a dummy process to keep the image running.

# Log startup infos.
echo Starting dummy process for srv_ctrl_image.
echo "Environment:"
env | sort

# ec2 instance id
print_ec2_metadata() {
    echo -n "$1: "
    curl -s "http://169.254.169.254/latest/meta-data/$1"
    echo
}

echo "EC2 instance meta data:"
print_ec2_metadata instance-id
print_ec2_metadata instance-type
print_ec2_metadata iam/info
print_ec2_metadata ami-id
print_ec2_metadata security-groups
print_ec2_metadata public-ipv4
print_ec2_metadata public-hostname

sigterm_handler() {
    # app still running?
    echo "Caught SIGTERM signal."
    if test -n "$pid" ; then
	_out=$(ps -o pid | grep -w "$pid")
	if test "$_out"=="$pid" ; then
	    echo "Checking for active maps."
            "${INSTALL_DIR}/bin/stop_map.sh"
	    echo "Ending dummy process."
	    kill -s SIGINT "$pid"
	fi
    fi
}

# Trap sigterm sent by docker stop.
trap sigterm_handler SIGTERM

# Create named pipe for sending output to stdout of main container process for logging.
_fifo='/container_stdout'
[ -e "$_fifo" ] && rm "$_fifo"
mkfifo "$_fifo"

tail -n +1 -f "$_fifo" &

# Run app.
cd "$INSTALL_DIR"
echo "Starting dummy background process to keep container alive."
tail -f /dev/null &
pid="$!"
echo $pid > ${INSTALL_DIR}/pid.txt

# Wait until app dies.
echo "Waiting for exit of dummy background process."
wait "$pid"

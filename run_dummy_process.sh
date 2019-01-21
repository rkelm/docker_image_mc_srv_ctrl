#!/bin/ash
# Starts a dummy process to keep the image running.
# ToDo: Wait for all jobs to stop gracefully on trap SIGTERM. 

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

# Run app.
cd "$APP_DIR"
tail -f /dev/null &
pid="$!"
echo $pid > ${INSTALL_DIR}/pid.txt

# Wait until app dies.
wait "$pid"

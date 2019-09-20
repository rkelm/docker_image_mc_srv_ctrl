#!/bin/ash
# Script to gracefully stop dummy process.

_fifo=/container_stdout

echo "Gracefully stopping." > "$_fifo"
echo "Stopping and saving map." > "$_fifo"

# Shutdown a running mc server and save a map before shutdown (in case a map may be running).
"${INSTALL_DIR}/bin/stop_map.sh"

# Do we have a process id?
if test -e "${INSTALL_DIR}/pid.txt" ; then
    pid=$( cat "${INSTALL_DIR}/pid.txt" )
    echo "Waiting for process $pid to terminate..."
    sleep 1
    kill -s SIGINT "$pid"
    rm "${INSTALL_DIR}/pid.txt" > /dev/null
fi

#!/bin/ash
# Script to gracefully stop mc server.

echo "Gracefully stopping."
echo "Stopping and saving map."

# Shutdown running map before shutting down.
"${INSTALL_DIR}/bin/stop_map.sh"

# Do we have a process id?
if test -e "${INSTALL_DIR}/pid.txt" ; then
    pid=$( cat "${INSTALL_DIR}/pid.txt" )
    echo "Waiting for process $pid to terminate..."
    sleep 1
    kill -s SIGINT "$pid"
    rm "${INSTALL_DIR}/pid.txt" > /dev/null
fi

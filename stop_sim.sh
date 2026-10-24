#!/bin/bash
# Stops every Gazebo, SITL and MAVProxy process plus their windows.
pkill -f '[s]im_vehicle.py'
pkill -f '[m]avproxy.py'
pkill -f '[b]uild/sitl/bin/ardu'
pkill -f '[x]term.*-T Drone'
pkill -f '[x]term.*ArduCopter'
pkill -f '[g]z sim'
sleep 2
pkill -9 -f '[b]uild/sitl/bin/ardu'
pkill -9 -f '[g]z sim'
if pgrep -f '[m]avproxy.py|[b]uild/sitl/bin/ardu|[g]z sim' > /dev/null; then
  echo "Some processes are still running:"
  pgrep -af '[m]avproxy.py|[b]uild/sitl/bin/ardu|[g]z sim'
else
  echo "Everything stopped."
fi

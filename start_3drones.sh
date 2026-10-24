#!/bin/bash
# Starts Gazebo with 3 Iris drones and one ArduCopter SITL per drone.
#   drone N  ->  SITL instance N-1, SYSID N, FDM port 9002+10*(N-1)
#   MAVLink for your code: udp:127.0.0.1:14561 / 14562 / 14563
SIM=$HOME/sim_drones
AP=$HOME/ardupilot
PARAMS="--add-param-file=$AP/Tools/autotest/default_params/copter.parm --add-param-file=$AP/Tools/autotest/default_params/gazebo-iris.parm"

"$SIM/stop_sim.sh" > /dev/null 2>&1

export GZ_SIM_RESOURCE_PATH=$SIM/models:$SIM/worlds:$GZ_SIM_RESOURCE_PATH

if [ ! -x "$AP/build/sitl/bin/arducopter" ]; then
  echo "Building ArduCopter SITL..."
  (cd "$AP" && ./waf configure --board sitl && ./waf copter) || exit 1
fi

mkdir -p "$SIM/logs"
echo "Starting Gazebo..."
gz sim -v3 -r iris_3drones.sdf > "$SIM/logs/gazebo.log" 2>&1 &
sleep 8

for n in 1 2 3; do
  i=$((n - 1))
  echo "Starting drone$n (instance $i, sysid $n)..."
  xterm -T "Drone$n" -xrm 'XTerm*selectToClipboard: true' -fa Monospace -fs 10 -geometry 100x25+$((i * 60))+$((i * 60)) -e bash -c "
    source $HOME/venv-ardupilot/bin/activate
    cd $AP
    $AP/Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON \
      -I$i --sysid $n -N -w --use-dir=$SIM/run/drone$n $PARAMS \
      --out=udp:127.0.0.1:$((14561 + i))
    echo; echo 'Drone$n stopped. Press Enter to close.'; read
  " &
  sleep 3
done

echo
echo "All started. Type commands in the Drone1/2/3 windows (e.g. mode guided, arm throttle, takeoff 10)."
echo "Stop everything with: ~/sim_drones/stop_sim.sh"

#!/bin/bash
# Creates iris_drone1..3 from ardupilot_gazebo's iris_with_ardupilot, each with its own FDM port
# and a downward-facing camera publishing on /droneN/down_camera.
set -e
SRC=$HOME/ardupilot_gazebo/models/iris_with_ardupilot
DST=$HOME/sim_drones/models

for i in 1 2 3; do
  port=$((9002 + (i - 1) * 10))
  dir=$DST/iris_drone$i
  mkdir -p "$dir"
  sed -e "s#<model name=\"iris_with_ardupilot\">#<model name=\"iris_drone$i\">#" \
      -e "s#<fdm_port_in>9002</fdm_port_in>#<fdm_port_in>$port</fdm_port_in>#" \
      "$SRC/model.sdf" > "$dir/model.sdf"
  sed -e "s#<name>Iris with ArduPilot</name>#<name>Iris drone $i</name>#" \
      "$SRC/model.config" > "$dir/model.config"

  # Camera link under the body; pitch 90 deg turns the camera's +X view axis straight down.
  camera=$(sed "s/DRONE/drone$i/g" <<'CAM'
    <link name="down_camera_link">
      <pose degrees="true">0 0 -0.08 0 90 0</pose>
      <inertial>
        <mass>0.01</mass>
        <inertia>
          <ixx>1e-6</ixx><iyy>1e-6</iyy><izz>1e-6</izz>
          <ixy>0</ixy><ixz>0</ixz><iyz>0</iyz>
        </inertia>
      </inertial>
      <visual name="visual">
        <geometry><box><size>0.02 0.04 0.04</size></box></geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
          <diffuse>0.1 0.1 0.1 1</diffuse>
        </material>
      </visual>
      <sensor name="down_camera" type="camera">
        <topic>DRONE/down_camera</topic>
        <camera>
          <horizontal_fov>1.2</horizontal_fov>
          <image>
            <width>640</width>
            <height>480</height>
          </image>
          <clip>
            <near>0.05</near>
            <far>1000</far>
          </clip>
        </camera>
        <always_on>1</always_on>
        <update_rate>30</update_rate>
        <visualize>1</visualize>
      </sensor>
    </link>

    <joint name="down_camera_joint" type="fixed">
      <parent>iris_with_standoffs::base_link</parent>
      <child>down_camera_link</child>
    </joint>

CAM
)
  CAMERA="$camera" python3 - "$dir/model.sdf" <<'PY'
import os, sys
path = sys.argv[1]
sdf = open(path).read()
i = sdf.rindex("  </model>")
open(path, "w").write(sdf[:i] + os.environ["CAMERA"] + "\n" + sdf[i:])
PY

  echo "iris_drone$i -> fdm_port_in $port, camera topic /drone$i/down_camera"
done

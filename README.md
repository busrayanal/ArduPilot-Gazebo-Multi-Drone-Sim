# ArduPilot + Gazebo Harmonic: 3-Drone Simulation (WSL2)

**English** | [Türkçe](README.tr.md)

An ArduPilot SITL + Gazebo Harmonic simulation running in Ubuntu 24.04 under WSL2 on Windows 11:

- **3 Iris quadcopters** in one world, each driven by its own ArduCopter SITL instance
- A **downward-facing camera** on every drone (640x480, 30 FPS)
- A **QR code** on the ground with a configurable message, plus an example Python script that reads it from the camera
- One-command start / stop

![QR code seen from a drone camera](docs/qr_camera.png)

---

## Contents

1. [Requirements](#1-requirements)
2. [Install WSL2 and Ubuntu 24.04](#2-install-wsl2-and-ubuntu-2404)
3. [Update the system](#3-update-the-system)
4. [Gazebo Harmonic](#4-gazebo-harmonic)
5. [GPU rendering (important)](#5-gpu-rendering-important)
6. [ArduPilot SITL](#6-ardupilot-sitl)
7. [ardupilot_gazebo plugin](#7-ardupilot_gazebo-plugin)
8. [Single-drone test](#8-single-drone-test)
9. [Install this repo](#9-install-this-repo)
10. [Usage](#10-usage)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Requirements

- Windows 11 (WSLg opens Linux GUI apps as normal windows)
- Virtualization enabled in BIOS/UEFI (Task Manager > Performance > CPU > "Virtualization: Enabled")
- ~30 GB free disk space
- An NVIDIA GPU is recommended (Intel/AMD work too, possibly slower)

Tested on: i7-12700H, 64 GB RAM, RTX 4060 Laptop, WSL 3.0.3, Ubuntu 24.04, Gazebo Harmonic (gz-sim 8).

## 2. Install WSL2 and Ubuntu 24.04

Open PowerShell **as Administrator** and run (`--location` is optional; use it to keep Ubuntu off the C: drive):

```powershell
wsl --install -d Ubuntu-24.04 --location D:\WSL\Ubuntu --version 2 --no-launch
```

The first run installs the WSL components and asks for a **reboot**. After rebooting, run **the same command again**. Check:

```powershell
wsl -l -v
```

You should see `Ubuntu-24.04` with `VERSION 2`.

Open **Ubuntu 24.04** from the Start menu and create a username (lowercase, no spaces or special characters) and password. The password is not echoed while typing; that is normal.

> WSL Ubuntu has no desktop, only a terminal. GUI programs like Gazebo open as regular Windows windows.

> In the terminal, **Ctrl+C does not copy; it stops the running program.** Use **Ctrl+Shift+C** / **Ctrl+Shift+V** or right-click.

## 3. Update the system

```bash
sudo apt update && sudo apt upgrade -y
```

## 4. Gazebo Harmonic

From the [official install page](https://gazebosim.org/docs/harmonic/install_ubuntu/):

```bash
sudo apt-get install -y curl lsb-release gnupg
sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update
sudo apt-get install -y gz-harmonic
```

## 5. GPU rendering (important)

WSL may render on the CPU (`llvmpipe`) by default, which makes Gazebo very slow. Check:

```bash
sudo apt-get install -y mesa-utils
glxinfo -B | grep "renderer string"
```

- `D3D12 (NVIDIA ...)`: you're good.
- `llvmpipe` or `D3D12 (Intel ...)` on a machine with an NVIDIA GPU:

```bash
cat >> ~/.bashrc <<'EOF'

# WSL: render with the NVIDIA GPU instead of llvmpipe
export GALLIUM_DRIVER=d3d12
export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
EOF
source ~/.bashrc
glxinfo -B | grep "renderer string"
```

It should now show `D3D12 (NVIDIA GeForce ...)`. The setting is permanent.

Test: `gz sim shapes.sdf` (close the window or press Ctrl+C in the terminal).

## 6. ArduPilot SITL

```bash
cd ~
sudo apt install -y git
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
cd ~/ardupilot
Tools/environment_install/install-prereqs-ubuntu.sh -y
```

When it finishes, **close and reopen the Ubuntu window.** The prompt should start with `(venv-ardupilot)`; ArduPilot's Python environment activates automatically. MAVProxy is installed in this step too.

Test without Gazebo:

```bash
cd ~/ardupilot/ArduCopter
sim_vehicle.py -w --console --map
```

At the `STABILIZE>` prompt:

```
mode guided
arm throttle
takeoff 10
```

`mode land` to land, Ctrl+C to quit.

> `Failed to download /SRTM3/...` is harmless (map terrain data).

## 7. ardupilot_gazebo plugin

[ArduPilot/ardupilot_gazebo](https://github.com/ArduPilot/ardupilot_gazebo):

```bash
sudo apt install -y libgz-sim8-dev rapidjson-dev libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

cd ~
git clone https://github.com/ArduPilot/ardupilot_gazebo
cd ardupilot_gazebo
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j8
```

Environment variables:

```bash
cat >> ~/.bashrc <<'EOF'

# ardupilot_gazebo
export GZ_VERSION=harmonic
export GZ_SIM_SYSTEM_PLUGIN_PATH=$HOME/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH
export GZ_SIM_RESOURCE_PATH=$HOME/ardupilot_gazebo/models:$HOME/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH
EOF
source ~/.bashrc
```

## 8. Single-drone test

Open two Ubuntu windows.

**Window 1:**

```bash
gz sim -v4 -r iris_runway.sdf
```

**Window 2:**

```bash
cd ~/ardupilot
sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON --map --console -w \
  --add-param-file=Tools/autotest/default_params/copter.parm \
  --add-param-file=Tools/autotest/default_params/gazebo-iris.parm
```

Then `mode guided`, `arm throttle`, `takeoff 10`.

> **Why `--add-param-file`?** As of October 2026, ArduPilot master looks up default parameters by the `--model JSON` name instead of the `-f gazebo-iris` frame, so the Iris parameters are not loaded and you get `PreArm: Motors: Check frame class and type`. Passing the parameter files explicitly fixes it. The scripts in this repo do this for you.

## 9. Install this repo

The scripts expect the repo at `~/sim_drones`:

```bash
cd ~
git clone https://github.com/busrayanal/ArduPilot-Gazebo-Multi-Drone-Sim.git sim_drones
cd ~/sim_drones
chmod +x *.sh
pip install qrcode
./setup_models.sh
```

`setup_models.sh` generates `iris_drone1..3` from ardupilot_gazebo's `iris_with_ardupilot`, each with its own FDM port and a downward camera.

## 10. Usage

### Start

```bash
~/sim_drones/start_3drones.sh
```

Gazebo opens, followed by **Drone1**, **Drone2** and **Drone3** windows. In each, at the `STABILIZE>` prompt:

```
mode guided
arm throttle
takeoff 10
```

If you get `PreArm` or `Accels inconsistent`, wait 10-20 seconds and repeat `arm throttle`.

### Stop

```bash
~/sim_drones/stop_sim.sh
```

You should see `Everything stopped.` Closing with Ctrl+C can leave ArduPilot processes running in the background; always use this script.

### Drones, ports, positions

| Drone | SITL instance | SYSID | Gazebo FDM port | MAVLink for your code | Camera topic | Position (Gazebo) |
|---|---|---|---|---|---|---|
| drone1 | 0 | 1 | 9002 | `udp:127.0.0.1:14561` | `/drone1/down_camera` | (0, 0) |
| drone2 | 1 | 2 | 9012 | `udp:127.0.0.1:14562` | `/drone2/down_camera` | (0, 4) |
| drone3 | 2 | 3 | 9022 | `udp:127.0.0.1:14563` | `/drone3/down_camera` | (0, 8) |

In Gazebo, +Y is north. Parameters are wiped on every start (`-w`) so every test begins from the same state.

### Viewing a camera

In Gazebo, open the **⋮** menu (top right), add **Image Display**, and pick `/drone1/down_camera`. On the ground the image is blurry (the camera is ~10 cm above the ground); it sharpens after takeoff.

### QR code

The QR code lies on the ground 20 m north of drone1 (4x4 m). To change the message (with the simulation stopped):

```bash
~/sim_drones/make_qr.sh "New message"
```

To read it, in a separate window:

```bash
python3 ~/sim_drones/examples/qr_oku.py 1
```

In the Drone1 window, fly over the QR code:

```
mode guided
arm throttle
takeoff 10
guided -35.363082 149.165237 10
```

The reader prints `drone1 QR: ...`.

> MAVProxy's `guided` takes **latitude longitude altitude**, not metres. `guided 20 0 10` sends the drone to latitude 20°, longitude 0°!

## 11. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `PreArm: Motors: Check frame class and type` | Iris parameters not loaded. See the `--add-param-file` note in [step 8](#8-single-drone-test). A leftover ArduPilot process can also cause it: run `stop_sim.sh`. |
| Gazebo is slow / stutters | Check `glxinfo -B` for `llvmpipe`, see [step 5](#5-gpu-rendering-important). |
| `ArduPilot controller has reset` (Gazebo terminal) | Normal a few times at startup. If it keeps scrolling during flight the link is dropping; stop and restart everything. |
| `Failed to download /SRTM3/...` | Harmless, ignore. |
| `DroneN stopped` in a drone window | Ctrl+C was pressed there. Restart with `stop_sim.sh` and `start_3drones.sh`. |
| Odd behaviour after closing | Background processes may be left over: `stop_sim.sh`. |

## Files

```
start_3drones.sh       Starts Gazebo + 3 SITL instances
stop_sim.sh            Stops everything
setup_models.sh        Generates iris_drone1..3 (port + camera)
make_qr.sh             Generates the QR texture
worlds/iris_3drones.sdf
models/qr_marker/      QR code model on the ground
examples/qr_oku.py     Example: read the QR code from a drone camera
```

## Credits

- [ArduPilot](https://github.com/ArduPilot/ardupilot) and [ardupilot_gazebo](https://github.com/ArduPilot/ardupilot_gazebo): the world file and Iris model are based on their `iris_runway.sdf` and `iris_with_ardupilot`.
- [Gazebo](https://gazebosim.org/)

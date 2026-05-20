# Robot-Measurement Project

## Folders


## Dependencies
```bash
git clone https://github.com/ciccio42/UR5e-2f-85.git
```

## Build docker from UR5e-Directory

### 1. ROS Image
```bash
cd UR5e-2f-85/docker
docker build -t ros2 . -f ros2Jazzy
# check ros2 container
xhost +local:docker
docker run -it --rm \
  --privileged \
  --net=host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  ros2

# inside container run
rviz2
```

### 2. UR-ROS2 
```bash
docker build -t ur_ros2 . -f URRos2
```

### 3. Sim-Robot
```bash
docker build -t ursim_e-series . -f UR_SIM
```

# How to run
## Sim Robot
```bash
# Create subnet
docker network create --subnet=192.168.56.0/24 ursim_net

# Run docker assigning IP, set ur5e
docker run --rm -it \
    -e ROBOT_MODEL=UR5e \
    --net ursim_net \
    --ip 192.168.56.101 \
    --privileged \
    --cap-add=NET_ADMIN \
    -p 5900:5900 -p 6080:6080 \
    -v /home/mi3000-2/Scrivania/Antenne_Robot/Antenna-Characterization-Robot-Arm/UR5e-2f-85/ur_programs:/ursim/programs \
    ursim_e-series


docker run -it --rm \
    --name ur_ros2 \
    --privileged \
    --net=ursim_net \
    -e DISPLAY=$DISPLAY \
    --ip 192.168.56.102 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /home/mi3000-2/Scrivania/Antenne_Robot/Antenna-Characterization-Robot-Arm/robot_calibration:/robot_calibration \
    ur_ros2:latest
```

```bash
# Only the first time
ros2 launch ur_calibration calibration_correction.launch.py \
  robot_ip:=192.168.56.101 \
  target_filename:="/robot_calibration/sim_calibration.yaml"

# Bring-UP Robot
ros2 launch ur_robot_driver ur_control.launch.py \
  ur_type:=ur5e \
  robot_ip:=192.168.56.101 \
  kinematics_params_file:=/robot_calibration/sim_calibration.yaml

# Run moveit-controller
ros2 launch ur_moveit_config ur_moveit.launch.py ur_type:=ur5e launch_rviz:=false use_fake_hardware:=true
```


## Real Robot




# Usefull commands
```bash
# Clean docker build cache
docker builder prune --all
# Clean dandling image
docker image prune -f
```

# ToDo
* [] Estimate TCP-Workload when Antenna is conncted
* [] Set DHCP (ubuntu site)
* [] Communication script with VM
* [] Compute Inverse Kinematics
* [] Control script package
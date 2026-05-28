from launch_ros.substitutions import FindPackageShare
from launch_ros.actions import Node

from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import PathJoinSubstitution, TextSubstitution, LaunchConfiguration


def generate_launch_description():
    
    ur_type = LaunchConfiguration("ur_type", default=TextSubstitution(text="ur5e"))
    robot_ip = LaunchConfiguration("robot_ip", default=TextSubstitution(text="192.168.56.101"))

    # Include UR launch
    ur_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution([
                FindPackageShare('ur_robot_driver'),
                'launch',
                'ur_rsp.launch.py'
            ])
        ),
        launch_arguments={
            'ur_type': ur_type,
            'robot_ip': robot_ip,
            'use_fake_hardware': 'false',
            'description_file': PathJoinSubstitution([
                FindPackageShare("ur5e_dual_horn_description"),
                'urdf',
                'ur5e_dual_horn.xacro'
            ]),
        }.items()
    )

    return LaunchDescription([
        ur_launch
    ])

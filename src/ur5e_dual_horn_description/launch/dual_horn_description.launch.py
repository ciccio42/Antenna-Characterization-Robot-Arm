from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import Command, FindExecutable, LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
	pkg_share = FindPackageShare('ur5e_dual_horn_description')
	xacro_file = PathJoinSubstitution([pkg_share, 'urdf', 'ur5e_dual_horn.xacro'])
	rviz_config = PathJoinSubstitution([pkg_share, 'rviz', 'dual_horn.rviz'])

	declare_name = DeclareLaunchArgument('name', default_value='ur', description='Robot name')
	declare_ur_type = DeclareLaunchArgument('ur_type', default_value='ur5e', description='UR robot type')
	declare_tf_prefix = DeclareLaunchArgument('tf_prefix', default_value='', description='Prefix for all TF links')
	declare_joint_limit_params = DeclareLaunchArgument('joint_limit_params', default_value=PathJoinSubstitution([FindPackageShare('ur_description'), 'config', 'ur5e', 'joint_limits.yaml']), description='Joint limits YAML')
	declare_kinematics_params = DeclareLaunchArgument('kinematics_params', default_value=PathJoinSubstitution([FindPackageShare('ur_description'), 'config', 'ur5e', 'default_kinematics.yaml']), description='Kinematics YAML')
	declare_physical_params = DeclareLaunchArgument('physical_params', default_value=PathJoinSubstitution([FindPackageShare('ur_description'), 'config', 'ur5e', 'physical_parameters.yaml']), description='Physical parameters YAML')
	declare_visual_params = DeclareLaunchArgument('visual_params', default_value=PathJoinSubstitution([FindPackageShare('ur_description'), 'config', 'ur5e', 'visual_parameters.yaml']), description='Visual parameters YAML')
	declare_use_fake_hardware = DeclareLaunchArgument('use_fake_hardware', default_value='true', description='Use fake hardware')
	declare_com_port = DeclareLaunchArgument('com_port', default_value='/dev/ttyUSB0', description='Robot COM port')
	declare_parent = DeclareLaunchArgument('parent', default_value='world', description='Parent frame for the UR base')
	declare_mount_xyz = DeclareLaunchArgument('mount_xyz', default_value='0 0 0.037', description='XYZ mount offset')
	declare_mount_rpy = DeclareLaunchArgument('mount_rpy', default_value='0 -3.14159 1.5708', description='RPY mount rotation')
	declare_use_rviz = DeclareLaunchArgument('use_rviz', default_value='true', description='Start RViz2')
	declare_use_joint_state_gui = DeclareLaunchArgument('use_joint_state_gui', default_value='true', description='Start joint state GUI')

	xacro_cmd = Command([
		FindExecutable(name='xacro'), ' ',
		xacro_file,
		' ', 'name:=', LaunchConfiguration('name'),
		' ', 'ur_type:=', LaunchConfiguration('ur_type'),
		' ', 'tf_prefix:=', LaunchConfiguration('tf_prefix'),
		' ', 'joint_limit_params:=', LaunchConfiguration('joint_limit_params'),
		' ', 'kinematics_params:=', LaunchConfiguration('kinematics_params'),
		' ', 'physical_params:=', LaunchConfiguration('physical_params'),
		' ', 'visual_params:=', LaunchConfiguration('visual_params'),
		' ', 'use_fake_hardware:=', LaunchConfiguration('use_fake_hardware'),
		' ', 'com_port:=', LaunchConfiguration('com_port'),
		' ', 'parent:=', LaunchConfiguration('parent'),
		' ', 'mount_xyz:="', LaunchConfiguration('mount_xyz'), '"',
		' ', 'mount_rpy:="', LaunchConfiguration('mount_rpy'), '"',
	])

	robot_description = {'robot_description': ParameterValue(xacro_cmd, value_type=str)}

	joint_state_publisher_gui_node = Node(
		package='joint_state_publisher_gui',
		executable='joint_state_publisher_gui',
		name='joint_state_publisher_gui',
		output='screen',
		condition=IfCondition(LaunchConfiguration('use_joint_state_gui')),
	)

	robot_state_pub_node = Node(
		package='robot_state_publisher',
		executable='robot_state_publisher',
		name='robot_state_publisher',
		output='screen',
		parameters=[robot_description],
	)

	rviz_node = Node(
		package='rviz2',
		executable='rviz2',
		name='rviz2',
		output='screen',
		arguments=['-d', rviz_config],
		condition=IfCondition(LaunchConfiguration('use_rviz')),
	)

	return LaunchDescription([
		declare_name,
		declare_ur_type,
		declare_tf_prefix,
		declare_joint_limit_params,
		declare_kinematics_params,
		declare_physical_params,
		declare_visual_params,
		declare_use_fake_hardware,
		declare_com_port,
		declare_parent,
		declare_mount_xyz,
		declare_mount_rpy,
		declare_use_rviz,
		declare_use_joint_state_gui,
		joint_state_publisher_gui_node,
		robot_state_pub_node,
		rviz_node,
	])


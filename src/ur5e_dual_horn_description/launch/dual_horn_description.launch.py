from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import Command, LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
	pkg_share = FindPackageShare('ur5e_dual_horn_description')
	xacro_file = PathJoinSubstitution([pkg_share, 'urdf', 'dual_horn.urdf.xacro'])
	rviz_config = PathJoinSubstitution([pkg_share, 'rviz', 'dual_horn.rviz'])

	declare_parent = DeclareLaunchArgument('parent_link', default_value='tool0', description='Parent link to attach the antenna')
	declare_prefix = DeclareLaunchArgument('prefix', default_value='', description='Name prefix for links/joints')
	declare_mesh = DeclareLaunchArgument('mesh_file', default_value='package://ur5e_dual_horn_description/meshes/dual_horn.stl', description='Mesh file for the dual horn')
	declare_mount_xyz = DeclareLaunchArgument('mount_xyz', default_value='0 0 0.037', description='XYZ mount offset')
	declare_mount_rpy = DeclareLaunchArgument('mount_rpy', default_value='0 0 0', description='RPY mount rotation')
	declare_use_rviz = DeclareLaunchArgument('use_rviz', default_value='true', description='Start RViz2')

	xacro_cmd = Command([
		'xacro', ' ',
		xacro_file,
		' ', 'parent_link:=', LaunchConfiguration('parent_link'),
		' ', 'prefix:=', LaunchConfiguration('prefix'),
		' ', 'mesh_file:=', LaunchConfiguration('mesh_file'),
		' ', 'mount_xyz:="', LaunchConfiguration('mount_xyz'), '"',
		' ', 'mount_rpy:="', LaunchConfiguration('mount_rpy'), '"',
	])

	robot_state_pub_node = Node(
		package='robot_state_publisher',
		executable='robot_state_publisher',
		name='robot_state_publisher',
		output='screen',
		parameters=[{'robot_description': xacro_cmd}],
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
		declare_parent,
		declare_prefix,
		declare_mesh,
		declare_mount_xyz,
		declare_mount_rpy,
		declare_use_rviz,
		robot_state_pub_node,
		rviz_node,
	])


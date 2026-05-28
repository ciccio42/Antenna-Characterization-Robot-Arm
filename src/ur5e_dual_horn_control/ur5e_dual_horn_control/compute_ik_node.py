from __future__ import annotations

from typing import List

import rclpy
from rclpy.node import Node

from .points_parser import PointTuple, parse_points_file


class ComputeIK(Node):
    """ROS 2 node that reads a points file and stores parsed tuples."""

    def __init__(self) -> None:
        super().__init__("compute_ik_node")
        self.declare_parameter("points_file", "")

        points_file = self.get_parameter("points_file").get_parameter_value().string_value
        if not points_file:
            self.get_logger().error("Parameter 'points_file' is empty")
            self.points: List[PointTuple] = []
            return

        self.points = parse_points_file(points_file)
        self.get_logger().info(f"{self.points}")
        self.get_logger().info(
            f"Loaded {len(self.points)} points from '{points_file}'"
        )

        

def main(args=None) -> None:
    rclpy.init(args=args)
    node = ComputeIK()
    try:
        rclpy.spin_once(node, timeout_sec=0.1)
    finally:
        node.destroy_node()
        rclpy.shutdown()

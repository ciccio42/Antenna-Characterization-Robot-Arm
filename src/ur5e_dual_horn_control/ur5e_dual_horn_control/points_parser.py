from __future__ import annotations

from pathlib import Path
from typing import List, Tuple


PointTuple = Tuple[float, float, float]


def parse_points_file(file_path: str | Path) -> List[PointTuple]:
    """Parse a points text file into a list of (theta, phi, delt) tuples."""
    points: List[PointTuple] = []
    path = Path(file_path)

    with path.open("r", encoding="utf-8", errors="ignore") as file_handle:
        for raw_line in file_handle:
            line = raw_line.strip()
            if not line:
                continue
            if line.startswith("-"):
                continue

            parts = line.split()
            if len(parts) < 3:
                continue

            try:
                theta = float(parts[0])
                phi = float(parts[1])
                delt = float(parts[2])
            except ValueError:
                continue

            points.append((theta, phi, delt))

    return points

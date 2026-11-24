#!/usr/bin/env python3
"""Compact the original Motion Coach pose recordings for offline app tests."""

import argparse
import gzip
import hashlib
import json
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
OUTPUT = APP / "test/fixtures/motion-replays.v1.json.gz"


def compact_stream(path: Path, stride: int, provenance: str) -> dict:
    raw = path.read_bytes()
    capture = json.loads(raw)
    frames = []
    for frame in capture["frames"][::stride]:
        points = frame["landmarks"]
        if len(points or ()) != 33:
            frames.append([frame["timestamp_ms"], None])
            continue
        packed = [
            value
            for point in points
            for value in (
                round(point["x"] * 10_000),
                round(point["y"] * 10_000),
                round(point["z"] * 10_000),
                round(point["visibility"] * 1000),
            )
        ]
        frames.append([frame["timestamp_ms"], packed])
    return {
        "provenance": provenance,
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "frames": frames,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "engine", type=Path, nargs="?", default=APP.parent / "motion-coach-cv"
    )
    args = parser.parse_args()

    exercises = {}
    golden = args.engine / "fixtures/golden"
    captures = args.engine / "data/captured-references"
    for synthetic in sorted(golden.glob("*.pose-stream.v1.json")):
        exercise_id = synthetic.name.split(".", 1)[0]
        if exercise_id.endswith("_jitter"):
            continue
        replays = {"synthetic": compact_stream(synthetic, 1, "analytic_body")}
        captured = captures / f"{exercise_id}.reference-loop.v1.json"
        if captured.is_file():
            replays["nia"] = compact_stream(captured, 2, "nia_exercise_video")
        exercises[exercise_id] = replays
    if not exercises:
        parser.error(f"No Motion Coach golden pose streams under {golden}")
    if sum("nia" in replays for replays in exercises.values()) != 8:
        parser.error(f"Expected eight NIA pose captures under {captures}")

    data = json.dumps(
        {"version": 1, "exercises": exercises}, separators=(",", ":")
    ).encode()
    with OUTPUT.open("wb") as file, gzip.GzipFile(
        filename="", mode="wb", fileobj=file, mtime=0
    ) as archive:
        archive.write(data)
    print(f"Wrote {OUTPUT.relative_to(APP)} ({OUTPUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()

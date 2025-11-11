#!/usr/bin/env python3
"""
Example: Receive Apple Watch sensor data from the arvos iPhone app.

Usage:
    pip install websockets
    python examples/watch_watch_stream.py --host 192.168.1.42 --port 9090

The script connects to the iPhone's websocket, decodes JSON messages,
and prints Apple Watch streams (IMU, attitude, motion activity).
"""

import argparse
import asyncio
import base64
import json
from typing import Any, Dict

import websockets


def decode_payload(message: Dict[str, Any]) -> Dict[str, Any]:
    """Decode the base64 payload from a JSON message."""
    payload_b64 = message.get("payload")
    if payload_b64 is None:
        return {}
    payload_bytes = base64.b64decode(payload_b64)
    if not payload_bytes:
        return {}
    return json.loads(payload_bytes.decode("utf-8"))


def format_watch_message(message: Dict[str, Any]) -> str:
    """Pretty-print watch-specific sensor messages."""
    msg_type = message.get("type")
    payload = decode_payload(message)

    if msg_type == "watch_imu":
        angular = payload.get("angularVelocity", [])
        linear = payload.get("linearAcceleration", [])
        return (
            f"[IMU] ω=({angular[0]:+.3f}, {angular[1]:+.3f}, {angular[2]:+.3f}) rad/s "
            f"a=({linear[0]:+.3f}, {linear[1]:+.3f}, {linear[2]:+.3f}) m/s²"
        )

    if msg_type == "watch_attitude":
        pitch = payload.get("pitch", 0.0)
        roll = payload.get("roll", 0.0)
        yaw = payload.get("yaw", 0.0)
        return (
            f"[ATTITUDE] pitch={pitch:+.3f} rad, roll={roll:+.3f} rad, yaw={yaw:+.3f} rad"
        )

    if msg_type == "watch_activity":
        confidence = payload.get("confidence", 0)
        flags = [
            label
            for label, flag in (
                ("walking", payload.get("isWalking")),
                ("running", payload.get("isRunning")),
                ("cycling", payload.get("isCycling")),
                ("vehicle", payload.get("isDriving")),
                ("stationary", payload.get("isStationary")),
            )
            if flag
        ]
        label = flags[0] if flags else "unknown"
        confidence_label = {0: "low", 1: "medium", 2: "high"}.get(confidence, "?")
        return f"[ACTIVITY] {label} (confidence: {confidence_label})"

    return ""


async def stream_watch_data(host: str, port: int) -> None:
    uri = f"ws://{host}:{port}"
    print(f"Connecting to {uri} ...")

    async with websockets.connect(uri) as websocket:
        print("Connected. Waiting for watch sensor data...\n")

        async for raw_message in websocket:
            try:
                message = json.loads(raw_message)
            except json.JSONDecodeError:
                continue

            msg_type = message.get("type")
            if not msg_type:
                continue

            if msg_type.startswith("watch_"):
                pretty = format_watch_message(message)
                if pretty:
                    timestamp = message.get("timestampNs", 0)
                    print(f"{timestamp}: {pretty}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Receive Apple Watch sensor data from arvos iPhone app"
    )
    parser.add_argument("--host", required=True, help="IP address of the iPhone")
    parser.add_argument(
        "--port", type=int, default=9090, help="WebSocket port (default: 9090)"
    )

    args = parser.parse_args()
    try:
        asyncio.run(stream_watch_data(args.host, args.port))
    except KeyboardInterrupt:
        print("\nDisconnected.")


if __name__ == "__main__":
    main()


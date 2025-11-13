#!/usr/bin/env python3
"""
Run the MCAP streaming server to capture telemetry from the ARVOS app.

Usage:
    python3 examples/mcap_stream_server.py --host 0.0.0.0 --port 17500 --out mcap_logs
"""

import argparse
import asyncio
from pathlib import Path

from arvos.servers import MCAPStreamServer


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="ARVOS MCAP streaming server")
    parser.add_argument("--host", default="0.0.0.0", help="Host/IP to bind (default: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=17500, help="TCP port to listen on (default: 17500)")
    parser.add_argument("--out", type=Path, default=Path("mcap_logs"), help="Directory to store MCAP files")
    return parser.parse_args()


async def main() -> None:
    args = parse_args()
    server = MCAPStreamServer(host=args.host, port=args.port, output_dir=args.out)
    try:
        await server.start()
    except KeyboardInterrupt:
        print("Stopping MCAP server...")
        await server.stop()


if __name__ == "__main__":
    asyncio.run(main())



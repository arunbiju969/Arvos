#!/usr/bin/env python3
"""
Lightweight launcher for the ARVOS WebSocket server.

This script is invoked by `start-viewer.sh` to ensure the iOS app has a
WebSocket endpoint available while the static web viewer is running.
"""

import argparse
import asyncio
import os
import signal
import sys
from typing import Optional


def resolve_repo_root() -> str:
    """Return the absolute path to the arvos-sdk repo root."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, ".."))


def ensure_local_package_available(repo_root: str) -> None:
    """
    Make sure the local `python/` package directory is importable during
    development (when the package hasn't been installed via pip yet).
    """
    python_src = os.path.join(repo_root, "python")
    if os.path.isdir(python_src) and python_src not in sys.path:
        sys.path.insert(0, python_src)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the ARVOS WebSocket server.")
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host interface to bind (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8765,
        help="Port to bind the WebSocket server (default: 8765)",
    )
    return parser


async def main(host: str, port: int) -> None:
    from arvos import ArvosServer  # noqa: WPS433 (import inside function)

    server = ArvosServer(host=host, port=port)

    # Suppress the ASCII QR code printing (web viewer already shows a QR code).
    server.print_qr_code = lambda: None  # type: ignore[assignment]

    async def handle_connect(client_id: str) -> None:
        print(f"✅ ARVOS iOS connected: {client_id}")

    async def handle_disconnect(client_id: str) -> None:
        print(f"👋 ARVOS iOS disconnected: {client_id}")

    server.on_connect = handle_connect
    server.on_disconnect = handle_disconnect

    print(f"🔌 Starting ARVOS WebSocket server on {host}:{port}")
    await server.start()


def run() -> None:
    repo_root = resolve_repo_root()
    ensure_local_package_available(repo_root)

    parser = build_parser()
    args = parser.parse_args()

    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        # Graceful shutdown on SIGINT/SIGTERM
        stop_event = asyncio.Event()

        def _signal_handler(_: int, __: Optional[object]) -> None:
            stop_event.set()

        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, _signal_handler)

        async def runner() -> None:
            server_task = asyncio.create_task(main(args.host, args.port))
            await stop_event.wait()
            server_task.cancel()
            try:
                await server_task
            except asyncio.CancelledError:
                pass

        loop.run_until_complete(runner())
    except KeyboardInterrupt:
        pass
    finally:
        try:
            loop.close()
        except Exception:  # noqa: BLE001
            pass
        print("🛑 ARVOS WebSocket server stopped")


if __name__ == "__main__":
    run()


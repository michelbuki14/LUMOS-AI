#!/usr/bin/env python3
"""LUMOS AI — Local Development Launcher
Runs everything with SQLite (no Docker/PostgreSQL/Redis needed).
"""
import os
import sys
import subprocess
import time
import signal
from pathlib import Path

BASE_DIR = Path(__file__).parent
STORAGE_DIR = BASE_DIR / "storage"
EXPORTS_DIR = BASE_DIR / "exports"
MODELS_DIR = BASE_DIR / "models"

# Create directories
for d in [STORAGE_DIR, EXPORTS_DIR, MODELS_DIR]:
    d.mkdir(exist_ok=True)

os.environ.setdefault("LUMOS_ENV", "local")
os.environ.setdefault("DATABASE_URL", f"sqlite+aiosqlite:///{BASE_DIR}/lumos_local.db")
os.environ.setdefault("STORAGE_DIR", str(STORAGE_DIR))
os.environ.setdefault("EXPORT_DIR", str(EXPORTS_DIR))
os.environ.setdefault("MODEL_DIR", str(MODELS_DIR))
os.environ.setdefault("JWT_SECRET", "local_dev_secret_not_for_production")
os.environ.setdefault("API_PORT", "8000")
os.environ.setdefault("AI_PORT", "8001")
os.environ.setdefault("RENDER_PORT", "8002")


def start_api():
    """Start the FastAPI backend."""
    env = os.environ.copy()
    env["PYTHONPATH"] = str(BASE_DIR / "services" / "api")
    cmd = [
        sys.executable, "-m", "uvicorn",
        "lumos.app:app",
        "--host", "0.0.0.0",
        "--port", env["API_PORT"],
        "--reload",
    ]
    return subprocess.Popen(
        cmd, cwd=str(BASE_DIR / "services" / "api"), env=env
    )


def start_ai():
    """Start the AI inference service."""
    env = os.environ.copy()
    env["PYTHONPATH"] = str(BASE_DIR / "services" / "ai")
    cmd = [
        sys.executable, "-m", "uvicorn",
        "lumos.ai.app:app",
        "--host", "0.0.0.0",
        "--port", env["AI_PORT"],
    ]
    return subprocess.Popen(
        cmd, cwd=str(BASE_DIR / "services" / "ai"), env=env
    )


def wait_for_health(url, timeout=30):
    """Wait for a service to become healthy."""
    import urllib.request
    start = time.time()
    while time.time() - start < timeout:
        try:
            req = urllib.request.Request(url, method="GET")
            with urllib.request.urlopen(req, timeout=2) as resp:
                if resp.status == 200:
                    return True
        except Exception:
            pass
        time.sleep(0.5)
    return False


def main():
    print("=" * 50)
    print("  LUMOS AI — Local Development Server")
    print("=" * 50)
    print()

    processes = []

    def cleanup(sig, frame):
        print("\nShutting down...")
        for p in processes:
            try:
                p.terminate()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)

    # Start API
    print("[1/2] Starting API server on http://localhost:8000...")
    api_proc = start_api()
    processes.append(api_proc)

    if wait_for_health("http://localhost:8000/health"):
        print("       API ready! Docs at http://localhost:8000/docs")
    else:
        print("       API failed to start")
        cleanup(None, None)

    # Start AI service
    print("[2/2] Starting AI service on http://localhost:8001...")
    ai_proc = start_ai()
    processes.append(ai_proc)

    if wait_for_health("http://localhost:8001/health"):
        print("       AI service ready!")
    else:
        print("       AI service failed to start")

    print()
    print("=" * 50)
    print("  LUMOS AI is running!")
    print("  API:    http://localhost:8000/docs")
    print("  AI:     http://localhost:8001/docs")
    print("  Press Ctrl+C to stop")
    print("=" * 50)

    # Wait for processes
    try:
        while True:
            for p in processes:
                ret = p.poll()
                if ret is not None:
                    print(f"Process exited with code {ret}")
                    cleanup(None, None)
            time.sleep(1)
    except KeyboardInterrupt:
        cleanup(None, None)


if __name__ == "__main__":
    main()

#!/usr/bin/env bash
# ============================================================
#  Quadra-Seer Sovereign — Flash Drive Installer (macOS / Linux)
#
#  Plug in the flash drive, run:  ./install.sh
#
#  First run takes 15-30 minutes (mostly downloading Python and
#  Node packages). It runs unattended — walk away and come back.
#  Every launch after that is instant.
#
#  What it does:
#    0. Checks for Python 3.10+ and Node.js
#    1. Installs Ollama (from the drive if bundled, or downloads it)
#    2. Loads the AI model (from the drive if bundled, or pulls it)
#    3. Sets up Python + Node dependencies
#    4. Launches Quadra-Seer Sovereign in your browser
#
#  Everything runs on YOUR machine. No cloud. No account.
# ============================================================
set -euo pipefail

DRIVE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$DRIVE/app"
VENDOR_DIR="$DRIVE/vendor"
MODEL="qwen2.5:3b"
# The build script records which model it bundled; that wins over the default.
[[ -f "$VENDOR_DIR/model.txt" ]] && MODEL="$(tr -d ' \t\r\n' < "$VENDOR_DIR/model.txt")"

echo ""
echo "============================================================"
echo "  QUADRA-SEER SOVEREIGN — Flash Drive Installer"
echo "============================================================"
echo ""
echo "  Drive: $DRIVE"
echo "  Model: $MODEL"
echo ""

# ── Step 0: Prerequisites ───────────────────────────────────
echo "[0/4] Checking prerequisites..."
if ! command -v python3 &>/dev/null; then
    echo ""
    echo "  ERROR: Python 3.10+ is not installed."
    echo "    macOS: brew install python@3.12"
    echo "    Linux: sudo apt install python3 python3-venv   (or your distro's equivalent)"
    exit 1
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'; then
    echo ""
    echo "  ERROR: Python 3.10+ is required (found $(python3 --version))."
    exit 1
fi
echo "  $(python3 --version) found."
if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    echo ""
    echo "  ERROR: Node.js is not installed."
    echo "  Get the LTS release from https://nodejs.org/ and re-run this installer."
    exit 1
fi
echo "  $(node --version) found."

# ── Step 1: Ollama ──────────────────────────────────────────
echo ""
echo "[1/4] Checking for Ollama..."
if ! command -v ollama &>/dev/null; then
    if [[ -d "$VENDOR_DIR/ollama" ]]; then
        echo "  Installing Ollama from flash drive (offline)..."
        case "$(uname -s)" in
            Darwin)
                if [[ -f "$VENDOR_DIR/ollama/Ollama-darwin.zip" ]]; then
                    unzip -q -o "$VENDOR_DIR/ollama/Ollama-darwin.zip" -d "$VENDOR_DIR/ollama/"
                fi
                # The .zip contains Ollama.app; the CLI lives in its Resources dir
                export PATH="$VENDOR_DIR/ollama/Ollama.app/Contents/Resources:$PATH"
                ;;
            Linux)
                if [[ ! -x "$VENDOR_DIR/ollama/bin/ollama" && -f "$VENDOR_DIR/ollama/ollama-linux.tgz" ]]; then
                    # The tarball contains bin/ollama — extract one level up
                    tar -xzf "$VENDOR_DIR/ollama/ollama-linux.tgz" -C "$VENDOR_DIR/ollama"
                fi
                export PATH="$VENDOR_DIR/ollama/bin:$PATH"
                ;;
        esac
    else
        echo "  Ollama not found — installing (internet required)..."
        case "$(uname -s)" in
            Darwin)
                if command -v brew &>/dev/null; then
                    brew install ollama
                else
                    echo "  Homebrew not found. Downloading Ollama..."
                    curl -fsSL https://ollama.com/download/Ollama-darwin.zip -o /tmp/Ollama-darwin.zip
                    unzip -q -o /tmp/Ollama-darwin.zip -d /Applications/
                fi
                ;;
            Linux)
                curl -fsSL https://ollama.com/install.sh | sh
                ;;
        esac
    fi
fi

if ! command -v ollama &>/dev/null; then
    echo ""
    echo "  ERROR: Ollama installation failed."
    echo "  Install manually from https://ollama.com/download and re-run."
    exit 1
fi
echo "  Ollama ready."

# If the drive has a bundled model store, (re)start our own Ollama server
# pointed at it. A server started earlier (e.g. at login) would NOT see
# OLLAMA_MODELS exported here, so it must be restarted under our env.
if [[ -d "$VENDOR_DIR/models/manifests" ]]; then
    echo "  Using model bundled on flash drive (offline)..."
    export OLLAMA_MODELS="$VENDOR_DIR/models"
    pkill -f "ollama serve" 2>/dev/null || true
    sleep 2
fi

# Start Ollama in the background if not running
if ! ollama list &>/dev/null; then
    echo "  Starting Ollama..."
    ollama serve &>/dev/null &
fi
for _ in $(seq 1 12); do
    ollama list &>/dev/null && break
    sleep 5
done
if ! ollama list &>/dev/null; then
    echo ""
    echo "  ERROR: The Ollama server did not start. Try running"
    echo "  'ollama serve' in a terminal to see what is wrong."
    exit 1
fi

# ── Step 2: Model ───────────────────────────────────────────
echo ""
echo "[2/4] Checking for AI model ($MODEL)..."
if ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "  Model already available."
else
    echo "  Pulling model $MODEL (internet required, one time)..."
    ollama pull "$MODEL"
fi

# ── Step 3: App dependencies ─────────────────────────────────
echo ""
echo "[3/4] Setting up Quadra-Seer (this is the long step on first run)..."
cd "$APP_DIR"

if [[ ! -d ".venv" ]]; then
    echo "  Creating Python environment..."
    python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
echo "  Installing Python dependencies (several minutes, one time)..."
pip install -q -r requirements.txt
pip install -q "pyarrow==18.1.0"

if [[ ! -d "node_modules" ]]; then
    echo "  Installing Node dependencies..."
    npm install
fi

# ── Step 4: Launch ──────────────────────────────────────────
echo ""
echo "[4/4] Launching Quadra-Seer Sovereign..."
echo ""
echo "============================================================"
echo "  Starting backend (port 5001)..."
echo "============================================================"
( .venv/bin/python atlantean_backend.py > /tmp/quadra-backend.log 2>&1 & )
sleep 5

echo "  Starting frontend (port 5000)..."
( npm run dev > /tmp/quadra-frontend.log 2>&1 & )
sleep 8

echo ""
echo "============================================================"
echo "  QUADRA-SEER SOVEREIGN IS RUNNING"
echo ""
echo "  Open your browser to: http://localhost:5000"
echo ""
echo "  Everything runs on YOUR machine. No cloud. No account."
echo "  Logs: /tmp/quadra-backend.log, /tmp/quadra-frontend.log"
echo "============================================================"
echo ""

# Open browser if possible
case "$(uname -s)" in
    Darwin) open "http://localhost:5000" 2>/dev/null || true ;;
    Linux)  xdg-open "http://localhost:5000" 2>/dev/null || true ;;
esac

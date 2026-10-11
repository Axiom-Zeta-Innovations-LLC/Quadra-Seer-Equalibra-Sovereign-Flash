#!/usr/bin/env bash
# ============================================================
#  Quadra-Seer Sovereign — Flash Drive Installer (macOS / Linux)
#
#  Plug in the flash drive, run:  ./install.sh
#
#  What it does:
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
MODEL="${MODEL:-qwen2.5:3b}"

echo ""
echo "============================================================"
echo "  QUADRA-SEER SOVEREIGN — Flash Drive Installer"
echo "============================================================"
echo ""
echo "  Drive: $DRIVE"
echo ""

# ── Step 1: Ollama ──────────────────────────────────────────
echo "[1/4] Checking for Ollama..."
if ! command -v ollama &>/dev/null; then
    if [[ -d "$VENDOR_DIR/ollama" ]]; then
        echo "  Installing Ollama from flash drive (offline)..."
        case "$(uname -s)" in
            Darwin)
                # macOS: bundled .app or binary
                if [[ -f "$VENDOR_DIR/ollama/Ollama-darwin.zip" ]]; then
                    unzip -q -o "$VENDOR_DIR/ollama/Ollama-darwin.zip" -d "$VENDOR_DIR/ollama/"
                fi
                export PATH="$VENDOR_DIR/ollama/bin:$PATH"
                ;;
            Linux)
                # Linux: bundled binary
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
else
    echo "  Ollama already installed."
fi

if ! command -v ollama &>/dev/null; then
    # Last resort: try the vendored binary directly
    if [[ -x "$VENDOR_DIR/ollama/bin/ollama" ]]; then
        export PATH="$VENDOR_DIR/ollama/bin:$PATH"
    else
        echo ""
        echo "  ERROR: Ollama installation failed."
        echo "  Install manually from https://ollama.com/download and re-run."
        exit 1
    fi
fi

# If the drive has a bundled model store, point Ollama at it
if [[ -d "$VENDOR_DIR/models" ]]; then
    echo "  Using model bundled on flash drive (offline)..."
    export OLLAMA_MODELS="$VENDOR_DIR/models"
fi

# Start Ollama in the background if not running
if ! ollama list &>/dev/null; then
    echo "  Starting Ollama..."
    ollama serve &>/dev/null &
    sleep 3
fi

# ── Step 2: Model ───────────────────────────────────────────
echo ""
echo "[2/4] Checking for AI model ($MODEL)..."
if ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "  Model already available."
else
    echo "  Loading model (a few minutes on first run)..."
    ollama pull "$MODEL"
fi

# ── Step 3: App dependencies ─────────────────────────────────
echo ""
echo "[3/4] Setting up Quadra-Seer..."
cd "$APP_DIR"

if [[ ! -d ".venv" ]]; then
    echo "  Creating Python environment..."
    python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
echo "  Installing Python dependencies..."
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

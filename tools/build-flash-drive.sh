#!/usr/bin/env bash
# ============================================================
#  Build the Quadra-Seer Sovereign offline flash-drive package.
#
#  Run this ONCE on a machine with internet to prepare a flash
#  drive that can install fully OFFLINE:
#
#    ./tools/build-flash-drive.sh /path/to/flash/drive [--model qwen2.5:3b]
#
#  What it does:
#    1. Copies this repo (app + installers) to the drive
#    2. Downloads Ollama installers for Windows / macOS / Linux
#    3. Pulls the AI model and bundles it for offline use
#
#  Result: plug the drive into any machine, double-click install,
#  no internet required. Needs a 16GB+ flash drive (model ~2GB).
# ============================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/flash/drive [--model <ollama-model>]"
    exit 1
fi

TARGET="$1"
MODEL="qwen2.5:3b"
if [[ "${2:-}" == "--model" ]]; then
    MODEL="$3"
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================================"
echo "  Building Quadra-Seer Sovereign flash-drive package"
echo "  Target: $TARGET"
echo "  Model:  $MODEL"
echo "============================================================"

mkdir -p "$TARGET"
VENDOR="$TARGET/vendor"
mkdir -p "$VENDOR/ollama" "$VENDOR/models"

# Record which model was bundled so the installers use it (not their default)
echo "$MODEL" > "$VENDOR/model.txt"

# ── 1. Copy repo (app + installers, no .git) ─────────────────
echo ""
echo "[1/3] Copying app and installers..."
rsync -a --exclude='.git' --exclude='vendor' "$REPO_DIR/" "$TARGET/"
chmod +x "$TARGET/install.sh"

# ── 2. Ollama binaries ───────────────────────────────────────
echo ""
echo "[2/3] Downloading Ollama installers..."
# Windows
if [[ ! -f "$VENDOR/ollama/OllamaSetup.exe" ]]; then
    echo "  Windows..."
    curl -fsSL "https://ollama.com/download/OllamaSetup.exe" -o "$VENDOR/ollama/OllamaSetup.exe"
fi
# macOS
if [[ ! -f "$VENDOR/ollama/Ollama-darwin.zip" ]]; then
    echo "  macOS..."
    curl -fsSL "https://ollama.com/download/Ollama-darwin.zip" -o "$VENDOR/ollama/Ollama-darwin.zip"
fi
# Linux
if [[ ! -x "$VENDOR/ollama/bin/ollama" ]]; then
    echo "  Linux..."
    curl -fsSL "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tgz" \
        -o "$VENDOR/ollama/ollama-linux.tgz"
    # The tarball contains bin/ollama — extract one level up so the
    # installer finds it at vendor/ollama/bin/ollama
    tar -xzf "$VENDOR/ollama/ollama-linux.tgz" -C "$VENDOR/ollama"
fi

# ── 3. Model (offline bundle) ────────────────────────────────
echo ""
echo "[3/3] Bundling AI model ($MODEL)..."
if ! command -v ollama &>/dev/null; then
    echo "  Ollama not found on this machine — installing temporarily..."
    curl -fsSL https://ollama.com/install.sh | sh
fi
ollama serve &>/dev/null &
SERVE_PID=$!
sleep 3
if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "  Pulling $MODEL (this downloads ~2GB)..."
    ollama pull "$MODEL"
fi
echo "  Copying model store to drive..."
OLLAMA_STORE="${OLLAMA_MODELS:-$HOME/.ollama/models}"
rsync -a "$OLLAMA_STORE/" "$VENDOR/models/"

# Stop the helper server we started on the build machine
kill "$SERVE_PID" 2>/dev/null || true

# ── Done ─────────────────────────────────────────────────────
SIZE=$(du -sh "$TARGET" | cut -f1)
echo ""
echo "============================================================"
echo "  DONE. Flash-drive package ready: $TARGET ($SIZE)"
echo ""
echo "  To use: plug the drive into any machine and run:"
echo "    Windows: double-click install.bat"
echo "    macOS/Linux: ./install.sh"
echo ""
echo "  No internet required on the target machine."
echo "============================================================"

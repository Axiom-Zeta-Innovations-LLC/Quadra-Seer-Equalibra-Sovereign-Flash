# Quadra-Seer Equalibra Sovereign — Flash Drive Edition

**Your AI, on a stick.** Plug in the flash drive, double-click install, and you have a private AI chatbot running entirely on your own machine. No cloud. No account. No internet required.

## For the person receiving the drive

1. Plug in the flash drive.
2. **Windows:** double-click `install.bat`. **Mac/Linux:** run `./install.sh`.
3. Wait 15–30 minutes on first run (it downloads Python/Node packages; unattended — walk away). Every launch after that is instant.
4. Your browser opens to Quadra-Seer Sovereign. Done.

Everything — the AI model, the app, your conversations — lives on your machine. Unplug the drive, keep your mind.

## For the person preparing the drive

This repo contains the app source and the installers, but **not** the large binaries (Ollama installers ~200MB, AI model ~2GB). Those live in `vendor/` which is gitignored. To build a complete offline drive:

```bash
# On a machine with internet, with the flash drive mounted:
./tools/build-flash-drive.sh /path/to/flash/drive

# Optional: choose a bigger/smarter model (needs more RAM + drive space)
./tools/build-flash-drive.sh /path/to/flash/drive --model qwen2.5:7b
```

The build script downloads Ollama for Windows/macOS/Linux, pulls the model, and assembles everything on the drive. One build, then the drive works offline forever.

### Honest note on "offline"

The offline bundle covers **Ollama + the AI model** — those never touch the internet on the target machine. The **Python and Node packages** (~1–2 GB, mostly torch) still download on first install, so the target machine needs internet *once* for step 3, or about 15–30 minutes of unattended setup. (Pre-building those environments onto the drive is possible — it would make installs fully offline and much faster — but the environments are OS-specific, so it means three separate builds. Say the word if you want that.)

### Without the offline bundle

If you skip the build step and just copy this repo to a drive, the installers still work — they'll download Ollama and the model on first run (internet required that one time).

## What's inside

| Path | What |
|---|---|
| `install.bat` | One-click Windows installer |
| `install.sh` | One-click macOS/Linux installer |
| `app/` | Quadra-Seer Sovereign source ([main repo](https://github.com/Axiom-Zeta-Innovations-LLC/quadra-seer-equalibra-sovereign)) |
| `tools/build-flash-drive.sh` | Assembles the offline package on a drive |
| `vendor/` | Ollama binaries + bundled model (gitignored, created by the build script) |

## Requirements on the target machine

- **OS:** Windows 10/11, macOS 12+, or Linux
- **RAM:** ~4GB free (3B model) or ~8GB free (7B model)
- **Disk:** ~1GB for the app + dependencies (model stays on the drive or copies over)
- **Python 3.10+** and **Node.js 22+** (the installer will tell you if they're missing)

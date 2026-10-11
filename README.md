# Quadra-Seer Equalibra Sovereign — Flash Drive Edition

**Your AI, on a stick.** Plug in the flash drive, double-click install, and you have a private AI chatbot running entirely on your own machine. No cloud. No account. No internet required.

## For the person receiving the drive

1. Plug in the flash drive.
2. **Windows:** double-click `install.bat`. **Mac/Linux:** run `./install.sh`.
3. Wait a few minutes (first run sets everything up).
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

## License

AGPL-3.0 — same as the main repo. The software is free; the flash drive is just a convenient way to carry it.

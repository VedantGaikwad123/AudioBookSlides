# AudioBookSlides - Windows Installation & Runtime Guide

This document provides a comprehensive guide to installing, configuring, running, and maintaining **AudioBookSlides** on Windows.

---

## 1. Quick Start (1-Click Installer)

1. Download or clone this repository.
2. Double-click `WINDOWS_INSTALL.bat`.
3. The installer will automatically:
   - Detect your CPU architecture (x64 / AMD64).
   - Check for a compatible Python version (3.9 - 3.11). If missing, it downloads an isolated, portable embedded Python environment into `python_embedded/`.
   - Install `pip` and the ultra-fast `uv` package manager.
   - Detect whether an NVIDIA GPU is present and install the appropriate **CUDA-accelerated** or **CPU-only** PyTorch wheels.
   - Install all project dependencies defined in `pyproject.toml`.
   - Detect, download, and configure **FFmpeg** in `tools\ffmpeg\bin`.
   - Offer to download and configure **ComfyUI** with `nodes_custom_sampler.py`, `ComfyUI-Manager`, and `ComfyUI-Impact-Pack`.
   - Run verification diagnostics (`scripts/check_environment.py`).
   - Create Desktop and Start Menu shortcuts.
4. Once completed, you can double-click **`LAUNCH.bat`** or your Desktop shortcut to start using the application or start the local ComfyUI server.

---

## 2. Directory Structure

```text
AudioBookSlides/
│
├── WINDOWS_INSTALL.bat        # 1-Click Automated Windows Installer & Updater
├── LAUNCH.bat                 # Unified Application Launcher & Interactive Menu
├── UNINSTALL.bat              # Safe Uninstaller & Environment Cleanup
├── installer_config.bat       # Centralized Configuration Parameters
├── pyproject.toml             # PEP 621 Standard Package & Dependency Spec
├── setup.py                   # Legacy Setuptools Entrypoint
├── VERSION                    # Local Semantic Version Tracker
│
├── abs.py                     # Master Pipeline CLI & Orchestrator
├── default_config.yaml        # Main Configuration File
├── tokenizer_vocab_2.txt      # Name Filter Dictionary
│
├── actors/                    # Casting Databases
│   ├── female.csv             # Curated Actress Roster
│   └── male.csv               # Curated Actor Roster
│
├── scripts/                   # Installer & Diagnostic Utilities
│   ├── check_cuda.py          # GPU & PyTorch CUDA Diagnostic Tool
│   ├── check_environment.py   # Full Environment Verification Script
│   └── create_shortcuts.bat   # Windows Shortcut Generator (.lnk)
│
├── logs/                      # Installer & Execution Logs
│   └── install.log            # Detailed Installation Log
│
└── python_embedded/           # (Optional) Isolated Portable Python (Auto-downloaded if needed)
```

---

## 3. Launching AudioBookSlides

### Option A: Interactive Double-Click (`LAUNCH.bat`)
Double-click `LAUNCH.bat` to bring up the interactive console:
```text
============================================================================
                     AudioBookSlides - Application Launcher
============================================================================

 [1] Process an Audiobook (Create Slideshow & Synchronized Video)
 [2] Run Hardware & Environment Diagnostics (CUDA / GPU / PyTorch)
 [3] Check for Application Updates
 [4] Edit Configuration (default_config.yaml)
 [5] Run Interactive Python Console in App Environment
 [6] Exit
```

### Option B: Command-Line Interface (CLI)
You can directly pass arguments to `LAUNCH.bat` or `abs.py`:
```cmd
LAUNCH.bat 06DeeplyOdd "E:\AudioBooks\Dean Koontz - Deeply Odd (2013)\*.mp3"
```
or inside your activated environment:
```cmd
abs 06DeeplyOdd "E:\AudioBooks\Dean Koontz - Deeply Odd (2013)\*.mp3"
```

---

## 4. Hardware & GPU Acceleration

AudioBookSlides automatically configures CUDA support for NVIDIA GPUs:
- **NVIDIA GPU Available**: Installs `torch`, `torchvision`, and `torchaudio` with CUDA 11.8 support (`--index-url https://download.pytorch.org/whl/cu118`).
- **Non-NVIDIA / CPU Mode**: Installs CPU-optimized wheels (`--index-url https://download.pytorch.org/whl/cpu`).

To manually inspect your GPU and CUDA status at any time, run:
```cmd
LAUNCH.bat
:: Select Option [2]
```
or:
```cmd
.venv\Scripts\python scripts\check_cuda.py
```

---

## 5. Updates & Version Control

- The installer checks the official GitHub Release endpoint (`GotAudio/AudioBookSlides/releases/latest`) on startup.
- If a new version is detected, it offers to download and apply the update automatically without destroying user data.
- You can also check for updates inside `LAUNCH.bat` (Option 3).

---

## 6. Uninstalling AudioBookSlides

Run `UNINSTALL.bat`. You will be guided through:
1. Removal of Desktop and Start Menu shortcuts.
2. Removal of `.venv` or `python_embedded/`.
3. Cleaning temporary caches and build folders.
4. Optional removal or preservation of user data (e.g., `books/`, `logs/`, `ABS_API_KEY.txt`).

---

## 7. Troubleshooting & Diagnostics

| Problem | Cause | Solution |
| :--- | :--- | :--- |
| `FFmpeg not found on PATH` | FFmpeg binaries are missing | Download FFmpeg from [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds/releases) and add `bin` to your Windows PATH. |
| `OpenAI API key not found` | Optional GPT key is missing | Create `ABS_API_KEY.txt` in the root folder with your OpenAI API key, or use the built-in non-GPT heuristic mode. |
| `ComfyUI output folder not found` | Image generation pending | Launch ComfyUI, wait for generation to finish, and rename `output` to `books\<bookname>` as prompted. |
| `Permission Denied` | File locked or system folder | `WINDOWS_INSTALL.bat` does not require Administrator privileges. Run in standard user mode inside a user-accessible folder. |

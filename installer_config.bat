@echo off
:: ============================================================================
:: AudioBookSlides - Unified Installer and Runtime Configuration
:: ============================================================================

set APP_NAME=AudioBookSlides
set APP_SHORT_NAME=abs
set PACKAGE_NAME=AudioBookSlides
set APP_VERSION_DEFAULT=1.1.0
set VERSION_FILE=VERSION

:: Supported Python Version Range (3.9 to 3.11 recommended for WhisperX and PyTorch CUDA on Windows)
set REQUIRED_PYTHON_MAJOR=3
set REQUIRED_PYTHON_MINOR_MIN=9
set REQUIRED_PYTHON_MINOR_MAX=11
set DEFAULT_PYTHON_VERSION=3.10.11
set EMBED_PYTHON_ZIP_NAME=python-3.10.11-embed-amd64.zip
set EMBED_PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip
set GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py

:: PyTorch Distribution URLs
set TORCH_CUDA_INDEX_URL=https://download.pytorch.org/whl/cu118
set TORCH_CPU_INDEX_URL=https://download.pytorch.org/whl/cpu
set TORCH_CUDA_VERSION=cu118

:: External Tools: FFmpeg Configuration
set FFMPEG_DIR=tools\ffmpeg
set FFMPEG_ZIP_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip
set FFMPEG_FALLBACK_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip

:: External Tools: ComfyUI Configuration
set COMFYUI_DIR=ComfyUI
set COMFYUI_REPO_URL=https://github.com/comfyanonymous/ComfyUI.git
set COMFYUI_MANAGER_REPO=https://github.com/ltdrdata/ComfyUI-Manager.git
set COMFYUI_IMPACT_REPO=https://github.com/ltdrdata/ComfyUI-Impact-Pack.git

:: Repository & Update Information
set REPOSITORY_URL=https://github.com/GotAudio/AudioBookSlides
set RELEASE_API_URL=https://api.github.com/repos/GotAudio/AudioBookSlides/releases/latest

:: Environment directories
set VENV_DIR=.venv
set EMBED_DIR=python_embedded
set LOG_DIR=logs
set LOG_FILE=logs\install.log
set SCRIPTS_DIR=scripts

@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

:: ============================================================================
:: 0. Load Configuration & Initialize Logging
:: ============================================================================
if exist "installer_config.bat" (
    call "installer_config.bat"
) else (
    set "APP_NAME=AudioBookSlides"
    set "APP_SHORT_NAME=abs"
    set "PACKAGE_NAME=AudioBookSlides"
    set "APP_VERSION_DEFAULT=1.1.0"
    set "VERSION_FILE=VERSION"
    set "REQUIRED_PYTHON_MAJOR=3"
    set "REQUIRED_PYTHON_MINOR_MIN=9"
    set "REQUIRED_PYTHON_MINOR_MAX=11"
    set "DEFAULT_PYTHON_VERSION=3.10.11"
    set "EMBED_PYTHON_ZIP_NAME=python-3.10.11-embed-amd64.zip"
    set "EMBED_PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip"
    set "GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py"
    set "TORCH_CUDA_INDEX_URL=https://download.pytorch.org/whl/cu118"
    set "TORCH_CPU_INDEX_URL=https://download.pytorch.org/whl/cpu"
    set "TORCH_CUDA_VERSION=cu118"
    set "FFMPEG_DIR=tools\ffmpeg"
    set "FFMPEG_ZIP_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    set "COMFYUI_DIR=ComfyUI"
    set "COMFYUI_REPO_URL=https://github.com/comfyanonymous/ComfyUI.git"
    set "COMFYUI_MANAGER_REPO=https://github.com/ltdrdata/ComfyUI-Manager.git"
    set "COMFYUI_IMPACT_REPO=https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    set "REPOSITORY_URL=https://github.com/GotAudio/AudioBookSlides"
    set "RELEASE_API_URL=https://api.github.com/repos/GotAudio/AudioBookSlides/releases/latest"
    set "VENV_DIR=.venv"
    set "EMBED_DIR=python_embedded"
    set "LOG_DIR=logs"
    set "LOG_FILE=logs\install.log"
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Include local FFmpeg in PATH if present
if exist "%CD%\%FFMPEG_DIR%\bin" (
    set "PATH=%CD%\%FFMPEG_DIR%\bin;%PATH%"
)

:: Read local version
if exist "%VERSION_FILE%" (
    set /p LOCAL_VERSION=<"%VERSION_FILE%"
) else (
    set "LOCAL_VERSION=%APP_VERSION_DEFAULT%"
    echo %LOCAL_VERSION%>"%VERSION_FILE%"
)

echo ============================================================================ >> "%LOG_FILE%"
echo [%DATE% %TIME%] Starting %APP_NAME% Installer v%LOCAL_VERSION% >> "%LOG_FILE%"

cls
echo ============================================================================
echo                      %APP_NAME% INSTALLER
echo                               Version %LOCAL_VERSION%
echo ============================================================================
echo.

:: ============================================================================
:: 1. System & Architecture Detection
:: ============================================================================
echo [1/10] Checking system and architecture...
echo [%DATE% %TIME%] [STAGE 1] Checking system and architecture >> "%LOG_FILE%"

set "ARCH=%PROCESSOR_ARCHITECTURE%"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "ARCH=AMD64"

echo Architecture detected: %ARCH%
echo [%DATE% %TIME%] Architecture: %ARCH% >> "%LOG_FILE%"

if /i not "%ARCH%"=="AMD64" (
    echo [WARN] AudioBookSlides and AI acceleration are optimized for Windows x64 (AMD64).
    echo [%DATE% %TIME%] Warning: Non-AMD64 architecture detected (%ARCH%) >> "%LOG_FILE%"
)

net session >nul 2>&1
if %errorlevel% == 0 (
    echo Permissions          : Administrator
    echo [%DATE% %TIME%] Running with Administrator privileges >> "%LOG_FILE%"
) else (
    echo Permissions          : Standard User (Per-User Install - Recommended)
    echo [%DATE% %TIME%] Running with standard user privileges >> "%LOG_FILE%"
)
echo.

:: ============================================================================
:: 2. Version Check & Safe Update System
:: ============================================================================
echo [2/10] Checking for application updates...
echo [%DATE% %TIME%] [STAGE 2] Checking for updates against %RELEASE_API_URL% >> "%LOG_FILE%"

set "LATEST_VERSION="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $res = Invoke-RestMethod -Uri '%RELEASE_API_URL%' -TimeoutSec 5 -ErrorAction Stop; $res.tag_name -replace '^v','' } catch { 'OFFLINE' }"`) do (
    set "LATEST_VERSION=%%V"
)

if "%LATEST_VERSION%"=="" set "LATEST_VERSION=OFFLINE"
if "%LATEST_VERSION%"=="OFFLINE" (
    echo Current version : %LOCAL_VERSION% (Offline / GitHub check skipped)
    echo [%DATE% %TIME%] Update check skipped (offline or rate-limited) >> "%LOG_FILE%"
) else (
    echo Current version : %LOCAL_VERSION%
    echo Latest version  : %LATEST_VERSION%
    echo [%DATE% %TIME%] Local version: %LOCAL_VERSION%, Latest version: %LATEST_VERSION% >> "%LOG_FILE%"
    
    if not "%LOCAL_VERSION%"=="%LATEST_VERSION%" (
        echo.
        echo ************************************************************
        echo  A newer version (%LATEST_VERSION%) is available!
        echo ************************************************************
        set /p DO_UPDATE="Do you want to update to the latest release now? [Y/N] (Default: N): "
        if /i "!DO_UPDATE!"=="Y" (
            echo [%DATE% %TIME%] User selected update to %LATEST_VERSION% >> "%LOG_FILE%"
            echo Downloading update archive safely...
            set "UPDATE_ZIP=temp_update.zip"
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $zipUrl = '%REPOSITORY_URL%/archive/refs/tags/v%LATEST_VERSION%.zip'; Invoke-WebRequest -Uri $zipUrl -OutFile '%UPDATE_ZIP%' -TimeoutSec 30; exit 0 } catch { exit 1 }"
            if exist "%UPDATE_ZIP%" (
                echo Extracting and applying update...
                powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                    "Expand-Archive -Path '%UPDATE_ZIP%' -DestinationPath 'temp_update' -Force; Copy-Item -Path 'temp_update\*/*' -Destination '.' -Recurse -Force; Remove-Item -Path 'temp_update' -Recurse -Force; Remove-Item -Path '%UPDATE_ZIP%' -Force"
                echo Update applied successfully! Please restart the installer.
                pause
                exit /b 0
            ) else (
                echo [WARN] Update download failed. Continuing with current version.
            )
        )
    )
)
echo.

:: ============================================================================
:: 3. FFmpeg Detection & Automated Download
:: ============================================================================
echo [3/10] Checking FFmpeg audio/video processing tools...
echo [%DATE% %TIME%] [STAGE 3] Checking FFmpeg >> "%LOG_FILE%"

set "FFMPEG_FOUND=0"
where ffmpeg >nul 2>&1
if %errorlevel% == 0 set "FFMPEG_FOUND=1"
if exist "%CD%\%FFMPEG_DIR%\bin\ffmpeg.exe" (
    set "FFMPEG_FOUND=1"
    set "PATH=%CD%\%FFMPEG_DIR%\bin;!PATH!"
)

if "%FFMPEG_FOUND%"=="1" (
    echo [OK] FFmpeg is already installed and available on PATH.
    echo [%DATE% %TIME%] FFmpeg found >> "%LOG_FILE%"
) else (
    echo FFmpeg is not found on PATH. AudioBookSlides requires FFmpeg for audio and video assembly.
    echo Downloading portable FFmpeg build...
    echo [%DATE% %TIME%] Downloading FFmpeg from %FFMPEG_ZIP_URL% >> "%LOG_FILE%"
    
    if not exist "%FFMPEG_DIR%" mkdir "%FFMPEG_DIR%"
    set "FFMPEG_ZIP=%FFMPEG_DIR%\ffmpeg.zip"
    
    curl -L "%FFMPEG_ZIP_URL%" -o "!FFMPEG_ZIP!" >> "%LOG_FILE%" 2>&1
    if not exist "!FFMPEG_ZIP!" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%FFMPEG_ZIP_URL%', '!FFMPEG_ZIP!')" >> "%LOG_FILE%" 2>&1
    )
    
    if exist "!FFMPEG_ZIP!" (
        echo Extracting FFmpeg binaries...
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "$temp = '%FFMPEG_DIR%\temp_extract'; Expand-Archive -Path '!FFMPEG_ZIP!' -DestinationPath $temp -Force; " ^
            "$binDir = Get-ChildItem -Path $temp -Recurse -Directory -Filter 'bin' | Select-Object -First 1; " ^
            "if ($binDir) { if (-not (Test-Path '%FFMPEG_DIR%\bin')) { New-Item -ItemType Directory -Path '%FFMPEG_DIR%\bin' -Force }; Copy-Item -Path ($binDir.FullName + '\*') -Destination '%FFMPEG_DIR%\bin' -Force }; " ^
            "Remove-Item -Path $temp -Recurse -Force; Remove-Item -Path '!FFMPEG_ZIP!' -Force" >> "%LOG_FILE%" 2>&1
        
        if exist "%CD%\%FFMPEG_DIR%\bin\ffmpeg.exe" (
            set "PATH=%CD%\%FFMPEG_DIR%\bin;!PATH!"
            echo [OK] FFmpeg downloaded and configured in .\%FFMPEG_DIR%\bin
            echo [%DATE% %TIME%] FFmpeg installed successfully >> "%LOG_FILE%"
        ) else (
            echo [WARN] Could not extract FFmpeg binaries automatically. You can install FFmpeg manually from https://github.com/BtbN/FFmpeg-Builds/releases
        )
    ) else (
        echo [WARN] Failed to download FFmpeg automatically. Please ensure ffmpeg is on your Windows PATH.
    )
)
echo.

:: ============================================================================
:: 4. Python Environment Detection & Setup
:: ============================================================================
echo [4/10] Checking Python environment...
echo [%DATE% %TIME%] [STAGE 4] Detecting Python >> "%LOG_FILE%"

set "PY_EXE="
set "USE_EMBEDDED=0"

if exist "%EMBED_DIR%\python.exe" (
    set "PY_EXE=%CD%\%EMBED_DIR%\python.exe"
    echo Found local embedded Python: !PY_EXE!
    echo [%DATE% %TIME%] Using existing embedded Python at !PY_EXE! >> "%LOG_FILE%"
    goto :PYTHON_FOUND
)

if exist "%VENV_DIR%\Scripts\python.exe" (
    set "PY_EXE=%CD%\%VENV_DIR%\Scripts\python.exe"
    echo Found existing virtual environment: !PY_EXE!
    echo [%DATE% %TIME%] Using existing virtualenv at !PY_EXE! >> "%LOG_FILE%"
    goto :PYTHON_FOUND
)

set "SYS_PY="
for /f "tokens=*" %%P in ('where python 2^>nul') do (
    if not defined SYS_PY (
        set "SYS_PY=%%P"
    )
)

if defined SYS_PY (
    for /f "tokens=2 delims= " %%V in ('"%SYS_PY%" --version 2^>^&1') do set "SYS_PY_VER=%%V"
    echo System Python found: %SYS_PY% (v!SYS_PY_VER!)
    echo [%DATE% %TIME%] Found system Python %SYS_PY% (v!SYS_PY_VER!) >> "%LOG_FILE%"
    
    for /f "tokens=1,2 delims=." %%A in ("!SYS_PY_VER!") do (
        set "PY_MAJ=%%A"
        set "PY_MIN=%%B"
    )
    
    if "!PY_MAJ!"=="%REQUIRED_PYTHON_MAJOR%" (
        if !PY_MIN! geq %REQUIRED_PYTHON_MINOR_MIN% (
            if !PY_MIN! leq %REQUIRED_PYTHON_MINOR_MAX% (
                echo Compatible system Python detected (v!SYS_PY_VER!).
                echo Creating isolated virtual environment in .\%VENV_DIR%...
                "%SYS_PY%" -m venv "%VENV_DIR%" >> "%LOG_FILE%" 2>&1
                if exist "%VENV_DIR%\Scripts\python.exe" (
                    set "PY_EXE=%CD%\%VENV_DIR%\Scripts\python.exe"
                    echo Virtual environment created successfully.
                    goto :PYTHON_FOUND
                ) else (
                    echo [WARN] Failed to create virtualenv. Falling back to embedded Python distribution.
                )
            )
        )
    )
    echo [INFO] System Python (v!SYS_PY_VER!) is outside recommended range (3.9 - 3.11).
)

echo Python 3.9-3.11 is not available locally.
echo Downloading portable isolated Python %DEFAULT_PYTHON_VERSION%...
echo [%DATE% %TIME%] Downloading embedded Python from %EMBED_PYTHON_URL% >> "%LOG_FILE%"

if not exist "%EMBED_DIR%" mkdir "%EMBED_DIR%"
set "EMBED_ZIP=%EMBED_DIR%\%EMBED_PYTHON_ZIP_NAME%"

curl -L "%EMBED_PYTHON_URL%" -o "%EMBED_ZIP%" >> "%LOG_FILE%" 2>&1
if not exist "%EMBED_ZIP%" (
    echo Trying PowerShell download fallback...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%EMBED_PYTHON_URL%', '%EMBED_ZIP%')" >> "%LOG_FILE%" 2>&1
)

if not exist "%EMBED_ZIP%" (
    echo.
    echo ============================================================================
    echo ERROR: Failed to download embedded Python distribution.
    echo Please check your internet connection or install Python 3.10 manually.
    echo ============================================================================
    echo [%DATE% %TIME%] ERROR: Embedded Python download failed >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo Extracting portable Python...
tar -xf "%EMBED_ZIP%" -C "%EMBED_DIR%" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%EMBED_ZIP%' -DestinationPath '%EMBED_DIR%' -Force" >> "%LOG_FILE%" 2>&1
)
del "%EMBED_ZIP%" >nul 2>&1

echo Configuring embedded Python paths...
for /f "delims=" %%F in ('dir /b "%EMBED_DIR%\python*._pth" 2^>nul') do (
    set "PTH_FILE=%EMBED_DIR%\%%F"
    echo .> "!PTH_FILE!"
    echo .>> "!PTH_FILE!"
    echo python310.zip>> "!PTH_FILE!"
    echo Lib\site-packages>> "!PTH_FILE!"
    echo import site>> "!PTH_FILE!"
)
if not exist "%EMBED_DIR%\Lib\site-packages" mkdir "%EMBED_DIR%\Lib\site-packages"

echo Installing pip in embedded Python...
curl -L "%GET_PIP_URL%" -o "%EMBED_DIR%\get-pip.py" >> "%LOG_FILE%" 2>&1
if not exist "%EMBED_DIR%\get-pip.py" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%GET_PIP_URL%', '%EMBED_DIR%\get-pip.py')" >> "%LOG_FILE%" 2>&1
)

"%EMBED_DIR%\python.exe" "%EMBED_DIR%\get-pip.py" --no-warn-script-location >> "%LOG_FILE%" 2>&1
del "%EMBED_DIR%\get-pip.py" >nul 2>&1

set "PY_EXE=%CD%\%EMBED_DIR%\python.exe"

:PYTHON_FOUND
echo Active Python: %PY_EXE%
echo [%DATE% %TIME%] Verified Python binary: %PY_EXE% >> "%LOG_FILE%"
echo.

:: ============================================================================
:: 5. Install & Upgrade Package Managers (pip, uv)
:: ============================================================================
echo [5/10] Installing and upgrading package managers (pip, uv)...
echo [%DATE% %TIME%] [STAGE 5] Upgrading pip and installing uv >> "%LOG_FILE%"

"%PY_EXE%" -m pip install --upgrade pip >> "%LOG_FILE%" 2>&1
"%PY_EXE%" -m pip install --upgrade uv >> "%LOG_FILE%" 2>&1

"%PY_EXE%" -m uv --version >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] uv fast package manager is ready.
    echo [%DATE% %TIME%] uv package manager installed successfully >> "%LOG_FILE%"
) else (
    echo [WARN] uv not found; pip will be used as fallback.
    echo [%DATE% %TIME%] uv installation warning; falling back to pip >> "%LOG_FILE%"
)
echo.

:: ============================================================================
:: 6. GPU & Hardware Detection
:: ============================================================================
echo [6/10] Detecting GPU and CUDA hardware acceleration...
echo [%DATE% %TIME%] [STAGE 6] Detecting GPU and CUDA >> "%LOG_FILE%"

set "IS_NVIDIA=0"
"%PY_EXE%" scripts\check_cuda.py >> "%LOG_FILE%" 2>&1
if %errorlevel% == 0 (
    set "IS_NVIDIA=1"
    echo NVIDIA GPU detected with CUDA support.
) else (
    echo No compatible NVIDIA GPU detected. CPU mode will be configured.
)
echo.

:: ============================================================================
:: 7. PyTorch & Application Dependencies
:: ============================================================================
echo [7/10] Installing PyTorch and dependencies...
echo [%DATE% %TIME%] [STAGE 7] Installing PyTorch and project dependencies >> "%LOG_FILE%"

if "%IS_NVIDIA%"=="1" (
    echo Installing CUDA-accelerated PyTorch (%TORCH_CUDA_VERSION%)...
    "%PY_EXE%" -m uv pip install --no-cache torch torchvision torchaudio --index-url %TORCH_CUDA_INDEX_URL% >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        echo [WARN] uv pip install failed, retrying with standard pip...
        "%PY_EXE%" -m pip install torch torchvision torchaudio --index-url %TORCH_CUDA_INDEX_URL% >> "%LOG_FILE%" 2>&1
    )
) else (
    echo Installing CPU PyTorch...
    "%PY_EXE%" -m uv pip install --no-cache torch torchvision torchaudio --index-url %TORCH_CPU_INDEX_URL% >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        "%PY_EXE%" -m pip install torch torchvision torchaudio --index-url %TORCH_CPU_INDEX_URL% >> "%LOG_FILE%" 2>&1
    )
)

echo.
echo Select Installation Mode:
echo [1] Production (Standard user install)
echo [2] Development (Editable developer install)
set /p INSTALL_MODE="Select option [1-2] (Default: 1): "
if "%INSTALL_MODE%"=="2" (
    echo Installing AudioBookSlides in development mode (-e .)...
    echo [%DATE% %TIME%] Installing in development mode >> "%LOG_FILE%"
    "%PY_EXE%" -m uv pip install -e . >> "%LOG_FILE%" 2>&1
    if errorlevel 1 "%PY_EXE%" -m pip install -e . >> "%LOG_FILE%" 2>&1
) else (
    echo Installing AudioBookSlides in standard mode (.) ...
    echo [%DATE% %TIME%] Installing in standard mode >> "%LOG_FILE%"
    "%PY_EXE%" -m uv pip install . >> "%LOG_FILE%" 2>&1
    if errorlevel 1 "%PY_EXE%" -m pip install . >> "%LOG_FILE%" 2>&1
)
echo.

:: ============================================================================
:: 8. ComfyUI Setup & Node Configuration
:: ============================================================================
echo [8/10] Setting up ComfyUI and Custom Nodes...
echo [%DATE% %TIME%] [STAGE 8] ComfyUI setup >> "%LOG_FILE%"

set "SETUP_COMFY=Y"
if not exist "%COMFYUI_DIR%" (
    set /p SETUP_COMFY="ComfyUI not found locally. Would you like to clone and configure ComfyUI now? [Y/N] (Default: Y): "
    if "!SETUP_COMFY!"=="" set "SETUP_COMFY=Y"
)

if /i "!SETUP_COMFY!"=="Y" (
    if not exist "%COMFYUI_DIR%" (
        echo Cloning ComfyUI repository...
        git clone "%COMFYUI_REPO_URL%" "%COMFYUI_DIR%" >> "%LOG_FILE%" 2>&1
        if not exist "%COMFYUI_DIR%" (
            echo Trying ZIP download fallback for ComfyUI...
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                "Invoke-WebRequest -Uri 'https://github.com/comfyanonymous/ComfyUI/archive/refs/heads/master.zip' -OutFile 'comfy_temp.zip'; " ^
                "Expand-Archive -Path 'comfy_temp.zip' -DestinationPath 'comfy_temp' -Force; " ^
                "Move-Item -Path 'comfy_temp\ComfyUI-master' -Destination '%COMFYUI_DIR%' -Force; " ^
                "Remove-Item -Path 'comfy_temp' -Recurse -Force; Remove-Item -Path 'comfy_temp.zip' -Force" >> "%LOG_FILE%" 2>&1
        )
    )

    if exist "%COMFYUI_DIR%" (
        echo Installing ComfyUI dependencies...
        if exist "%COMFYUI_DIR%\requirements.txt" (
            "%PY_EXE%" -m uv pip install -r "%COMFYUI_DIR%\requirements.txt" >> "%LOG_FILE%" 2>&1
            if errorlevel 1 "%PY_EXE%" -m pip install -r "%COMFYUI_DIR%\requirements.txt" >> "%LOG_FILE%" 2>&1
        )

        :: Copy nodes_custom_sampler.py into ComfyUI/comfy_extras/
        if exist "nodes_custom_sampler.py" (
            if not exist "%COMFYUI_DIR%\comfy_extras" mkdir "%COMFYUI_DIR%\comfy_extras"
            copy /y "nodes_custom_sampler.py" "%COMFYUI_DIR%\comfy_extras\nodes_custom_sampler.py" >nul 2>&1
            echo [OK] Copied nodes_custom_sampler.py to %COMFYUI_DIR%\comfy_extras\
        )

        :: Install Custom Nodes (ComfyUI-Manager & ComfyUI-Impact-Pack)
        if not exist "%COMFYUI_DIR%\custom_nodes" mkdir "%COMFYUI_DIR%\custom_nodes"
        
        if not exist "%COMFYUI_DIR%\custom_nodes\ComfyUI-Manager" (
            echo Cloning ComfyUI-Manager...
            git clone "%COMFYUI_MANAGER_REPO%" "%COMFYUI_DIR%\custom_nodes\ComfyUI-Manager" >> "%LOG_FILE%" 2>&1
        )
        if not exist "%COMFYUI_DIR%\custom_nodes\ComfyUI-Impact-Pack" (
            echo Cloning ComfyUI-Impact-Pack...
            git clone "%COMFYUI_IMPACT_REPO%" "%COMFYUI_DIR%\custom_nodes\ComfyUI-Impact-Pack" >> "%LOG_FILE%" 2>&1
        )
        echo [OK] ComfyUI and custom nodes configured.
    ) else (
        echo [WARN] ComfyUI setup skipped or download failed.
    )
)
echo.

:: ============================================================================
:: 9. Environment & Integrity Verification
:: ============================================================================
echo [9/10] Verifying environment and installation integrity...
echo [%DATE% %TIME%] [STAGE 9] Running check_environment.py >> "%LOG_FILE%"

"%PY_EXE%" scripts\check_environment.py
if errorlevel 1 (
    echo.
    echo ============================================================================
    echo ERROR: Installation verification failed.
    echo Please review '%LOG_FILE%' for detailed diagnostic information.
    echo ============================================================================
    echo [%DATE% %TIME%] ERROR: check_environment.py returned failure >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo.

:: ============================================================================
:: 10. Shortcuts & Launcher
:: ============================================================================
echo [10/10] Configuring shortcuts and launcher...
echo [%DATE% %TIME%] [STAGE 10] Configuring shortcuts >> "%LOG_FILE%"

set /p MAKE_SHORTCUTS="Create Desktop and Start Menu shortcuts? [Y/N] (Default: Y): "
if /i not "%MAKE_SHORTCUTS%"=="N" (
    call scripts\create_shortcuts.bat >> "%LOG_FILE%" 2>&1
)

echo.
echo ============================================================================
echo                 INSTALLATION COMPLETED SUCCESSFULLY!
echo ============================================================================
echo  You can now start the application at any time using:
echo    - LAUNCH.bat (interactive launcher)
echo    - Desktop / Start Menu shortcut
echo    - Command Line: abs [bookname] "wildcard_path"
echo ============================================================================
echo [%DATE% %TIME%] Installation finished successfully >> "%LOG_FILE%"
echo.

set /p RUN_NOW="Would you like to launch %APP_NAME% now? [Y/N] (Default: Y): "
if /i not "%RUN_NOW%"=="N" (
    call "LAUNCH.bat"
)

exit /b 0

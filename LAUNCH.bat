@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

:: Load configuration
if exist "installer_config.bat" (
    call "installer_config.bat"
) else (
    set "APP_NAME=AudioBookSlides"
    set "VENV_DIR=.venv"
    set "EMBED_DIR=python_embedded"
    set "FFMPEG_DIR=tools\ffmpeg"
    set "COMFYUI_DIR=ComfyUI"
)

:: Include local FFmpeg in PATH if present
if exist "%CD%\%FFMPEG_DIR%\bin" (
    set "PATH=%CD%\%FFMPEG_DIR%\bin;%PATH%"
)

:: Locate Python executable
set "PY_EXE="
if exist "%VENV_DIR%\Scripts\python.exe" (
    set "PY_EXE=%CD%\%VENV_DIR%\Scripts\python.exe"
) else if exist "%EMBED_DIR%\python.exe" (
    set "PY_EXE=%CD%\%EMBED_DIR%\python.exe"
) else (
    for /f "tokens=*" %%P in ('where python 2^>nul') do (
        if not defined PY_EXE set "PY_EXE=%%P"
    )
)

if not defined PY_EXE (
    echo ============================================================================
    echo ERROR: Python environment not found!
    echo Please run 'WINDOWS_INSTALL.bat' first to install %APP_NAME%.
    echo ============================================================================
    echo.
    set /p RUN_INSTALL="Would you like to run WINDOWS_INSTALL.bat now? [Y/N] (Default: Y): "
    if /i not "!RUN_INSTALL!"=="N" (
        call "WINDOWS_INSTALL.bat"
        exit /b 0
    )
    pause
    exit /b 1
)

:: If arguments were provided via CLI, pass them directly to abs.py
if not "%~1"=="" (
    "%PY_EXE%" abs.py %*
    exit /b %errorlevel%
)

:: Interactive Menu Mode (when double-clicked)
:MENU
cls
echo ============================================================================
echo                      %APP_NAME% - Application Launcher
echo ============================================================================
echo.
echo  [1] Process an Audiobook (Create Slideshow & Synchronized Video)
echo  [2] Start Local ComfyUI Image Server (http://127.0.0.1:8188)
echo  [3] Run Hardware & Environment Diagnostics (CUDA / GPU / PyTorch)
echo  [4] Check for Application Updates
echo  [5] Edit Configuration (default_config.yaml)
echo  [6] Run Interactive Python Console in App Environment
echo  [7] Exit
echo.
echo ============================================================================
set /p MENU_CHOICE="Enter selection [1-7]: "

if "%MENU_CHOICE%"=="1" goto :RUN_BOOK
if "%MENU_CHOICE%"=="2" goto :RUN_COMFYUI
if "%MENU_CHOICE%"=="3" goto :RUN_DIAGNOSTICS
if "%MENU_CHOICE%"=="4" goto :RUN_UPDATE_CHECK
if "%MENU_CHOICE%"=="5" goto :EDIT_CONFIG
if "%MENU_CHOICE%"=="6" goto :RUN_SHELL
if "%MENU_CHOICE%"=="7" exit /b 0

echo Invalid selection. Please choose 1-7.
timeout /t 2 >nul
goto :MENU

:RUN_BOOK
echo.
echo ============================================================================
echo  Step 1: Enter a short, safe name for your book (no spaces or special chars).
echo  Example: 01SherlockHolmes or DeeplyOdd
echo ============================================================================
set /p BOOK_NAME="Book Name: "
if "%BOOK_NAME%"=="" (
    echo Book name cannot be empty.
    pause
    goto :MENU
)

echo.
echo ============================================================================
echo  Step 2: Enter the path or wildcard to your audio file(s).
echo  You can drag and drop a folder or file here, or enter a wildcard pattern.
echo  Example: E:\AudioBooks\Sherlock\*.mp3
echo ============================================================================
set /p AUDIO_PATH="Audio Path: "
if "%AUDIO_PATH%"=="" (
    echo Audio path cannot be empty.
    pause
    goto :MENU
)

:: Strip surrounding quotes if user entered them
set "AUDIO_PATH=%AUDIO_PATH:"=%"

echo.
echo Starting AudioBookSlides for book '%BOOK_NAME%'...
echo ----------------------------------------------------------------------------
"%PY_EXE%" abs.py "%BOOK_NAME%" "%AUDIO_PATH%"
echo.
echo ----------------------------------------------------------------------------
echo Process finished.
pause
goto :MENU

:RUN_COMFYUI
echo.
echo Starting ComfyUI Image Server...
echo ----------------------------------------------------------------------------
if exist "ComfyUI\main.py" (
    start "ComfyUI Server" "%PY_EXE%" "ComfyUI\main.py" --auto-launch
    echo ComfyUI started in a separate window (http://127.0.0.1:8188).
) else if exist "..\ComfyUI\main.py" (
    start "ComfyUI Server" "%PY_EXE%" "..\ComfyUI\main.py" --auto-launch
    echo ComfyUI started in a separate window (http://127.0.0.1:8188).
) else (
    echo [ERROR] ComfyUI directory not found. Run WINDOWS_INSTALL.bat to set up ComfyUI.
)
pause
goto :MENU

:RUN_DIAGNOSTICS
echo.
echo Running Environment and Hardware Diagnostics...
echo ----------------------------------------------------------------------------
"%PY_EXE%" scripts\check_cuda.py
echo.
"%PY_EXE%" scripts\check_environment.py
echo ----------------------------------------------------------------------------
pause
goto :MENU

:RUN_UPDATE_CHECK
echo.
echo Checking for updates...
echo ----------------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $res = Invoke-RestMethod -Uri '%RELEASE_API_URL%' -TimeoutSec 5 -ErrorAction Stop; Write-Host ('Latest release: ' + $res.tag_name); Write-Host ('Release URL: ' + $res.html_url) } catch { Write-Host 'Could not reach GitHub release API (offline or rate limited).' }"
echo ----------------------------------------------------------------------------
pause
goto :MENU

:EDIT_CONFIG
if exist "default_config.yaml" (
    start notepad.exe "default_config.yaml"
) else (
    echo default_config.yaml not found!
    pause
)
goto :MENU

:RUN_SHELL
echo.
echo Launching Python interactive shell in the %APP_NAME% environment...
echo Type 'exit()' to return to the menu.
echo ----------------------------------------------------------------------------
"%PY_EXE%"
goto :MENU

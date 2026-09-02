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
    set "LOG_DIR=logs"
)

cls
echo ============================================================================
echo                      %APP_NAME% - UNINSTALLER
echo ============================================================================
echo.
echo WARNING: This will remove the %APP_NAME% runtime environment and shortcuts.
echo.
set /p CONFIRM="Are you sure you want to proceed with uninstallation? [Y/N] (Default: N): "
if /i not "%CONFIRM%"=="Y" (
    echo Uninstallation canceled.
    pause
    exit /b 0
)

echo.
echo [1/4] Removing Desktop and Start Menu shortcuts...
if exist "%USERPROFILE%\Desktop\%APP_NAME%.lnk" (
    del /f /q "%USERPROFILE%\Desktop\%APP_NAME%.lnk" >nul 2>&1
    echo  - Removed Desktop shortcut.
)
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\%APP_NAME%.lnk" (
    del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\%APP_NAME%.lnk" >nul 2>&1
    echo  - Removed Start Menu shortcut.
)

echo.
echo [2/4] Removing isolated Python environment...
if exist "%VENV_DIR%" (
    rmdir /s /q "%VENV_DIR%" >nul 2>&1
    echo  - Removed virtual environment (%VENV_DIR%).
)
if exist "%EMBED_DIR%" (
    rmdir /s /q "%EMBED_DIR%" >nul 2>&1
    echo  - Removed embedded Python (%EMBED_DIR%).
)

echo.
echo [3/4] Cleaning build artifacts and cache...
if exist "build" rmdir /s /q "build" >nul 2>&1
if exist "AudioBookSlides.egg-info" rmdir /s /q "AudioBookSlides.egg-info" >nul 2>&1
if exist ".cache" rmdir /s /q ".cache" >nul 2>&1

echo.
echo [4/4] User Data and Configuration:
echo.
set /p DEL_DATA="Do you want to delete generated book videos, logs, and API keys as well? [Y/N] (Default: N): "
if /i "%DEL_DATA%"=="Y" (
    if exist "tools" (
        rmdir /s /q "tools" >nul 2>&1
        echo  - Removed 'tools' directory (FFmpeg).
    )
    if exist "ComfyUI" (
        rmdir /s /q "ComfyUI" >nul 2>&1
        echo  - Removed 'ComfyUI' directory.
    )
    if exist "books" (
        rmdir /s /q "books" >nul 2>&1
        echo  - Removed 'books' directory.
    )
    if exist "%LOG_DIR%" (
        rmdir /s /q "%LOG_DIR%" >nul 2>&1
        echo  - Removed '%LOG_DIR%' directory.
    )
    if exist "ABS_API_KEY.txt" (
        del /f /q "ABS_API_KEY.txt" >nul 2>&1
        echo  - Removed ABS_API_KEY.txt.
    )
    echo User data and external tools removed.
) else (
    echo User data ('books/', 'logs/', ComfyUI models, and API keys) preserved.
)

echo.
echo ============================================================================
echo %APP_NAME% has been successfully uninstalled.
echo ============================================================================
pause
exit /b 0

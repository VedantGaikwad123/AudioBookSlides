@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0.."
set "ROOT_DIR=%CD%"

:: Read installer config if present
if exist "installer_config.bat" (
    call "installer_config.bat"
) else (
    set "APP_NAME=AudioBookSlides"
)

set "TARGET_BAT=%ROOT_DIR%\LAUNCH.bat"
set "SHORTCUT_NAME=%APP_NAME%.lnk"

echo Creating application shortcuts...

:: Option 1: Desktop Shortcut
set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if exist "%DESKTOP_DIR%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ws = New-Object -ComObject WScript.Shell; " ^
        "$s = $ws.CreateShortcut('%DESKTOP_DIR%\%SHORTCUT_NAME%'); " ^
        "$s.TargetPath = '%TARGET_BAT%'; " ^
        "$s.WorkingDirectory = '%ROOT_DIR%'; " ^
        "$s.Description = 'AudioBookSlides Launcher'; " ^
        "$s.Save()"
    if exist "%DESKTOP_DIR%\%SHORTCUT_NAME%" (
        echo [OK] Desktop shortcut created: %DESKTOP_DIR%\%SHORTCUT_NAME%
    ) else (
        echo [WARN] Could not create Desktop shortcut.
    )
)

:: Option 2: Start Menu Shortcut
set "STARTMENU_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
if exist "%STARTMENU_DIR%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ws = New-Object -ComObject WScript.Shell; " ^
        "$s = $ws.CreateShortcut('%STARTMENU_DIR%\%SHORTCUT_NAME%'); " ^
        "$s.TargetPath = '%TARGET_BAT%'; " ^
        "$s.WorkingDirectory = '%ROOT_DIR%'; " ^
        "$s.Description = 'AudioBookSlides Launcher'; " ^
        "$s.Save()"
    if exist "%STARTMENU_DIR%\%SHORTCUT_NAME%" (
        echo [OK] Start Menu shortcut created: %STARTMENU_DIR%\%SHORTCUT_NAME%
    ) else (
        echo [WARN] Could not create Start Menu shortcut.
    )
)

echo Done.
exit /b 0

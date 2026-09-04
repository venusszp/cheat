@echo off
title Steam steamui.dll Fix
color 0A

echo ========================================================
echo             Fixing Steam: steamui.dll Error
echo ========================================================
echo.

:: 1. Kill Steam processes
echo [1/4] Closing Steam processes...
taskkill /F /IM steam.exe /T >nul 2>&1
taskkill /F /IM steamwebhelper.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul

:: 2. Find Steam directory
echo [2/4] Detecting Steam directory...
set "STEAMPATH="

:: Try 64-bit registry
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do (
    set "STEAMPATH=%%b"
)

:: Try 32-bit registry / user registry if not found
if not defined STEAMPATH (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v "SteamPath" 2^>nul') do (
        set "STEAMPATH=%%b"
    )
)

:: Replace forward slashes if any
if defined STEAMPATH (
    set "STEAMPATH=%STEAMPATH:/=\%"
)

:: Fallback standard locations
if not exist "%STEAMPATH%\steam.exe" (
    if exist "%ProgramFiles(x86)%\Steam\steam.exe" (
        set "STEAMPATH=%ProgramFiles(x86)%\Steam"
    ) else if exist "%ProgramFiles%\Steam\steam.exe" (
        set "STEAMPATH=%ProgramFiles%\Steam"
    ) else if exist "D:\Steam\steam.exe" (
        set "STEAMPATH=D:\Steam"
    ) else if exist "E:\Steam\steam.exe" (
        set "STEAMPATH=E:\Steam"
    )
)

if not exist "%STEAMPATH%\steam.exe" (
    echo [!] Could not auto-detect Steam.
    set /p STEAMPATH="Please enter Steam folder path (e.g. C:\Steam): "
)

if not exist "%STEAMPATH%\steam.exe" (
    color 0C
    echo [ERROR] steam.exe was not found.
    pause
    exit /b
)

echo [+] Steam found at: "%STEAMPATH%"
echo.

:: 3. Clear corrupted packages and caches
echo [3/4] Removing corrupted UI files, beta flag and update package...
if exist "%STEAMPATH%\steamui.dll" del /f /q "%STEAMPATH%\steamui.dll"
if exist "%STEAMPATH%\package\beta" del /f /q "%STEAMPATH%\package\beta"
if exist "%STEAMPATH%\package" rd /s /q "%STEAMPATH%\package"
if exist "%STEAMPATH%\depotcache" rd /s /q "%STEAMPATH%\depotcache"
if exist "%STEAMPATH%\appcache" rd /s /q "%STEAMPATH%\appcache"

echo [+] Cache and update packages removed successfully.
echo.

:: 4. Launch Steam to force a clean update
echo [4/4] Launching Steam to re-download fresh steamui.dll...
start "" "%STEAMPATH%\steam.exe"

echo.
echo ========================================================
echo  Done! Steam is now updating and will re-download files.
echo ========================================================
pause

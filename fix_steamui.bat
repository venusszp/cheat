@echo off
setlocal EnableDelayedExpansion
title Steam Full Repair and VC++ Installer
color 0A

:: Set log file on Desktop
set "LOGFILE=%USERPROFILE%\Desktop\steam_fix_log.txt"
echo ======================================================== > "%LOGFILE%"
echo       Steam Repair and VC++ Auto-Installer Log           >> "%LOGFILE%"
echo       Started: %DATE% %TIME%                             >> "%LOGFILE%"
echo ======================================================== >> "%LOGFILE%"

echo ========================================================
echo       Steam steamui.dll Full Fix ^& VC++ Installer
echo ========================================================
echo [i] Full progress is being recorded to:
echo     "%LOGFILE%"
echo.

:: -----------------------------------------------------------
:: 1. Kill all Steam processes
:: -----------------------------------------------------------
echo [1/5] Closing Steam processes...
echo [1/5] Closing Steam processes... >> "%LOGFILE%"

taskkill /F /IM steam.exe /T >> "%LOGFILE%" 2>&1
taskkill /F /IM steamwebhelper.exe /T >> "%LOGFILE%" 2>&1
taskkill /F /IM steamservice.exe /T >> "%LOGFILE%" 2>&1
taskkill /F /IM gameoverlayui.exe /T >> "%LOGFILE%" 2>&1
timeout /t 2 /nobreak >nul
echo [+] Steam processes terminated. >> "%LOGFILE%"

:: -----------------------------------------------------------
:: 2. Download and install Visual C++ 2015-2022 (x86 and x64)
:: -----------------------------------------------------------
echo [2/5] Downloading Visual C++ Redistributable (x86 and x64)...
echo [2/5] Downloading and installing Visual C++ runtimes... >> "%LOGFILE%"

set "TEMP_DIR=%TEMP%\steam_vc_fix"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

set "URL_X86=https://aka.ms/vs/17/release/vc_redist.x86.exe"
set "URL_X64=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "VC_X86=%TEMP_DIR%\vc_redist.x86.exe"
set "VC_X64=%TEMP_DIR%\vc_redist.x64.exe"

echo     - Downloading VC++ x86 (required for Steam)...
echo     Downloading VC++ x86 from %URL_X86% >> "%LOGFILE%"
curl.exe -L -k -s -o "%VC_X86%" "%URL_X86%" || powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%URL_X86%', '%VC_X86%')"

if exist "%VC_X86%" (
    echo     [+] Installing VC++ x86...
    echo     Installing VC++ x86... >> "%LOGFILE%"
    start /wait "" "%VC_X86%" /install /passive /norestart >> "%LOGFILE%" 2>&1
    echo     [+] VC++ x86 installation completed with exit code !errorlevel! >> "%LOGFILE%"
) else (
    echo     [-] Failed to download VC++ x86! >> "%LOGFILE%"
)

echo     - Downloading VC++ x64...
echo     Downloading VC++ x64 from %URL_X64% >> "%LOGFILE%"
curl.exe -L -k -s -o "%VC_X64%" "%URL_X64%" || powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%URL_X64%', '%VC_X64%')"

if exist "%VC_X64%" (
    echo     [+] Installing VC++ x64...
    echo     Installing VC++ x64... >> "%LOGFILE%"
    start /wait "" "%VC_X64%" /install /passive /norestart >> "%LOGFILE%" 2>&1
    echo     [+] VC++ x64 installation completed with exit code !errorlevel! >> "%LOGFILE%"
) else (
    echo     [-] Failed to download VC++ x64! >> "%LOGFILE%"
)

echo [+] Visual C++ packages installed.
echo.

:: -----------------------------------------------------------
:: 3. Detect Steam installation path
:: -----------------------------------------------------------
echo [3/5] Detecting Steam installation folder...
echo [3/5] Detecting Steam installation folder... >> "%LOGFILE%"

set "STEAMPATH="

for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do (
    set "STEAMPATH=%%b"
)

if not defined STEAMPATH (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v "SteamPath" 2^>nul') do (
        set "STEAMPATH=%%b"
    )
)

if defined STEAMPATH (
    set "STEAMPATH=%STEAMPATH:/=\%"
)

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
    echo [!] Could not auto-detect Steam folder.
    set /p STEAMPATH="Please enter the path to Steam folder manually: "
)

if not exist "%STEAMPATH%\steam.exe" (
    color 0C
    echo [ERROR] steam.exe was not found in: "%STEAMPATH%"
    echo [ERROR] steam.exe was not found in: "%STEAMPATH%" >> "%LOGFILE%"
    pause
    exit /b 1
)

echo [+] Found Steam directory: "%STEAMPATH%"
echo [+] Found Steam directory: "%STEAMPATH%" >> "%LOGFILE%"
echo.

:: -----------------------------------------------------------
:: 4. Clean corrupted client files (SAFE CLEANUP)
:: Keeps steamapps (all games) and userdata (configs/saves) intact!
:: -----------------------------------------------------------
echo [4/5] Performing deep cleanup of corrupted Steam client files...
echo (Your games in 'steamapps' and saves in 'userdata' are 100%% safe)
echo [4/5] Starting deep cleanup... >> "%LOGFILE%"

:: Delete package & beta lock
if exist "%STEAMPATH%\package" (
    echo Removing package folder... >> "%LOGFILE%"
    rd /s /q "%STEAMPATH%\package" >> "%LOGFILE%" 2>&1
)

:: Delete cache directories
for %%d in (appcache depotcache bin dumps graphics) do (
    if exist "%STEAMPATH%\%%d" (
        echo Removing folder %%d... >> "%LOGFILE%"
        rd /s /q "%STEAMPATH%\%%d" >> "%LOGFILE%" 2>&1
    )
)

:: Delete core client dlls so Steam downloads fresh verified copies
for %%f in (steamui.dll steam.dll tier0_s.dll vstdlib_s.dll crashhandler.dll crashhandler64.dll steamclient.dll steamclient64.dll) do (
    if exist "%STEAMPATH%\%%f" (
        echo Removing file %%f... >> "%LOGFILE%"
        del /f /q "%STEAMPATH%\%%f" >> "%LOGFILE%" 2>&1
    )
)

echo [+] Cleanup completed. Corrupted binaries removed. >> "%LOGFILE%"
echo.

:: -----------------------------------------------------------
:: 5. Launch Steam with -clearbeta to re-download fresh client
:: -----------------------------------------------------------
echo [5/5] Launching Steam with -clearbeta to force fresh download...
echo [5/5] Launching Steam... >> "%LOGFILE%"

start "" "%STEAMPATH%\steam.exe" -clearbeta

echo Steam launched successfully. >> "%LOGFILE%"
echo Finished at: %DATE% %TIME% >> "%LOGFILE%"

echo.
echo ========================================================
echo  DONE! 
echo  - VC++ 2015-2022 (x86 and x64) installed.
echo  - Corrupted libraries cleaned (Games untouched).
echo  - Steam has been launched and is re-downloading files.
echo.
echo  Full log saved to:
echo  "%LOGFILE%"
echo ========================================================
pause

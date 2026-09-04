@echo off
chcp 65001 >nul
title Исправление ошибки Failed to load steamui.dll
color 0B

echo =======================================================
echo     Автоматическое исправление ошибки steamui.dll
echo =======================================================
echo.

:: 1. Закрываем процессы Steam
echo [1/4] Завершение процессов Steam...
taskkill /F /IM steam.exe /T >nul 2>&1
taskkill /F /IM steamwebhelper.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul

:: 2. Поиск пути установки Steam через реестр
echo [2/4] Поиск папки Steam...
set "STEAMPATH="

for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v "SteamPath" 2^>nul') do (
    set "STEAMPATH=%%b"
)

:: Если в реестре путь со слэшами '/', заменяем на '\'
if defined STEAMPATH (
    set "STEAMPATH=%STEAMPATH:/=\%"
)

:: Если реестр пуст, проверяем стандартные папки
if not exist "%STEAMPATH%\steam.exe" (
    if exist "%ProgramFiles(x86)%\Steam\steam.exe" (
        set "STEAMPATH=%ProgramFiles(x86)%\Steam"
    ) else if exist "%ProgramFiles%\Steam\steam.exe" (
        set "STEAMPATH=%ProgramFiles%\Steam"
    ) else if exist "D:\Steam\steam.exe" (
        set "STEAMPATH=D:\Steam"
    )
)

if not exist "%STEAMPATH%\steam.exe" (
    echo [!] Не удалось автоматически найти Steam.
    set /p STEAMPATH="Введите путь к папке Steam вручную (например, C:\Steam): "
)

if not exist "%STEAMPATH%\steam.exe" (
    color 0C
    echo [ОШИБКА] Файл steam.exe не найден по указанному пути.
    pause
    exit /b
)

echo [+] Steam найден в: "%STEAMPATH%"
echo.

:: 3. Очистка поврежденных файлов обновления и кэша UI
echo [3/4] Удаление поврежденных библиотек и пакетов обновления...
if exist "%STEAMPATH%\steamui.dll" del /f /q "%STEAMPATH%\steamui.dll"
if exist "%STEAMPATH%\package\beta" del /f /q "%STEAMPATH%\package\beta"
if exist "%STEAMPATH%\package" rd /s /q "%STEAMPATH%\package"
if exist "%STEAMPATH%\depotcache" rd /s /q "%STEAMPATH%\depotcache"
if exist "%STEAMPATH%\appcache" rd /s /q "%STEAMPATH%\appcache"

echo [+] Временные файлы и поврежденные библиотеки удалены.
echo.

:: 4. Запуск Steam для чистой самодиагностики и перекачки файлов
echo [4/4] Запуск Steam для повторной загрузки библиотек...
start "" "%STEAMPATH%\steam.exe"

echo.
echo =======================================================
echo  Готово! Steam запустился и заново скачает steamui.dll.
echo =======================================================
pause

@echo off
:: ============================================================
::  Quadra-Seer Sovereign — Flash Drive Installer (Windows)
::
::  Plug in the flash drive, double-click this file. That's it.
::
::  First run takes 15-30 minutes (mostly downloading Python and
::  Node packages). It runs unattended — walk away and come back.
::  Every launch after that is instant.
::
::  What it does:
::    0. Checks for Python 3.10+ and Node.js
::    1. Installs Ollama (from the drive if bundled, or downloads it)
::    2. Loads the AI model (from the drive if bundled, or pulls it)
::    3. Sets up Python + Node dependencies
::    4. Launches Quadra-Seer Sovereign in your browser
::
::  Everything runs on YOUR machine. No cloud. No account.
:: ============================================================
setlocal EnableDelayedExpansion

title Quadra-Seer Sovereign — Flash Drive Installer

set "DRIVE=%~dp0"
set "APP_DIR=%DRIVE%app"
set "VENDOR_DIR=%DRIVE%vendor"
set "MODEL=qwen2.5:3b"
if exist "%VENDOR_DIR%\model.txt" set /p MODEL=<"%VENDOR_DIR%\model.txt"

echo.
echo  ============================================================
echo   QUADRA-SEER SOVEREIGN — Flash Drive Installer
echo  ============================================================
echo.
echo  Drive: %DRIVE%
echo  Model: %MODEL%
echo.

:: ── Step 0: Prerequisites ───────────────────────────────────
echo [0/4] Checking prerequisites...

where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Python 3.10 or newer is not installed.
    echo  Get it from https://www.python.org/downloads/ and re-run this installer.
    echo  (Tip: tick "Add python.exe to PATH" during the Python setup.)
    pause
    exit /b 1
)
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Python 3.10 or newer is required. Please upgrade Python
    echo  from https://www.python.org/downloads/ and re-run this installer.
    pause
    exit /b 1
)
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "PYVER=%%v"
echo  Python %PYVER% found.

where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Node.js is not installed.
    echo  Get the LTS release from https://nodejs.org/ and re-run this installer.
    pause
    exit /b 1
)
for /f %%v in ('node --version 2^>^&1') do set "NODEVER=%%v"
echo  Node.js %NODEVER% found.

:: ── Step 1: Ollama ──────────────────────────────────────────
echo.
echo [1/4] Checking for Ollama...

:: where.exe can miss a fresh install (PATH only refreshes in new
:: shells), so also check Ollama's default install location directly.
set "OLLAMA_OK="
where ollama >nul 2>nul
if %ERRORLEVEL% EQU 0 set "OLLAMA_OK=1"
if not defined OLLAMA_OK if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
    set "OLLAMA_OK=1"
)

if not defined OLLAMA_OK (
    if exist "%VENDOR_DIR%\ollama\OllamaSetup.exe" (
        call :install_ollama_offline
    ) else (
        call :install_ollama_online
    )
    :: Re-check after install (PATH of this shell is stale for new installs)
    if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
        set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
    )
    where ollama >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo  ERROR: Ollama installation failed. Please install manually from
        echo  https://ollama.com/download and re-run this installer.
        pause
        exit /b 1
    )
    echo  Ollama installed.
) else (
    echo  Ollama already installed.
)

:: ── Step 2: Model ───────────────────────────────────────────
echo.
echo [2/4] Checking for AI model (%MODEL%)...

:: If the drive has a bundled model store, run our own Ollama server
:: pointed at it. The Ollama tray app's background server would NOT see
:: OLLAMA_MODELS set in this window, so we stop it and serve from here.
if exist "%VENDOR_DIR%\models\manifests" (
    echo  Using model bundled on flash drive (offline)...
    taskkill /F /IM ollama.exe >nul 2>nul
    taskkill /F /IM "ollama app.exe" >nul 2>nul
    timeout /t 2 /nobreak >nul
    set "OLLAMA_MODELS=%VENDOR_DIR%\models"
    start "Ollama Server" /min ollama serve
)

:: Wait for the server to answer (fresh installs need a few seconds).
:: If nothing is listening after a bit, start our own server.
set "POLL=0"
:wait_ollama_up
ollama list >nul 2>nul
if %ERRORLEVEL% EQU 0 goto :ollama_up
if %POLL% EQU 3 (
    echo  No Ollama server responding - starting one...
    start "Ollama Server" /min ollama serve
)
set /a POLL+=1
if %POLL% GEQ 12 (
    echo.
    echo  ERROR: The Ollama server did not start. Try running
    echo  "ollama serve" in a terminal to see what is wrong.
    pause
    exit /b 1
)
timeout /t 5 /nobreak >nul
goto :wait_ollama_up
:ollama_up

ollama list 2>nul | findstr /C:"%MODEL%" >nul
if %ERRORLEVEL% EQU 0 (
    echo  Model already available.
    goto :model_done
)

echo  Pulling model %MODEL% (internet required, one time)...
ollama pull %MODEL%
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Could not load the model. Check your internet connection
    echo  or make sure the flash drive has the bundled model.
    pause
    exit /b 1
)
:model_done

:: ── Step 3: App dependencies ─────────────────────────────────
echo.
echo [3/4] Setting up Quadra-Seer (this is the long step on first run)...
cd /d "%APP_DIR%"

if not exist ".venv" (
    echo  Creating Python environment...
    python -m venv .venv
)
call .venv\Scripts\activate.bat
echo  Installing Python dependencies (several minutes, one time)...
pip install -q -r requirements.txt
pip install -q "pyarrow==18.1.0"

if not exist "node_modules" (
    echo  Installing Node dependencies...
    call npm install
)

:: ── Step 4: Launch ──────────────────────────────────────────
:: (cd first so the child windows inherit the folder — avoids fragile
:: nested quoting when the drive path contains spaces.)
echo.
echo [4/4] Launching Quadra-Seer Sovereign...
echo.
echo  ============================================================
echo   Starting backend (port 5001)...
echo  ============================================================
start "Quadra-Seer Backend" cmd /k ".venv\Scripts\activate.bat && python atlantean_backend.py"

timeout /t 5 /nobreak >nul

echo  Starting frontend (port 5000)...
start "Quadra-Seer Frontend" cmd /k "npm run dev"

timeout /t 8 /nobreak >nul

echo.
echo  ============================================================
echo   QUADRA-SEER SOVEREIGN IS RUNNING
echo.
echo   Open your browser to: http://localhost:5000
echo.
echo   Everything runs on YOUR machine. No cloud. No account.
echo   Close the Backend, Frontend and Ollama Server windows to stop.
echo  ============================================================
echo.
start http://localhost:5000
pause
goto :eof

:: ── Subroutines ─────────────────────────────────────────────

:install_ollama_offline
echo  Installing Ollama from flash drive (offline)...
:: Inno Setup silent flags. NOTE: the installer launches the Ollama tray
:: app and may never exit on its own, so we poll for ollama.exe on disk
:: instead of waiting on the setup process.
start "" "%VENDOR_DIR%\ollama\OllamaSetup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
set "POLL=0"
:wait_ollama_exe
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" goto :ollama_exe_found
set /a POLL+=1
if %POLL% GEQ 60 (
    echo.
    echo  ERROR: The Ollama installer did not finish within 5 minutes.
    pause
    exit /b 1
)
timeout /t 5 /nobreak >nul
goto :wait_ollama_exe
:ollama_exe_found
taskkill /F /IM OllamaSetup.exe >nul 2>nul
goto :eof

:install_ollama_online
echo  Ollama not found. Downloading installer (internet required)...
set "INSTALLER=%TEMP%\OllamaSetup.exe"
powershell -NoProfile -UseBasicParsing -Command "Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $env:INSTALLER"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Could not download the Ollama installer. Check your
    echo  internet connection and re-run.
    pause
    exit /b 1
)
echo  Running Ollama installer...
start "" "%INSTALLER%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
set "POLL=0"
:wait_ollama_exe2
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" goto :ollama_exe_found2
set /a POLL+=1
if %POLL% GEQ 60 (
    echo.
    echo  ERROR: The Ollama installer did not finish within 5 minutes.
    pause
    exit /b 1
)
timeout /t 5 /nobreak >nul
goto :wait_ollama_exe2
:ollama_exe_found2
taskkill /F /IM OllamaSetup.exe >nul 2>nul
goto :eof

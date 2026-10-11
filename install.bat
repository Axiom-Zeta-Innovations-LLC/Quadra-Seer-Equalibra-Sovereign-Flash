@echo off
:: ============================================================
::  Quadra-Seer Sovereign — Flash Drive Installer (Windows)
::
::  Plug in the flash drive, double-click this file. That's it.
::
::  What it does:
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

echo.
echo  ============================================================
echo   QUADRA-SEER SOVEREIGN — Flash Drive Installer
echo  ============================================================
echo.
echo  Drive: %DRIVE%
echo.

:: ── Step 1: Ollama ──────────────────────────────────────────
echo [1/4] Checking for Ollama...
where ollama >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo  Ollama already installed.
    goto :ollama_done
)

if exist "%VENDOR_DIR%\ollama\OllamaSetup.exe" (
    echo  Installing Ollama from flash drive (offline)...
    start /wait "" "%VENDOR_DIR%\ollama\OllamaSetup.exe" /S
) else (
    echo  Ollama not found. Downloading installer (internet required)...
    set "INSTALLER=%TEMP%\OllamaSetup.exe"
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $env:INSTALLER"
    echo  Running Ollama installer...
    start /wait "" "%INSTALLER%" /S
)

where ollama >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Ollama installation failed. Please install manually from
    echo  https://ollama.com/download and re-run this installer.
    pause
    exit /b 1
)
:ollama_done

:: ── Step 2: Model ───────────────────────────────────────────
echo.
echo [2/4] Checking for AI model (%MODEL%)...

:: If the drive has a bundled model, point Ollama at it
if exist "%VENDOR_DIR%\models" (
    echo  Using model bundled on flash drive (offline)...
    set "OLLAMA_MODELS=%VENDOR_DIR%\models"
)

ollama list 2>nul | findstr /C:"%MODEL%" >nul
if %ERRORLEVEL% EQU 0 (
    echo  Model already available.
    goto :model_done
)

echo  Loading model (this takes a few minutes on first run)...
ollama pull %MODEL%
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: Could not load the model. Check your internet connection
    echo  or make sure the flash drive has the bundled model.
    pause
    exit /b 1
)
:model_done

:: ── Step 3: App dependencies ────────────────────────────────
echo.
echo [3/4] Setting up Quadra-Seer...
cd /d "%APP_DIR%"

if not exist ".venv" (
    echo  Creating Python environment...
    python -m venv .venv
)
call .venv\Scripts\activate.bat
echo  Installing Python dependencies...
pip install -q -r requirements.txt
pip install -q "pyarrow==18.1.0"

if not exist "node_modules" (
    echo  Installing Node dependencies...
    call npm install
)

:: ── Step 4: Launch ──────────────────────────────────────────
echo.
echo [4/4] Launching Quadra-Seer Sovereign...
echo.
echo  ============================================================
echo   Starting backend (port 5001)...
echo  ============================================================
start "Quadra-Seer Backend" cmd /k "cd /d "%APP_DIR%" && .venv\Scripts\activate.bat && python atlantean_backend.py"

timeout /t 5 /nobreak >nul

echo  Starting frontend (port 5000)...
start "Quadra-Seer Frontend" cmd /k "cd /d "%APP_DIR%" && npm run dev"

timeout /t 8 /nobreak >nul

echo.
echo  ============================================================
echo   QUADRA-SEER SOVEREIGN IS RUNNING
echo.
echo   Open your browser to: http://localhost:5000
echo.
echo   Everything runs on YOUR machine. No cloud. No account.
echo   Close the Backend and Frontend windows to stop.
echo  ============================================================
echo.
start http://localhost:5000
pause

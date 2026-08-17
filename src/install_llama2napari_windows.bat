@echo off
:: ================================================
:: llama-cpp-python Installer for Napari (Windows)
:: Auto-detects CUDA version and installs matching wheel via pip
:: ================================================

setlocal EnableDelayedExpansion

echo.
echo ========================================
echo  llama-cpp-python Installer for Napari
echo ========================================
echo.

rem -------------------------------------------------
rem 1. Ask for the Napari installation path
rem -------------------------------------------------
set "DEFAULT_APPDATA_ROOT=%LOCALAPPDATA%"
set "NAPARI_PATH_INPUT="
set /p "NAPARI_PATH_INPUT=Napari installation directory [%DEFAULT_APPDATA_ROOT%]: "

if not defined NAPARI_PATH_INPUT (
    set "APPDATA_ROOT=%DEFAULT_APPDATA_ROOT%"
) else (
    set "APPDATA_ROOT=%NAPARI_PATH_INPUT%"
)

if "%APPDATA_ROOT:~-1%"=="\" set "APPDATA_ROOT=%APPDATA_ROOT:~0,-1%"

echo Scanning for Napari folder in:
echo   %APPDATA_ROOT%
echo.

rem -------------------------------------------------
rem 2. Check a specific napari-* folder or scan its parent
rem -------------------------------------------------
set "NAPARI_ENV="
set "CONDA_EXE="
set "PYTHON_EXE="

for %%F in ("%APPDATA_ROOT%") do set "ROOT_NAME=%%~nxF"

if /i "!ROOT_NAME:~0,7!"=="napari-" (
    set "FULLDIR=%APPDATA_ROOT%"
    set "TEST_EXE=!FULLDIR!\envs\!ROOT_NAME!\Scripts\conda.exe"
    set "TEST_PYTHON=!FULLDIR!\envs\!ROOT_NAME!\python.exe"
    echo   [CHECK] "!FULLDIR!"
    if exist "!TEST_EXE!" if exist "!TEST_PYTHON!" (
        set "NAPARI_ENV=!FULLDIR!"
        set "CONDA_EXE=!TEST_EXE!"
        set "PYTHON_EXE=!TEST_PYTHON!"
        echo   [FOUND] Napari environment: !ROOT_NAME!
        goto :FOUND_ENV
    ) else (
        echo   [MISS] conda.exe/python.exe not present in this folder
    )
) else (
    for /f "delims=" %%F in ('dir "%APPDATA_ROOT%\napari-*" /b /ad 2^>nul') do (
        set "FULLDIR=%APPDATA_ROOT%\%%F"
        set "TEST_EXE=!FULLDIR!\envs\%%F\Scripts\conda.exe"
        set "TEST_PYTHON=!FULLDIR!\envs\%%F\python.exe"
        echo   [CHECK] "!FULLDIR!"
        if exist "!TEST_EXE!" if exist "!TEST_PYTHON!" (
            set "NAPARI_ENV=!FULLDIR!"
            set "CONDA_EXE=!TEST_EXE!"
            set "PYTHON_EXE=!TEST_PYTHON!"
            echo   [FOUND] Napari environment: %%F
            goto :FOUND_ENV
        ) else (
            echo   [MISS] conda.exe/python.exe not present in this folder
        )
    )
)

rem -------------------------------------------------
rem No napari folder at all
rem -------------------------------------------------
echo.
echo [ERROR] No Napari installation found!
echo Expected folder pattern: napari-x.x.x  (e.g. napari-0.6.4)
echo.
echo Make sure Napari was installed with the official Windows installer.
pause
exit /b 1


:FOUND_ENV
echo.
echo [OK] Using Napari environment: %NAPARI_ENV%
echo      Conda executable: %CONDA_EXE%
echo      Python executable: %PYTHON_EXE%
echo.

rem -------------------------------------------------
rem 3. NVIDIA / CUDA detection
rem -------------------------------------------------
set "CUDA_VERSION="
set "CUDA_CODE="
set "CUDA_TAG="

echo Checking for CUDA version...

rem nvidia-smi reports the newest CUDA runtime supported by the installed driver.
rem Recent Windows drivers label this "CUDA UMD Version"; older drivers use
rem "CUDA Version".
for /f "tokens=3 delims=:" %%A in ('nvidia-smi 2^>nul ^| findstr /C:"CUDA Version:" /C:"CUDA UMD Version:"') do (
    for /f "tokens=1" %%B in ("%%A") do set "CUDA_VERSION=%%B"
)

if defined CUDA_VERSION (
    echo [OK] NVIDIA driver supports CUDA Version: %CUDA_VERSION%

    rem Convert major.minor to a comparable integer, e.g. 13.3 becomes 1303.
    for /f "tokens=1,2 delims=." %%A in ("%CUDA_VERSION%") do (
        set /a CUDA_CODE=%%A * 100 + %%B
    )
) else (
    echo [INFO] nvidia-smi did not report a CUDA version. Using CPU wheel.
)

rem Select the newest available wheel that the installed driver can support.
if defined CUDA_CODE (
    if !CUDA_CODE! GEQ 1108 set "CUDA_TAG=cu118"
    if !CUDA_CODE! GEQ 1201 set "CUDA_TAG=cu121"
    if !CUDA_CODE! GEQ 1202 set "CUDA_TAG=cu122"
    if !CUDA_CODE! GEQ 1203 set "CUDA_TAG=cu123"
    if !CUDA_CODE! GEQ 1204 set "CUDA_TAG=cu124"
    if !CUDA_CODE! GEQ 1205 set "CUDA_TAG=cu125"
    if !CUDA_CODE! GEQ 1300 set "CUDA_TAG=cu130"
    if !CUDA_CODE! GEQ 1302 set "CUDA_TAG=cu132"
)

if defined CUDA_TAG (
    echo [OK] Nearest compatible CUDA wheel tag: %CUDA_TAG%
    goto :GPU_INSTALL
)

if defined CUDA_VERSION (
    echo [WARN] No available CUDA wheel supports detected version %CUDA_VERSION%.
    echo [WARN] Falling back to CPU wheel.
)
goto :CPU_INSTALL


rem ================================================
:GPU_INSTALL
echo.
echo Installing llama-cpp-python with CUDA wheel %CUDA_TAG% ...
call "%PYTHON_EXE%" -m pip install --upgrade pip
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to upgrade pip!
    pause
    exit /b 1
)
call "%PYTHON_EXE%" -m pip install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/%CUDA_TAG% --no-cache-dir
if errorlevel 1 (
    echo.
    echo [ERROR] CUDA wheel install failed -> falling back to CPU.
    goto :CPU_INSTALL
)
echo.
echo [SUCCESS] llama-cpp-python installed with CUDA wheel %CUDA_TAG%!
goto :END


rem ================================================
:CPU_INSTALL
echo.
echo Installing llama-cpp-python with CPU wheel ...
call "%PYTHON_EXE%" -m pip install --upgrade pip
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to upgrade pip!
    pause
    exit /b 1
)
call "%PYTHON_EXE%" -m pip install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu
if errorlevel 1 (
    echo.
    echo [ERROR] CPU wheel install failed!
    pause
    exit /b 1
)
echo.
echo [SUCCESS] llama-cpp-python installed with CPU wheel!
goto :END


rem ================================================
:END
echo.
echo ========================================
echo Installation complete!
echo Napari folder : %NAPARI_ENV%
if defined CUDA_TAG (
    echo Installed wheel target: %CUDA_TAG%
) else (
    echo Installed wheel target: cpu
)
echo llama-cpp-python ready for use.
echo ========================================
echo.
pause
exit /b 0

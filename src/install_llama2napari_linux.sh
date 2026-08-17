#!/usr/bin/env bash
# ================================================
# llama-cpp-python Installer for Napari (Linux)
# Searches a user-selected path (default: ~/.local) and installs
# llama-cpp-python with CPU or CUDA wheels via pip
# ================================================

set -euo pipefail

echo
echo "========================================"
echo " llama-cpp-python Installer for Napari"
echo "========================================"
echo

# -------------------------------------------------
# 1. Ask for the Napari installation path
# -------------------------------------------------
DEFAULT_APPDATA_ROOT="$HOME/.local"
NAPARI_PATH_INPUT=""

read -r -p "Napari installation directory [$DEFAULT_APPDATA_ROOT]: " NAPARI_PATH_INPUT || true

if [ -z "$NAPARI_PATH_INPUT" ]; then
    APPDATA_ROOT="$DEFAULT_APPDATA_ROOT"
elif [ "$NAPARI_PATH_INPUT" = "~" ]; then
    APPDATA_ROOT="$HOME"
elif [[ "$NAPARI_PATH_INPUT" == "~/"* ]]; then
    APPDATA_ROOT="$HOME/${NAPARI_PATH_INPUT:2}"
else
    APPDATA_ROOT="$NAPARI_PATH_INPUT"
fi

echo "Scanning for Napari folder in:"
echo "  $APPDATA_ROOT"
echo

# -------------------------------------------------
# 2. Look for napari-* folders
# -------------------------------------------------
NAPARI_ENV=""
PYTHON_EXE=""

if [[ "$(basename "$APPDATA_ROOT")" == napari-* ]]; then
    NAPARI_FOLDERS=("$APPDATA_ROOT")
else
    NAPARI_FOLDERS=("$APPDATA_ROOT"/napari-*)
fi

for folder in "${NAPARI_FOLDERS[@]}"; do
    [ -d "$folder" ] || continue

    echo "  [CHECK] $folder"

    TEST_PYTHON="$folder/envs/$(basename "$folder")/bin/python"

    if [ -x "$TEST_PYTHON" ]; then
        NAPARI_ENV="$folder"
        PYTHON_EXE="$TEST_PYTHON"
        echo "  [FOUND] Napari environment: $(basename "$folder")"
        break
    fi
done

# -------------------------------------------------
# 3. Handle no environment found
# -------------------------------------------------
if [ -z "$NAPARI_ENV" ]; then
    echo
    echo "[ERROR] No Napari installation found!"
    echo "Expected folder pattern: napari-x.x.x  (e.g. napari-0.6.5)"
    echo
    echo "Make sure Napari was installed with the official Linux installer."
    exit 1
fi

# -------------------------------------------------
# 4. Detect CUDA version (if any)
# -------------------------------------------------
CUDA_VERSION=""
CUDA_CODE=""
CUDA_TAG=""

if command -v nvidia-smi >/dev/null 2>&1; then
    CUDA_VERSION="$(
        nvidia-smi 2>/dev/null \
            | grep -oE 'CUDA( UMD)? Version: [0-9]+\.[0-9]+' \
            | awk 'NR == 1 { print $NF }' \
            || true
    )"
fi

if [ -n "$CUDA_VERSION" ]; then
    echo "[OK] NVIDIA driver supports CUDA version: $CUDA_VERSION"

    CUDA_MAJOR="${CUDA_VERSION%%.*}"
    CUDA_MINOR="${CUDA_VERSION#*.}"
    CUDA_CODE=$((10#$CUDA_MAJOR * 100 + 10#$CUDA_MINOR))
else
    echo "[INFO] nvidia-smi did not report a CUDA version."
fi

# Select the newest available wheel that the installed driver can support.
if [ -n "$CUDA_CODE" ]; then
    if (( CUDA_CODE >= 1108 )); then CUDA_TAG="cu118"; fi
    if (( CUDA_CODE >= 1201 )); then CUDA_TAG="cu121"; fi
    if (( CUDA_CODE >= 1202 )); then CUDA_TAG="cu122"; fi
    if (( CUDA_CODE >= 1203 )); then CUDA_TAG="cu123"; fi
    if (( CUDA_CODE >= 1204 )); then CUDA_TAG="cu124"; fi
    if (( CUDA_CODE >= 1205 )); then CUDA_TAG="cu125"; fi
    if (( CUDA_CODE >= 1300 )); then CUDA_TAG="cu130"; fi
    if (( CUDA_CODE >= 1302 )); then CUDA_TAG="cu132"; fi
fi

# -------------------------------------------------
# 5. Install llama-cpp-python with pip
# -------------------------------------------------
echo
echo "[INFO] Installing llama-cpp-python into $NAPARI_ENV ..."
"$PYTHON_EXE" -m pip install --upgrade pip

if [ -n "$CUDA_TAG" ]; then
    echo "[INFO] Nearest compatible CUDA wheel for $CUDA_VERSION: $CUDA_TAG"
    "$PYTHON_EXE" -m pip install llama-cpp-python \
        --extra-index-url "https://abetlen.github.io/llama-cpp-python/whl/$CUDA_TAG" --no-cache-dir
else
    if [ -n "$CUDA_VERSION" ]; then
        echo "[WARN] No available CUDA wheel supports detected version $CUDA_VERSION."
        echo "[WARN] Falling back to CPU wheel."
    else
        echo "[INFO] No CUDA detected. Using CPU wheel."
    fi

    "$PYTHON_EXE" -m pip install llama-cpp-python \
        --extra-index-url "https://abetlen.github.io/llama-cpp-python/whl/cpu"
fi

echo
echo "✅ Installation complete!"
echo "Environment: $NAPARI_ENV"
echo "Python used: $PYTHON_EXE"
if [ -n "$CUDA_TAG" ]; then
    echo "Installed wheel target: $CUDA_TAG"
else
    echo "Installed wheel target: cpu"
fi
echo

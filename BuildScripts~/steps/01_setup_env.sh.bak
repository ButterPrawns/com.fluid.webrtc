#!/bin/bash -eu

# This script sets up the environment for WebRTC Android build

# Define paths and variables
export COMMAND_DIR=$(cd $(dirname $0)/..; pwd)
export PATH="$(pwd)/depot_tools:$PATH"
export WEBRTC_VERSION=5845
export OUTPUT_DIR="$(pwd)/out"
export ARTIFACTS_DIR="$(pwd)/artifacts"

# Set Android SDK and NDK paths - using the correct WSL path format
export ANDROID_SDK_ROOT="/mnt/c/Users/kaika/AppData/Local/Android/Sdk"
export ANDROID_NDK_VERSION="28.0.12916984"  # Updated to match your installed version
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION"

# Check if Android SDK and NDK exist
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
  echo "ERROR: Android SDK not found at $ANDROID_SDK_ROOT"
  echo "Please install Android Studio and SDK from https://developer.android.com/studio"
  echo "After installation, update ANDROID_SDK_ROOT in this script."
  echo "Required components:"
  echo "  - Android SDK Platform (API 33 or latest)"
  echo "  - Android SDK Platform-Tools"
  echo "  - Android SDK Build-Tools"
  echo "  - Android NDK (version $ANDROID_NDK_VERSION)"
  echo "You can continue the build without Android SDK, but the Android library won't be built."
  export BUILD_ANDROID=false
else
  export BUILD_ANDROID=true
  # Check if NDK exists
  if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "WARNING: Android NDK not found at $ANDROID_NDK_ROOT"
    echo "Please install Android NDK through Android Studio SDK Manager."
    echo "You can continue the build without Android NDK, but the Android library won't be built."
    export BUILD_ANDROID=false
  fi
fi

# Create necessary directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$ARTIFACTS_DIR/lib"
mkdir -p "$ARTIFACTS_DIR/lib/arm64"
mkdir -p "$ARTIFACTS_DIR/lib/x64"

# Check for depot_tools and install if missing
if [ ! -e "$(pwd)/depot_tools" ]; then
  echo "Cloning depot_tools..."
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

# Add Python bin path after depot_tools installation
export PYTHON3_BIN="$(pwd)/depot_tools/python-bin/python3"

echo "Environment setup complete. Variables defined:"
echo "COMMAND_DIR: $COMMAND_DIR"
echo "PATH: $PATH"
echo "WEBRTC_VERSION: $WEBRTC_VERSION"
echo "OUTPUT_DIR: $OUTPUT_DIR"
echo "ARTIFACTS_DIR: $ARTIFACTS_DIR"
echo "PYTHON3_BIN: $PYTHON3_BIN"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo "ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
echo "BUILD_ANDROID: $BUILD_ANDROID" 
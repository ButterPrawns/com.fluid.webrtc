#!/bin/bash -eu

# This script sets up the environment for WebRTC Android build

# Define paths and variables
export COMMAND_DIR=$(cd $(dirname $0)/..; pwd)
export PATH="$(pwd)/depot_tools:$PATH"
export WEBRTC_VERSION=5845
export OUTPUT_DIR="$(pwd)/out"
export ARTIFACTS_DIR="$(pwd)/artifacts"

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
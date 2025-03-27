#!/bin/bash

# Common variables
export COMMAND_DIR=$(cd $(dirname $0); pwd)
export PATH="$(pwd)/depot_tools:$PATH"
export WEBRTC_VERSION=5845
export OUTPUT_DIR="$(pwd)/out"
export ARTIFACTS_DIR="$(pwd)/artifacts"
export PYTHON3_BIN="$(pwd)/depot_tools/python-bin/python3"

# Create necessary directories
mkdir -p "$ARTIFACTS_DIR/lib"

# Check if a command succeeded
check_result() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed"
    exit 1
  fi
} 
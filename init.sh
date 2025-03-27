#!/bin/bash -eu

# Source common variables and functions
source $(dirname $0)/common.sh

echo "Initializing build environment..."

# Clone depot_tools if not already present
if [ ! -e "$(pwd)/depot_tools" ]; then
  echo "Cloning depot_tools..."
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
  check_result "Cloning depot_tools"
fi

echo "Initialization complete" 
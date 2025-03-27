#!/bin/bash -eu

# This script runs all the steps to build WebRTC for Android

SCRIPT_DIR=$(cd $(dirname $0); pwd)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)

function run_step() {
  step_file=$1
  step_name=$2
  
  echo ""
  echo "${BOLD}${GREEN}RUNNING STEP: ${step_name}${NORMAL}"
  echo "========================================"
  
  if bash "$step_file"; then
    echo "${BOLD}${GREEN}✓ STEP COMPLETED: ${step_name}${NORMAL}"
    return 0
  else
    echo "${BOLD}${RED}✗ STEP FAILED: ${step_name} (Exit code: $?)${NORMAL}"
    return 1
  fi
}

function print_logs() {
  if [ -d "$(pwd)/logs" ]; then
    ls -la "$(pwd)/logs"
    echo "${YELLOW}Check the logs directory for detailed error information.${NORMAL}"
  fi
}

# Create logs directory
mkdir -p "$(pwd)/logs"

echo "${BOLD}${GREEN}Starting WebRTC Android build process${NORMAL}"
echo "========================================"

# Run each step and capture logs
if ! run_step "$SCRIPT_DIR/01_setup_env.sh" "Setup Environment" > "$(pwd)/logs/01_setup_env.log" 2>&1; then
  echo "${RED}Environment setup failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

if ! run_step "$SCRIPT_DIR/02_fetch_webrtc.sh" "Fetch WebRTC Source" > "$(pwd)/logs/02_fetch_webrtc.log" 2>&1; then
  echo "${RED}WebRTC fetch failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

if ! run_step "$SCRIPT_DIR/03_apply_patches.sh" "Apply Patches" > "$(pwd)/logs/03_apply_patches.log" 2>&1; then
  echo "${RED}Patch application failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

if ! run_step "$SCRIPT_DIR/04_apply_namespace_shadowing.sh" "Apply Namespace Shadowing" > "$(pwd)/logs/04_apply_namespace_shadowing.log" 2>&1; then
  echo "${RED}Namespace shadowing failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

if ! run_step "$SCRIPT_DIR/05_build_static_libs.sh" "Build Static Libraries" > "$(pwd)/logs/05_build_static_libs.log" 2>&1; then
  echo "${RED}Static library build failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

if ! run_step "$SCRIPT_DIR/06_build_aar.sh" "Build AAR" > "$(pwd)/logs/06_build_aar.log" 2>&1; then
  echo "${RED}AAR build failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

if ! run_step "$SCRIPT_DIR/07_package_artifacts.sh" "Package Artifacts" > "$(pwd)/logs/07_package_artifacts.log" 2>&1; then
  echo "${RED}Artifacts packaging failed. Check logs for details.${NORMAL}"
  print_logs
  exit 1
fi

echo ""
echo "${BOLD}${GREEN}WebRTC Android build completed successfully!${NORMAL}"
echo "Artifacts are available in: $(pwd)/artifacts"
echo "AAR files are located in: $(pwd)/artifacts/lib/" 
#!/bin/bash -eu

# Main script for building WebRTC for Android
# This script orchestrates the entire build process by calling all the component scripts

# Record starting time
START_TIME=$(date +%s)

# Define the script directory
SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "=== WebRTC for Android Build Process ==="
echo "Starting build at: $(date)"
echo

echo "Step 1: Initialization"
${SCRIPT_DIR}/init.sh
echo

echo "Step 2: Fetching WebRTC source code"
${SCRIPT_DIR}/fetch_source.sh
echo

echo "Step 3: Applying patches"
${SCRIPT_DIR}/apply_patches.sh
echo

echo "Step 4: Building static libraries"
${SCRIPT_DIR}/build_libs.sh
echo

echo "Step 5: Building AAR packages"
${SCRIPT_DIR}/build_aar.sh
echo

echo "Step 6: Packaging"
${SCRIPT_DIR}/package.sh
echo

# Calculate and display build time
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
HOURS=$((ELAPSED_TIME / 3600))
MINUTES=$(( (ELAPSED_TIME % 3600) / 60 ))
SECONDS=$((ELAPSED_TIME % 60))

echo "=== Build Completed Successfully ==="
echo "Total build time: ${HOURS}h ${MINUTES}m ${SECONDS}s"
echo "Output available at: $(pwd)/artifacts/webrtc-android.zip" 
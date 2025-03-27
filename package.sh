#!/bin/bash -eu

# Source common variables and functions
source $(dirname $0)/common.sh

echo "Packaging WebRTC for Android..."

echo "Generating license information..."
"$PYTHON3_BIN" "./src/tools_webrtc/libs/generate_licenses.py" \
  --target :webrtc "$OUTPUT_DIR" "$OUTPUT_DIR"
check_result "License generation"

echo "Collecting header files..."
cd src
find . -name "*.h" -print | cpio -pd "$ARTIFACTS_DIR/include"
check_result "Header collection"

echo "Copying license file..."
cp "$OUTPUT_DIR/LICENSE.md" "$ARTIFACTS_DIR"
check_result "License copying"

echo "Creating final zip archive..."
cd "$ARTIFACTS_DIR"
zip -r webrtc-android.zip lib include LICENSE.md
check_result "Creating zip archive"

echo "Packaging complete. Output available at: $ARTIFACTS_DIR/webrtc-android.zip" 
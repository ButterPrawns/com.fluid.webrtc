#!/bin/bash -eu

# This script packages the artifacts for WebRTC Android

# Load environment variables
source $(dirname $0)/01_setup_env.sh

echo "Packaging artifacts..."

# Generate license information
echo "Generating license information..."
"$PYTHON3_BIN" "./src/tools_webrtc/libs/generate_licenses.py" \
  --target :webrtc "$OUTPUT_DIR" "$OUTPUT_DIR"

# Copy license file
if [ -f "$OUTPUT_DIR/LICENSE.md" ]; then
  echo "Copying LICENSE.md to artifacts directory..."
  cp "$OUTPUT_DIR/LICENSE.md" "$ARTIFACTS_DIR"
else
  echo "WARNING: LICENSE.md not found in output directory."
fi

# Copy header files
echo "Copying header files to artifacts directory..."
cd src
find . -name "*.h" -print | cpio -pd "$ARTIFACTS_DIR/include"
cd ..

# Create the zip file
echo "Creating final zip archive..."
cd "$ARTIFACTS_DIR"
zip -r webrtc-android.zip lib include LICENSE.md

# Verify final output
echo "Verifying output files..."
if [ -f "$ARTIFACTS_DIR/webrtc-android.zip" ]; then
  echo "Success: webrtc-android.zip created."
  echo "AAR files are located in: $ARTIFACTS_DIR/lib/"
  
  # List the contents of the artifacts directory
  echo "Artifacts directory contents:"
  ls -la "$ARTIFACTS_DIR/lib/"
else
  echo "ERROR: Failed to create webrtc-android.zip"
  exit 1
fi

echo "Artifacts packaging completed successfully." 
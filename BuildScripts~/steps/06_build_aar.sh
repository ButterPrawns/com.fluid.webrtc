#!/bin/bash -eu

# This script builds the AAR file for WebRTC Android

# Load environment variables
source $(dirname $0)/01_setup_env.sh

echo "Building AAR files..."

pushd src

for is_debug in "true" "false"
do
  build_type=$([ "$is_debug" = "true" ] && echo "debug" || echo "release")
  echo "Building $build_type AAR..."
  
  # use `treat_warnings_as_errors` option to avoid deprecation warnings
  echo "Running build_aar.py script..."
  "$PYTHON3_BIN" tools_webrtc/android/build_aar.py \
    --build-dir $OUTPUT_DIR \
    --output $OUTPUT_DIR/libwebrtc.aar \
    --arch arm64-v8a x86_64 \
    --extra-gn-args "is_debug=${is_debug} \
      is_java_debug=${is_debug} \
      rtc_use_h264=false \
      rtc_include_tests=false \
      rtc_build_examples=false \
      is_component_build=false \
      use_rtti=true \
      use_custom_libcxx=false \
      treat_warnings_as_errors=false \
      use_errorprone_java_compiler=false \
      use_cxx17=true"

  # Verify the AAR was actually built
  if [ ! -f "$OUTPUT_DIR/libwebrtc.aar" ]; then
    echo "ERROR: Failed to build libwebrtc.aar for $build_type"
    exit 1
  fi

  filename="libwebrtc.aar"
  if [ $is_debug = "true" ]; then
    filename="libwebrtc-debug.aar"
  fi
  
  # copy aar
  echo "Copying AAR to artifacts directory..."
  cp "$OUTPUT_DIR/libwebrtc.aar" "$ARTIFACTS_DIR/lib/${filename}"
  
  echo "AAR file for $build_type built successfully."
done

popd

echo "All AAR files built successfully." 
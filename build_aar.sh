#!/bin/bash -eu

# Source common variables and functions
source $(dirname $0)/common.sh

build_aar() {
  local is_debug=$1
  
  echo "Building WebRTC AAR package (debug=${is_debug})..."
  
  pushd src
  
  echo "Running build_aar.py..."
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
  check_result "Building AAR (debug=${is_debug})"
  
  filename="libwebrtc.aar"
  if [ $is_debug = "true" ]; then
    filename="libwebrtc-debug.aar"
  fi
  
  echo "Copying AAR to artifacts directory..."
  cp "$OUTPUT_DIR/libwebrtc.aar" "$ARTIFACTS_DIR/lib/${filename}"
  check_result "Copying AAR (debug=${is_debug})"
  
  popd
  
  echo "AAR package (debug=${is_debug}) built successfully"
}

echo "Building WebRTC AAR packages..."

# Build debug AAR
build_aar "true"

# Build release AAR
build_aar "false"

echo "All WebRTC AAR packages built successfully" 
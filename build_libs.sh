#!/bin/bash -eu

# Source common variables and functions
source $(dirname $0)/common.sh

build_lib() {
  local target_cpu=$1
  local is_debug=$2
  
  echo "Building WebRTC for target_cpu=${target_cpu}, is_debug=${is_debug}"
  
  mkdir -p "$ARTIFACTS_DIR/lib/${target_cpu}"
  
  echo "Generating ninja files..."
  gn gen "$OUTPUT_DIR" --root="src" \
    --args="is_debug=${is_debug} \
    is_java_debug=${is_debug} \
    target_os=\"android\" \
    target_cpu=\"${target_cpu}\" \
    rtc_use_h264=false \
    rtc_include_tests=false \
    rtc_build_examples=false \
    is_component_build=false \
    use_rtti=true \
    use_custom_libcxx=false \
    treat_warnings_as_errors=false \
    use_errorprone_java_compiler=false \
    use_cxx17=true"
  check_result "GN generation for ${target_cpu} (debug=${is_debug})"
  
  echo "Building static library..."
  ninja -C "$OUTPUT_DIR" webrtc
  check_result "Ninja build for ${target_cpu} (debug=${is_debug})"
  
  filename="libwebrtc.a"
  if [ $is_debug = "true" ]; then
    filename="libwebrtcd.a"
  fi
  
  echo "Copying static library to artifacts directory..."
  cp "$OUTPUT_DIR/obj/libwebrtc.a" "$ARTIFACTS_DIR/lib/${target_cpu}/${filename}"
  check_result "Copying static library for ${target_cpu} (debug=${is_debug})"
  
  echo "Build for ${target_cpu} (debug=${is_debug}) completed"
}

echo "Building WebRTC static libraries..."

# Build for arm64
build_lib "arm64" "true"   # Debug
build_lib "arm64" "false"  # Release

# Build for x64
build_lib "x64" "true"     # Debug
build_lib "x64" "false"    # Release

echo "All WebRTC static libraries built successfully" 
#!/bin/bash -eu

# This script builds the static libraries for WebRTC

# Load environment variables
source $(dirname $0)/01_setup_env.sh

echo "Building static libraries..."

# Ensure Clang is properly installed
echo "Checking for Clang installation..."
if [ ! -d "src/third_party/llvm-build" ]; then
  echo "Clang not found. Installing Clang (this is much faster than a full sync)..."
  python3 src/tools/clang/scripts/update.py
fi

# Install required sysroot
echo "Installing required sysroot..."
python3 src/build/linux/sysroot_scripts/install-sysroot.py --arch=amd64

# Generate LASTCHANGE files
echo "Generating git commit information..."
pushd src
# Get the commit timestamp
COMMIT_TIMESTAMP=$(git show -s --format=%ct HEAD)
# Create LASTCHANGE.committime with just the timestamp
echo "$COMMIT_TIMESTAMP" > build/util/LASTCHANGE.committime
# Create LASTCHANGE with the full information
python3 build/util/lastchange.py -o build/util/LASTCHANGE
popd

for target_cpu in "arm64" "x64"
do
  echo "Building for CPU architecture: $target_cpu"
  mkdir -p "$ARTIFACTS_DIR/lib/${target_cpu}"

  for is_debug in "true" "false"
  do
    build_type=$([ "$is_debug" = "true" ] && echo "debug" || echo "release")
    echo "Building $build_type version..."
    
    # generate ninja files
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

    # build static library
    echo "Building WebRTC static library with ninja..."
    ninja -C "$OUTPUT_DIR" webrtc

    # Verify the library was actually built
    if [ ! -f "$OUTPUT_DIR/obj/libwebrtc.a" ]; then
      echo "ERROR: Failed to build libwebrtc.a for $target_cpu $build_type"
      exit 1
    fi

    filename="libwebrtc.a"
    if [ $is_debug = "true" ]; then
      filename="libwebrtcd.a"
    fi

    # copy static library
    echo "Copying static library to artifacts directory..."
    cp "$OUTPUT_DIR/obj/libwebrtc.a" "$ARTIFACTS_DIR/lib/${target_cpu}/${filename}"
    
    echo "Build completed for $target_cpu $build_type"
  done
done

echo "All static libraries built successfully." 
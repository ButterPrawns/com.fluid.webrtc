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

# Install required sysroots
echo "Installing required sysroots..."
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

# Check if Android build is enabled
if [ "$BUILD_ANDROID" != "true" ]; then
  echo "WARNING: Skipping Android build because Android SDK/NDK is not properly installed."
  echo "If you want to build for Android, please install Android SDK and NDK and update the paths in 01_setup_env.sh"
  exit 0
fi

# Try to find Android platform JAR
ANDROID_PLATFORM_DIR="$ANDROID_SDK_ROOT/platforms"
PLATFORM_JAR=""

# Check if platforms directory exists
if [ -d "$ANDROID_PLATFORM_DIR" ]; then
  echo "Found Android platforms directory at: $ANDROID_PLATFORM_DIR"
  
  # Look for android-33 or any other platform
  if [ -d "$ANDROID_PLATFORM_DIR/android-33" ]; then
    PLATFORM_VERSION="android-33"
  else
    # Find any platform directory
    PLATFORM_VERSION=$(ls -1 "$ANDROID_PLATFORM_DIR" | grep android- | sort -r | head -1)
  fi
  
  if [ -n "$PLATFORM_VERSION" ]; then
    echo "Using platform version: $PLATFORM_VERSION"
    PLATFORM_JAR="$ANDROID_PLATFORM_DIR/$PLATFORM_VERSION/android.jar"
    
    if [ -f "$PLATFORM_JAR" ]; then
      echo "Found platform JAR at: $PLATFORM_JAR"
    else
      echo "WARNING: Platform JAR not found at: $PLATFORM_JAR"
      export BUILD_ANDROID=false
    fi
  else
    echo "WARNING: No Android platform found in $ANDROID_PLATFORM_DIR"
    export BUILD_ANDROID=false
  fi
else
  echo "WARNING: Android platforms directory not found at: $ANDROID_PLATFORM_DIR"
  export BUILD_ANDROID=false
fi

# Re-check if Android build is enabled after platform JAR check
if [ "$BUILD_ANDROID" != "true" ]; then
  echo "WARNING: Skipping Android build because required Android platform files are missing."
  echo "Please install Android SDK platforms through Android Studio SDK Manager."
  exit 0
fi

# Set the exact sysroot path based on the user's discovery
NDK_SYSROOT="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
echo "Using NDK sysroot at: $NDK_SYSROOT"

# Verify sysroot exists
if [ ! -d "$NDK_SYSROOT" ]; then
  echo "ERROR: NDK sysroot not found at $NDK_SYSROOT"
  echo "Please check your NDK installation."
  exit 1
fi

# Verify C++ headers exist in sysroot
if [ ! -d "$NDK_SYSROOT/usr/include/c++" ]; then
  echo "WARNING: C++ headers not found in NDK sysroot at $NDK_SYSROOT/usr/include/c++"
  echo "This may cause compilation errors."
fi

# Install Android NDK sysroot
echo "Installing Android NDK sysroot..."
if [ ! -d "src/third_party/android_toolchain" ]; then
  echo "Downloading Android NDK..."
  python3 src/build/install-build-deps-android.sh
fi

# Copy the platform JAR to the output directory to ensure it's found
mkdir -p "$OUTPUT_DIR/platforms/$PLATFORM_VERSION"
echo "Copying Android platform JAR to output directory..."
cp "$PLATFORM_JAR" "$OUTPUT_DIR/platforms/$PLATFORM_VERSION/android.jar"

for target_cpu in "arm64"
do
  echo "Building for CPU architecture: $target_cpu"
  mkdir -p "$ARTIFACTS_DIR/lib/${target_cpu}"

  for is_debug in "true" "false"
  do
    build_type=$([ "$is_debug" = "true" ] && echo "debug" || echo "release")
    echo "Building $build_type version..."
    
    # generate ninja files
    echo "Generating ninja files..."
    
    # Set compiler flags to ensure correct sysroot path
    export CXXFLAGS="--sysroot=\"$NDK_SYSROOT\""
    export CFLAGS="--sysroot=\"$NDK_SYSROOT\""
    echo "Set compiler flags: CXXFLAGS=$CXXFLAGS"
    
    gn gen "$OUTPUT_DIR" --root="src" \
      --args="
      is_debug=${is_debug}
      is_java_debug=${is_debug}
      target_os=\"android\"
      target_cpu=\"${target_cpu}\"
      rtc_use_h264=false
      rtc_include_tests=false
      rtc_build_examples=false
      is_component_build=false
      use_rtti=true
      use_custom_libcxx=false
      treat_warnings_as_errors=false
      use_errorprone_java_compiler=false
      use_cxx17=true
      android_sdk_root=\"$ANDROID_SDK_ROOT\"
      android_ndk_root=\"$ANDROID_NDK_ROOT\"
      android64_ndk_api_level=21
      android_ndk_version=\"$ANDROID_NDK_VERSION\"
      sysroot=\"$NDK_SYSROOT\"
      "

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
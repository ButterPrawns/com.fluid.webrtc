#!/bin/bash -eu

# This script applies patches to the WebRTC source code

# Load environment variables
source $(dirname $0)/01_setup_env.sh

echo "Starting to apply patches..."

# Add jsoncpp
echo "Applying jsoncpp patch..."
patch -N "src/BUILD.gn" < "$COMMAND_DIR/patches/add_jsoncpp.patch" || echo "Patch may have already been applied."

# Add visibility libunwind
echo "Applying libunwind visibility patch..."
patch -N "src/buildtools/third_party/libunwind/BUILD.gn" < "$COMMAND_DIR/patches/add_visibility_libunwind.patch" || echo "Patch may have already been applied."

# Add deps libunwind
echo "Applying libunwind deps patch..."
patch -N "src/build/config/BUILD.gn" < "$COMMAND_DIR/patches/add_deps_libunwind.patch" || echo "Patch may have already been applied."

# Add -mno-outline-atomics flag
echo "Applying no-outline-atomics flag patch..."
patch -N "src/build/config/compiler/BUILD.gn" < "$COMMAND_DIR/patches/add_nooutlineatomics_flag.patch" || echo "Patch may have already been applied."

# downgrade to JDK8 because Unity supports OpenJDK version 1.8.
echo "Applying JDK8 downgrade patches..."
patch -N "src/build/android/gyp/compile_java.py" < "$COMMAND_DIR/patches/downgradeJDKto8_compile_java.patch" || echo "Patch may have already been applied."
patch -N "src/build/android/gyp/turbine.py" < "$COMMAND_DIR/patches/downgradeJDKto8_turbine.patch" || echo "Patch may have already been applied."

# Fix SetRawImagePlanes() in LibvpxVp8Encoder
echo "Applying LibvpxVp8Encoder patch..."
patch -N "src/modules/video_coding/codecs/vp8/libvpx_vp8_encoder.cc" < "$COMMAND_DIR/patches/libvpx_vp8_encoder.patch" || echo "Patch may have already been applied."

pushd src

# Fix AdaptedVideoTrackSource::video_adapter()
echo "Applying AdaptedVideoTrackSource patch..."
patch -p1 < "$COMMAND_DIR/patches/fix_adaptedvideotracksource.patch" || echo "Patch may have already been applied."

# Fix Android video encoder 
echo "Applying Android video encoder patch..."
patch -p1 < "$COMMAND_DIR/patches/fix_android_videoencoder.patch" || echo "Patch may have already been applied."

popd

echo "All patches applied successfully." 
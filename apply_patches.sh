#!/bin/bash -eu

# Source common variables and functions
source $(dirname $0)/common.sh

echo "Applying patches to WebRTC source code..."

# Add jsoncpp
echo "Applying jsoncpp patch..."
patch -N "src/BUILD.gn" < "$COMMAND_DIR/patches/add_jsoncpp.patch"
check_result "jsoncpp patch"

# Add visibility libunwind
echo "Applying libunwind visibility patch..."
patch -N "src/buildtools/third_party/libunwind/BUILD.gn" < "$COMMAND_DIR/patches/add_visibility_libunwind.patch"
check_result "libunwind visibility patch"

# Add deps libunwind
echo "Applying libunwind deps patch..."
patch -N "src/build/config/BUILD.gn" < "$COMMAND_DIR/patches/add_deps_libunwind.patch"
check_result "libunwind deps patch"

# Add -mno-outline-atomics flag
echo "Applying no-outline-atomics flag patch..."
patch -N "src/build/config/compiler/BUILD.gn" < "$COMMAND_DIR/patches/add_nooutlineatomics_flag.patch"
check_result "no-outline-atomics patch"

# downgrade to JDK8 because Unity supports OpenJDK version 1.8.
echo "Applying JDK8 downgrade patches for Unity compatibility..."
patch -N "src/build/android/gyp/compile_java.py" < "$COMMAND_DIR/patches/downgradeJDKto8_compile_java.patch"
patch -N "src/build/android/gyp/turbine.py" < "$COMMAND_DIR/patches/downgradeJDKto8_turbine.patch"
check_result "JDK8 downgrade patches"

# Fix SetRawImagePlanes() in LibvpxVp8Encoder
echo "Applying VP8 encoder patch..."
patch -N "src/modules/video_coding/codecs/vp8/libvpx_vp8_encoder.cc" < "$COMMAND_DIR/patches/libvpx_vp8_encoder.patch"
check_result "VP8 encoder patch"

pushd src
# Fix AdaptedVideoTrackSource::video_adapter()
echo "Applying AdaptedVideoTrackSource patch..."
patch -p1 < "$COMMAND_DIR/patches/fix_adaptedvideotracksource.patch"
check_result "AdaptedVideoTrackSource patch"

# Fix Android video encoder 
echo "Applying Android video encoder patch..."
patch -p1 < "$COMMAND_DIR/patches/fix_android_videoencoder.patch"
check_result "Android video encoder patch"
popd

echo "All patches applied successfully" 
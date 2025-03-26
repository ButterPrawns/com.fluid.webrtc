#!/bin/bash -eu

if [ ! -e "$(pwd)/depot_tools" ]
then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

export COMMAND_DIR=$(cd $(dirname $0); pwd)
export PATH="$(pwd)/depot_tools:$PATH"
export WEBRTC_VERSION=5845
export OUTPUT_DIR="$(pwd)/out"
export ARTIFACTS_DIR="$(pwd)/artifacts"
export PYTHON3_BIN="$(pwd)/depot_tools/python-bin/python3"

if [ ! -e "$(pwd)/src" ]
then
  # Exclude example for reduction
  patch -N "depot_tools/fetch_configs/webrtc.py" < "$COMMAND_DIR/patches/fetch_exclude_examples.patch"
  fetch --nohooks webrtc_android
  cd src
  sudo sh -c 'echo 127.0.1.1 $(hostname) >> /etc/hosts'
  sudo git config --system core.longpaths true
  git checkout "refs/remotes/branch-heads/$WEBRTC_VERSION"
  cd ..
  gclient sync -D --force --reset
fi

# Add jsoncpp
patch -N "src/BUILD.gn" < "$COMMAND_DIR/patches/add_jsoncpp.patch"

# Add visibility libunwind
patch -N "src/buildtools/third_party/libunwind/BUILD.gn" < "$COMMAND_DIR/patches/add_visibility_libunwind.patch"

# Add deps libunwind
patch -N "src/build/config/BUILD.gn" < "$COMMAND_DIR/patches/add_deps_libunwind.patch"

# Add -mno-outline-atomics flag
patch -N "src/build/config/compiler/BUILD.gn" < "$COMMAND_DIR/patches/add_nooutlineatomics_flag.patch"

# downgrade to JDK8 because Unity supports OpenJDK version 1.8.
# https://docs.unity3d.com/Manual/android-sdksetup.html
patch -N "src/build/android/gyp/compile_java.py" < "$COMMAND_DIR/patches/downgradeJDKto8_compile_java.patch"
patch -N "src/build/android/gyp/turbine.py" < "$COMMAND_DIR/patches/downgradeJDKto8_turbine.patch"

# Fix SetRawImagePlanes() in LibvpxVp8Encoder
patch -N "src/modules/video_coding/codecs/vp8/libvpx_vp8_encoder.cc" < "$COMMAND_DIR/patches/libvpx_vp8_encoder.patch"

pushd src
# Fix AdaptedVideoTrackSource::video_adapter()
patch -p1 < "$COMMAND_DIR/patches/fix_adaptedvideotracksource.patch"
# Fix Android video encoder 
patch -p1 < "$COMMAND_DIR/patches/fix_android_videoencoder.patch"
popd

# Shadow org_webrtc and org.webrtc references to com.fluid.webrtc
echo "Shadowing org_webrtc and org.webrtc references to com.fluid.webrtc..."

# Find and replace in JNI source files
find src/sdk/android/src/jni -type f \( -name "*.cc" -o -name "*.h" \) | while read file; do
  # Replace Java_org_webrtc with Java_com_fluid_webrtc
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "$file"
  # Replace "org/webrtc/ with "com/fluid/webrtc/
  sed -i 's/"org\/webrtc\//"com\/fluid\/webrtc\//g' "$file"
  # Replace 'org/webrtc/ with 'com/fluid/webrtc/
  sed -i "s/'org\/webrtc\//'com\/fluid\/webrtc\//g" "$file"
  # Replace org.webrtc. with com.fluid.webrtc.
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$file"
  # Replace org.webrtc" with com.fluid.webrtc"
  sed -i 's/org\.webrtc"/com\.fluid\.webrtc"/g' "$file"
  # Replace org/webrtc/ with com/fluid/webrtc/ (without quotes)
  sed -i 's/org\/webrtc\//com\/fluid\/webrtc\//g' "$file"
  # Replace GetClass call pattern - using simpler pattern that doesn't require group capture
  sed -i 's/GetClass(env, "org\/webrtc\//GetClass(env, "com\/fluid\/webrtc\//g' "$file"
  echo "Processed JNI file: $file"
done

# Also process C++ files that might include JNI stuff
find src/sdk/android/native_api -type f \( -name "*.cc" -o -name "*.h" \) | while read file; do
  # Replace Java_org_webrtc with Java_com_fluid_webrtc
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "$file"
  # Replace org/webrtc/ with com/fluid/webrtc/
  sed -i 's/org\/webrtc\//com\/fluid\/webrtc\//g' "$file"
  # Replace org.webrtc. with com.fluid.webrtc.
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$file"
  echo "Processed native API file: $file"
done

# Process JNI implementation files (*.cc)
find src/sdk/android -type f -name "*.cc" | while read file; do
  # Replace GetClass call pattern - using simpler pattern
  sed -i 's/GetClass(env, "org\/webrtc\//GetClass(env, "com\/fluid\/webrtc\//g' "$file"
  # Replace org/webrtc/ with com/fluid/webrtc/ in other occurrences
  sed -i 's/"org\/webrtc\//"com\/fluid\/webrtc\//g' "$file"
  echo "Processed cc file: $file"
done

# Specifically handle our plugin AndroidCodecFactoryHelper.cpp which references org/webrtc classes
if [ -f "$COMMAND_DIR/../Plugin~/WebRTCPlugin/Android/AndroidCodecFactoryHelper.cpp" ]; then
  echo "Processing AndroidCodecFactoryHelper.cpp..."
  sed -i 's/"org\/webrtc\//"com\/fluid\/webrtc\//g' "$COMMAND_DIR/../Plugin~/WebRTCPlugin/Android/AndroidCodecFactoryHelper.cpp"
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$COMMAND_DIR/../Plugin~/WebRTCPlugin/Android/AndroidCodecFactoryHelper.cpp"
  echo "Processed AndroidCodecFactoryHelper.cpp"
fi

# Process Android JNI registration code
find src/sdk/android -type f -name "*.java" | while read file; do
  # Replace package org.webrtc with package com.fluid.webrtc
  sed -i 's/package org\.webrtc/package com\.fluid\.webrtc/g' "$file"
  # Replace import org.webrtc with import com.fluid.webrtc
  sed -i 's/import org\.webrtc/import com\.fluid\.webrtc/g' "$file"
  # Replace other org.webrtc references
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$file"
  echo "Processed $file"
done

# Process JNI method registration in AndroidManifest.xml files
find src/sdk/android -type f -name "AndroidManifest.xml" | while read file; do
  sed -i 's/org\.webrtc/com\.fluid\.webrtc/g' "$file"
  echo "Processed $file"
done

# Update the JNI symbols file if it exists
if [ -f "src/sdk/android/jni_symbols.txt" ]; then
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "src/sdk/android/jni_symbols.txt"
  echo "Updated JNI symbols in src/sdk/android/jni_symbols.txt"
fi

# Process Plugin~/tools/android/jni_symbols.txt file
if [ -f "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt" ]; then
  cp "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt" "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt.bak"
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt"
  echo "Updated JNI symbols in $COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt"
fi

mkdir -p "$ARTIFACTS_DIR/lib"


for target_cpu in "arm64" "x64"
do
  mkdir -p "$ARTIFACTS_DIR/lib/${target_cpu}"

  for is_debug in "true" "false"
  do
    # generate ninja files
    # use `treat_warnings_as_errors` option to avoid deprecation warnings
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
    ninja -C "$OUTPUT_DIR" webrtc

    filename="libwebrtc.a"
    if [ $is_debug = "true" ]; then
      filename="libwebrtcd.a"
    fi

    # copy static library
    cp "$OUTPUT_DIR/obj/libwebrtc.a" "$ARTIFACTS_DIR/lib/${target_cpu}/${filename}"
  done
done

pushd src

for is_debug in "true" "false"
do
  # use `treat_warnings_as_errors` option to avoid deprecation warnings
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

  filename="libwebrtc.aar"
  if [ $is_debug = "true" ]; then
    filename="libwebrtc-debug.aar"
  fi
  # copy aar
  cp "$OUTPUT_DIR/libwebrtc.aar" "$ARTIFACTS_DIR/lib/${filename}"
done

popd

"$PYTHON3_BIN" "./src/tools_webrtc/libs/generate_licenses.py" \
  --target :webrtc "$OUTPUT_DIR" "$OUTPUT_DIR"

cd src
find . -name "*.h" -print | cpio -pd "$ARTIFACTS_DIR/include"

cp "$OUTPUT_DIR/LICENSE.md" "$ARTIFACTS_DIR"

# create zip
cd "$ARTIFACTS_DIR"
zip -r webrtc-android.zip lib include LICENSE.md

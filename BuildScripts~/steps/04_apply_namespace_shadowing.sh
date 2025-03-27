#!/bin/bash -eu

# This script applies namespace shadowing to replace org.webrtc with com.fluid.webrtc

# Load environment variables
source $(dirname $0)/01_setup_env.sh

echo "Shadowing org_webrtc and org.webrtc references to com.fluid.webrtc..."

# Find and replace in JNI source files
echo "Processing JNI source files..."
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
  echo "  Processed JNI file: $file"
done

# Also process C++ files that might include JNI stuff
echo "Processing native API files..."
find src/sdk/android/native_api -type f \( -name "*.cc" -o -name "*.h" \) | while read file; do
  # Replace Java_org_webrtc with Java_com_fluid_webrtc
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "$file"
  # Replace org/webrtc/ with com/fluid/webrtc/
  sed -i 's/org\/webrtc\//com\/fluid\/webrtc\//g' "$file"
  # Replace org.webrtc. with com.fluid.webrtc.
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$file"
  echo "  Processed native API file: $file"
done

# Process JNI implementation files (*.cc)
echo "Processing CC files..."
find src/sdk/android -type f -name "*.cc" | while read file; do
  # Replace GetClass call pattern - using simpler pattern
  sed -i 's/GetClass(env, "org\/webrtc\//GetClass(env, "com\/fluid\/webrtc\//g' "$file"
  # Replace org/webrtc/ with com/fluid/webrtc/ in other occurrences
  sed -i 's/"org\/webrtc\//"com\/fluid\/webrtc\//g' "$file"
  echo "  Processed cc file: $file"
done

# Specifically handle our plugin AndroidCodecFactoryHelper.cpp which references org/webrtc classes
if [ -f "$COMMAND_DIR/../Plugin~/WebRTCPlugin/Android/AndroidCodecFactoryHelper.cpp" ]; then
  echo "Processing AndroidCodecFactoryHelper.cpp..."
  sed -i 's/"org\/webrtc\//"com\/fluid\/webrtc\//g' "$COMMAND_DIR/../Plugin~/WebRTCPlugin/Android/AndroidCodecFactoryHelper.cpp"
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$COMMAND_DIR/../Plugin~/WebRTCPlugin/Android/AndroidCodecFactoryHelper.cpp"
  echo "  Processed AndroidCodecFactoryHelper.cpp"
fi

# Process Android JNI registration code
echo "Processing Java files..."
find src/sdk/android -type f -name "*.java" | while read file; do
  # Replace package org.webrtc with package com.fluid.webrtc
  sed -i 's/package org\.webrtc/package com\.fluid\.webrtc/g' "$file"
  # Replace import org.webrtc with import com.fluid.webrtc
  sed -i 's/import org\.webrtc/import com\.fluid\.webrtc/g' "$file"
  # Replace other org.webrtc references
  sed -i 's/org\.webrtc\./com\.fluid\.webrtc\./g' "$file"
  echo "  Processed Java file: $file"
done

# Process JNI method registration in AndroidManifest.xml files
echo "Processing AndroidManifest.xml files..."
find src/sdk/android -type f -name "AndroidManifest.xml" | while read file; do
  sed -i 's/org\.webrtc/com\.fluid\.webrtc/g' "$file"
  echo "  Processed manifest file: $file"
done

# Update the JNI symbols file if it exists
if [ -f "src/sdk/android/jni_symbols.txt" ]; then
  echo "Updating JNI symbols in src/sdk/android/jni_symbols.txt..."
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "src/sdk/android/jni_symbols.txt"
  echo "  Updated JNI symbols in src/sdk/android/jni_symbols.txt"
fi

# Process Plugin~/tools/android/jni_symbols.txt file
if [ -f "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt" ]; then
  echo "Updating JNI symbols in Plugin~/tools/android/jni_symbols.txt..."
  cp "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt" "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt.bak"
  sed -i 's/Java_org_webrtc/Java_com_fluid_webrtc/g' "$COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt"
  echo "  Updated JNI symbols in $COMMAND_DIR/../Plugin~/tools/android/jni_symbols.txt"
fi

echo "Namespace shadowing completed successfully." 
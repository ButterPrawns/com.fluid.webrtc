#!/bin/bash -eu

# This script downloads and installs Android NDK r21b for Linux/WSL

echo "Installing Android NDK r21b for Linux..."

# Define install directory
NDK_INSTALL_DIR="$HOME/android-ndk-r21b"
NDK_DOWNLOAD_URL="https://dl.google.com/android/repository/android-ndk-r21b-linux-x86_64.zip"
NDK_ZIP_FILE="android-ndk-r21b-linux-x86_64.zip"

# Create a temp directory for download
TEMP_DIR="$(pwd)/ndk_temp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download Android NDK r21b
echo "Downloading Android NDK r21b (this may take a while)..."
wget -q --show-progress "$NDK_DOWNLOAD_URL"

# Unzip the downloaded NDK file to home directory
echo "Extracting Android NDK r21b to $NDK_INSTALL_DIR..."
unzip -q "$NDK_ZIP_FILE" -d "$HOME"

# Remove the zip file
rm "$NDK_ZIP_FILE"
cd ..
rmdir "$TEMP_DIR"

# Set Android NDK root path to environment variables
echo "Updating environment variables..."
export ANDROID_NDK="$NDK_INSTALL_DIR"
export ANDROID_NDK_ROOT="$NDK_INSTALL_DIR"

# Update the 01_setup_env.sh script to use the installed NDK
SETUP_ENV_SCRIPT="$(dirname $0)/01_setup_env.sh"
echo "Updating $SETUP_ENV_SCRIPT to use the installed NDK..."

# Make a backup of the original script
cp "$SETUP_ENV_SCRIPT" "${SETUP_ENV_SCRIPT}.bak"

# Update the script with correct NDK path
sed -i "s|export ANDROID_NDK_ROOT=.*|export ANDROID_NDK_ROOT=\"$NDK_INSTALL_DIR\"|" "$SETUP_ENV_SCRIPT"
sed -i "s|export ANDROID_NDK_VERSION=.*|# Using NDK r21b as recommended in the README|" "$SETUP_ENV_SCRIPT"

echo "Android NDK r21b installed successfully at: $NDK_INSTALL_DIR"
echo "Environment variables set up for current session:"
echo "ANDROID_NDK=$ANDROID_NDK"
echo "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
echo ""
echo "The 01_setup_env.sh script has been updated to use this NDK."
echo "You can now run the other build scripts." 
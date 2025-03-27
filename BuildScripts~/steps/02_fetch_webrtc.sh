#!/bin/bash -eu

# This script fetches the WebRTC source code

# Load environment variables
source $(dirname $0)/01_setup_env.sh

echo "Starting WebRTC fetch..."

if [ ! -e "$(pwd)/src" ]; then
  echo "WebRTC source not found. Fetching..."
  
  # Exclude example for reduction
  patch -N "depot_tools/fetch_configs/webrtc.py" < "$COMMAND_DIR/patches/fetch_exclude_examples.patch"
  
  echo "Running fetch command (this may take a while)..."
  fetch --nohooks webrtc_android
  
  cd src
  
  echo "Adding hostname to /etc/hosts..."
  sudo sh -c 'echo 127.0.1.1 $(hostname) >> /etc/hosts'
  
  echo "Configuring git for long paths..."
  sudo git config --system core.longpaths true
  
  echo "Checking out WebRTC version $WEBRTC_VERSION..."
  git checkout "refs/remotes/branch-heads/$WEBRTC_VERSION"
  
  cd ..
  
  echo "Running gclient sync (this may take a while)..."
  gclient sync -D --force --reset
  
  echo "WebRTC source fetch completed successfully."
else
  echo "WebRTC source already exists at $(pwd)/src. Skipping fetch."
fi 
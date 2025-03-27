#!/bin/bash -eu

# Source common variables and functions
source $(dirname $0)/common.sh

echo "Fetching WebRTC source code..."

if [ ! -e "$(pwd)/src" ]; then
  echo "Excluding examples for reduction"
  patch -N "depot_tools/fetch_configs/webrtc.py" < "$COMMAND_DIR/patches/fetch_exclude_examples.patch"
  
  echo "Fetching webrtc_android..."
  fetch --nohooks webrtc_android
  check_result "Fetching webrtc_android"
  
  cd src
  sudo sh -c 'echo 127.0.1.1 $(hostname) >> /etc/hosts'
  sudo git config --system core.longpaths true
  
  echo "Checking out WebRTC version $WEBRTC_VERSION..."
  git checkout "refs/remotes/branch-heads/$WEBRTC_VERSION"
  check_result "Git checkout"
  cd ..
  
  echo "Syncing dependencies..."
  gclient sync -D --force --reset
  check_result "GClient sync"
  
  echo "Source code fetched successfully"
else
  echo "WebRTC source already exists, skipping fetch"
fi 
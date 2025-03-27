#!/bin/bash -eu

# Get Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME)"

# Check if running in WSL
WSL_ENV=false
if grep -q "Microsoft" /proc/version || grep -q "microsoft" /proc/version; then
  echo "WSL detected - configuring for WSL environment"
  WSL_ENV=true
  
  # Determine Windows username more reliably
  WIN_USERNAME=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  WIN_HOME="/mnt/c/Users/$WIN_USERNAME"
  
  if [ ! -d "$WIN_HOME" ]; then
    echo "Cannot locate Windows home directory at $WIN_HOME"
    echo "Skipping .wslconfig creation"
  else
    echo "Creating recommended .wslconfig file in Windows home directory ($WIN_HOME)"
    cat > "$WIN_HOME/.wslconfig" << EOF
[wsl2]
memory=32GB
processors=14
localhostForwarding=true
EOF
    echo "Created .wslconfig file"
  fi
fi

# Install basic tools
echo "Installing basic build tools..."
sudo apt update
sudo apt install -y build-essential pkg-config zip unzip git python3-full python3-venv \
                    ninja-build pciutils bc cmake software-properties-common curl wget

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
if [ ! -d ~/webrtc-venv ]; then
  python3 -m venv ~/webrtc-venv
fi
source ~/webrtc-venv/bin/activate

# Install Python packages in the virtual environment
echo "Installing Python packages..."
pip install --upgrade pip
pip install glad2

# For Ubuntu 24.04 (Noble), use clang-14 which is available in the repositories
if (( $(echo "$UBUNTU_VERSION >= 22.04" | bc -l) )); then
  echo "Using Clang 14 for newer Ubuntu..."
  sudo apt install -y clang-14 lld-14 libstdc++-9-dev
  
  # Set clang-14 as the default clang
  sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 100 || true
  sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 100 || true
  sudo update-alternatives --install /usr/bin/lld lld /usr/bin/lld-14 100 || true
else
  # For older Ubuntu versions, try to install clang-11
  echo "Using Clang 11 for older Ubuntu..."
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
  sudo apt-add-repository "deb http://apt.llvm.org/$UBUNTU_CODENAME/ llvm-toolchain-$UBUNTU_CODENAME-11 main"
  sudo apt update
  sudo apt install -y clang-11 lld-11 libstdc++-9-dev
  
  # Set clang-11 as the default clang
  sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-11 100 || true
  sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-11 100 || true
  sudo update-alternatives --install /usr/bin/lld lld /usr/bin/lld-11 100 || true
fi

# Install newer GCC for recent GLIBCXX support
echo "Installing GCC 9..."
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y g++-9
sudo ln -sf g++-9 /usr/bin/g++

# Install graphics libraries - check for package names that might vary by Ubuntu version
echo "Installing graphics libraries..."
if (( $(echo "$UBUNTU_VERSION >= 22.04" | bc -l) )); then
  # Modern Ubuntu
  sudo apt install -y libvulkan1 libvulkan-dev libglfw3-dev mesa-vulkan-drivers
else
  # Older Ubuntu
  sudo apt install -y vulkan-utils libvulkan1 libvulkan-dev libglfw3-dev
fi

# Check for NVIDIA GPU - in WSL we check Windows side
if [ "$WSL_ENV" = true ]; then
  echo "Running in WSL - checking for NVIDIA GPU on Windows..."
  if [ -d "/mnt/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA" ]; then
    echo "NVIDIA CUDA Toolkit found on Windows side. Using Windows CUDA installation."
    echo "Make sure Windows PATH includes CUDA and you have WSL2-compatible NVIDIA drivers installed."
    
    # No need to install CUDA in WSL as we'll use the Windows version
    WINDOWS_CUDA_PATH=$(ls -d "/mnt/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA"/v* | sort -V | tail -1)
    echo "Found Windows CUDA at: $WINDOWS_CUDA_PATH"
    
    # Add to bashrc - using Windows CUDA through WSL
    if ! grep -q "WINDOWS_CUDA_PATH" ~/.bashrc; then
      echo "export WINDOWS_CUDA_PATH=\"$WINDOWS_CUDA_PATH\"" >> ~/.bashrc
      echo "export PATH=\"\$PATH:\$WINDOWS_CUDA_PATH/bin\"" >> ~/.bashrc
    fi
  else
    echo "NVIDIA CUDA Toolkit not found on Windows side."
  fi
elif command -v lspci &> /dev/null && lspci | grep -q NVIDIA; then
  echo "NVIDIA GPU detected on Linux, installing CUDA..."
  # Use the appropriate CUDA repo for the Ubuntu version
  if (( $(echo "$UBUNTU_VERSION >= 22.04" | bc -l) )); then
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    sudo apt update
    sudo apt install -y cuda-toolkit-11-8
    rm cuda-keyring_1.0-1_all.deb
  else
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
    sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
    sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
    sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
    sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
    sudo apt update
    sudo apt install -y cuda-toolkit-11-0
  fi
else
  echo "No NVIDIA GPU detected, skipping CUDA installation"
fi

# Download Android NDK r21b
if [ ! -d ~/android-ndk-r21b ]; then
  echo "Downloading Android NDK r21b..."
  
  # Use a temp directory
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
  
  # Download and verify checksum before extracting
  wget -O android-ndk.zip https://dl.google.com/android/repository/android-ndk-r21b-linux-x86_64.zip
  
  # Verify the file was downloaded correctly
  if unzip -t android-ndk.zip > /dev/null; then
    echo "NDK zip file verified successfully"
    unzip android-ndk.zip -d ~/
    echo "NDK extracted to ~/android-ndk-r21b"
  else
    echo "WARNING: NDK zip file verification failed!"
    echo "Try manually downloading from: https://developer.android.com/ndk/downloads"
    echo "and extracting to: ~/android-ndk-r21b"
  fi
  
  # Clean up
  cd -
  rm -rf "$TEMP_DIR"
else
  echo "Android NDK r21b already installed"
fi

# Set Android NDK root path to environment variables
echo "Setting up environment variables..."
if ! grep -q "ANDROID_NDK" ~/.bashrc; then
  echo "export ANDROID_NDK=~/android-ndk-r21b/" >> ~/.bashrc
  echo "source ~/webrtc-venv/bin/activate" >> ~/.bashrc
  echo "Environment variables added to ~/.bashrc"
fi

# Set Android NDK in current shell
export ANDROID_NDK=~/android-ndk-r21b/

echo "Environment setup complete!"
echo "Please run 'source ~/.bashrc' to apply environment variables or restart your terminal"
echo "The build should now work with: cd /c/gitprojects/com.fluid.webrtc && bash BuildScripts~/build_fluid_libwebrtc_android.sh"
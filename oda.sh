#!/bin/bash

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║               ODA Installer               ║"
echo "║     On Device AI Development Setup       ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo -e "${RED}Error: This script is designed to run on Ubuntu only.${NC}"
    exit 1
fi

# Check for sudo privileges
if ! sudo -v; then
    echo -e "${RED}Error: This script requires sudo privileges.${NC}"
    exit 1
fi

# Function to print status messages
status() {
    echo -e "${GREEN}==>${NC} $1"
}

# Update system
status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential build tools
status "Installing build essentials..."
sudo apt install -y build-essential git curl wget software-properties-common cmake

# Install Python and pip
status "Setting up Python environment..."
sudo apt install -y python3-pip python3-venv
python3 -m pip install --upgrade pip

# Install common AI/ML libraries
status "Installing AI/ML libraries..."
python3 -m pip install torch torchvision torchaudio tensorflow numpy pandas scikit-learn jupyter

# Install Docker
status "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install NVIDIA drivers and CUDA if GPU is available
if lspci | grep -i nvidia > /dev/null; then
    status "NVIDIA GPU detected, installing drivers and CUDA..."
    sudo apt install -y nvidia-driver-535 nvidia-cuda-toolkit
    sudo apt install -y nvidia-container-toolkit
fi

# Install VS Code
status "Installing Visual Studio Code..."
sudo snap install code --classic

# Install and configure ZSH
status "Setting up ZSH..."
sudo apt install -y zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh -s $(which zsh)

# Install llama.cpp
status "Installing llama.cpp..."
cd /tmp
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake .. -DLLAMA_CUBLAS=ON
cmake --build . --config Release
sudo cp bin/main /usr/local/bin/llama
cd ../..
rm -rf llama.cpp

# Final message
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════╗"
echo "║        Installation Complete! 🎉          ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"
echo "Please log out and log back in for all changes to take effect."
echo "Enjoy your new AI development environment!"

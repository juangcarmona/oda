#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

# Colors for pretty output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration variables
readonly PYTHON_VERSION="3.10"  # Specify Python version explicitly
readonly NVIDIA_DRIVER_VERSION="535"
readonly REQUIRED_SPACE=20000000  # Required free space in KB

# Print banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║               ODA Installer               ║"
echo "║     On Device AI Development Setup       ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print status messages
status() {
    echo -e "${GREEN}==>${NC} $1"
}

# Function to check system requirements
check_system_requirements() {
    # Check if running on Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        echo -e "${RED}Error: This script is designed to run on Ubuntu only.${NC}"
        exit 1
    }

    # Check for sudo privileges
    if ! sudo -v; then
        echo -e "${RED}Error: This script requires sudo privileges.${NC}"
        exit 1
    }

    # Check available disk space
    local available_space
    available_space=$(df -k /usr/local | tail -1 | awk '{print $4}')
    if [ "${available_space}" -lt "${REQUIRED_SPACE}" ]; then
        echo -e "${RED}Error: Not enough disk space. Required: ${REQUIRED_SPACE}KB, Available: ${available_space}KB${NC}"
        exit 1
    }
}

# Function to install Python and dependencies
install_python() {
    status "Setting up Python ${PYTHON_VERSION} environment..."
    sudo apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python3-pip
    python3 -m pip install --upgrade pip

    # Create a virtual environment
    python3 -m venv "${HOME}/.oda-venv"
    source "${HOME}/.oda-venv/bin/activate"

    status "Installing AI/ML libraries..."
    # Install with version pinning for stability
    pip install --no-cache-dir \
        torch==2.1.0 \
        torchvision==0.16.0 \
        torchaudio==2.1.0 \
        tensorflow==2.14.0 \
        numpy==1.24.3 \
        pandas==2.1.1 \
        scikit-learn==1.3.1 \
        jupyter==1.0.0
}

# Function to install Docker
install_docker() {
    status "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker "$USER"
        rm get-docker.sh
    else
        status "Docker is already installed, skipping..."
    fi
}

# Function to install NVIDIA components
install_nvidia() {
    if lspci | grep -i nvidia > /dev/null; then
        status "NVIDIA GPU detected, installing drivers and CUDA..."
        
        # Add NVIDIA repository
        sudo add-apt-repository -y ppa:graphics-drivers/ppa
        
        # Install NVIDIA drivers and CUDA
        sudo apt install -y nvidia-driver-${NVIDIA_DRIVER_VERSION} nvidia-cuda-toolkit
        
        # Install NVIDIA Docker support
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
            sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt update && sudo apt install -y nvidia-container-toolkit
    else
        status "No NVIDIA GPU detected, skipping NVIDIA components..."
    fi
}

# Function to install llama.cpp
install_llama() {
    status "Installing llama.cpp..."
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "${temp_dir}" || exit 1
    
    git clone https://github.com/ggerganov/llama.cpp.git
    cd llama.cpp || exit 1
    mkdir build && cd build || exit 1
    
    if lspci | grep -i nvidia > /dev/null; then
        cmake .. -DLLAMA_CUBLAS=ON
    else
        cmake ..
    fi
    
    cmake --build . --config Release
    sudo cp bin/main /usr/local/bin/llama
    
    cd / && rm -rf "${temp_dir}"
}

# Main installation process
main() {
    check_system_requirements
    
    # Update system
    status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # Install essential build tools
    status "Installing build essentials..."
    sudo apt install -y build-essential git curl wget software-properties-common cmake

    install_python
    install_docker
    install_nvidia
    
    # Install VS Code
    status "Installing Visual Studio Code..."
    if ! command -v code &> /dev/null; then
        sudo snap install code --classic
    else
        status "VS Code is already installed, skipping..."
    fi
    
    # Install and configure ZSH
    status "Setting up ZSH..."
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        sudo apt install -y zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        chsh -s "$(which zsh)" || true
    else
        status "ZSH is already installed, skipping..."
    fi
    
    install_llama
    
    # Final message
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║        Installation Complete! 🎉          ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Please log out and log back in for all changes to take effect."
    echo "To activate the Python virtual environment, run: source ~/.oda-venv/bin/activate"
    echo "Enjoy your new AI development environment!"
}

# Run main function
main
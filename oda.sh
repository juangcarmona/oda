#!/bin/bash

set -euo pipefail
trap 'error "Failed at line $LINENO. Exit code: $?"' ERR

# Version-pinned dependencies
readonly PYTHON_VERSION="3.10"
readonly PYTORCH_VERSION="2.1.0"
readonly TENSORFLOW_VERSION="2.14.0"
readonly NUMPY_VERSION="1.24.3"
readonly PANDAS_VERSION="2.1.1"
readonly SCIKIT_VERSION="1.3.1"
readonly NVIDIA_VERSION="535"

# Global variables
DISTRO=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
readonly INSTALL_DIR="$HOME/.oda"
readonly VENV_DIR="$HOME/.oda-venv"
readonly LOG_FILE="/tmp/oda-install.log"
readonly REQUIRED_SPACE_GB=20
HAS_GPU=false

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Helper functions
log() {
    echo -e "${GREEN}[ODA]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    exit 1
}

check_sudo() {
    if ! sudo -v; then
        error "Sudo privileges are required for installation"
    fi
    # Keep sudo alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

check_disk_space() {
    local free_space
    free_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$free_space" -lt "$REQUIRED_SPACE_GB" ]; then
        error "Insufficient disk space. At least ${REQUIRED_SPACE_GB}GB required, found ${free_space}GB"
    fi
}

check_internet_connection() {
    if ! ping -c 1 google.com &> /dev/null; then
        error "No internet connection detected"
    fi
}

setup_package_manager() {
    case "$DISTRO" in
        ubuntu)
            PACKAGE_MANAGER="apt-get"
            INSTALL_CMD="sudo apt-get install -y"
            UPDATE_CMD="sudo apt-get update"
            ;;
        redhat)
            PACKAGE_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y"
            UPDATE_CMD="sudo dnf check-update"
            ;;
    esac
}

detect_distribution() {
    # Read os-release file
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu)
                DISTRO="ubuntu"
                log "Detected Ubuntu distribution"
                # Check version
                if [ "${VERSION_ID%%.*}" -lt 20 ]; then
                    error "Ubuntu version must be 20.04 or newer (found $VERSION_ID)"
                fi
                ;;
            rhel|centos|rocky|almalinux)
                DISTRO="redhat"
                log "Detected Red Hat compatible distribution: $ID"
                # Check version
                if [ "${VERSION_ID%%.*}" -lt 8 ]; then
                    error "Red Hat compatible distribution version must be 8 or newer (found $VERSION_ID)"
                fi
                ;;
            *)
                error "Unsupported Linux distribution: $ID. Currently supporting Ubuntu and Red Hat compatible distributions"
                ;;
        esac
        setup_package_manager
    else
        error "Could not detect Linux distribution"
    fi
}

detect_gpu() {
    if lspci | grep -i nvidia > /dev/null; then
        HAS_GPU=true
        # Check NVIDIA driver compatibility
        if nvidia-smi &> /dev/null; then
            local driver_version
            driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
            log "NVIDIA GPU detected with driver version: $driver_version"
        else
            warn "NVIDIA GPU detected but no drivers installed"
        fi
    else
        warn "No NVIDIA GPU detected, installing CPU-only versions"
    fi
}

install_base_packages() {
    log "Installing base packages..."
    
    local packages=(
        curl
        wget
        git
        zsh
        build-essential
    )
    
    # Update package lists
    $UPDATE_CMD
    
    # Install packages
    for package in "${packages[@]}"; do
        log "Installing $package..."
        $INSTALL_CMD "$package" || error "Failed to install $package"
    done
}

install_python() {
    log "Installing Python ${PYTHON_VERSION}..."
    
    case "$DISTRO" in
        ubuntu)
            # Add deadsnakes PPA for Python
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt-get update
            $INSTALL_CMD "python${PYTHON_VERSION}" "python${PYTHON_VERSION}-venv" "python${PYTHON_VERSION}-dev"
            ;;
        redhat)
            # Enable EPEL repository
            $INSTALL_CMD epel-release
            # Install Python
            $INSTALL_CMD "python${PYTHON_VERSION}" "python${PYTHON_VERSION}-devel"
            ;;
    esac
}

setup_python_environment() {
    log "Setting up Python virtual environment..."
    
    # Create virtual environment
    python${PYTHON_VERSION} -m venv "$VENV_DIR" || error "Failed to create virtual environment"
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate" || error "Failed to activate virtual environment"
    
    # Upgrade pip
    pip install --upgrade pip || error "Failed to upgrade pip"
    
    # Install AI/ML packages
    if [ "$HAS_GPU" = true ]; then
        pip install "torch==${PYTORCH_VERSION}" --index-url https://download.pytorch.org/whl/cu118
        pip install "tensorflow==${TENSORFLOW_VERSION}"
    else
        pip install "torch==${PYTORCH_VERSION}" --index-url https://download.pytorch.org/whl/cpu
        pip install "tensorflow-cpu==${TENSORFLOW_VERSION}"
    fi
    
    pip install "numpy==${NUMPY_VERSION}" \
                "pandas==${PANDAS_VERSION}" \
                "scikit-learn==${SCIKIT_VERSION}" || error "Failed to install Python packages"
}

install_nvidia() {
    if [ "$HAS_GPU" = true ]; then
        log "Installing NVIDIA components..."
        
        case "$DISTRO" in
            ubuntu)
                # Add NVIDIA repository
                wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
                sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
                sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
                sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
                sudo apt-get update
                $INSTALL_CMD "nvidia-driver-${NVIDIA_VERSION}" cuda
                ;;
            redhat)
                # Add NVIDIA repository
                sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
                sudo dnf clean all
                $INSTALL_CMD "kmod-nvidia-${NVIDIA_VERSION}" cuda
                ;;
        esac
    fi
}

setup_docker() {
    log "Setting up Docker..."
    
    case "$DISTRO" in
        ubuntu)
            # Install Docker using official repository
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
            ;;
        redhat)
            # Add Docker repository
            sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
            $INSTALL_CMD docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
    esac
    
    # Add user to docker group
    sudo usermod -aG docker "$USER"
    
    if [ "$HAS_GPU" = true ]; then
        # Install NVIDIA Container Toolkit
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        
        case "$DISTRO" in
            ubuntu)
                sudo apt-get update
                $INSTALL_CMD nvidia-docker2
                ;;
            redhat)
                sudo dnf clean all
                $INSTALL_CMD nvidia-docker2
                ;;
        esac
        
        sudo systemctl restart docker
    fi
}

setup_development_tools() {
    log "Setting up development tools..."
    
    # Install VS Code
    case "$DISTRO" in
        ubuntu)
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg
            sudo apt-get update
            $INSTALL_CMD code
            ;;
        redhat)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            $INSTALL_CMD code
            ;;
    esac
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Clone and build llama.cpp
    git clone https://github.com/ggerganov/llama.cpp.git "$INSTALL_DIR/llama.cpp"
    cd "$INSTALL_DIR/llama.cpp"
    if [ "$HAS_GPU" = true ]; then
        make CUDA=1
    else
        make
    fi
}

validate_system_requirements() {
    log "Validating system requirements..."
    
    # Check disk space (20GB minimum)
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$free_space" -lt 20 ]; then
        error "Insufficient disk space. Need at least 20GB free, have ${free_space}GB"
    fi

    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        error "No internet connection detected"
    fi

    # Check if running as root
    if [ "$(id -u)" = "0" ]; then
        error "This script should not be run as root"
    fi

    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        error "sudo is required but not installed"
    fi

    # Verify sudo access
    if ! sudo -v; then
        error "User does not have sudo privileges"
    fi

    log "System requirements validated successfully"
}

cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove temporary directories
    sudo rm -rf /tmp/oda-*
    
    # Clean package manager cache based on distribution
    if [ "$PACKAGE_MANAGER" = "apt-get" ]; then
        sudo apt-get clean
    elif [ "$PACKAGE_MANAGER" = "dnf" ]; then
        sudo dnf clean all
    fi
    
    # Remove downloaded installers
    rm -f ~/cuda*.run
    rm -f ~/vscode*.deb
    rm -f ~/vscode*.rpm
    
    log "Cleanup completed successfully"
}

main() {
    # Print banner
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║               ODA Installer               ║"
    echo "║     On Device AI Development Setup       ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Starting ODA installation..."
    
    # Validate system requirements
    validate_system_requirements
    
    # Detect distribution
    detect_distribution
    
    # Setup package manager
    setup_package_manager
    
    # Install base packages
    install_base_packages
    
    # Install Python
    install_python
    
    # Setup Python environment
    setup_python_environment
    
    # Install NVIDIA components if GPU is present
    if [ "$HAS_GPU" = true ]; then
        install_nvidia
    fi
    
    # Install Docker
    setup_docker
    
    # Install development tools
    setup_development_tools
    
    # Cleanup
    cleanup
    
    # Print success message
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║        Installation Complete! 🎉          ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Installation completed successfully!"
    echo -e "\nTo activate the Python environment, run:"
    echo -e "    ${GREEN}source $VENV_DIR/bin/activate${NC}"
    echo -e "\nTo start using ZSH, run:"
    echo -e "    ${GREEN}zsh${NC}"
    echo -e "\nInstallation log is available at: ${LOG_FILE}"
    
    # Print versions of installed components
    echo -e "\nInstalled versions:"
    echo -e "Python: $(python3 --version 2>/dev/null || echo 'Not found')"
    echo -e "Docker: $(docker --version 2>/dev/null || echo 'Not found')"
    if [ "$HAS_GPU" = true ]; then
        echo -e "NVIDIA Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'Not found')"
        echo -e "CUDA: $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' || echo 'Not found')"
    fi
}

main "$@"
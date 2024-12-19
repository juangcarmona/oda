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
readonly TENSORRT_VERSION="8.6.1"
readonly TRITON_VERSION="2.40.0"
readonly TVM_VERSION="0.15.0"

# Global variables
DISTRO=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
readonly INSTALL_DIR="$HOME/.oda"
readonly VENV_DIR="$HOME/.oda-venv"
readonly LOG_FILE="/tmp/oda-install.log"
readonly STATUS_FILE="$INSTALL_DIR/.install_status"
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
    if [ "$HAS_GPU" = false ]; then
        return
    fi
    
    log "Installing NVIDIA components..."
    
    case "$DISTRO" in
        ubuntu)
            # Add NVIDIA repository
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
            
            $UPDATE_CMD
            
            # Install NVIDIA drivers and CUDA
            $INSTALL_CMD nvidia-driver-$NVIDIA_VERSION cuda-toolkit
            
            # Install TensorRT
            $INSTALL_CMD tensorrt
            
            # Install NVIDIA Container Toolkit
            $INSTALL_CMD nvidia-container-toolkit
            ;;
            
        redhat)
            # Add NVIDIA repository
            sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
            
            # Install NVIDIA drivers and CUDA
            $INSTALL_CMD nvidia-driver-$NVIDIA_VERSION cuda-toolkit
            
            # Install TensorRT
            $INSTALL_CMD tensorrt
            
            # Install NVIDIA Container Toolkit
            curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
                sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
            $INSTALL_CMD nvidia-container-toolkit
            ;;
    esac
    
    # Install NVIDIA Triton
    sudo docker pull nvcr.io/nvidia/tritonserver:${TRITON_VERSION}-py3
    sudo docker pull nvcr.io/nvidia/tritonserver:${TRITON_VERSION}-py3-sdk
    
    # Install NVIDIA Nsight Systems
    case "$DISTRO" in
        ubuntu)
            $INSTALL_CMD nsight-systems
            ;;
        redhat)
            $INSTALL_CMD nsight-systems
            ;;
    esac
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

# Function to mark a step as completed
mark_completed() {
    local step=$1
    mkdir -p "$(dirname "$STATUS_FILE")"
    touch "$STATUS_FILE"
    if ! grep -q "^$step$" "$STATUS_FILE" 2>/dev/null; then
        echo "$step" >> "$STATUS_FILE"
    fi
}

# Function to check if a step is completed
is_completed() {
    local step=$1
    [ -f "$STATUS_FILE" ] && grep -q "^$step$" "$STATUS_FILE" 2>/dev/null
}

# Function to run a step if not already completed
run_step() {
    local step=$1
    local step_func=$2
    
    if ! is_completed "$step"; then
        log "Running step: $step"
        if $step_func; then
            mark_completed "$step"
            log "Step completed successfully: $step"
        else
            error "Step failed: $step"
            return 1
        fi
    else
        log "Skipping completed step: $step"
    fi
    return 0
}

setup_development_tools() {
    # VS Code installation
    run_step "vscode" _install_vscode || return 1
    
    # Oh My Zsh installation
    run_step "oh-my-zsh" _install_oh_my_zsh || return 1
    
    # llama.cpp installation
    run_step "llama-cpp" _install_llama_cpp || return 1
}

_install_vscode() {
    case "$DISTRO" in
        ubuntu)
            log "Cleaning up any previous failed installations..."
            sudo dpkg --remove --force-remove-reinstreq code || true
            sudo apt-get remove --purge code || true
            
            log "Fixing package system..."
            sudo apt-get clean
            sudo apt-get autoclean
            sudo apt-get update
            sudo apt-get --fix-broken install -y
            
            log "Installing VS Code dependencies one by one..."
            dependencies=(
                "xdg-utils"
                "libxrandr2"
                "libxkbfile1"
                "libxkbcommon0"
                "libxfixes3"
                "libxdamage1"
                "libxcomposite1"
                "libpango-1.0-0"
                "libgtk-3-0"
                "libgbm1"
                "libcairo2"
                "libatspi2.0-0"
                "libatk1.0-0"
                "libatk-bridge2.0-0"
                "libvulkan1"
            )

            for dep in "${dependencies[@]}"; do
                log "Installing $dep..."
                sudo apt-get install -y "$dep" || {
                    warn "Failed to install $dep, continuing..."
                    continue
                }
            done

            log "Installing VS Code via direct download..."
            wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
            sudo dpkg -i /tmp/vscode.deb || true
            sudo apt-get install -f -y
            rm /tmp/vscode.deb
            ;;
        redhat)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            $INSTALL_CMD code
            ;;
    esac
    return 0
}

_install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "Oh My Zsh is already installed. Skipping installation..."
        if [ -d "$HOME/.oh-my-zsh/.git" ]; then
            log "Updating Oh My Zsh via git..."
            (cd "$HOME/.oh-my-zsh" && git pull)
        fi
    else
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    return 0
}

_install_llama_cpp() {
    LLAMA_DIR="$INSTALL_DIR/llama.cpp"
    if [ -d "$LLAMA_DIR" ]; then
        log "llama.cpp directory already exists. Updating..."
        cd "$LLAMA_DIR"
        git pull origin master
    else
        log "Cloning llama.cpp..."
        git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
        cd "$LLAMA_DIR"
    fi
    
    log "Building llama.cpp..."
    if [ "$HAS_GPU" = true ]; then
        make clean && make CUDA=1
    else
        make clean && make
    fi
    return 0
}

setup_ai_tools() {
    # Install TVM dependencies
    run_step "tvm-deps" _install_tvm_deps || return 1
    
    # Install and build TVM
    run_step "tvm" _install_tvm || return 1
    
    # Install Python AI packages
    run_step "python-ai-packages" _install_python_ai_packages || return 1
    
    # Install OpenVINO
    run_step "openvino" _install_openvino || return 1
    
    # Install NCNN
    run_step "ncnn" _install_ncnn || return 1
    
    # Install ARM NN (only for aarch64)
    if [ "$(uname -m)" = "aarch64" ]; then
        run_step "armnn" _install_armnn || return 1
    fi
}

_install_tvm_deps() {
    case "$DISTRO" in
        ubuntu)
            $INSTALL_CMD cmake build-essential git python3-dev python3-setuptools gcc libtinfo-dev zlib1g-dev libedit-dev libxml2-dev
            ;;
        redhat)
            $INSTALL_CMD cmake gcc-c++ git python3-devel python3-setuptools ncurses-devel zlib-devel
            ;;
    esac
    return 0
}

_install_tvm() {
    if [ -d "tvm" ]; then
        log "TVM directory exists. Updating..."
        cd tvm
        git fetch --all
        git checkout v${TVM_VERSION}
        git submodule update --init --recursive
    else
        log "Cloning TVM..."
        git clone --recursive https://github.com/apache/tvm tvm
        cd tvm
        git checkout v${TVM_VERSION}
    fi

    log "Building TVM..."
    mkdir -p build
    cp cmake/config.cmake build/ || {
        log "config.cmake already exists in build directory"
    }
    cd build
    if [ "$HAS_GPU" = true ]; then
        echo "set(USE_CUDA ON)" >> config.cmake
        echo "set(USE_CUDNN ON)" >> config.cmake
    fi
    cmake ..
    make -j$(nproc)
    cd python
    pip install -e .
    cd ../../
    return 0
}

_install_python_ai_packages() {
    source "$VENV_DIR/bin/activate"
    pip install tensorflow==${TENSORFLOW_VERSION}
    pip install onnx onnxruntime-gpu
    pip install torch torchvision torchaudio
    pip install mediapipe
    pip install mlperf-inference
    pip install neural-compressor torch2trt tensorflow-model-optimization mxnet paddlepaddle-gpu tritonclient[all]
    deactivate
    return 0
}

_install_openvino() {
    case "$DISTRO" in
        ubuntu)
            wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
            sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
            echo "deb https://apt.repos.intel.com/openvino/2023 ubuntu22 main" | sudo tee /etc/apt/sources.list.d/intel-openvino-2023.list
            $UPDATE_CMD
            $INSTALL_CMD intel-openvino-dev-ubuntu22
            ;;
        redhat)
            sudo dnf config-manager --add-repo https://yum.repos.intel.com/openvino/2023/setup/intel-openvino-2023.repo
            $INSTALL_CMD intel-openvino-dev
            ;;
    esac
    return 0
}

_install_ncnn() {
    git clone https://github.com/Tencent/ncnn.git
    cd ncnn
    mkdir -p build
    cd build
    if [ "$HAS_GPU" = true ]; then
        cmake -DNCNN_VULKAN=ON ..
    else
        cmake ..
    fi
    make -j$(nproc)
    sudo make install
    cd ../..
    return 0
}

_install_armnn() {
    git clone https://github.com/ARM-software/armnn.git
    cd armnn
    mkdir -p build
    cd build
    cmake .. \
        -DARMCOMPUTE_ROOT=/usr/local/include \
        -DARMCOMPUTE_BUILD_DIR=/usr/local/lib
    make -j$(nproc)
    sudo make install
    cd ../..
    return 0
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
    echo "║     On Device AI Development Setup        ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Starting ODA installation..."
    
    # Validate system requirements
    validate_system_requirements
    
    # Detect distribution
    detect_distribution
    
    # Setup package manager
    setup_package_manager
    
    # Detect GPU
    detect_gpu
    
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
    
    # Setup AI tools
    setup_ai_tools
    
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
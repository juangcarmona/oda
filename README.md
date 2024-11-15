# ODA (On Device AI)

Turn your Linux system into a fully-configured, sleek, and modern on-device AI development system by running a single command.

Radicle: `rad://z2ELVemM12PrcCMfi7dQCTHfsWPNh`

## Overview

ODA is a comprehensive setup script that transforms a fresh Linux installation into a complete AI development environment. It automates the installation and configuration of essential tools, libraries, and environments commonly used in AI development.

## Features

- One-command setup
- Automatic distribution detection and configuration
- Essential development tools
- Python environment with AI/ML libraries (version-pinned)
- Docker configuration
- GPU drivers and CUDA setup (if available)
- Development environment configurations
- Performance optimizations
- Strict error handling and validation

## Quick Start

```bash
# Option 1: Direct execution (recommended)
curl -sSL https://raw.githubusercontent.com/mitkox/oda/main/oda.sh | bash

# Option 2: Download and inspect before running
curl -O https://raw.githubusercontent.com/mitkox/oda/main/oda.sh
chmod +x oda.sh
./oda.sh
```

After installation, activate the Python virtual environment:
```bash
source ~/.oda-venv/bin/activate
```

## What Gets Installed

- System essentials (git, curl, build tools)
- Python 3.10 with virtual environment
- Version-pinned AI/ML libraries:
  - PyTorch 2.1.0
  - TensorFlow 2.14.0
  - NumPy 1.24.3
  - pandas 2.1.1
  - scikit-learn 1.3.1
- llama.cpp with CUDA support (when GPU available)
- Docker and NVIDIA Container Toolkit
- Development tools (VS Code)
- Shell improvements (zsh, oh-my-zsh)
- NVIDIA driver 535 and CUDA (if GPU available)

## Requirements

### Supported Distributions
- Ubuntu 20.04 LTS or newer
- Red Hat Enterprise Linux 8 or newer
- CentOS 8 or newer
- Rocky Linux 8 or newer
- AlmaLinux 8 or newer

### System Requirements
- Internet connection
- Sudo privileges
- 20GB free disk space
- NVIDIA GPU (optional, for GPU acceleration)

## Features

### Error Handling
- Strict error checking with detailed error messages
- Disk space validation
- System compatibility checks
- Detailed installation logs at `/tmp/oda-install.log`

### Python Environment
- Isolated virtual environment at `~/.oda-venv`
- Version-pinned dependencies for stability
- Pre-configured for AI/ML development

### GPU Support
- Automatic NVIDIA GPU detection
- CUDA-enabled builds when GPU is available
- Containerized GPU support with NVIDIA Docker
- Fallback to CPU-only versions when no GPU is present

### Distribution Support
- Automatic distribution detection
- Distribution-specific optimizations
- Automatic package manager detection
- Distribution-specific repository management

### Security Features
- HTTPS-only downloads
- GPG key verification for repositories
- Secure temporary file handling
- Principle of least privilege
- Comprehensive error checking

## Installation Directory Structure

```
$HOME/
├── .oda/                    # Main installation directory
│   └── llama.cpp/          # llama.cpp installation
└── .oda-venv/              # Python virtual environment
```

## Troubleshooting

### Installation Logs
Check the installation log for detailed information:
```bash
cat /tmp/oda-install.log
```

### Common Issues
1. **GPU Not Detected**: Ensure NVIDIA drivers are properly installed
2. **Package Installation Fails**: Check internet connection and try again
3. **Permission Issues**: Ensure you have sudo privileges
4. **Space Issues**: Ensure you have at least 20GB free space

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details

## Security

For security concerns, please see our [Security Policy](SECURITY.md)

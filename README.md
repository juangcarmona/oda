# ODA (On Device AI)

Turn a fresh Ubuntu installation into a fully-configured, sleek, and modern on device AI development system by running a single command.

Radicle: `rad://z2ELVemM12PrcCMfi7dQCTHfsWPNh`

## Overview

ODA is a comprehensive setup script that transforms a fresh Ubuntu installation into a complete AI development environment. It automates the installation and configuration of essential tools, libraries, and environments commonly used in AI development.

## Features

- One-command setup
- Essential development tools
- Python environment with AI/ML libraries (version-pinned)
- Docker configuration
- GPU drivers and CUDA setup (if available)
- Development environment configurations
- Performance optimizations
- Strict error handling and validation

## Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/mitkox/oda/main/oda.sh | bash
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

- Fresh Ubuntu installation (20.04 LTS or newer)
- Internet connection
- Sudo privileges
- 20GB free disk space

## Features

### Error Handling
- Strict error checking with detailed error messages
- Disk space validation
- System compatibility checks

### Python Environment
- Isolated virtual environment at `~/.oda-venv`
- Version-pinned dependencies for stability
- Pre-configured for AI/ML development

### GPU Support
- Automatic NVIDIA GPU detection
- CUDA-enabled builds when GPU is available
- Containerized GPU support with NVIDIA Docker

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details

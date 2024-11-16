# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2024-11-16

### Added
- Command-line options for flexible installation:
  - `-y/--yes`: Non-interactive mode
  - `-d/--dry-run`: Preview mode
  - `-v/--verbose`: Enhanced logging
  - `--no-gpu`: Skip GPU installations
  - `--resume`: Resume failed installations
- Support for additional Linux distributions:
  - Debian
  - Fedora
  - CentOS
- Enhanced logging system with DEBUG, INFO, WARN, and ERROR levels
- Configuration backup system
- Installation state tracking and resume capability
- CUDA/Driver compatibility matrix
- Version compatibility checks

### Changed
- Improved error handling with detailed messages
- Enhanced distribution detection system
- Updated documentation with new features and examples
- Restructured main installation flow with step tracking

### Fixed
- Package manager detection for different distributions
- NVIDIA driver installation on various distributions
- VS Code repository configuration

## [0.0.1] - 2024-11-15

### Added
- Initial release
- Automated Linux distribution detection
- Support for Ubuntu and Red Hat-based systems
- Comprehensive system validation
- Python environment setup with AI/ML libraries
- Docker installation and configuration
- NVIDIA GPU support
- Development tools installation (VS Code, ZSH)
- Detailed documentation
- Security policy
- Contributing guidelines

### Security
- HTTPS-only downloads
- GPG key verification
- Secure file handling
- Principle of least privilege implementation
- No root installation requirement
- Clean environment management

# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Security Considerations

### Installation Script Security
- The installation script is downloaded via HTTPS to ensure integrity
- All package installations use official repositories and verified sources
- SHA256 checksums are verified for downloaded components where available
- All installations require explicit user confirmation via sudo

### System Modifications
- The script modifies system configurations only when necessary
- All system modifications are logged and reversible
- User permissions are modified only for essential functionality (e.g., Docker group)

### Virtual Environment
- Python packages are installed in an isolated virtual environment
- Dependencies are version-pinned to prevent supply chain attacks
- Third-party packages are installed only from PyPI using secure HTTPS

### GPU and CUDA Security
- NVIDIA drivers are installed only from official Ubuntu repositories
- CUDA installations are verified against NVIDIA's public keys
- Container runtime configurations follow NVIDIA's security guidelines

## Reporting a Vulnerability

We take security vulnerabilities seriously. Please follow these steps to report a vulnerability:

1. **Do Not** open a public GitHub issue for security vulnerabilities
2. Send a detailed report to [sec@mitkox.com](mailto:sec@mitkox.com)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Expect
- Acknowledgment of your report within 48 hours
- Regular updates on the progress
- Credit for responsible disclosure (if desired)

## Best Practices for Users

1. **Before Installation**
   - Verify the script's content before execution
   - Check the installation URL matches the official repository
   - Ensure you're on a supported Ubuntu version

2. **During Installation**
   - Review sudo commands before entering password
   - Monitor system modifications
   - Ensure adequate disk space (20GB minimum)

3. **Post Installation**
   - Keep the system updated
   - Regularly update AI/ML libraries
   - Monitor GPU resource usage

## Security Features

### Access Control
- All installed components follow principle of least privilege
- Docker containers run with restricted capabilities
- GPU access is properly sandboxed

### Network Security
- Downloads use HTTPS exclusively
- Package signatures are verified
- Container network access can be restricted

### Data Protection
- No sensitive data is collected
- Installation logs are stored locally
- Virtual environment isolates dependencies

## Dependency Security

We regularly monitor and update dependencies for:
- Known vulnerabilities
- Supply chain risks
- Compatibility issues

## License Compliance

All components are installed with respect to their licenses:
- Open source compliance is maintained
- License terms are preserved
- Attribution is provided where required

## Contact

For security-related matters, contact:
- Security Email: [sec@mitkox.com](mailto:sec@mitkox.com)
- Radicle: `rad://z2ELVemM12PrcCMfi7dQCTHfsWPNh`
- GitHub: [@mitkox](https://github.com/mitkox)

# Security Policy

## Supported Versions

We release patches for security vulnerabilities. The following versions are currently being supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.0.1   | :white_check_mark: |

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

We take the security of our project seriously. If you believe you have found a security vulnerability, please report it to us as described below.

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to [sec@mitkox.com](mailto:sec@mitkox.com).

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information:

* Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
* Full paths of source file(s) related to the manifestation of the issue
* The location of the affected source code (tag/branch/commit or direct URL)
* Any special configuration required to reproduce the issue
* Step-by-step instructions to reproduce the issue
* Proof-of-concept or exploit code (if possible)
* Impact of the issue, including how an attacker might exploit it

## Security Features

Our project implements several security features to protect your system:

1. **HTTPS-Only Downloads**: All package and script downloads use HTTPS
2. **GPG Key Verification**: Package repositories are verified using GPG keys
3. **Secure File Handling**: Temporary files are properly cleaned up
4. **Principle of Least Privilege**: Operations requiring elevated privileges are minimized
5. **No Root Installation**: The script prevents running as root for better security
6. **Clean Environment**: Temporary files and caches are cleaned after installation
7. **Access Control**: All installed components follow principle of least privilege
8. **Network Security**: Downloads use HTTPS exclusively
9. **Data Protection**: No sensitive data is collected

## Best Practices

When using our project, follow these security best practices:

1. Always inspect scripts before running them
2. Keep your system updated
3. Use strong passwords for all services
4. Follow the principle of least privilege
5. Regularly monitor system logs
6. Keep backups of important data
7. **Before Installation**
   - Verify the script's content before execution
   - Check the installation URL matches the official repository
   - Ensure you're on a supported Ubuntu version

8. **During Installation**
   - Review sudo commands before entering password
   - Monitor system modifications
   - Ensure adequate disk space (20GB minimum)

9. **Post Installation**
   - Keep the system updated
   - Regularly update AI/ML libraries
   - Monitor GPU resource usage

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine the affected versions
2. Audit code to find any potential similar problems
3. Prepare fixes for all supported versions
4. Release new versions as soon as possible

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

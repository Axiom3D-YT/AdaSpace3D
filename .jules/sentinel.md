## 2025-12-12 - Supply Chain Security in Build Scripts
**Vulnerability:** The build script (`builder.ps1`) downloaded an executable (`arduino-cli.exe`) from the internet without verifying its integrity.
**Learning:** This creates a supply chain vulnerability where a compromised release or a man-in-the-middle attack could inject malicious code into the build process.
**Prevention:** Always verify the checksum (SHA256) of downloaded binaries against a known good value before executing them.

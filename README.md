# Discord Screen Share Bypass

> Bypass Discord screen share restrictions on blocked networks using HTTPS proxy

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)]()

---

## What is this?

This tool allows you to **bypass Discord screen share blocks** on restricted networks such as:
- Networks with DPI (Deep Packet Inspection)
- ISPs blocking Discord traffic

**Works for:**
- Discord screen sharing
- Discord video calls

---

## How it works

```
[Your Device] → [HTTPS Proxy] → [Discord Screen Sharing]
                (encrypted)
```

All Discord traffic is routed through an external HTTPS proxy server, bypassing local network restrictions.

---

## Quick Installation

### Windows

**Automated (Recommended):**

Open PowerShell as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/kyou0x/discord-screenshare-bypass/main/install-windows.ps1 | iex
```

---

### Linux

**Automated (Recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/kyou0x/discord-screenshare-bypass/main/install-linux.sh | sudo bash
```
---

## Usage

After installation, simply open Discord normally. Screen sharing and all features will work without restrictions.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of server deployment and configuration scripts focused on Linux server setup and proxy management. The main repository contains platform-specific proxy installation scripts under the `proxy/` directory.

## Repository Structure

```
server-scripts/
├── README.md                   # Main project documentation
├── proxy/                      # Proxy installation scripts by platform
│   ├── linux/                  # Linux-specific scripts
│   │   ├── install_v2ray.sh    # Main V2Ray installation script
│   │   └── README.md           # Detailed usage documentation
│   ├── macos/                  # macOS-specific scripts
│   ├── windows/                # Windows-specific scripts
│   └── wsl/                    # WSL-specific scripts
```

## Main Components

### V2Ray Proxy Installation (Linux)

The primary component is a comprehensive V2Ray installation script (`proxy/linux/install_v2ray.sh`) that provides:

- **Multi-protocol support**: VMess, VLESS, Shadowsocks
- **Subscription management**: Automatic parsing and configuration
- **Server management**: Node switching, status monitoring
- **Proxy modes**: Local-only or LAN sharing
- **Custom port configuration**: User-defined SOCKS5/HTTP ports
- **Security features**: User authentication, DNS optimization
- **Management aliases**: Comprehensive command-line tools

## Common Commands

### Installation and Setup

```bash
# Download and run the main installation script
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/proxy/linux/install_v2ray.sh
chmod +x install_v2ray.sh
./install_v2ray.sh

# Load command aliases after installation
source ~/.bashrc
```

### V2Ray Management Commands

```bash
# Service management
v2start          # Start V2Ray service
v2stop           # Stop V2Ray service
v2restart        # Restart V2Ray service
v2status         # Check service status
v2log            # View logs

# Server management
v2switch         # Switch between servers
v2list           # List all available servers
v2vmess          # List VMess servers only
v2vless          # List VLESS servers only
v2ss             # List Shadowsocks servers only

# Subscription management
v2update         # Update subscription
v2scan           # Re-parse subscription

# Proxy connection
v2connect        # Quick proxy connect (start service + set env vars)
proxy_on         # Enable proxy (alias for v2connect)
proxy_off        # Disable proxy (clear env vars)
proxy_status     # Check proxy status
```

### Manual Script Management

If aliases are not loaded, scripts can be run directly:

```bash
cd ~/v2ray
./start.sh       # Start service
./stop.sh        # Stop service
./status.sh      # Check status
./switch.sh      # Switch servers
./update.sh      # Update subscription
```

## Architecture Notes

### Installation Process

1. **Environment Check**: Validates system architecture and required tools
2. **Subscription Input**: Collects and validates V2Ray subscription URL
3. **Proxy Mode Selection**: Chooses between local-only or LAN sharing
4. **Port Configuration**: Sets custom SOCKS5/HTTP ports with validation
5. **Binary Download**: Fetches latest V2Ray core for system architecture
6. **Subscription Parsing**: Python script parses multiple protocol formats
7. **Configuration Generation**: Creates V2Ray config with DNS/routing rules
8. **Management Scripts**: Generates comprehensive management toolset
9. **Alias Setup**: Configures bash aliases for easy management

### Key Components

- **install_v2ray.sh**: Main installation script (1761 lines)
- **full_parser.py**: Python script for subscription parsing (embedded)
- **server_manager.py**: Server switching and management (embedded)
- **Management Scripts**: Auto-generated shell scripts for service control

### Configuration Files

All configurations are stored in `~/v2ray/`:
- `config.json`: Active V2Ray configuration
- `servers_all.json`: All parsed servers
- `proxy_config.txt`: Port and authentication settings
- `subscription.txt`: Raw subscription data
- `subscription_url.txt`: Subscription URL

### Security Features

- DNS optimization with Chinese DNS servers
- Intelligent routing for domestic/international traffic
- User authentication for LAN sharing mode
- Port validation and conflict detection
- Process isolation using nohup and PID files

## Development Notes

- The main script is written in Bash with embedded Python components
- Uses color-coded output for better user experience
- Includes comprehensive error handling and validation
- Supports multiple system architectures (x86_64, ARM, etc.)
- No root privileges required for installation
- All operations are user-scoped to `~/v2ray/`

## Platform Support

Currently the repository focuses on Linux with plans for:
- macOS scripts (basic structure present)
- Windows scripts (basic structure present)
- WSL scripts (basic structure present)

The Linux implementation is the most mature and feature-complete.
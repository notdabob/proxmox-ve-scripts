# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains ProxMox VE automation scripts for creating and configuring virtual machines with MCP (Model Context Protocol) servers. The primary purpose is to automate the deployment of Docker-based MCP server infrastructure on ProxMox virtualization hosts.

## Common Commands

### Server Deployment (ProxMox Host)

```bash
# Make scripts executable
chmod +x scripts/proxmox_create_mcp_vm.sh

# Deploy MCP server VM
./scripts/proxmox_create_mcp_vm.sh

# Check VM status
qm status 120

# View VM configuration
qm config 120

# Connect to VM console
qm terminal 120

# SSH to deployed VM (after deployment)
ssh mcpadmin@<VM_IP>
```

### Client Configuration

```bash
# Install Python dependencies
pip3 install requests

# Run auto-configuration
python3 scripts/mcp_client_autoconfig.py

# Test MCP server connectivity manually
curl http://<VM_IP>:7001/health
curl http://<VM_IP>:7002/health
```

### Troubleshooting Commands

```bash
# On ProxMox host - check VM network interfaces
qm guest cmd 120 network-get-interfaces

# On ProxMox host - monitor VM agent
qm agent 120 ping

# On client - test MCP server discovery
python3 -c "import socket; print(socket.gethostbyname('mcp-server'))"
```

## Architecture

The project implements a two-phase deployment pattern:

### Phase 1: VM Creation and Configuration

The main script (`scripts/proxmox_create_mcp_vm.sh`) orchestrates:

1. **VM Creation**: Uses ProxMox `qm` CLI to create VM with virtio drivers, SCSI storage
2. **Manual Installation**: Pauses for Ubuntu Server 22.04 LTS installation
3. **Network Discovery**: Uses ProxMox guest agent to detect VM IP (`qm guest cmd`)
4. **SSH Setup**: Configures passwordless SSH access
5. **Docker Installation**: Deploys Docker CE and Docker Compose
6. **MCP Deployment**: Creates Docker Compose configurations for each MCP server

### Phase 2: Client Auto-Configuration

The Python script (`scripts/mcp_client_autoconfig.py`) performs:

1. **Service Discovery**: Attempts hostname resolution, falls back to subnet scanning
2. **Health Validation**: Tests each MCP server endpoint
3. **Configuration Updates**: Modifies JSON configs for multiple AI clients

### Key Components

- **VM Creation**: Uses ProxMox `qm` commands to create VMs with virtio drivers and SCSI storage
- **Network Discovery**: Automatically detects VM IP using ProxMox guest agent
- **Docker Deployment**: Installs Docker and deploys pre-configured MCP servers (Context7, Desktop Commander)
- **Service Orchestration**: Uses Docker Compose for container management
- **Client Auto-Configuration**: Python script that discovers MCP servers and configures client applications

## Configuration Variables

The script uses hardcoded configuration at the top of `scripts/proxmox_create_mcp_vm.sh`:

- `VMID`: ProxMox VM identifier (default: 120)
- `VMNAME`: VM display name (default: "mcp-server")
- `VMRAM`: Memory allocation in MB (default: 4096)
- `VMDISK_SIZE`: Virtual disk size (default: 32G)
- `VMISO`: Path to Ubuntu ISO image in ProxMox storage
- `MCP_SERVERS`: Array of MCP server names to deploy
- `BRIDGE`: Network bridge (default: "vmbr0")

## Prerequisites

### Server Deployment

- ProxMox VE host with `qm` command access
- Ubuntu 22.04 Server ISO uploaded to ProxMox storage
- `sshpass` utility available for SSH automation
- Network bridge `vmbr0` configured

### Client Configuration Prerequisites

- Python 3 with `requests` library
- Network access to MCP VM
- Write permissions to client configuration directories

## Usage

### VM Creation and Server Deployment

Execute the main script from the ProxMox host:

```bash
./scripts/proxmox_create_mcp_vm.sh
```

The script requires manual intervention during Ubuntu installation - it will pause and wait for user confirmation before proceeding with automation.

### Client Auto-Configuration

After VM deployment, configure MCP clients using the Python auto-configuration script:

```bash
python3 scripts/mcp_client_autoconfig.py
```

This script:

- Automatically discovers the MCP VM on the network (by hostname or subnet scan)
- Tests MCP server availability via health checks
- Updates configuration files for Claude Desktop, Perplexity, and MCP SuperAssistant
- Supports multiple MCP client applications simultaneously

The client script updates these configuration paths:

- Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Perplexity: `~/.perplexity/mcp.json`
- MCP SuperAssistant: `~/mcpconfig.json`

## Security Considerations

- Default credentials are hardcoded (`VMUSER="mcpadmin"`, `VMPASS="changeme"`)
- SSH strict host key checking is disabled for automation
- Script requires modification of credentials before production use

## Adding New MCP Servers

To add a new MCP server to the deployment:

1. Edit `scripts/proxmox_create_mcp_vm.sh`:
   - Add server name to `MCP_SERVERS` array
   - The script will create a Docker Compose file for it

2. Edit `scripts/mcp_client_autoconfig.py`:
   - Add port mapping to `MCP_PORTS` dictionary
   - Ensure port doesn't conflict with existing services

3. The deployment script expects MCP servers to:
   - Be available as Docker images
   - Expose a `/health` endpoint
   - Run on unique ports starting from 7001

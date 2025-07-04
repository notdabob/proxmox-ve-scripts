# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains ProxMox VE automation scripts for deploying MCP (Model Context Protocol) servers using industry-standard tools. It leverages the [ProxmoxVE Community Scripts](https://github.com/community-scripts/ProxmoxVE) to create Docker-ready VMs and then deploys a suite of MCP servers.

## Common Commands

### One-Command Deployment (ProxMox Host)

```bash
# Option 1: Complete deployment (VM + MCP servers)
./scripts/one-liner-deploy.sh

# Option 2: Complete Docker VM with Portainer (Alternative approach)
./scripts/proxmox_docker_vm_complete.sh

# Or using environment variables
VMID=150 HOSTNAME=my-mcp MEMORY=8192 ./scripts/one-liner-deploy.sh
```

### Step-by-Step Deployment

```bash
# Step 1: Create Docker VM using ProxmoxVE Community Script
./scripts/create_mcp_docker_vm.sh

# Step 2: Deploy MCP servers (after VM boots)
./scripts/deploy_mcp_to_docker_vm.sh <VM_IP>

# Or auto-detect IP
./scripts/deploy_mcp_to_docker_vm.sh auto 120
```

### Direct ProxmoxVE Community Script Usage

```bash
# Create Docker VM directly
VMID=120 HOSTNAME=docker CORE=4 MEMORY=4096 DISK=40 \
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/docker-vm.sh)"
```

### VM Management

```bash
# Check VM status
qm status 120

# Get VM IP address
qm guest cmd 120 network-get-interfaces

# Connect to VM console
qm terminal 120

# SSH to deployed VM (default password: proxmox)
ssh root@<VM_IP>

# Use MCP management command (on VM)
ssh root@<VM_IP> 'mcp status'
ssh root@<VM_IP> 'mcp logs'
ssh root@<VM_IP> 'mcp restart'
```

### Client Configuration

```bash
# Run auto-configuration
python3 scripts/mcp_client_autoconfig.py

# Test MCP server connectivity
curl http://<VM_IP>:7001/health  # Context7
curl http://<VM_IP>:7002/health  # Desktop Commander
curl http://<VM_IP>:7003/health  # Filesystem MCP
```

## Architecture

The project now offers multiple deployment approaches:

### Approach 1: ProxmoxVE Community Scripts (Recommended)

Uses the ProxmoxVE Community `docker-vm.sh` script which:

1. **Creates Debian 12 VM** - Latest stable Debian with cloud-init support
2. **Installs Docker CE** - Docker and Docker Compose pre-installed
3. **Configures Networking** - Automatic DHCP with QEMU Guest Agent
4. **Sets Default Password** - root:proxmox (should be changed)

Then deploys MCP servers via `deploy_mcp_to_docker_vm.sh`.

### Approach 2: Complete Docker VM Script (Alternative)

The `proxmox_docker_vm_complete.sh` script provides:

1. **Debian 12 Cloud Image** - Downloads and customizes latest Debian
2. **Docker Pre-installation** - Uses virt-customize for image preparation
3. **Portainer Deployment** - Automatic container management UI
4. **QEMU Guest Agent** - Pre-configured for ProxMox integration
5. **Interactive Setup** - User-friendly configuration prompts

### MCP Server Deployment

The deployment script (`deploy_mcp_to_docker_vm.sh`) performs:

1. **Docker Compose Setup** - Creates compose file with all MCP servers
2. **Service Deployment** - Deploys Context7, Desktop Commander, Filesystem MCP
3. **Health Checks** - Configures health monitoring for each service
4. **Management Tools** - Installs `mcp` command for easy control

## Configuration

### VM Configuration

Set these environment variables before running scripts:

- `VMID`: ProxMox VM identifier (default: 120)
- `HOSTNAME`: VM hostname (default: mcp-docker)
- `CORE`: CPU cores (default: 4)
- `MEMORY`: RAM in MB (default: 4096)
- `DISK`: Disk size in GB (default: 40)

### MCP Servers

Currently deployed MCP servers:

- **Context7 MCP** (port 7001) - SQLite-based context management
- **Desktop Commander** (port 7002) - System control capabilities
- **Filesystem MCP** (port 7003) - File system access

## Prerequisites

### ProxMox Host Requirements

- ProxMox VE 7.0 or later
- Internet connection for downloading Debian cloud image
- `wget` or `curl` available
- SSH client with `sshpass` for deployment

### Network Requirements

- DHCP available on the network bridge (usually vmbr0)
- Ports 7001-7003 accessible from client machines

## Security Considerations

- Default VM password is `proxmox` - **CHANGE THIS IMMEDIATELY**
- MCP servers are exposed on all interfaces - consider firewall rules
- Docker socket is mounted for Desktop Commander - understand the implications

## Troubleshooting

### VM Creation Issues

```bash
# Check if VM exists
qm list | grep 120

# Check ProxMox storage
pvesm status

# View VM creation logs
journalctl -u pvedaemon -f
```

### MCP Deployment Issues

```bash
# Test SSH connectivity
ssh root@<VM_IP> 'docker --version'

# Check Docker status on VM
ssh root@<VM_IP> 'systemctl status docker'

# View MCP logs
ssh root@<VM_IP> 'cd /opt/mcp && docker compose logs'
```

### Network Issues

```bash
# Check VM network from ProxMox host
ping <VM_IP>

# Check QEMU Guest Agent
qm agent 120 ping

# View VM network config
qm guest cmd 120 network-get-interfaces
```

## Documentation Best Practices for Claude Code

- Use Markdown (`.md` files) for all primary project documentation, including `README.md`, installation guides, and general how-tos.
- Ensure Markdown files are clear, concise, and render well on GitHub and other code hosting platforms.
- Use Jupyter Notebooks (`.ipynb` files) only for interactive tutorials, code walkthroughs, or data-driven examples where executable code and output are needed.
- Link to Jupyter Notebooks from Markdown documentation when providing interactive or advanced examples.
- Do not use Jupyter Notebooks for static project documentation or main README files.
- Keep documentation up to date and ensure all code examples are tested and accurate.
- Prefer plain Markdown for compatibility and ease of collaboration.

## Jupyter Notebook Usage Guidelines for Claude Code

- When creating interactive tutorials, code walkthroughs, or step-by-step guides that benefit from live code execution and output, generate a Jupyter Notebook (`.ipynb` file) in addition to Markdown documentation.
- Jupyter Notebooks should:
  - Include clear Markdown cells explaining each step, command, or concept.
  - Provide code cells that users can execute directly to follow along with the tutorial or solution.
  - Show expected outputs or results where possible.
  - Be organized and easy to follow, with section headings and comments.
- For project-specific solutions (e.g., running scripts, deploying VMs, or configuring services), create a notebook that demonstrates the process interactively, allowing users to modify parameters and see results.
- Link to the generated Jupyter Notebook from the main documentation (e.g., `README.md`) so users can easily find and use the interactive guide.
- Ensure all code in notebooks is tested and works as intended in the project environment.
- Name notebooks descriptively (e.g., `interactive_vm_deployment_tutorial.ipynb`).
- Keep notebooks up to date with project changes and document any required dependencies or setup steps at the top of the notebook.

## File Structure Documentation Rule

- Do not prompt to update or modify `docs/file-structure.md` unless explicitly requested by the user.

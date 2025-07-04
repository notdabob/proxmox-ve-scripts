# ProxMox VE Scripts

Automated deployment scripts for MCP (Model Context Protocol) servers on ProxMox VE.

[![GitHub Repository](https://img.shields.io/badge/GitHub-proxmox--ve--scripts-blue?logo=github)](https://github.com/notdabob/proxmox-ve-scripts)

---

## 🚀 INSTANT DEPLOY (Recommended)

**One command to create a Docker VM with MCP servers:**

```bash
git clone https://github.com/notdabob/proxmox-ve-scripts.git && cd proxmox-ve-scripts && chmod +x scripts/*.sh && ./scripts/one-liner-deploy.sh
```

This uses the industry-standard [ProxmoxVE Community Scripts](https://github.com/community-scripts/ProxmoxVE) to:

- ✅ Create a Debian 12 VM with Docker pre-installed
- ✅ Auto-configure networking and storage
- ✅ Deploy MCP servers (Context7, Desktop Commander, Filesystem)
- ✅ Set up management commands

---

## Alternative Methods

### Method 1: Complete Docker VM with Portainer

```bash
./scripts/proxmox_docker_vm_complete.sh
```

This alternative approach provides:

- Interactive configuration wizard
- Debian 12 with Docker CE pre-installed
- Portainer for container management
- Automatic QEMU Guest Agent setup
- Custom disk sizing options

### Method 2: Create VM Only (ProxmoxVE Community Script)

```bash
VMID=120 HOSTNAME=mcp-docker CORE=4 MEMORY=4096 DISK=40 \
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/docker-vm.sh)"
```

Then deploy MCP servers separately.

### Method 3: Step-by-Step

```bash
# 1. Create Docker VM
./scripts/create_mcp_docker_vm.sh

# 2. Deploy MCP servers (after VM boots)
./scripts/deploy_mcp_to_docker_vm.sh <VM_IP>
```

## What Gets Deployed

- **Debian 12 VM** with Docker CE pre-installed
- **MCP Servers**:
  - Context7 MCP (Port 7001) - SQLite context management
  - Desktop Commander (Port 7002) - System control capabilities
  - Filesystem MCP (Port 7003) - File system access
- **Management Tool**: `mcp` command for easy control

## Client Configuration

After deployment, configure your AI clients (Claude Desktop, etc.):

```bash
python3 scripts/mcp_client_autoconfig.py
```

This will auto-detect the MCP servers and configure your clients.

## Features

- **Industry-Standard Base** - Uses proven ProxmoxVE Community Scripts
- **Automated VM Creation** - Debian 12 VM with Docker CE pre-installed
- **MCP Server Suite** - Context7, Desktop Commander, and Filesystem MCP servers
- **Zero Manual Configuration** - Fully automated deployment process
- **Client Auto-Configuration** - Discovers and configures Claude Desktop, Perplexity, etc.
- **Management Tools** - Built-in `mcp` command for easy server control

## Documentation

- **Project Structure**: See [`docs/file-structure.md`](docs/file-structure.md) for visual project layout
- **Detailed Guide**: See [`CLAUDE.md`](CLAUDE.md) for comprehensive documentation
- **Version History**: See [`docs/CHANGELOG.md`](docs/CHANGELOG.md) for release notes
- **Jupyter Notebooks**: See [`docs/README.ipynb`](docs/README.ipynb) for interactive examples and tutorials

## Jupyter Notebooks

- When you want a new interactive tutorial or code walkthrough, prompt Claude Code with a clear request, such as:
- “Create a Jupyter notebook that demonstrates how to deploy an MCP server using the scripts in this project
- with step-by-step explanations and runnable code cells.”

## Requirements

- ProxMox VE host with internet connection
- Python 3 with requests library (for client configuration)
- Network connectivity between clients and MCP VM

## Security Note

Default VM credentials: `root:proxmox` - **Change these immediately after deployment!**

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/notdabob/proxmox-ve-scripts/issues) on GitHub.

## License

[License information to be added]

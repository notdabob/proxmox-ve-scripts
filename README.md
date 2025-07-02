# ProxMox VE Scripts

Automated deployment scripts for MCP (Model Context Protocol) servers on ProxMox VE.

[![GitHub Repository](https://img.shields.io/badge/GitHub-proxmox--ve--scripts-blue?logo=github)](https://github.com/notdabob/proxmox-ve-scripts)

## 🚀 Quick Start (One-Liner)

Run this command directly on your ProxMox host shell to download and start the setup:

```bash
git clone https://github.com/notdabob/proxmox-ve-scripts.git && cd proxmox-ve-scripts && chmod +x scripts/*.sh && ./scripts/proxmox_create_mcp_vm.sh
```

This will:
1. Clone the repository
2. Make scripts executable
3. Launch the interactive VM creation wizard
4. Auto-download Ubuntu ISO if needed
5. Create and configure your Docker host VM with MCP servers

## Detailed Installation

If you prefer to install step-by-step:

```bash
# Clone the repository
git clone https://github.com/notdabob/proxmox-ve-scripts.git
cd proxmox-ve-scripts

# Make scripts executable
chmod +x scripts/*.sh scripts/modules/*.sh
```

## Deployment Options

### Option 1: All-in-One Deployment

Deploy everything with a single script:
```bash
./scripts/proxmox_create_mcp_vm.sh
```

### Option 2: Modular Deployment

For more control, deploy in separate steps:

1. **Create Docker Host VM**:
   ```bash
   ./scripts/create_docker_host_vm.sh
   ```

2. **Deploy MCP Servers** (after VM creation):
   ```bash
   ./scripts/deploy_mcp_servers.sh <VM_IP>
   ```

### Configure Clients

After deployment, configure your AI clients (Claude Desktop, Perplexity, etc.):
```bash
python3 scripts/mcp_client_autoconfig.py
```

## Features

- **Automated VM Creation** - Creates Ubuntu VMs with Docker pre-configured
- **Modular Architecture** - Reusable modules for VM creation and Docker deployment
- **Network Integration** - Docker containers with full host network access (192.168.1.0/24)
- **MCP Server Deployment** - Deploys multiple MCP servers via Docker Compose
- **Client Auto-Configuration** - Discovers and configures Claude Desktop, Perplexity, and MCP SuperAssistant

## Documentation

- **Project Structure**: See [`docs/file-structure.md`](docs/file-structure.md) for visual project layout
- **Detailed Guide**: See [`CLAUDE.md`](CLAUDE.md) for comprehensive documentation
- **Version History**: See [`docs/CHANGELOG.md`](docs/CHANGELOG.md) for release notes

## Requirements

- ProxMox VE host with Ubuntu 22.04 ISO
- Python 3 with requests library (for client configuration)
- Network connectivity between clients and MCP VM

## Security Note

Default credentials are provided for automation. **Change these before production use.**

## Usage

This structure supports:

1. **Automated VM deployment** on ProxMox hosts
2. **MCP server orchestration** via Docker Compose
3. **Client auto-configuration** for multiple AI assistants
4. **Documentation maintenance** with Claude Code integration

Last updated: 2025-07-02

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request to the [GitHub repository](https://github.com/notdabob/proxmox-ve-scripts).

## Issues and Support

If you encounter any issues or have questions, please [open an issue](https://github.com/notdabob/proxmox-ve-scripts/issues) on GitHub.

## License

[License information to be added]

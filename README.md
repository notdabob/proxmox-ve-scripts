# ProxMox VE Scripts

Automated deployment scripts for MCP (Model Context Protocol) servers on ProxMox VE.

## Quick Start

### Option 1: All-in-One Deployment

1. **Deploy MCP Server VM** (on ProxMox host):
   ```bash
   ./scripts/proxmox_create_mcp_vm.sh
   ```

### Option 2: Modular Deployment

1. **Create Docker Host VM** (on ProxMox host):
   ```bash
   ./scripts/create_docker_host_vm.sh
   ```

2. **Deploy MCP Servers** (after VM creation):
   ```bash
   ./scripts/deploy_mcp_servers.sh <VM_IP>
   ```

### Configure Clients

3. **Configure MCP Clients** (on client machine):
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

Last updated: 2025-01-02

## License

[License information to be added]

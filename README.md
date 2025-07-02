# ProxMox VE Scripts

Automated deployment scripts for MCP (Model Context Protocol) servers on ProxMox VE.

## Quick Start

1. **Deploy MCP Server VM** (on ProxMox host):
   ```bash
   ./scripts/proxmox_create_mcp_vm.sh
   ```

2. **Configure MCP Clients** (on client machine):
   ```bash
   python3 scripts/mcp_client_autoconfig.py
   ```

## Features

- **Automated VM Creation** - Creates Ubuntu 22.04 VMs with Docker pre-configured
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

## License

[License information to be added]
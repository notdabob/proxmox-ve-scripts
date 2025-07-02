# ProxMox VE Scripts

Automated deployment scripts for MCP (Model Context Protocol) servers on ProxMox VE.

[![GitHub Repository](https://img.shields.io/badge/GitHub-proxmox--ve--scripts-blue?logo=github)](https://github.com/notdabob/proxmox-ve-scripts)

---

## 🚀 GET STARTED IN 10 SECONDS

**Step 1:** Open your ProxMox host terminal

**Step 2:** Copy and paste this single command:

```bash
git clone https://github.com/notdabob/proxmox-ve-scripts.git && cd proxmox-ve-scripts && chmod +x scripts/*.sh && ./scripts/quick_deploy.sh
```

**Step 3:** Follow the interactive prompts

That's it! The script will:
- ✅ Download all necessary files
- ✅ Make scripts executable  
- ✅ Launch the setup wizard
- ✅ Auto-download Ubuntu ISO if needed
- ✅ Create your Docker VM with MCP servers

---

## Alternative One-Liner (No Git Required)

If you just want to create a VM quickly without cloning the repo:

```bash
curl -fsSL https://raw.githubusercontent.com/notdabob/proxmox-ve-scripts/main/scripts/quick_deploy.sh | bash
```

---

## Alternative Deployment Methods

### Manual Step-by-Step

If you already cloned the repository and want to run scripts individually:

#### Option 1: All-in-One Script

```bash
./scripts/proxmox_create_mcp_vm.sh
```

#### Option 2: Modular Deployment

```bash
# First create the VM
./scripts/create_docker_host_vm.sh

# Then deploy MCP servers
./scripts/deploy_mcp_servers.sh <VM_IP>
```

### Configure MCP Clients

After deployment, configure your AI clients (on client machine):

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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/notdabob/proxmox-ve-scripts/issues) on GitHub.

## License

[License information to be added]

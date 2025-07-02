# Project File Structure

This document provides a visual representation of the ProxMox VE Scripts project structure.

## Directory Structure

```mermaid
graph TD
    A[proxmox_ve-scripts/] --> B[.claude/]
    A --> C[docs/]
    A --> D[scripts/]
    A --> E[.gitignore]
    A --> F[CLAUDE.md]
    A --> G[README.md]

    B --> H[claude_command_setup.sh]
    B --> I[commands/]
    I --> J[commit.md]

    C --> K[CHANGELOG.md]
    C --> L[file-structure.md]

    D --> M[proxmox_create_mcp_vm.sh]
    D --> N[mcp_client_autoconfig.py]
    D --> O[create_docker_host_vm.sh]
    D --> P[deploy_mcp_servers.sh]
    D --> Q[modules/]
    D --> R[config/]

    Q --> S[proxmox_vm_create.sh]
    Q --> T[docker_deploy.sh]

    R --> U[docker-host.conf.example]

    style A fill:#f9f,stroke:#333,stroke-width:4px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#bbf,stroke:#333,stroke-width:2px
    style D fill:#bbf,stroke:#333,stroke-width:2px
    style Q fill:#bfb,stroke:#333,stroke-width:2px
    style R fill:#bfb,stroke:#333,stroke-width:2px
```

## File Descriptions

### Root Directory

- **`.gitignore`** - Git ignore patterns for Python, IDE, and temporary files
- **`CLAUDE.md`** - Comprehensive project documentation for Claude Code AI assistant
- **`README.md`** - Project overview and quick start guide

### `.claude/` Directory

- **`claude_command_setup.sh`** - Setup script for Claude custom commands
- **`commands/`** - Custom Claude command definitions
  - **`commit.md`** - Smart commit command with version management

### `docs/` Directory

- **`CHANGELOG.md`** - Version history following semantic versioning
- **`file-structure.md`** - This file - visual project structure documentation

### `scripts/` Directory

- **`proxmox_create_mcp_vm.sh`** - Original all-in-one script for VM creation and MCP deployment
- **`mcp_client_autoconfig.py`** - Python script for automatic MCP client configuration
- **`create_docker_host_vm.sh`** - Modular script for creating Docker-optimized VMs
- **`deploy_mcp_servers.sh`** - Deploy MCP servers to existing Docker host VMs
- **`modules/`** - Reusable bash modules
  - **`proxmox_vm_create.sh`** - ProxMox VM creation functions
  - **`docker_deploy.sh`** - Docker installation and deployment functions
- **`config/`** - Configuration files
  - **`docker-host.conf.example`** - Example configuration for Docker host VMs

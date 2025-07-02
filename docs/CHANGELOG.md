# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0] - 2025-07-02

### Added in v0.8.0 at 2025-07-02 17:29:11 EDT

- Created simplified quick_deploy.sh script for easier VM creation
- Added robust proxmox_create_mcp_vm_v2.sh with better error handling
- Added curl one-liner option that doesn't require git clone
- Implemented proper logging with timestamps
- Added DEBUG mode support for troubleshooting

### Fixed in v0.8.0 at 2025-07-02 17:29:11 EDT

- Completely rewrote ISO detection logic to avoid sed errors
- Fixed output contamination by properly separating stdout/stderr
- Improved storage detection with better parsing of /etc/pve/storage.cfg
- Fixed markdown linting issues in README

### Enhanced in v0.8.0 at 2025-07-02 17:29:11 EDT

- Simplified user experience with quick_deploy.sh
- Better error messages and logging throughout
- More defensive programming with proper error checks
- Removed complex regex operations for better compatibility

## [0.7.3] - 2025-07-02

### Fixed in v0.7.3 at 2025-07-02 17:20:25 EDT

- Fixed grep -P option error on ProxMox hosts (switched to -E for POSIX compatibility)
- Fixed array passing issues in ISO location selection
- Fixed empty custom version handling in Ubuntu selection
- Redirected status messages to stderr to prevent output contamination
- Fixed discover_iso_locations to output one directory per line
- Added missing chmod for modules directory in one-liner command

## [0.7.2] - 2025-07-02

### Enhanced in v0.7.2 at 2025-07-02 17:07:17 EDT

- Added one-liner quick start command for ProxMox host terminal
- Reorganized README with clearer section flow
- Added emoji for quick start section visibility
- Improved deployment options documentation
- Made instructions more beginner-friendly

## [0.7.1] - 2025-07-02

### Enhanced in v0.7.1 at 2025-07-02 17:01:38 EDT

- Added GitHub repository references and badges to README
- Added installation instructions with git clone commands
- Added contributing and support sections with GitHub links
- Updated last modified date in README

## [0.7.0] - 2025-07-02

### Added in v0.7.0 at 2025-07-02 16:54:54 EDT

- Modular architecture with reusable bash modules
- Separate VM creation module (`modules/proxmox_vm_create.sh`)
- Docker deployment module (`modules/docker_deploy.sh`)
- Standalone Docker host VM creation script
- Separate MCP server deployment script
- Configuration file support for Docker host VMs
- Network configuration for Docker containers with host network access
- Helper scripts for Docker management on VMs
- Traefik reverse proxy option for better routing

### Enhanced in v0.7.0 at 2025-07-02 16:54:54 EDT

- Better separation of concerns between VM creation and service deployment
- Improved Docker networking with macvlan support for host network access
- More flexible deployment options (all-in-one or modular)
- Better error handling and status reporting

## [0.6.0] - 2025-07-02

### Added in v0.6.0 at 2025-07-02 16:35:29 EDT

- Dynamic Ubuntu version selection with interactive menu
- Automatic detection of latest Ubuntu point releases
- Support for multiple Ubuntu LTS versions (20.04, 22.04, 24.04)
- Custom version input option for flexibility

### Enhanced in v0.6.0 at 2025-07-02 16:35:29 EDT

- Made script future-proof by removing hardcoded Ubuntu versions
- Improved version detection logic with fallback mechanisms
- Better user experience with sensible defaults (22.04 LTS recommended)

## [0.5.0] - 2025-07-02

### Added in v0.5.0 at 2025-07-02 16:32:12 EDT

- Automatic Ubuntu Server ISO download functionality if not present
- ISO storage location discovery with intelligent path detection
- Tree command installation check and usage for visual directory exploration
- Interactive storage selection when multiple ISO locations exist
- Automatic ProxMox storage name resolution from file paths
- Visual feedback showing existing ISOs in each storage location

### Enhanced in v0.5.0 at 2025-07-02 16:32:12 EDT

- Improved script robustness with better error handling
- Better user experience with visual storage exploration
- Automatic path-to-storage-name mapping using /etc/pve/storage.cfg

## [0.4.2] - 2025-07-02

### Fixed in v0.4.2 at 2025-07-02 13:59:27 EDT

- Added missing newline at end of CHANGELOG.md file

## [0.4.1] - 2025-01-02

### Fixed in v0.4.1 at 2025-01-02 13:56:56 EST

- Updated commit.md to include timestamp requirements in changelog section headers
- Added timestamps to all existing changelog entries for consistency
- Clarified timestamp format as "YYYY-MM-DD HH:MM:SS TZ"

## [0.4.0] - 2025-01-02

### Added in v0.4.0 at 2025-01-02 13:45:00 EST

- Project README.md with quick start guide and documentation links
- docs/file-structure.md with mermaid diagram visualization
- Enhanced commit.md to maintain file-structure.md and README.md

### Enhanced in v0.4.0 at 2025-01-02 13:45:00 EST

- Updated commit command to automatically update documentation
- Improved project documentation structure and navigation

## [0.3.0] - 2025-01-02

### Fixed in v0.3.0 at 2025-01-02 13:30:00 EST

- Moved CHANGELOG.md to docs folder per project conventions
- Updated commit.md to reference correct docs/CHANGELOG.md path
- Aligned documentation structure with project standards

## [0.2.0] - 2025-01-02

### Added in v0.2.0 at 2025-01-02 13:00:00 EST

- Common Commands section in CLAUDE.md with frequently used commands for deployment, troubleshooting, and testing
- Detailed Architecture section explaining the two-phase deployment pattern
- Specific default values for all configuration variables
- Instructions for extending the system with additional MCP servers

### Enhanced in v0.2.0 at 2025-01-02 13:00:00 EST

- Improved markdown formatting to comply with linting standards
- Better organization of prerequisites and configuration sections
- More detailed command-line usage examples

## [0.1.0] - Initial Release

### Added in v0.1.0 at 2025-01-02 12:00:00 EST

- Initial ProxMox VM creation script for MCP server deployment
- Automated Docker and MCP server installation
- Client auto-configuration script for multiple AI assistants
- Basic documentation in CLAUDE.md

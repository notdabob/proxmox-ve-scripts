# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

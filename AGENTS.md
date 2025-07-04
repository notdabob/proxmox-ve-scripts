# AGENTS.md - Development Guidelines

## Build/Test Commands
- **Test scripts**: `bash -n scripts/*.sh` (syntax check)
- **Run deployment**: `./scripts/one-liner-deploy.sh`
- **Test Python**: `python3 -m py_compile scripts/mcp_client_autoconfig.py`
- **Docker services**: `docker compose -f docker-compose.yaml config` (validate)

## Code Style Guidelines

### Shell Scripts (.sh)
- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use `"${VAR:-default}"` for variables with defaults
- Quote all variables: `"$VAR"` not `$VAR`
- Use descriptive function names and comments
- Follow existing indentation (2 spaces)

### Python (.py)
- Use standard library imports first, then third-party
- Use snake_case for variables and functions
- Include type hints where beneficial
- Use f-strings for formatting: `f"text {var}"`
- Handle exceptions with try/except blocks

### Docker Compose
- Use version '3.8' format
- Include health checks for all services
- Use named volumes for persistence
- Set restart policies to `unless-stopped`
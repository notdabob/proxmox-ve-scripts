#!/bin/bash
# Create Docker VM using ProxmoxVE Community Scripts
# Then deploy MCP servers

set -e

# Default configuration
VMID="${VMID:-120}"
HOSTNAME="${HOSTNAME:-mcp-docker}"
CORE="${CORE:-4}"
MEMORY="${MEMORY:-4096}"
DISK="${DISK:-40}"

echo "=== Creating Docker VM with ProxmoxVE Community Script ==="
echo ""
echo "Configuration:"
echo "  VMID: $VMID"
echo "  Hostname: $HOSTNAME"
echo "  Cores: $CORE"
echo "  Memory: $MEMORY MB"
echo "  Disk: $DISK GB"
echo ""

# Create the Docker VM using the community script
VMID=$VMID HOSTNAME=$HOSTNAME CORE=$CORE MEMORY=$MEMORY DISK=$DISK \
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/docker-vm.sh)"

echo ""
echo "=== Docker VM Created Successfully! ==="
echo ""
echo "The VM has been created with Docker pre-installed."
echo "Default credentials: root / proxmox"
echo ""
echo "Next steps:"
echo "1. Wait for the VM to fully boot (about 1-2 minutes)"
echo "2. Get the VM IP: qm guest cmd $VMID network-get-interfaces"
echo "3. Deploy MCP servers: ./scripts/deploy_mcp_to_docker_vm.sh <VM_IP>"
echo ""
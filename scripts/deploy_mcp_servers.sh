#!/bin/bash
# Deploy MCP Servers to Docker Host VM
# This script deploys MCP servers to an existing Docker host VM

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source modules
source "${SCRIPT_DIR}/modules/docker_deploy.sh"

# Configuration
MCP_SERVERS="${MCP_SERVERS:-context7-mcp desktop-commander}"
HOST_NETWORK="${HOST_NETWORK:-192.168.1.0/24}"

# Usage function
usage() {
    echo "Usage: $0 <vm_ip> [username]"
    echo ""
    echo "Deploy MCP servers to a Docker host VM"
    echo ""
    echo "Arguments:"
    echo "  vm_ip     - IP address of the Docker host VM"
    echo "  username  - SSH username (default: docker)"
    echo ""
    echo "Environment variables:"
    echo "  MCP_SERVERS    - Space-separated list of MCP servers to deploy"
    echo "  HOST_NETWORK   - Host network CIDR (default: 192.168.1.0/24)"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

VM_IP="$1"
VMUSER="${2:-docker}"

echo "========================================="
echo "MCP Server Deployment"
echo "========================================="
echo "Target VM: $VM_IP"
echo "Username: $VMUSER"
echo "MCP Servers: $MCP_SERVERS"
echo "Host Network: $HOST_NETWORK"
echo ""

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$VMUSER@$VM_IP" echo "SSH connection successful" 2>/dev/null; then
    echo "Error: Cannot connect to $VMUSER@$VM_IP via SSH"
    echo "Please ensure:"
    echo "  1. The VM is running"
    echo "  2. SSH key authentication is configured"
    echo "  3. The IP address is correct"
    exit 1
fi

# Deploy MCP servers
deploy_mcp_servers "$VM_IP" "$VMUSER" "$MCP_SERVERS" "$HOST_NETWORK"

# Show deployment results
echo ""
echo "========================================="
echo "MCP Servers Deployed Successfully!"
echo "========================================="
echo ""
echo "Available endpoints:"
port=7001
for server in $MCP_SERVERS; do
    echo "  $server: http://$VM_IP:$port"
    ((port++))
done
echo ""
echo "Traefik Dashboard: http://$VM_IP:8080"
echo ""
echo "Management commands (run on VM):"
echo "  ~/mcp-manage.sh status     - Show service status"
echo "  ~/mcp-manage.sh logs       - View logs"
echo "  ~/mcp-manage.sh restart    - Restart services"
echo "  ~/test-network.sh          - Test network connectivity"
echo "========================================="
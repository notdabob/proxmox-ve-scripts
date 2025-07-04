#!/bin/bash
# One-liner MCP deployment using ProxmoxVE community scripts

set -e

echo "=== One-Click MCP Server Deployment ==="
echo ""

# Configuration
VMID="${VMID:-210}"
HOSTNAME="${HOSTNAME:-mcp-docker}"
CORE="${CORE:-4}"
MEMORY="${MEMORY:-4096}"
DISK="${DISK:-40}"

echo "Creating Docker VM with:"
echo "  VMID: $VMID"
echo "  Hostname: $HOSTNAME"
echo "  Cores: $CORE"
echo "  Memory: $MEMORY MB"
echo "  Disk: $DISK GB"
echo ""

# Create VM using community script
VMID=$VMID HOSTNAME=$HOSTNAME CORE=$CORE MEMORY=$MEMORY DISK=$DISK \
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/docker-vm.sh)"

# After VM creation and initial boot wait
echo "Waiting for VM to boot (60 seconds)..."
sleep 60

# Install qemu-guest-agent and fix DNS using qm guest exec
echo "Ensuring qemu-guest-agent is installed and DNS is set..."
qm guest exec $VMID -- bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
qm guest exec $VMID -- bash -c "apt-get update"
qm guest exec $VMID -- bash -c "apt-get install -y qemu-guest-agent"

# Optionally, restart the agent
qm guest exec $VMID -- systemctl restart qemu-guest-agent

# Try to get VM IP
echo "Detecting VM IP address..."
for i in {1..10}; do
    VM_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | \
        grep -Eo '"ip-address": "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"' | \
        grep -v '127.0.0.1' | \
        head -n1 | \
        cut -d'"' -f4)
    
    if [ -n "$VM_IP" ]; then
        echo "VM IP detected: $VM_IP"
        break
    fi
    
    echo "Attempt $i/10: Waiting for VM network..."
    sleep 10
done

if [ -z "$VM_IP" ]; then
    echo ""
    echo "Could not auto-detect VM IP."
    echo "Please wait for VM to fully boot, then run:"
    echo "  ./scripts/deploy_mcp_to_docker_vm.sh <VM_IP>"
    echo ""
    echo "To find VM IP: qm guest cmd $VMID network-get-interfaces"
    exit 0
fi

# Deploy MCP servers
echo ""
echo "Deploying MCP servers to $VM_IP..."
$(dirname "$0")/deploy_mcp_to_docker_vm.sh "$VM_IP" "$VMID"
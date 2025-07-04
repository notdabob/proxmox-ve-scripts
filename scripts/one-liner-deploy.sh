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

echo ""
echo "Waiting for VM to boot (60 seconds)..."
sleep 60

# Try to get VM IP using QEMU Guest Agent
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

# Generate SSH key if not present
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key for root..."
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# Copy SSH key to VM (default password: proxmox)
echo "Copying SSH key to VM for passwordless access..."
sshpass -p "proxmox" ssh-copy-id -o StrictHostKeyChecking=no root@$VM_IP

# Fix DNS and install qemu-guest-agent, Docker, and Docker Compose inside the VM
echo "Configuring VM $VMID for MCP stack..."

ssh root@$VM_IP "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
ssh root@$VM_IP "apt-get update"
ssh root@$VM_IP "DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-guest-agent docker.io docker-compose"
ssh root@$VM_IP "systemctl enable qemu-guest-agent && systemctl start qemu-guest-agent"

# Create docker-compose.yaml for MCP stack
cat <<EOF > docker-compose.yaml
version: '3'
services:
  context7-mcp:
    image: upstash/context7-mcp:latest
    restart: always
    ports:
      - "7001:7001"
  desktop-commander:
    image: wonderwhyer/desktop-commander:latest
    restart: always
    ports:
      - "7002:7002"
  filesystem-mcp:
    image: yourorg/filesystem-mcp:latest
    restart: always
    ports:
      - "7003:7003"
EOF

# Copy docker-compose.yaml to VM
scp -o StrictHostKeyChecking=no docker-compose.yaml root@$VM_IP:/root/

# Start MCP stack in the VM
ssh root@$VM_IP "cd /root && docker compose up -d"

echo ""
echo "MCP stack deployed and running in VM $VMID at $VM_IP!"
echo "You can now access:"
echo "  Context7 MCP:       http://$VM_IP:7001"
echo "  Desktop Commander:  http://$VM_IP:7002"
echo "  Filesystem MCP:     http://$VM_IP:7003"
echo ""
echo "Deployment complete."
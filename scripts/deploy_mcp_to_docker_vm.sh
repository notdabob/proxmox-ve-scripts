#!/bin/bash
# Deploy MCP servers to a Docker VM created by ProxmoxVE community script

set -e

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <VM_IP> [VM_ID]"
    echo ""
    echo "Deploy MCP servers to a Docker VM"
    echo ""
    echo "Arguments:"
    echo "  VM_IP  - IP address of the Docker VM"
    echo "  VM_ID  - Optional VM ID to auto-detect IP (default: 120)"
    exit 1
fi

VM_IP="$1"
VMID="${2:-120}"

# If VM_IP is "auto", try to detect it
if [ "$VM_IP" = "auto" ]; then
    echo "Auto-detecting VM IP for VMID $VMID..."
    VM_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | \
        grep -Eo '"ip-address": "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"' | \
        grep -v '127.0.0.1' | \
        head -n1 | \
        cut -d'"' -f4)
    
    if [ -z "$VM_IP" ]; then
        echo "Error: Could not detect VM IP. Please specify manually."
        exit 1
    fi
    echo "Detected IP: $VM_IP"
fi

# Default password for ProxmoxVE Docker VM
DEFAULT_PASS="proxmox"

echo "=== Deploying MCP Servers to Docker VM ==="
echo "Target: root@$VM_IP"
echo ""

# Create Docker Compose file for MCP servers
cat << 'EOF' > /tmp/mcp-docker-compose.yml
version: '3.8'

services:
  context7-mcp:
    image: ghcr.io/modelcontextprotocol/servers/sqlite:latest
    container_name: context7-mcp
    restart: unless-stopped
    ports:
      - "7001:3000"
    environment:
      - MCP_SERVER_NAME=context7
    volumes:
      - ./data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  desktop-commander:
    image: mcp/desktop-commander:latest
    container_name: desktop-commander
    restart: unless-stopped
    ports:
      - "7002:7002"
    environment:
      - PORT=7002
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7002/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  filesystem-mcp:
    image: ghcr.io/modelcontextprotocol/servers/filesystem:latest
    container_name: filesystem-mcp
    restart: unless-stopped
    ports:
      - "7003:3000"
    environment:
      - ALLOWED_DIRECTORIES=/data,/workspace
    volumes:
      - ./workspace:/workspace
      - ./data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  default:
    name: mcp-network
EOF

# Create deployment script
cat << 'DEPLOY_SCRIPT' > /tmp/deploy-mcp.sh
#!/bin/bash
set -e

echo "Setting up MCP servers..."

# Create directories
mkdir -p /opt/mcp/{data,workspace}
cd /opt/mcp

# Copy docker-compose file
cat > docker-compose.yml << 'EOF'
$(cat /tmp/mcp-docker-compose.yml)
EOF

# Pull images
echo "Pulling Docker images..."
docker compose pull

# Start services
echo "Starting MCP services..."
docker compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 10

# Show status
echo ""
echo "=== MCP Services Status ==="
docker compose ps
echo ""

# Show endpoints
echo "=== Available MCP Endpoints ==="
ip=$(hostname -I | awk '{print $1}')
echo "Context7 MCP:        http://$ip:7001"
echo "Desktop Commander:   http://$ip:7002"
echo "Filesystem MCP:      http://$ip:7003"
echo ""

# Create helper script
cat > /usr/local/bin/mcp << 'HELPER'
#!/bin/bash
cd /opt/mcp

case "$1" in
    status) docker compose ps ;;
    logs) docker compose logs -f ${2:-} ;;
    restart) docker compose restart ${2:-} ;;
    stop) docker compose stop ${2:-} ;;
    start) docker compose start ${2:-} ;;
    update) docker compose pull && docker compose up -d ;;
    *) echo "Usage: mcp {status|logs|restart|stop|start|update} [service]" ;;
esac
HELPER

chmod +x /usr/local/bin/mcp

echo "Management command installed: 'mcp'"
echo "Example: mcp status"
DEPLOY_SCRIPT

# Copy files to VM
echo "Copying deployment files to VM..."
sshpass -p "$DEFAULT_PASS" scp -o StrictHostKeyChecking=no \
    /tmp/mcp-docker-compose.yml \
    /tmp/deploy-mcp.sh \
    root@$VM_IP:/tmp/

# Execute deployment
echo "Deploying MCP servers..."
sshpass -p "$DEFAULT_PASS" ssh -o StrictHostKeyChecking=no root@$VM_IP \
    "chmod +x /tmp/deploy-mcp.sh && /tmp/deploy-mcp.sh"

# Clean up
rm -f /tmp/mcp-docker-compose.yml /tmp/deploy-mcp.sh

echo ""
echo "=== MCP Deployment Complete! ==="
echo ""
echo "Access your MCP servers at:"
echo "  - Context7 MCP:      http://$VM_IP:7001"
echo "  - Desktop Commander: http://$VM_IP:7002"
echo "  - Filesystem MCP:    http://$VM_IP:7003"
echo ""
echo "SSH access: ssh root@$VM_IP (password: $DEFAULT_PASS)"
echo "Management: ssh root@$VM_IP 'mcp status'"
echo ""
echo "IMPORTANT: Change the default password!"
echo "  ssh root@$VM_IP 'passwd'"
echo ""
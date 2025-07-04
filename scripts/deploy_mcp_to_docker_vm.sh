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
    echo "  VM_ID  - Optional VM ID to auto-detect IP (default: 210)"
    exit 1
fi

VM_IP="$1"
VMID="${2:-210}"

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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if docker-compose.yaml exists
if [ ! -f "$PROJECT_ROOT/docker-compose.yaml" ]; then
    echo "Error: docker-compose.yaml not found at $PROJECT_ROOT/docker-compose.yaml"
    exit 1
fi

# Create deployment script
cat << 'DEPLOY_SCRIPT' > /tmp/deploy-mcp.sh
#!/bin/bash
set -e

echo "Setting up MCP servers..."

# Create directories
mkdir -p /opt/mcp
cd /opt/mcp

# Start services
echo "Starting MCP services..."
docker compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 15

# Show status
echo ""
echo "=== MCP Services Status ==="
docker compose ps
echo ""

# Check health status
echo "=== Health Check Status ==="
for service in context7-mcp desktop-commander filesystem-mcp; do
    if docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null | grep -q "healthy"; then
        echo "$service: ✓ Healthy"
    else
        echo "$service: ⚠ Not healthy yet"
    fi
done
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
    status) 
        docker compose ps
        echo ""
        echo "Health Status:"
        for service in context7-mcp desktop-commander filesystem-mcp; do
            health=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null || echo "unknown")
            echo "  $service: $health"
        done
        ;;
    logs) docker compose logs -f ${2:-} ;;
    restart) docker compose restart ${2:-} ;;
    stop) docker compose stop ${2:-} ;;
    start) docker compose start ${2:-} ;;
    update) docker compose pull && docker compose up -d ;;
    down) docker compose down ;;
    up) docker compose up -d ;;
    *) 
        echo "Usage: mcp {status|logs|restart|stop|start|update|down|up} [service]"
        echo ""
        echo "Commands:"
        echo "  status  - Show service status and health"
        echo "  logs    - Show logs (follow mode)"
        echo "  restart - Restart services"
        echo "  stop    - Stop services"
        echo "  start   - Start services"
        echo "  update  - Pull latest images and restart"
        echo "  down    - Stop and remove containers"
        echo "  up      - Create and start containers"
        ;;
esac
HELPER

chmod +x /usr/local/bin/mcp

echo "Management command installed: 'mcp'"
echo "Example: mcp status"
DEPLOY_SCRIPT

# Copy files to VM
echo "Copying deployment files to VM..."
sshpass -p "$DEFAULT_PASS" scp -o StrictHostKeyChecking=no \
    "$PROJECT_ROOT/docker-compose.yaml" \
    /tmp/deploy-mcp.sh \
    root@$VM_IP:/tmp/

# Move files to correct location and execute deployment
echo "Deploying MCP servers..."
sshpass -p "$DEFAULT_PASS" ssh -o StrictHostKeyChecking=no root@$VM_IP \
    "mkdir -p /opt/mcp && \
     mv /tmp/docker-compose.yaml /opt/mcp/ && \
     chmod +x /tmp/deploy-mcp.sh && \
     /tmp/deploy-mcp.sh"

# Clean up
rm -f /tmp/deploy-mcp.sh

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
#!/bin/bash
# Docker Deployment Module
# This module handles Docker installation and container deployment with host network access

# Install Docker on remote host
# Usage: install_docker <vm_ip> <username>
install_docker() {
    local vm_ip="$1"
    local username="$2"
    
    echo "Installing Docker on VM..."
    
    # Install Docker
    ssh -o StrictHostKeyChecking=no "$username@$vm_ip" << 'EOF'
        # Update system
        sudo apt-get update
        
        # Install prerequisites
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        
        # Enable Docker service
        sudo systemctl enable docker
        sudo systemctl start docker
EOF
    
    if [ $? -eq 0 ]; then
        echo "Docker installed successfully"
        return 0
    else
        echo "Failed to install Docker"
        return 1
    fi
}

# Configure Docker networking for host access
# Usage: configure_docker_network <vm_ip> <username> <host_network>
configure_docker_network() {
    local vm_ip="$1"
    local username="$2"
    local host_network="$3"  # e.g., "192.168.1.0/24"
    
    echo "Configuring Docker network for host access..."
    
    # Create Docker daemon configuration for host network access
    ssh -o StrictHostKeyChecking=no "$username@$vm_ip" << EOF
        # Create Docker daemon config directory
        sudo mkdir -p /etc/docker
        
        # Configure Docker daemon with custom bridge settings
        sudo tee /etc/docker/daemon.json > /dev/null << 'DAEMON_EOF'
{
    "bip": "172.17.0.1/16",
    "fixed-cidr": "172.17.0.0/16",
    "default-address-pools": [
        {
            "base": "172.18.0.0/16",
            "size": 24
        }
    ],
    "dns": ["8.8.8.8", "8.8.4.4"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
DAEMON_EOF
        
        # Create a custom Docker network with host access
        sudo systemctl restart docker
        
        # Create macvlan network for direct host network access
        # This allows containers to get IPs on the host network
        docker network create -d macvlan \
            --subnet=$host_network \
            --gateway=${host_network%.*}.1 \
            -o parent=ens18 \
            host-access 2>/dev/null || true
        
        # Create bridge network for standard container communication
        docker network create mcp-network 2>/dev/null || true
        
        echo "Docker networks created:"
        docker network ls
EOF
    
    return 0
}

# Deploy MCP servers with Docker Compose
# Usage: deploy_mcp_servers <vm_ip> <username> <mcp_servers_array> <host_network>
deploy_mcp_servers() {
    local vm_ip="$1"
    local username="$2"
    local mcp_servers="$3"  # Space-separated list
    local host_network="$4"
    
    echo "Creating Docker Compose configuration for MCP servers..."
    
    # Generate Docker Compose file
    local compose_content="version: '3.8'

networks:
  mcp-network:
    external: true
  host-access:
    external: true

services:"
    
    # Port counter starting at 7001
    local port=7001
    
    # Add each MCP server to compose file
    for server in $mcp_servers; do
        compose_content+="
  $server:
    image: ${server}:latest
    restart: always
    networks:
      - mcp-network
    ports:
      - \"${port}:${port}\"
    environment:
      - PORT=${port}
      - HOST_NETWORK=${host_network}
    labels:
      - \"traefik.enable=false\"
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:${port}/health\"]
      interval: 30s
      timeout: 10s
      retries: 3"
        
        # Special configurations for known MCP servers
        case "$server" in
            "context7-mcp")
                compose_content+="
    image: upstash/context7-mcp:latest"
                ;;
            "desktop-commander")
                compose_content+="
    image: wonderwhyer/desktop-commander:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro"
                ;;
        esac
        
        compose_content+="
"
        ((port++))
    done
    
    # Add Traefik reverse proxy for better routing (optional)
    compose_content+="
  traefik:
    image: traefik:v2.10
    restart: always
    command:
      - \"--api.insecure=true\"
      - \"--providers.docker=true\"
      - \"--providers.docker.exposedbydefault=false\"
      - \"--entrypoints.web.address=:80\"
    ports:
      - \"80:80\"
      - \"8080:8080\"
    networks:
      - mcp-network
      - host-access
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro"
    
    # Deploy the compose file
    echo "$compose_content" | ssh -o StrictHostKeyChecking=no "$username@$vm_ip" "cat > ~/docker-compose.yml"
    
    # Create .env file for environment variables
    ssh -o StrictHostKeyChecking=no "$username@$vm_ip" << EOF
        # Create .env file
        cat > ~/.env << ENV_EOF
HOST_NETWORK=$host_network
COMPOSE_PROJECT_NAME=mcp-servers
ENV_EOF
        
        # Pull images first
        echo "Pulling Docker images..."
        docker compose pull
        
        # Start services
        echo "Starting MCP services..."
        docker compose up -d
        
        # Wait for services to be healthy
        echo "Waiting for services to become healthy..."
        sleep 10
        
        # Show service status
        echo ""
        echo "MCP Services Status:"
        docker compose ps
        echo ""
        echo "Container Network Information:"
        docker compose exec -T context7-mcp ip addr show 2>/dev/null || true
EOF
    
    return 0
}

# Create helper scripts on the VM
# Usage: create_helper_scripts <vm_ip> <username>
create_helper_scripts() {
    local vm_ip="$1"
    local username="$2"
    
    echo "Creating helper scripts on VM..."
    
    ssh -o StrictHostKeyChecking=no "$username@$vm_ip" << 'EOF'
        # Create MCP management script
        cat > ~/mcp-manage.sh << 'SCRIPT_EOF'
#!/bin/bash
# MCP Server Management Script

case "$1" in
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f ${2:-}
        ;;
    restart)
        docker compose restart ${2:-}
        ;;
    stop)
        docker compose stop ${2:-}
        ;;
    start)
        docker compose start ${2:-}
        ;;
    update)
        docker compose pull
        docker compose up -d
        ;;
    *)
        echo "Usage: $0 {status|logs|restart|stop|start|update} [service]"
        exit 1
        ;;
esac
SCRIPT_EOF
        
        chmod +x ~/mcp-manage.sh
        
        # Create network test script
        cat > ~/test-network.sh << 'SCRIPT_EOF'
#!/bin/bash
# Test network connectivity from containers

echo "Testing network connectivity..."

# Test from each container
for container in $(docker compose ps -q); do
    name=$(docker inspect -f '{{.Name}}' $container | sed 's|^/||')
    echo ""
    echo "Testing from $name:"
    
    # Test DNS
    echo -n "  DNS resolution: "
    docker exec $container nslookup google.com &>/dev/null && echo "OK" || echo "FAILED"
    
    # Test internet
    echo -n "  Internet access: "
    docker exec $container ping -c 1 8.8.8.8 &>/dev/null && echo "OK" || echo "FAILED"
    
    # Test host network
    echo -n "  Host network access: "
    docker exec $container ping -c 1 192.168.1.1 &>/dev/null && echo "OK" || echo "FAILED"
done
SCRIPT_EOF
        
        chmod +x ~/test-network.sh
        
        echo "Helper scripts created:"
        echo "  ~/mcp-manage.sh - Manage MCP services"
        echo "  ~/test-network.sh - Test network connectivity"
EOF
    
    return 0
}

# Export functions
export -f install_docker
export -f configure_docker_network
export -f deploy_mcp_servers
export -f create_helper_scripts
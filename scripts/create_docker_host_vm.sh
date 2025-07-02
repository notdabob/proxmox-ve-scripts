#!/bin/bash
# Create Docker Host VM on ProxMox
# This script creates a VM optimized for running Docker containers with host network access

set -e

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/docker-host.conf"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Default configuration
VMID="${VMID:-120}"
VMNAME="${VMNAME:-docker-host}"
VMUSER="${VMUSER:-docker}"
VMPASS="${VMPASS:-changeme}"
HOST_NETWORK="${HOST_NETWORK:-192.168.1.0/24}"
UBUNTU_LTS_VERSION="${UBUNTU_LTS_VERSION:-}"
UBUNTU_PREFER_LATEST="${UBUNTU_PREFER_LATEST:-true}"

# Source modules
source "${SCRIPT_DIR}/modules/proxmox_vm_create.sh"
source "${SCRIPT_DIR}/modules/docker_deploy.sh"

# Source ISO management functions from the original script
source "${SCRIPT_DIR}/proxmox_create_mcp_vm.sh" 2>/dev/null || {
    echo "Warning: Could not source ISO management functions"
}

# Main execution
main() {
    echo "========================================="
    echo "ProxMox Docker Host VM Creation"
    echo "========================================="
    echo ""
    
    # Ensure running as root
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    fi
    
    # Install prerequisites
    if ! command -v sshpass &> /dev/null; then
        echo "Installing sshpass..."
        apt-get update && apt-get install -y sshpass
    fi
    
    # Get Ubuntu ISO
    if [ -z "$UBUNTU_ISO_PATH" ]; then
        # Use ISO management from original script if available
        if command -v get_latest_ubuntu_info &> /dev/null; then
            install_tree_if_needed
            
            # Select Ubuntu version if not specified
            if [ -z "$UBUNTU_LTS_VERSION" ]; then
                UBUNTU_LTS_VERSION=$(select_ubuntu_version)
            fi
            
            # Get latest Ubuntu version info
            ubuntu_info=$(get_latest_ubuntu_info "$UBUNTU_LTS_VERSION" "$UBUNTU_PREFER_LATEST")
            UBUNTU_ISO_URL=$(echo "$ubuntu_info" | cut -d'|' -f1)
            UBUNTU_ISO_NAME=$(echo "$ubuntu_info" | cut -d'|' -f2)
            
            # Discover and select ISO location
            iso_locations=($(discover_iso_locations))
            selected_iso_path=$(select_iso_location "${iso_locations[*]}")
            
            # Download ISO if needed
            download_ubuntu_iso "$selected_iso_path" "$UBUNTU_ISO_URL" "$UBUNTU_ISO_NAME"
            
            # Get storage name
            storage_name=$(get_storage_name_from_path "$selected_iso_path")
            UBUNTU_ISO_PATH="${storage_name}:iso/${UBUNTU_ISO_NAME}"
        else
            echo "Error: Ubuntu ISO path not specified and ISO management not available"
            exit 1
        fi
    fi
    
    echo ""
    echo "Configuration Summary:"
    echo "  VM ID: $VMID"
    echo "  VM Name: $VMNAME"
    echo "  Ubuntu ISO: $UBUNTU_ISO_PATH"
    echo "  Host Network: $HOST_NETWORK"
    echo ""
    read -p "Continue with VM creation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    
    # Create VM
    create_proxmox_vm "$VMID" "$VMNAME" "$UBUNTU_ISO_PATH"
    
    # Start VM for installation
    start_vm_for_install "$VMID" "$VMUSER" "$VMPASS"
    
    # Get VM IP
    VM_IP=$(get_vm_ip "$VMID")
    if [ -z "$VM_IP" ]; then
        echo "Failed to get VM IP address"
        exit 1
    fi
    
    # Configure network for Docker
    configure_vm_network_for_docker "$VMID" "$VM_IP" "$HOST_NETWORK"
    
    # Setup SSH
    setup_ssh_auth "$VM_IP" "$VMUSER" "$VMPASS"
    
    # Install Docker
    install_docker "$VM_IP" "$VMUSER"
    
    # Configure Docker networking
    configure_docker_network "$VM_IP" "$VMUSER" "$HOST_NETWORK"
    
    # Create helper scripts
    create_helper_scripts "$VM_IP" "$VMUSER"
    
    echo ""
    echo "========================================="
    echo "Docker Host VM Created Successfully!"
    echo "========================================="
    echo "VM ID: $VMID"
    echo "VM IP: $VM_IP"
    echo "Username: $VMUSER"
    echo ""
    echo "SSH Access: ssh $VMUSER@$VM_IP"
    echo ""
    echo "Docker is installed and configured with:"
    echo "  - Standard bridge network (mcp-network)"
    echo "  - Host network access capability"
    echo ""
    echo "Helper scripts available on VM:"
    echo "  - ~/mcp-manage.sh - Manage Docker services"
    echo "  - ~/test-network.sh - Test network connectivity"
    echo ""
    echo "To deploy MCP servers, use:"
    echo "  ./scripts/deploy_mcp_servers.sh $VM_IP"
    echo "========================================="
}

# Run main function
main "$@"
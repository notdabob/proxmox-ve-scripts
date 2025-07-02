#!/bin/bash
# ProxMox VM Creation Module
# This module handles the creation and initial configuration of ProxMox VMs

# Default VM configuration
DEFAULT_VM_CONFIG=(
    ["VMID"]="120"
    ["VMNAME"]="docker-host"
    ["VMDISK"]="local-lvm"
    ["VMRAM"]="4096"
    ["VMCORES"]="2"
    ["VMSOCKETS"]="1"
    ["VMDISK_SIZE"]="32G"
    ["BRIDGE"]="vmbr0"
    ["VLAN_TAG"]=""  # Optional VLAN tag
    ["VMNET_MODEL"]="virtio"  # Network adapter model
)

# Create a ProxMox VM with specified configuration
# Usage: create_proxmox_vm <vmid> <vmname> <iso_path> [config_array]
create_proxmox_vm() {
    local vmid="$1"
    local vmname="$2"
    local iso_path="$3"
    shift 3
    
    # Use provided config or defaults
    local -A config
    if [ $# -gt 0 ]; then
        local config_str="$1"
        eval "config=($config_str)"
    else
        # Copy defaults
        for key in "${!DEFAULT_VM_CONFIG[@]}"; do
            config[$key]="${DEFAULT_VM_CONFIG[$key]}"
        done
    fi
    
    # Override with provided values
    config["VMID"]="$vmid"
    config["VMNAME"]="$vmname"
    
    echo "Creating VM $vmid ($vmname)..."
    
    # Build network configuration
    local net_config="${config[VMNET_MODEL]},bridge=${config[BRIDGE]}"
    if [ -n "${config[VLAN_TAG]}" ]; then
        net_config="${net_config},tag=${config[VLAN_TAG]}"
    fi
    
    # Create the VM
    qm create "$vmid" \
        --name "$vmname" \
        --memory "${config[VMRAM]}" \
        --cores "${config[VMCORES]}" \
        --sockets "${config[VMSOCKETS]}" \
        --net0 "$net_config" \
        --ostype l26 \
        --scsihw virtio-scsi-pci \
        --scsi0 "${config[VMDISK]}:${config[VMDISK_SIZE]}" \
        --boot "order=scsi0" \
        --ide2 "$iso_path,media=cdrom" \
        --agent enabled=1
    
    if [ $? -eq 0 ]; then
        echo "VM $vmid created successfully"
        return 0
    else
        echo "Failed to create VM $vmid"
        return 1
    fi
}

# Start VM and wait for installation
# Usage: start_vm_for_install <vmid> <username> <password>
start_vm_for_install() {
    local vmid="$1"
    local username="$2"
    local password="$3"
    
    echo "Starting VM $vmid for installation..."
    qm start "$vmid"
    
    echo ""
    echo "========================================="
    echo "MANUAL INSTALLATION REQUIRED"
    echo "========================================="
    echo "Please complete Ubuntu Server installation with:"
    echo "  Username: $username"
    echo "  Password: $password"
    echo ""
    echo "IMPORTANT: Enable OpenSSH server during installation!"
    echo "========================================="
    echo ""
    read -p "Press Enter after you have completed the installation and shut down the VM..."
    
    # Remove CD-ROM and set boot order
    echo "Configuring VM for normal boot..."
    qm set "$vmid" --ide2 none
    qm set "$vmid" --boot "order=scsi0"
}

# Get VM IP address using QEMU guest agent
# Usage: get_vm_ip <vmid>
get_vm_ip() {
    local vmid="$1"
    local max_attempts=20
    local attempt=1
    
    echo "Starting VM and detecting IP address..."
    qm start "$vmid" 2>/dev/null || true  # Ignore if already started
    
    # Wait for guest agent
    sleep 10
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts: Checking for VM IP..."
        
        local vm_ip=$(qm guest cmd "$vmid" network-get-interfaces 2>/dev/null | \
            grep -Eo '"ip-address": "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"' | \
            grep -v '127.0.0.1' | \
            head -n1 | \
            cut -d'"' -f4)
        
        if [ -n "$vm_ip" ]; then
            echo "VM IP detected: $vm_ip"
            echo "$vm_ip"
            return 0
        fi
        
        sleep 5
        ((attempt++))
    done
    
    echo "Failed to detect VM IP after $max_attempts attempts"
    return 1
}

# Configure VM network for Docker with host network access
# Usage: configure_vm_network_for_docker <vmid> <vm_ip> <host_network>
configure_vm_network_for_docker() {
    local vmid="$1"
    local vm_ip="$2"
    local host_network="$3"  # e.g., "192.168.1.0/24"
    
    echo "Configuring VM network for Docker host access..."
    
    # Extract network information
    local network_base=$(echo "$host_network" | cut -d'/' -f1)
    local network_prefix=$(echo "$host_network" | cut -d'/' -f2)
    
    # Check if VM is already on the host network
    if [[ "$vm_ip" == ${network_base%.*}.* ]]; then
        echo "VM is already on the host network ($host_network)"
        return 0
    fi
    
    echo "Note: VM IP ($vm_ip) is not on host network ($host_network)"
    echo "Docker containers will use bridge networking to access host network"
    
    return 0
}

# Setup SSH key authentication
# Usage: setup_ssh_auth <vm_ip> <username> <password>
setup_ssh_auth() {
    local vm_ip="$1"
    local username="$2"
    local password="$3"
    
    echo "Setting up SSH key authentication..."
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    fi
    
    # Copy SSH key to VM
    echo "Copying SSH key to VM..."
    sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no "$username@$vm_ip"
    
    if [ $? -eq 0 ]; then
        echo "SSH key authentication configured successfully"
        return 0
    else
        echo "Failed to configure SSH key authentication"
        return 1
    fi
}

# Export functions for use by other scripts
export -f create_proxmox_vm
export -f start_vm_for_install
export -f get_vm_ip
export -f configure_vm_network_for_docker
export -f setup_ssh_auth
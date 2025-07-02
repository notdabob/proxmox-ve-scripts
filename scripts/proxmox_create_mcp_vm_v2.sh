#!/bin/bash
# ProxMox MCP VM Creation Script - Version 2
# More robust version with better error handling

set -euo pipefail

# Enable debug mode if DEBUG=1
[[ "${DEBUG:-0}" == "1" ]] && set -x

# --- CONFIGURATION ---
VMID="${VMID:-120}"
VMNAME="${VMNAME:-mcp-server}"
VMDISK="${VMDISK:-local-lvm}"
VMRAM="${VMRAM:-4096}"
VMDISK_SIZE="${VMDISK_SIZE:-32G}"
VMUSER="${VMUSER:-mcpadmin}"
VMPASS="${VMPASS:-changeme}"
BRIDGE="${BRIDGE:-vmbr0}"
MCP_SERVERS=("context7-mcp" "desktop-commander")

# Ubuntu defaults
DEFAULT_UBUNTU_VERSION="22.04"
DEFAULT_UBUNTU_POINT="5"

# --- HELPER FUNCTIONS ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Install tree if needed
install_tree_if_needed() {
    if ! command -v tree &> /dev/null; then
        log "Installing tree command..."
        apt-get update && apt-get install -y tree
    fi
}

# Select Ubuntu version
select_ubuntu_version() {
    local selection
    
    echo "Select Ubuntu LTS Version:" >&2
    echo "1. Ubuntu 24.04 LTS (Noble Numbat)" >&2
    echo "2. Ubuntu 22.04 LTS (Jammy Jellyfish) - Recommended" >&2
    echo "3. Ubuntu 20.04 LTS (Focal Fossa)" >&2
    echo "4. Custom version" >&2
    echo "" >&2
    
    read -p "Select version (1-4) [2]: " selection
    selection=${selection:-2}
    
    case "$selection" in
        1) echo "24.04" ;;
        2) echo "22.04" ;;
        3) echo "20.04" ;;
        4) 
            local custom_version
            read -p "Enter Ubuntu version (e.g., 22.04): " custom_version
            echo "${custom_version:-$DEFAULT_UBUNTU_VERSION}"
            ;;
        *) 
            log "Invalid selection. Using default."
            echo "$DEFAULT_UBUNTU_VERSION"
            ;;
    esac
}

# Get Ubuntu ISO information
get_ubuntu_iso_info() {
    local version="$1"
    local point_release=""
    
    log "Determining Ubuntu $version ISO information..."
    
    # Known stable releases
    case "$version" in
        "20.04") point_release="20.04.6" ;;
        "22.04") point_release="22.04.5" ;;
        "24.04") point_release="24.04.1" ;;
        *) point_release="${version}.1" ;;
    esac
    
    # Try to detect latest if we have internet
    if command -v curl &> /dev/null; then
        local detected=$(curl -s "https://releases.ubuntu.com/${version}/" 2>/dev/null | \
            grep -Eo "ubuntu-${version}\.[0-9]+-live-server-amd64\.iso" | \
            sort -V | tail -n1 | \
            grep -Eo "${version}\.[0-9]+" || echo "")
        
        if [[ -n "$detected" ]]; then
            point_release="$detected"
            log "Detected latest version: $point_release"
        fi
    fi
    
    local iso_name="ubuntu-${point_release}-live-server-amd64.iso"
    local iso_url="https://releases.ubuntu.com/${version}/${iso_name}"
    
    echo "${iso_url}|${iso_name}"
}

# Discover ISO storage locations
discover_iso_locations() {
    log "Discovering ISO storage locations..."
    local locations=()
    
    # Check ProxMox storage configuration
    if [[ -f /etc/pve/storage.cfg ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^dir: ]]; then
                local storage_name="${line#dir: }"
            elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]+ ]]; then
                local path="${line#*path }"
                path="${path%% *}"  # Remove any trailing content
                if [[ -d "$path/template/iso" ]]; then
                    locations+=("$path/template/iso")
                fi
            fi
        done < /etc/pve/storage.cfg
    fi
    
    # Check common mount points
    for mount in /mnt/*; do
        [[ -d "$mount/template/iso" ]] && locations+=("$mount/template/iso")
    done
    
    # Check default location
    [[ -d "/var/lib/vz/template/iso" ]] && locations+=("/var/lib/vz/template/iso")
    
    # Remove duplicates
    local unique_locations=()
    for loc in "${locations[@]}"; do
        local found=0
        for unique in "${unique_locations[@]}"; do
            [[ "$loc" == "$unique" ]] && found=1 && break
        done
        [[ $found -eq 0 ]] && unique_locations+=("$loc")
    done
    
    printf '%s\n' "${unique_locations[@]}"
}

# Select ISO location
select_iso_location() {
    local locations=("$@")
    local count=${#locations[@]}
    
    if [[ $count -eq 0 ]]; then
        log "No ISO locations found. Creating default..."
        mkdir -p /var/lib/vz/template/iso
        echo "/var/lib/vz/template/iso"
        return
    fi
    
    if [[ $count -eq 1 ]]; then
        log "Using ISO location: ${locations[0]}"
        echo "${locations[0]}"
        return
    fi
    
    echo "Multiple ISO storage locations found:" >&2
    for i in "${!locations[@]}"; do
        local num=$((i + 1))
        echo "$num. ${locations[$i]}" >&2
        if command -v tree &> /dev/null; then
            tree -L 1 "${locations[$i]}" 2>/dev/null | head -5 | sed 's/^/   /' >&2
        fi
    done
    
    local selection
    while true; do
        read -p "Select location (1-$count): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le $count ]]; then
            echo "${locations[$((selection-1))]}"
            return
        fi
        echo "Invalid selection. Please try again." >&2
    done
}

# Download ISO
download_iso() {
    local iso_path="$1"
    local iso_url="$2"
    local iso_name="$3"
    local full_path="${iso_path}/${iso_name}"
    
    if [[ -f "$full_path" ]]; then
        log "ISO already exists: $full_path"
        return 0
    fi
    
    log "Downloading ISO from: $iso_url"
    log "Destination: $full_path"
    
    if command -v wget &> /dev/null; then
        wget --progress=bar:force -O "$full_path" "$iso_url" || {
            rm -f "$full_path"
            error "Failed to download ISO"
        }
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$full_path" "$iso_url" || {
            rm -f "$full_path"
            error "Failed to download ISO"
        }
    else
        error "Neither wget nor curl is available"
    fi
    
    chmod 644 "$full_path"
    log "ISO downloaded successfully"
}

# Get ProxMox storage name from path
get_storage_name() {
    local iso_path="$1"
    local base_path="${iso_path%/template/iso}"
    
    if [[ -f /etc/pve/storage.cfg ]]; then
        local storage_name=""
        local current_storage=""
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^([a-zA-Z0-9_-]+): ]]; then
                current_storage="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]+ ]] && [[ -n "$current_storage" ]]; then
                local path="${line#*path }"
                path="${path%% *}"
                if [[ "$path" == "$base_path" ]]; then
                    echo "$current_storage"
                    return
                fi
            fi
        done < /etc/pve/storage.cfg
    fi
    
    echo "local"
}

# --- MAIN SCRIPT ---
main() {
    # Check if running as root
    [[ $EUID -ne 0 ]] && error "This script must be run as root"
    
    log "ProxMox MCP VM Creation Script Starting..."
    
    # Install prerequisites
    install_tree_if_needed
    
    # Select Ubuntu version
    UBUNTU_VERSION=$(select_ubuntu_version)
    log "Selected Ubuntu version: $UBUNTU_VERSION"
    
    # Get ISO information
    iso_info=$(get_ubuntu_iso_info "$UBUNTU_VERSION")
    UBUNTU_ISO_URL=$(echo "$iso_info" | cut -d'|' -f1)
    UBUNTU_ISO_NAME=$(echo "$iso_info" | cut -d'|' -f2)
    
    log "ISO URL: $UBUNTU_ISO_URL"
    log "ISO Name: $UBUNTU_ISO_NAME"
    
    # Discover and select ISO location
    readarray -t iso_locations < <(discover_iso_locations)
    selected_iso_path=$(select_iso_location "${iso_locations[@]}")
    log "Selected ISO path: $selected_iso_path"
    
    # Download ISO if needed
    download_iso "$selected_iso_path" "$UBUNTU_ISO_URL" "$UBUNTU_ISO_NAME"
    
    # Get storage name
    storage_name=$(get_storage_name "$selected_iso_path")
    VMISO="${storage_name}:iso/${UBUNTU_ISO_NAME}"
    log "ProxMox ISO path: $VMISO"
    
    # Create VM
    log "Creating VM $VMID ($VMNAME)..."
    qm create $VMID \
        --name "$VMNAME" \
        --memory "$VMRAM" \
        --net0 "virtio,bridge=$BRIDGE" \
        --cores 2 \
        --sockets 1 \
        --ostype l26 \
        --scsihw virtio-scsi-pci \
        --scsi0 "$VMDISK:$VMDISK_SIZE" \
        --boot "order=scsi0" \
        --ide2 "$VMISO,media=cdrom" \
        --agent enabled=1 || error "Failed to create VM"
    
    log "VM created successfully!"
    
    # Start VM for installation
    log "Starting VM for installation..."
    qm start $VMID
    
    echo ""
    echo "========================================"
    echo "MANUAL INSTALLATION REQUIRED"
    echo "========================================"
    echo "1. Connect to VM console: qm terminal $VMID"
    echo "2. Complete Ubuntu Server installation"
    echo "   Username: $VMUSER"
    echo "   Password: $VMPASS"
    echo "3. Enable OpenSSH server during install"
    echo "4. Shutdown VM after installation"
    echo "========================================"
    echo ""
    
    read -p "Press Enter after installation is complete and VM is shut down..."
    
    # Continue with rest of script...
    log "Continuing with post-installation setup..."
    
    # The rest of the original script would go here
    # (network detection, SSH setup, Docker installation, etc.)
}

# Run main function
main "$@"
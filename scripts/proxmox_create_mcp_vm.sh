#!/bin/bash
set -e

# --- CONFIGURATION ---
VMID=120
VMNAME="mcp-server"
VMDISK="local-lvm"
VMRAM=4096
VMDISK_SIZE=32G
# Ubuntu version configuration
UBUNTU_LTS_VERSION=""        # Leave empty to prompt user, or set to "20.04", "22.04", "24.04"
UBUNTU_PREFER_LATEST=true    # Set to true to auto-detect latest point release
VMUSER="mcpadmin"
VMPASS="changeme"
BRIDGE="vmbr0"
MCP_SERVERS=("context7" "desktop-commander") # Add more MCP server names here

# --- FUNCTIONS ---
install_tree_if_needed() {
    if ! command -v tree &> /dev/null; then
        echo "Installing tree command..."
        apt-get update && apt-get install -y tree
    fi
}

select_ubuntu_version() {
    echo ""
    echo "========================================="
    echo "Select Ubuntu LTS Version:"
    echo "========================================="
    echo "1. Ubuntu 24.04 LTS (Noble Numbat) - Latest LTS"
    echo "2. Ubuntu 22.04 LTS (Jammy Jellyfish) - Recommended"
    echo "3. Ubuntu 20.04 LTS (Focal Fossa)"
    echo "4. Custom version (specify manually)"
    echo "========================================="
    
    while true; do
        read -p "Select version (1-4) [2]: " selection
        selection=${selection:-2}  # Default to option 2
        
        case "$selection" in
            1) echo "24.04"; return ;;
            2) echo "22.04"; return ;;
            3) echo "20.04"; return ;;
            4) 
                read -p "Enter Ubuntu version (e.g., 22.04): " custom_version
                if [ -z "$custom_version" ]; then
                    echo "22.04"  # Default if empty
                else
                    echo "$custom_version"
                fi
                return
                ;;
            *) echo "Invalid selection. Please try again." ;;
        esac
    done
}

get_latest_ubuntu_info() {
    local lts_version="$1"
    local prefer_latest="$2"
    
    echo "Detecting latest Ubuntu ${lts_version} release..." >&2
    
    # Try to fetch the release page to find latest point release
    local release_page_url="https://releases.ubuntu.com/${lts_version}/"
    local latest_point_release=""
    
    if command -v curl &> /dev/null; then
        # Parse the directory listing to find the latest point release
        # Use extended regex instead of Perl regex for better compatibility
        latest_point_release=$(curl -s "$release_page_url" | \
            grep -Eo "ubuntu-${lts_version}\.[0-9]+-live-server-amd64\.iso" | \
            sort -V | tail -n1 | \
            sed -E "s/.*-(${lts_version}\.[0-9]+)-.*/\1/" || echo "")
    elif command -v wget &> /dev/null; then
        latest_point_release=$(wget -qO- "$release_page_url" | \
            grep -Eo "ubuntu-${lts_version}\.[0-9]+-live-server-amd64\.iso" | \
            sort -V | tail -n1 | \
            sed -E "s/.*-(${lts_version}\.[0-9]+)-.*/\1/" || echo "")
    fi
    
    # If we couldn't detect or user prefers specific version
    if [ -z "$latest_point_release" ] || [ "$prefer_latest" != "true" ]; then
        # Use known stable versions as fallback
        case "$lts_version" in
            "20.04") latest_point_release="20.04.6" ;;
            "22.04") latest_point_release="22.04.5" ;;
            "24.04") latest_point_release="24.04.1" ;;
            *) latest_point_release="${lts_version}.1" ;;
        esac
    fi
    
    local iso_name="ubuntu-${latest_point_release}-live-server-amd64.iso"
    local iso_url="https://releases.ubuntu.com/${lts_version}/${iso_name}"
    
    echo "Detected Ubuntu version: ${latest_point_release}" >&2
    echo "$iso_url|$iso_name"
}

discover_iso_locations() {
    echo "Discovering ISO storage locations on ProxMox host..." >&2
    local iso_dirs=()
    
    # Check common ProxMox storage mount points
    for mount_point in /mnt/* /var/lib/vz; do
        if [ -d "$mount_point" ]; then
            # Look for template/iso directories
            while IFS= read -r dir; do
                iso_dirs+=("$dir")
            done < <(find "$mount_point" -type d -path "*/template/iso" 2>/dev/null)
        fi
    done
    
    # Also check ProxMox storage configuration
    if [ -f /etc/pve/storage.cfg ]; then
        while IFS= read -r path; do
            if [ -d "$path/template/iso" ]; then
                iso_dirs+=("$path/template/iso")
            fi
        done < <(grep -E "^\s*path" /etc/pve/storage.cfg | awk '{print $2}')
    fi
    
    # Remove duplicates
    local unique_dirs=()
    for dir in "${iso_dirs[@]}"; do
        if [[ ! " ${unique_dirs[@]} " =~ " ${dir} " ]]; then
            unique_dirs+=("$dir")
        fi
    done
    
    # Output each directory on a separate line
    for dir in "${unique_dirs[@]}"; do
        echo "$dir"
    done
}

select_iso_location() {
    local iso_locations=("$@")
    
    if [ ${#iso_locations[@]} -eq 0 ]; then
        echo "No ISO storage locations found. Creating default location..."
        mkdir -p /var/lib/vz/template/iso
        echo "/var/lib/vz/template/iso"
        return
    fi
    
    if [ ${#iso_locations[@]} -eq 1 ]; then
        echo "Found single ISO storage location: ${iso_locations[0]}"
        # Show contents using tree if available
        if command -v tree &> /dev/null && [ -d "${iso_locations[0]}" ]; then
            echo "Current contents:"
            tree -L 1 "${iso_locations[0]}" | head -20
        fi
        echo "${iso_locations[0]}"
        return
    fi
    
    echo ""
    echo "========================================="
    echo "Multiple ISO storage locations found:"
    echo "========================================="
    
    for i in "${!iso_locations[@]}"; do
        echo ""
        echo "$((i+1)). ${iso_locations[$i]}"
        # Show existing ISOs in each location
        if [ -d "${iso_locations[$i]}" ]; then
            local iso_count=$(find "${iso_locations[$i]}" -name "*.iso" 2>/dev/null | wc -l)
            echo "   Total ISO files: $iso_count"
            
            # Show tree output if available
            if command -v tree &> /dev/null; then
                echo "   Contents:"
                tree -L 1 "${iso_locations[$i]}" 2>/dev/null | head -10 | sed 's/^/   /'
            else
                # Fallback to ls
                echo "   Recent ISOs:"
                ls -1 "${iso_locations[$i]}"/*.iso 2>/dev/null | head -5 | sed 's/^/   - /'
            fi
        fi
    done
    
    echo ""
    echo "========================================="
    
    while true; do
        read -p "Select location (1-${#iso_locations[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#iso_locations[@]} ]; then
            echo "${iso_locations[$((selection-1))]}"
            return
        fi
        echo "Invalid selection. Please try again."
    done
}

download_ubuntu_iso() {
    local iso_path="$1"
    local iso_url="$2"
    local iso_name="$3"
    
    local full_path="${iso_path}/${iso_name}"
    
    if [ -f "$full_path" ]; then
        echo "Ubuntu ISO already exists at: $full_path"
        return 0
    fi
    
    echo "Downloading Ubuntu Server ISO..."
    echo "URL: $iso_url"
    echo "Destination: $full_path"
    
    # Download with progress bar
    if command -v wget &> /dev/null; then
        wget --progress=bar:force -O "$full_path" "$iso_url"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$full_path" "$iso_url"
    else
        echo "Error: Neither wget nor curl is available"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo "ISO downloaded successfully!"
        chmod 644 "$full_path"
        return 0
    else
        echo "Failed to download ISO"
        rm -f "$full_path"
        return 1
    fi
}

get_storage_name_from_path() {
    local iso_path="$1"
    
    # Check ProxMox storage configuration for matching path
    if [ -f /etc/pve/storage.cfg ]; then
        # Extract the base path by removing /template/iso suffix
        local base_path="${iso_path%/template/iso}"
        
        # Parse storage.cfg to find matching storage
        local storage_name=""
        local current_storage=""
        local in_storage_block=0
        
        while IFS= read -r line; do
            # Check if this is a storage definition line
            if [[ "$line" =~ ^([a-zA-Z0-9_-]+):.*$ ]]; then
                current_storage="${BASH_REMATCH[1]}"
                in_storage_block=1
            elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]+(.*) ]] && [ $in_storage_block -eq 1 ]; then
                local config_path="${BASH_REMATCH[1]}"
                # Remove any trailing slashes for comparison
                config_path="${config_path%/}"
                base_path="${base_path%/}"
                
                if [ "$config_path" = "$base_path" ]; then
                    storage_name="$current_storage"
                    break
                fi
            elif [ -z "$line" ]; then
                in_storage_block=0
            fi
        done < /etc/pve/storage.cfg
        
        if [ -n "$storage_name" ]; then
            echo "$storage_name"
            return
        fi
    fi
    
    # Default fallback
    echo "local"
}

# --- MAIN SCRIPT ---

# Ensure running as root on ProxMox host
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Install tree if needed
install_tree_if_needed

# Select Ubuntu version if not specified
if [ -z "$UBUNTU_LTS_VERSION" ]; then
    UBUNTU_LTS_VERSION=$(select_ubuntu_version)
fi

# Get latest Ubuntu version info
ubuntu_info=$(get_latest_ubuntu_info "$UBUNTU_LTS_VERSION" "$UBUNTU_PREFER_LATEST")
UBUNTU_ISO_URL=$(echo "$ubuntu_info" | cut -d'|' -f1)
UBUNTU_ISO_NAME=$(echo "$ubuntu_info" | cut -d'|' -f2)

echo "Using Ubuntu ISO: $UBUNTU_ISO_NAME"

# Discover ISO locations
echo "Scanning for ISO storage locations..."
readarray -t iso_locations < <(discover_iso_locations)

# Let user select ISO location
selected_iso_path=$(select_iso_location "${iso_locations[@]}")
echo "Selected ISO storage path: $selected_iso_path"

# Download Ubuntu ISO if needed
download_ubuntu_iso "$selected_iso_path" "$UBUNTU_ISO_URL" "$UBUNTU_ISO_NAME"

# Get ProxMox storage name from path
storage_name=$(get_storage_name_from_path "$selected_iso_path")
echo "Using ProxMox storage: $storage_name"

# Update VMISO path for qm command
VMISO="${storage_name}:iso/${UBUNTU_ISO_NAME}"

echo "Creating VM $VMID ($VMNAME)..."
qm create $VMID --name $VMNAME --memory $VMRAM --net0 virtio,bridge=$BRIDGE --cores 2 --sockets 1 --ostype l26 --scsihw virtio-scsi-pci --scsi0 $VMDISK:$VMDISK_SIZE --boot order=scsi0 --ide2 $VMISO,media=cdrom --agent enabled=1

echo "Starting VM for installation. Please complete Ubuntu Server install (user: $VMUSER, pass: $VMPASS), then shut down VM."
qm start $VMID
read -p "Press Enter after you have completed the Ubuntu installation and shut down the VM..."

echo "Setting VM to boot from disk..."
qm set $VMID --boot order=scsi0

echo "Starting VM..."
qm start $VMID
sleep 30

echo "Fetching VM IP address..."
VMIP=""
for i in {1..10}; do
  VMIP=$(qm guest cmd $VMID network-get-interfaces | grep -Eo '\"ip-address\": \"([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\"' | grep -v '127.0.0.1' | head -n1 | cut -d'"' -f4)
  [ -n "$VMIP" ] && break
  sleep 10
done

if [ -z "$VMIP" ]; then
  echo "Failed to detect VM IP. Please check manually."
  exit 1
fi

echo "VM IP detected: $VMIP"

echo "Setting up SSH key authentication..."
# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# Copy SSH key to new VM (uses password once)
echo "Copying SSH key to VM..."
sshpass -p "$VMPASS" ssh-copy-id -o StrictHostKeyChecking=no "$VMUSER@$VMIP"

echo "Installing Docker and Docker Compose on VM..."
ssh -o StrictHostKeyChecking=no $VMUSER@$VMIP "curl -fsSL https://get.docker.com | sh"
ssh $VMUSER@$VMIP "sudo usermod -aG docker $VMUSER"

echo "Creating Docker Compose file for MCP servers..."
cat <<EOF > docker-compose.yml
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
  # Add more MCP servers here...
EOF

scp -o StrictHostKeyChecking=no docker-compose.yml $VMUSER@$VMIP:/home/$VMUSER/
ssh $VMUSER@$VMIP "cd /home/$VMUSER && docker compose up -d"

echo "All MCP servers deployed!"
echo "VM IP: $VMIP"
echo "You can now connect your clients to the following endpoints:"
echo "  Context7 MCP: http://$VMIP:7001"
echo "  Desktop Commander: http://$VMIP:7002"
echo "Remember to change the default password for $VMUSER after first login."

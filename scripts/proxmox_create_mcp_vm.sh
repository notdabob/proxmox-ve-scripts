#!/bin/bash
set -e

# --- CONFIGURATION ---
VMID=120
VMNAME="mcp-server"
VMDISK="local-lvm"
VMRAM=4096
VMDISK_SIZE=32G
UBUNTU_ISO_URL="https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso"
UBUNTU_ISO_NAME="ubuntu-22.04.5-live-server-amd64.iso"
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

discover_iso_locations() {
    echo "Discovering ISO storage locations on ProxMox host..."
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
    
    echo "${unique_dirs[@]}"
}

select_iso_location() {
    local iso_locations=($1)
    
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

# Discover ISO locations
echo "Scanning for ISO storage locations..."
iso_locations=($(discover_iso_locations))

# Let user select ISO location
selected_iso_path=$(select_iso_location "${iso_locations[*]}")
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

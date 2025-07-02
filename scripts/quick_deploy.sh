#!/bin/bash
# Quick Deploy Script - Simplified MCP VM creation for ProxMox
# This is a more robust, simplified version

set -e

# Configuration
VMID=120
VMNAME="mcp-server"
ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
ISO_NAME="ubuntu-22.04.5-live-server-amd64.iso"

echo "=== ProxMox MCP VM Quick Deploy ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root"
    exit 1
fi

# Find ISO storage location
echo "Finding ISO storage location..."
ISO_DIR=""

# Check common locations
for dir in /var/lib/vz/template/iso /mnt/*/template/iso; do
    if [ -d "$dir" ]; then
        echo "Found: $dir"
        ISO_DIR="$dir"
        break
    fi
done

if [ -z "$ISO_DIR" ]; then
    echo "Creating default ISO directory..."
    ISO_DIR="/var/lib/vz/template/iso"
    mkdir -p "$ISO_DIR"
fi

echo "Using ISO directory: $ISO_DIR"

# Download ISO if needed
ISO_PATH="$ISO_DIR/$ISO_NAME"
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Ubuntu ISO..."
    echo "This may take a few minutes..."
    
    if command -v wget >/dev/null 2>&1; then
        wget -O "$ISO_PATH" "$ISO_URL" || exit 1
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$ISO_PATH" "$ISO_URL" || exit 1
    else
        echo "ERROR: Neither wget nor curl found"
        exit 1
    fi
else
    echo "ISO already exists: $ISO_PATH"
fi

# Determine storage name
STORAGE="local"
if [ "$ISO_DIR" != "/var/lib/vz/template/iso" ]; then
    # Try to find the storage name from path
    if grep -q "$ISO_DIR" /etc/pve/storage.cfg 2>/dev/null; then
        STORAGE=$(grep -B5 "$ISO_DIR" /etc/pve/storage.cfg | grep "^[a-zA-Z]" | tail -1 | cut -d: -f1)
    fi
fi

echo "Using storage: $STORAGE"

# Create VM
echo ""
echo "Creating VM $VMID ($VMNAME)..."
qm create $VMID \
    --name "$VMNAME" \
    --memory 4096 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --scsi0 local-lvm:32 \
    --ide2 "$STORAGE:iso/$ISO_NAME,media=cdrom" \
    --boot order=scsi0 \
    --ostype l26 \
    --agent 1

echo ""
echo "=== VM Created Successfully! ==="
echo ""
echo "Next steps:"
echo "1. Start the VM: qm start $VMID"
echo "2. Open console: qm terminal $VMID"
echo "3. Install Ubuntu Server"
echo "4. After installation, run the MCP deployment script"
echo ""
echo "VM ID: $VMID"
echo "VM Name: $VMNAME"
echo ""
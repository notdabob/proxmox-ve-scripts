#!/bin/bash
set -e

# --- CONFIGURATION ---
VMID=120
VMNAME="mcp-server"
VMDISK="local-lvm"
VMRAM=4096
VMDISK_SIZE=32G
VMISO="local:iso/ubuntu-22.04.4-live-server-amd64.iso"
VMUSER="mcpadmin"
VMPASS="changeme"
BRIDGE="vmbr0"
MCP_SERVERS=("context7" "desktop-commander") # Add more MCP server names here

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

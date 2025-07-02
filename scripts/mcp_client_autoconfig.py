import os
import json
import socket
import requests

# --- CONFIGURATION ---
VM_HOSTNAME = "mcp-server"
MCP_PORTS = {
    "context7": 7001,
    "desktop-commander": 7002,
    # Add more here...
}
CLAUDE_CONFIG_PATH = os.path.expanduser("~/Library/Application Support/Claude/claude_desktop_config.json")
PERPLEXITY_CONFIG_PATH = os.path.expanduser("~/.perplexity/mcp.json")
MCP_SUPERASSISTANT_CONFIG_PATH = os.path.expanduser("~/mcpconfig.json")

def get_vm_ip():
    # Try to resolve by hostname first
    try:
        return socket.gethostbyname(VM_HOSTNAME)
    except Exception:
        pass
    # Fallback: scan subnet for open MCP ports
    import ipaddress
    import subprocess
    subnet = ".".join(socket.gethostbyname(socket.gethostname()).split('.')[:3]) + "."
    for i in range(2, 255):
        ip = subnet + str(i)
        for port in MCP_PORTS.values():
            try:
                sock = socket.create_connection((ip, port), timeout=0.5)
                sock.close()
                return ip
            except Exception:
                continue
    return None

def update_config(path, mcp_servers):
    if os.path.exists(path):
        with open(path, "r") as f:
            config = json.load(f)
    else:
        config = {}
    config["mcpServers"] = mcp_servers
    with open(path, "w") as f:
        json.dump(config, f, indent=2)
    print(f"Updated {path}")

def main():
    print("Detecting MCP VM on network...")
    vm_ip = get_vm_ip()
    if not vm_ip:
        print("Could not auto-detect MCP VM. Please enter the IP manually:")
        vm_ip = input("VM IP: ").strip()
    print(f"Detected MCP VM at {vm_ip}")

    mcp_servers = {}
    for name, port in MCP_PORTS.items():
        # Optionally, check if the server is alive
        try:
            r = requests.get(f"http://{vm_ip}:{port}/health", timeout=1)
            if r.status_code == 200:
                print(f"{name} MCP detected on port {port}")
        except Exception:
            print(f"Warning: {name} MCP not detected on port {port}")
        mcp_servers[name] = {
            "type": "http",
            "url": f"http://{vm_ip}:{port}/"
        }

    # Update Claude Desktop config
    update_config(CLAUDE_CONFIG_PATH, mcp_servers)
    # Update Perplexity config
    update_config(PERPLEXITY_CONFIG_PATH, mcp_servers)
    # Update MCP SuperAssistant config
    update_config(MCP_SUPERASSISTANT_CONFIG_PATH, mcp_servers)

    print("All configs updated! Restart Claude Desktop, Perplexity, and reload your browser for ChatGPT MCP SuperAssistant.")

if __name__ == "__main__":
    main()

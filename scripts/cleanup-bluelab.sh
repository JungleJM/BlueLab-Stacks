#!/bin/bash

# BlueLab Cleanup Script
# Removes only BlueLab components, preserves Docker and Distrobox

echo "🧹 BlueLab Cleanup Script"
echo "========================"
echo "This will remove BlueLab components but keep Docker and Distrobox"
echo ""

# Stop BlueLab containers
echo "🛑 Stopping BlueLab containers..."
docker stop $(docker ps -a --filter "name=bluelab" --format "{{.ID}}") 2>/dev/null || true

# Remove BlueLab containers
echo "🗑️  Removing BlueLab containers..."
docker rm $(docker ps -a --filter "name=bluelab" --format "{{.ID}}") 2>/dev/null || true

# Remove BlueLab Distrobox container
echo "📦 Removing BlueLab Distrobox container..."
distrobox rm bluelab -f 2>/dev/null || true

# Remove BlueLab data directory
echo "📁 Removing BlueLab data directory..."
sudo rm -rf /var/lib/bluelab 2>/dev/null || true

# Remove BlueLab SSH key (only the specific one)
echo "🔑 Removing BlueLab SSH key..."
if [ -f ~/.ssh/authorized_keys ]; then
    # Remove only the BlueLab test key, preserve other keys
    grep -v "bluelab-test-vm" ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp 2>/dev/null || true
    mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys 2>/dev/null || true
    # Only remove authorized_keys if it's empty now
    if [ ! -s ~/.ssh/authorized_keys ]; then
        rm -f ~/.ssh/authorized_keys
    fi
fi

# Remove BlueLab SSH config additions (only our additions)
echo "⚙️  Removing BlueLab SSH configuration..."
if [ -f /etc/ssh/sshd_config ]; then
    sudo sed -i '/# BlueLab SSH Configuration/,$d' /etc/ssh/sshd_config 2>/dev/null || true
fi

# Remove installation logs
echo "📋 Removing installation logs..."
rm -f /tmp/bluelab-install.log 2>/dev/null || true

# Remove BlueLab network (if it exists)
echo "🌐 Removing BlueLab Docker network..."
docker network rm bluelab-network 2>/dev/null || true

# Clean up any BlueLab images (optional)
echo "🖼️  Removing BlueLab Docker images..."
docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(bluelab|linuxserver)" | awk '{print $1}' | xargs docker rmi -f 2>/dev/null || true

echo ""
echo "✅ BlueLab cleanup complete!"
echo ""
echo "🔍 What was preserved:"
echo "  • Docker engine and other containers"
echo "  • Distrobox and other containers" 
echo "  • SSH server and other SSH keys"
echo "  • System packages and configuration"
echo ""
echo "🗑️  What was removed:"
echo "  • BlueLab containers and data (/var/lib/bluelab)"
echo "  • BlueLab Distrobox container"
echo "  • BlueLab SSH test key"
echo "  • BlueLab installation logs"
echo "  • BlueLab Docker network and images"
echo ""

# Show remaining containers to verify
if command -v docker >/dev/null 2>&1; then
    echo "📦 Remaining Docker containers:"
    docker ps -a || echo "  (None or Docker not accessible)"
    echo ""
fi

if command -v distrobox >/dev/null 2>&1; then
    echo "📦 Remaining Distrobox containers:"
    distrobox list || echo "  (None)"
    echo ""
fi

echo "🎯 System restored - BlueLab components removed!"
#!/bin/bash

# Simple SSH Enable Script
# Just enables password authentication for easy access

echo "🔑 Simple SSH Setup"
echo "=================="
echo ""

# Install SSH if not present
echo "📦 Installing SSH server..."
if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y openssh-server
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y openssh-server
fi

# Enable password authentication
echo "🔓 Enabling password authentication..."
sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set a simple password for current user
echo "🔐 Setting password for user: $(whoami)"
echo "Please set a simple password (like 'test123'):"
sudo passwd $(whoami)

# Start SSH service
echo "🚀 Starting SSH service..."
sudo systemctl enable sshd
sudo systemctl start sshd

# Show connection info
echo ""
echo "✅ SSH Setup Complete!"
echo "====================="
echo ""
echo "You can now connect with:"
echo "  ssh $(whoami)@$(hostname -I | awk '{print $1}')"
echo ""
echo "SSH service status:"
sudo systemctl status sshd --no-pager -l | head -5
echo ""
echo "SSH is listening on port 22:"
sudo ss -tlnp | grep :22
echo ""
echo "🎯 Ready for remote connection!"
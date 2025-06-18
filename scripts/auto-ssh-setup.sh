#!/bin/bash

# BlueLab Auto SSH Setup - Run this on the VM
# This script automatically sets up SSH without manual key copying

echo "🔧 BlueLab Auto SSH Setup"
echo "========================="
echo ""

# Install SSH server
echo "📦 Installing SSH server..."
if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y openssh-server
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y openssh-server
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y openssh-server
else
    echo "❌ Could not detect package manager"
    exit 1
fi

# Enable and start SSH
echo "🚀 Starting SSH service..."
sudo systemctl enable sshd
sudo systemctl start sshd

# Create .ssh directory
echo "🔑 Setting up SSH keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Download and add the public key directly from GitHub
echo "📥 Downloading SSH public key..."
curl -sSL "https://raw.githubusercontent.com/JungleJM/BlueLab-Stacks/main/.github/ssh-keys/bluelab_test.pub" >> ~/.ssh/authorized_keys 2>/dev/null || {
    echo "📝 Adding SSH key manually..."
    cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN17N5opCHt02yVVKnja9wFnFGgK4tgyCeBkUcuBsyOP bluelab-test-vm
EOF
}

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys

# Configure SSH for better security
echo "🔒 Configuring SSH..."
sudo tee -a /etc/ssh/sshd_config > /dev/null << 'EOF'

# BlueLab SSH Configuration
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication yes
PermitRootLogin no
EOF

# Restart SSH to apply config
sudo systemctl restart sshd

# Show status
echo ""
echo "✅ SSH Setup Complete!"
echo "====================="
echo ""
echo "SSH Service Status:"
sudo systemctl status sshd --no-pager -l

echo ""
echo "SSH is listening on:"
sudo ss -tlnp | grep :22

echo ""
echo "🎯 You can now connect from your host machine with:"
echo "   ssh j@$(hostname -I | awk '{print $1}')"
echo ""
echo "🚀 Ready to start BlueLab installation!"
echo "   curl -sSL https://raw.githubusercontent.com/JungleJM/BlueLab-Stacks/main/install.sh | bash"
#!/bin/bash

# Script to set up SSH access on test VM
# Run this on the VM (192.168.50.113)

echo "Setting up SSH access for BlueLab testing..."

# Ensure SSH is installed and running
sudo systemctl enable ssh
sudo systemctl start ssh

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key to authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN17N5opCHt02yVVKnja9wFnFGgK4tgyCeBkUcuBsyOP bluelab-test-vm" >> ~/.ssh/authorized_keys

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys

# Show SSH status
echo "SSH service status:"
sudo systemctl status ssh --no-pager

echo ""
echo "SSH setup complete! You can now connect with:"
echo "ssh -i ~/.ssh/bluelab_test $(whoami)@192.168.50.113"
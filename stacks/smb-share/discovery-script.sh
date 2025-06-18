#!/bin/sh

# SMB Discovery Helper Script
# Helps with network discovery and provides connection information

echo "BlueLab SMB Discovery Service Starting..."

# Install required packages
apk add --no-cache samba-client curl

# Function to get local IP
get_local_ip() {
    hostname -i | awk '{print $1}'
}

# Function to get Tailscale IP (if available)
get_tailscale_ip() {
    # This would be populated by the main installer
    echo "${TAILSCALE_IP:-$(get_local_ip)}"
}

# Main discovery loop
while true; do
    LOCAL_IP=$(get_local_ip)
    TAILSCALE_IP=$(get_tailscale_ip)
    
    echo "$(date): SMB Shares Available:"
    echo "  Local Network: //$LOCAL_IP/bluelab"
    echo "  Tailscale: //$TAILSCALE_IP/bluelab"
    echo ""
    echo "Available Shares:"
    echo "  bluelab - Main data directory"
    echo "  media - Movies and TV shows"
    echo "  downloads - Download directory"
    echo "  photos - Photo storage"
    echo "  music - Music library"
    echo "  books - Book library"
    echo "  documents - Document storage"
    echo ""
    echo "Default Credentials:"
    echo "  Username: ${SMB_USER:-bluelab}"
    echo "  Password: ${SMB_PASSWORD:-bluelab123}"
    echo ""
    
    # Sleep for 1 hour before next announcement
    sleep 3600
done
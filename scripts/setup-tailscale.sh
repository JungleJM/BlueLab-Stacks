#!/bin/bash

# BlueLab Stacks - Tailscale Setup Helper
# Run this after Phase 1 installation to configure Tailscale

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DATA_DIR="/var/lib/bluelab"
CONTAINER_NAME="bluelab"

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $*"
}

setup_tailscale() {
    log "Setting up Tailscale integration..."
    
    # Check if container exists
    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "BlueLab container not found. Please run install.sh first."
        exit 1
    fi
    
    # Install Tailscale in container if not already installed
    log "Installing Tailscale in container..."
    distrobox enter "$CONTAINER_NAME" -- bash -c "
        if ! command -v tailscale &> /dev/null; then
            curl -fsSL https://tailscale.com/install.sh | sh
        fi
    "
    
    # Get auth URL
    log "Getting Tailscale authentication URL..."
    
    echo ""
    echo "=============================================="
    echo "🔗 Tailscale Setup Required"
    echo "=============================================="
    echo ""
    echo "1. Visit the Tailscale admin console:"
    echo "   https://login.tailscale.com/admin/settings/keys"
    echo ""
    echo "2. Generate an auth key with these settings:"
    echo "   - ✓ Reusable"
    echo "   - ✓ Ephemeral (optional)"
    echo "   - ✓ Pre-approved (optional)"
    echo ""
    echo "3. Copy the auth key and paste it below:"
    echo ""
    
    read -p "Enter your Tailscale auth key: " auth_key
    
    if [[ -z "$auth_key" ]]; then
        log_error "Auth key cannot be empty"
        exit 1
    fi
    
    # Connect to Tailscale
    log "Connecting to Tailscale..."
    distrobox enter "$CONTAINER_NAME" -- tailscale up --authkey="$auth_key" --hostname="${DOMAIN_PREFIX:-homelab}-server"
    
    # Get Tailscale IP
    log "Getting Tailscale IP address..."
    sleep 5
    
    local tailscale_ip
    tailscale_ip=$(distrobox enter "$CONTAINER_NAME" -- tailscale ip -4)
    
    if [[ -n "$tailscale_ip" ]]; then
        log_success "Tailscale connected successfully!"
        log "Tailscale IP: $tailscale_ip"
        
        # Update global.env with Tailscale IP
        if [[ -f "$DATA_DIR/config/global.env" ]]; then
            if grep -q "TAILSCALE_IP=" "$DATA_DIR/config/global.env"; then
                sed -i "s/TAILSCALE_IP=.*/TAILSCALE_IP=$tailscale_ip/" "$DATA_DIR/config/global.env"
            else
                echo "TAILSCALE_IP=$tailscale_ip" >> "$DATA_DIR/config/global.env"
            fi
            log_success "Updated configuration with Tailscale IP"
        fi
        
        # Update AdGuard DNS configuration
        update_dns_configuration "$tailscale_ip"
        
    else
        log_error "Failed to get Tailscale IP address"
        exit 1
    fi
}

update_dns_configuration() {
    local tailscale_ip=$1
    local domain_prefix
    
    # Get domain prefix from config
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        domain_prefix=$(grep "DOMAIN_PREFIX=" "$DATA_DIR/config/global.env" | cut -d'=' -f2)
    else
        domain_prefix="homelab"
    fi
    
    log "Updating DNS configuration..."
    
    # Update AdGuard configuration with real IPs
    local adguard_config="$DATA_DIR/stacks/core-networking/config/adguard.yaml"
    if [[ -f "$adguard_config" ]]; then
        # Replace placeholder with actual Tailscale IP
        sed -i "s/HOST_IP_PLACEHOLDER/$tailscale_ip/g" "$adguard_config"
        sed -i "s/\${DOMAIN_PREFIX}/$domain_prefix/g" "$adguard_config"
        
        # Restart AdGuard to apply changes
        distrobox enter "$CONTAINER_NAME" -- bash -c "
            cd $DATA_DIR/stacks/core-networking
            docker compose restart adguard
        "
        
        log_success "DNS configuration updated"
    fi
}

show_access_info() {
    local tailscale_ip
    local domain_prefix
    
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        tailscale_ip=$(grep "TAILSCALE_IP=" "$DATA_DIR/config/global.env" | cut -d'=' -f2)
        domain_prefix=$(grep "DOMAIN_PREFIX=" "$DATA_DIR/config/global.env" | cut -d'=' -f2)
    fi
    
    echo ""
    echo "=============================================="
    echo "🌐 Tailscale Setup Complete!"
    echo "=============================================="
    echo ""
    echo "Your services are now accessible remotely:"
    echo ""
    echo "📊 Main Dashboard:"
    echo "  Local: http://localhost:3000"
    echo "  Remote: http://${tailscale_ip}:3000"
    echo ""
    echo "🌍 Custom Domains (configure in AdGuard):"
    echo "  ${domain_prefix}.local → ${tailscale_ip}"
    echo "  ${domain_prefix}.movies → ${tailscale_ip}:7878 (when Phase 2 installed)"
    echo "  ${domain_prefix}.tv → ${tailscale_ip}:8989 (when Phase 2 installed)"
    echo ""
    echo "🔧 Next Steps:"
    echo "1. Access AdGuard Home: http://${tailscale_ip}:3001"
    echo "2. Complete initial setup (username: admin, set password)"
    echo "3. DNS rewrites are pre-configured for ${domain_prefix}.* domains"
    echo "4. Install Phase 2 for media services"
    echo ""
}

setup_vpn_configuration() {
    echo ""
    echo "=============================================="
    echo "🔒 VPN Configuration"
    echo "=============================================="
    echo ""
    echo "Would you like to set up a VPN for your entire system?"
    echo "This will work alongside Tailscale using split tunneling."
    echo ""
    echo "Options:"
    echo "1) Set up later (skip for now)"
    echo "2) Get a free VPN (ProtonVPN recommended)"
    echo "3) Get a paid VPN (AirVPN recommended)"
    echo "4) I have a WireGuard config file"
    echo ""
    
    read -p "Choose an option (1-4): " vpn_choice
    
    case $vpn_choice in
        1)
            log "VPN setup skipped - you can configure it later"
            ;;
        2)
            show_free_vpn_info
            ;;
        3)
            show_paid_vpn_info
            ;;
        4)
            setup_wireguard_config
            ;;
        *)
            log_warning "Invalid choice, skipping VPN setup"
            ;;
    esac
}

show_free_vpn_info() {
    echo ""
    echo "=============================================="
    echo "🆓 Free VPN Recommendation: ProtonVPN"
    echo "=============================================="
    echo ""
    echo "ProtonVPN offers a reliable free tier with:"
    echo "• No data limits"
    echo "• Strong privacy protection"
    echo "• WireGuard support"
    echo ""
    echo "To set up ProtonVPN:"
    echo "1. Visit: https://account.protonvpn.com/signup"
    echo "2. Create a free account"
    echo "3. Download WireGuard configuration:"
    echo "   • Log in to your account"
    echo "   • Go to Downloads"
    echo "   • Select 'WireGuard configuration'"
    echo "   • Choose a free server location"
    echo "   • Download the .conf file"
    echo ""
    echo "4. Run this script again and choose option 4 to upload the config"
    echo ""
    read -p "Press Enter to continue..."
}

show_paid_vpn_info() {
    echo ""
    echo "=============================================="
    echo "💳 Paid VPN Recommendation: AirVPN"
    echo "=============================================="
    echo ""
    echo "AirVPN offers excellent privacy and performance:"
    echo "• Strong encryption and privacy policies"
    echo "• WireGuard and OpenVPN support"
    echo "• Port forwarding capabilities"
    echo "• Starting at €4.50/month"
    echo ""
    echo "To set up AirVPN:"
    echo "1. Visit: https://airvpn.org"
    echo "2. Create an account and subscribe"
    echo "3. Generate WireGuard configuration:"
    echo "   • Log in to Client Area"
    echo "   • Go to 'Config Generator'"
    echo "   • Select 'WireGuard'"
    echo "   • Choose your preferred server"
    echo "   • Download the .conf file"
    echo ""
    echo "4. Run this script again and choose option 4 to upload the config"
    echo ""
    read -p "Press Enter to continue..."
}

setup_wireguard_config() {
    echo ""
    echo "=============================================="
    echo "📁 WireGuard Configuration Setup"
    echo "=============================================="
    echo ""
    echo "Please paste your WireGuard configuration below."
    echo "This should be the entire contents of your .conf file."
    echo "Press Ctrl+D when finished, or type 'DONE' on a new line:"
    echo ""
    
    local config_content=""
    local line
    
    while IFS= read -r line; do
        if [[ "$line" == "DONE" ]]; then
            break
        fi
        config_content+="$line"$'\n'
    done
    
    if [[ -z "$config_content" ]]; then
        log_warning "No configuration provided, skipping VPN setup"
        return
    fi
    
    # Validate WireGuard config
    if ! echo "$config_content" | grep -q "\[Interface\]" || ! echo "$config_content" | grep -q "\[Peer\]"; then
        log_error "Invalid WireGuard configuration format"
        return
    fi
    
    log "Installing WireGuard and setting up configuration..."
    
    # Install WireGuard in container
    distrobox enter "$CONTAINER_NAME" -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y wireguard-tools resolvconf
    "
    
    # Create WireGuard config directory
    sudo mkdir -p /etc/wireguard
    
    # Save configuration with split tunneling setup
    local wg_config="/etc/wireguard/wg0.conf"
    
    # Create modified config with split tunneling
    create_split_tunnel_config "$config_content" "$wg_config"
    
    # Set proper permissions
    sudo chmod 600 "$wg_config"
    
    # Start WireGuard
    log "Starting WireGuard VPN..."
    if sudo wg-quick up wg0; then
        log_success "WireGuard VPN connected successfully!"
        
        # Enable auto-start
        sudo systemctl enable wg-quick@wg0
        
        show_vpn_status
    else
        log_error "Failed to start WireGuard VPN"
    fi
}

create_split_tunnel_config() {
    local original_config="$1"
    local output_file="$2"
    local tailscale_ip
    
    # Get Tailscale IP from config
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        tailscale_ip=$(grep "TAILSCALE_IP=" "$DATA_DIR/config/global.env" | cut -d'=' -f2)
    fi
    
    log "Creating split tunnel configuration..."
    
    # Extract interface section
    local interface_section
    interface_section=$(echo "$original_config" | sed -n '/\[Interface\]/,/\[Peer\]/p' | head -n -1)
    
    # Extract peer section  
    local peer_section
    peer_section=$(echo "$original_config" | sed -n '/\[Peer\]/,$p')
    
    # Create new config with split tunneling
    sudo tee "$output_file" > /dev/null << EOF
# BlueLab WireGuard Configuration with Split Tunneling
# This allows both VPN and Tailscale to work together

$interface_section

# Custom routing for split tunneling
PostUp = ip route add 100.64.0.0/10 dev tailscale0 2>/dev/null || true
PostUp = ip route add 192.168.0.0/16 dev tailscale0 2>/dev/null || true
PostUp = ip route add 10.0.0.0/8 dev tailscale0 2>/dev/null || true
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o %i -j MASQUERADE

PostDown = iptables -D FORWARD -i %i -j ACCEPT 2>/dev/null || true
PostDown = iptables -D FORWARD -o %i -j ACCEPT 2>/dev/null || true
PostDown = iptables -t nat -D POSTROUTING -o %i -j MASQUERADE 2>/dev/null || true

$peer_section
EOF
    
    log_success "Split tunnel configuration created"
}

show_vpn_status() {
    echo ""
    echo "=============================================="
    echo "🌐 VPN & Network Status"
    echo "=============================================="
    echo ""
    
    # Show WireGuard status
    local wg_status
    wg_status=$(sudo wg show 2>/dev/null || echo "Not connected")
    
    # Show Tailscale status
    local ts_status
    ts_status=$(distrobox enter "$CONTAINER_NAME" -- tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "Unknown")
    
    # Get IPs
    local public_ip
    public_ip=$(curl -s -4 icanhazip.com 2>/dev/null || echo "Unable to determine")
    
    local tailscale_ip
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        tailscale_ip=$(grep "TAILSCALE_IP=" "$DATA_DIR/config/global.env" | cut -d'=' -f2)
    fi
    
    echo "🔒 VPN Status:"
    if [[ "$wg_status" != "Not connected" ]]; then
        echo "  ✓ WireGuard: Connected"
        echo "  📍 Public IP: $public_ip (via VPN)"
    else
        echo "  ✗ WireGuard: Not connected"
        echo "  📍 Public IP: $public_ip (direct)"
    fi
    
    echo ""
    echo "🌐 Tailscale Status:"
    if [[ "$ts_status" == "Running" ]]; then
        echo "  ✓ Tailscale: Connected"
        echo "  🏠 Tailscale IP: $tailscale_ip"
    else
        echo "  ⚠ Tailscale: $ts_status"
    fi
    
    echo ""
    echo "📋 Network Configuration:"
    echo "  • Internet traffic: Routes through VPN"
    echo "  • Tailscale traffic: Direct connection (split tunnel)"
    echo "  • Local network: Direct connection"
    echo "  • Your services: Accessible via Tailscale IP"
    echo ""
    echo "🔧 Management Commands:"
    echo "  • Check VPN status: sudo wg show"
    echo "  • Stop VPN: sudo wg-quick down wg0"
    echo "  • Start VPN: sudo wg-quick up wg0"
    echo "  • Check Tailscale: distrobox enter $CONTAINER_NAME -- tailscale status"
    echo ""
}

main() {
    log "BlueLab Stacks - Tailscale Setup"
    log "================================"
    
    setup_tailscale
    show_access_info
    
    # After Tailscale is set up, offer VPN configuration
    setup_vpn_configuration
    
    log_success "Tailscale setup completed!"
}

main "$@"
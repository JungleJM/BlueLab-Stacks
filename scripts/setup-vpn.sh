#!/bin/bash

# BlueLab Stacks - VPN Setup Helper
# Standalone script for setting up WireGuard VPN with split tunneling

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

check_requirements() {
    log "Checking VPN setup requirements..."
    
    # Check if running as regular user (not root)
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root (sudo will be used when needed)"
        exit 1
    fi
    
    # Check for required commands
    for cmd in curl sudo; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is required but not installed"
            exit 1
        fi
    done
    
    # Check if BlueLab is set up
    if [[ ! -d "$DATA_DIR" ]]; then
        log_error "BlueLab Stacks not found. Please run install.sh first."
        exit 1
    fi
    
    log_success "Requirements check passed"
}

show_vpn_menu() {
    echo ""
    echo "=============================================="
    echo "🔒 BlueLab VPN Configuration"
    echo "=============================================="
    echo ""
    echo "This script will set up a VPN that works alongside Tailscale"
    echo "using split tunneling for maximum privacy and functionality."
    echo ""
    echo "Options:"
    echo "1) Set up later (exit)"
    echo "2) Get a free VPN (ProtonVPN recommended)"
    echo "3) Get a paid VPN (AirVPN recommended)"
    echo "4) I have a WireGuard config file"
    echo "5) Check current VPN status"
    echo "6) Remove VPN configuration"
    echo ""
    
    read -p "Choose an option (1-6): " vpn_choice
    
    case $vpn_choice in
        1)
            log "VPN setup cancelled"
            exit 0
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
        5)
            show_vpn_status
            ;;
        6)
            remove_vpn_config
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
}

show_free_vpn_info() {
    echo ""
    echo "=============================================="
    echo "🆓 Free VPN: ProtonVPN"
    echo "=============================================="
    echo ""
    echo "ProtonVPN offers a reliable free tier with:"
    echo "• No data limits"
    echo "• Strong privacy protection (based in Switzerland)"
    echo "• WireGuard support"
    echo "• 3 server locations (Japan, Netherlands, US)"
    echo ""
    echo "📋 Setup Steps:"
    echo "1. Visit: https://account.protonvpn.com/signup"
    echo "2. Create a free account (no payment required)"
    echo "3. Verify your email address"
    echo "4. Log in to your ProtonVPN account"
    echo "5. Go to 'Downloads' section"
    echo "6. Select 'WireGuard configuration'"
    echo "7. Choose a free server location"
    echo "8. Download the .conf file"
    echo "9. Run this script again and choose option 4"
    echo ""
    echo "💡 Tip: Keep the downloaded .conf file - you can use it"
    echo "    on multiple devices with the same account."
    echo ""
    read -p "Press Enter to return to main menu..."
    show_vpn_menu
}

show_paid_vpn_info() {
    echo ""
    echo "=============================================="
    echo "💳 Paid VPN: AirVPN"
    echo "=============================================="
    echo ""
    echo "AirVPN offers excellent privacy and performance:"
    echo "• Strong privacy policies (no logs, based in Italy)"
    echo "• WireGuard and OpenVPN support"
    echo "• Port forwarding capabilities"
    echo "• 200+ servers worldwide"
    echo "• Starting at €4.50/month"
    echo ""
    echo "📋 Setup Steps:"
    echo "1. Visit: https://airvpn.org"
    echo "2. Create an account and choose a subscription"
    echo "3. Complete payment"
    echo "4. Log in to Client Area"
    echo "5. Go to 'Config Generator'"
    echo "6. Select 'WireGuard' as protocol"
    echo "7. Choose your preferred server(s)"
    echo "8. Generate and download the .conf file"
    echo "9. Run this script again and choose option 4"
    echo ""
    echo "💡 Alternative paid VPNs that work well:"
    echo "   • Mullvad (€5/month, very privacy-focused)"
    echo "   • IVPN (privacy-focused, supports WireGuard)"
    echo ""
    read -p "Press Enter to return to main menu..."
    show_vpn_menu
}

setup_wireguard_config() {
    echo ""
    echo "=============================================="
    echo "📁 WireGuard Configuration Setup"
    echo "=============================================="
    echo ""
    echo "Please paste your WireGuard configuration below."
    echo "This should be the complete contents of your .conf file."
    echo ""
    echo "💡 Tips:"
    echo "• Copy the entire file content (Ctrl+A, Ctrl+C)"
    echo "• Paste here (Ctrl+Shift+V in most terminals)"
    echo "• Type 'DONE' on a new line when finished"
    echo "• Press Ctrl+C to cancel"
    echo ""
    echo "Paste configuration:"
    
    local config_content=""
    local line
    
    while IFS= read -r line; do
        if [[ "$line" == "DONE" ]]; then
            break
        fi
        config_content+="$line"$'\n'
    done
    
    if [[ -z "$config_content" ]]; then
        log_warning "No configuration provided"
        read -p "Return to main menu? (y/n): " return_menu
        if [[ "$return_menu" =~ ^[Yy]$ ]]; then
            show_vpn_menu
        else
            exit 0
        fi
        return
    fi
    
    # Validate WireGuard config
    log "Validating WireGuard configuration..."
    
    if ! echo "$config_content" | grep -q "\[Interface\]"; then
        log_error "Invalid configuration: Missing [Interface] section"
        return
    fi
    
    if ! echo "$config_content" | grep -q "\[Peer\]"; then
        log_error "Invalid configuration: Missing [Peer] section"
        return
    fi
    
    if ! echo "$config_content" | grep -q "PrivateKey"; then
        log_error "Invalid configuration: Missing PrivateKey"
        return
    fi
    
    if ! echo "$config_content" | grep -q "PublicKey"; then
        log_error "Invalid configuration: Missing PublicKey"
        return
    fi
    
    log_success "Configuration validation passed"
    
    # Install WireGuard if needed
    install_wireguard
    
    # Create configuration directory
    sudo mkdir -p /etc/wireguard
    
    # Create split tunnel configuration
    local wg_config="/etc/wireguard/wg0.conf"
    create_split_tunnel_config "$config_content" "$wg_config"
    
    # Set proper permissions
    sudo chmod 600 "$wg_config"
    
    # Test configuration
    log "Testing WireGuard configuration..."
    if sudo wg-quick up wg0; then
        log_success "WireGuard VPN connected successfully!"
        
        # Enable auto-start
        if sudo systemctl enable wg-quick@wg0 2>/dev/null; then
            log_success "VPN will start automatically on boot"
        else
            log_warning "Could not enable auto-start (systemd not available?)"
        fi
        
        # Save VPN info to config
        save_vpn_info
        
        show_vpn_status
    else
        log_error "Failed to start WireGuard VPN"
        log "Check your configuration and try again"
    fi
}

install_wireguard() {
    log "Installing WireGuard..."
    
    # Detect distribution
    local distro
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        distro="$ID"
    else
        distro="unknown"
    fi
    
    case "$distro" in
        "fedora"|"silverblue"|"kinoite")
            if command -v rpm-ostree &> /dev/null; then
                log "Installing WireGuard via rpm-ostree..."
                rpm-ostree install wireguard-tools
                log_warning "System reboot may be required"
            else
                sudo dnf install -y wireguard-tools
            fi
            ;;
        "ubuntu"|"debian"|"pop")
            sudo apt update
            sudo apt install -y wireguard
            ;;
        *)
            log_warning "Unknown distribution, attempting generic installation..."
            # Try various package managers
            if command -v dnf &> /dev/null; then
                sudo dnf install -y wireguard-tools
            elif command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y wireguard
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm wireguard-tools
            else
                log_error "Could not install WireGuard automatically"
                log "Please install wireguard-tools package manually"
                exit 1
            fi
            ;;
    esac
    
    log_success "WireGuard installation completed"
}

create_split_tunnel_config() {
    local original_config="$1"
    local output_file="$2"
    
    log "Creating split tunnel configuration..."
    
    # Extract sections
    local interface_section
    interface_section=$(echo "$original_config" | sed -n '/\[Interface\]/,/\[Peer\]/p' | head -n -1)
    
    local peer_section
    peer_section=$(echo "$original_config" | sed -n '/\[Peer\]/,$p')
    
    # Get Tailscale network info
    local tailscale_ip=""
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        tailscale_ip=$(grep "TAILSCALE_IP=" "$DATA_DIR/config/global.env" | cut -d'=' -f2 || echo "")
    fi
    
    # Create new config with split tunneling
    sudo tee "$output_file" > /dev/null << EOF
# BlueLab WireGuard Configuration with Split Tunneling
# Generated on: $(date)
# This allows both VPN and Tailscale to work together

$interface_section

# Split tunnel routing rules
# These rules ensure Tailscale traffic bypasses the VPN
PostUp = ip rule add table main suppress_prefixlength 0 pref 100
PostUp = ip route add 100.64.0.0/10 dev tailscale0 table main 2>/dev/null || true
PostUp = ip route add 192.168.0.0/16 table main 2>/dev/null || true
PostUp = ip route add 10.0.0.0/8 table main 2>/dev/null || true
PostUp = ip route add 172.16.0.0/12 table main 2>/dev/null || true

# Clean up rules on shutdown
PostDown = ip rule del table main suppress_prefixlength 0 pref 100 2>/dev/null || true

$peer_section
EOF
    
    log_success "Split tunnel configuration created"
    log "Configuration saved to: $output_file"
}

save_vpn_info() {
    # Save VPN status to global config
    local vpn_info_file="$DATA_DIR/config/vpn.env"
    
    cat > "$vpn_info_file" << EOF
# BlueLab VPN Configuration Info
VPN_ENABLED=true
VPN_TYPE=wireguard
VPN_CONFIG_DATE=$(date -Iseconds)
VPN_INTERFACE=wg0
EOF
    
    log "VPN configuration info saved"
}

show_vpn_status() {
    echo ""
    echo "=============================================="
    echo "🌐 VPN & Network Status"
    echo "=============================================="
    echo ""
    
    # Check WireGuard status
    local wg_status
    if sudo wg show wg0 &>/dev/null; then
        wg_status="Connected"
        local wg_info
        wg_info=$(sudo wg show wg0)
    else
        wg_status="Not connected"
    fi
    
    # Check Tailscale status
    local ts_status="Unknown"
    local tailscale_ip=""
    
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        tailscale_ip=$(grep "TAILSCALE_IP=" "$DATA_DIR/config/global.env" | cut -d'=' -f2 || echo "")
    fi
    
    if [[ -n "$tailscale_ip" ]]; then
        if distrobox list | grep -q "$CONTAINER_NAME"; then
            if distrobox enter "$CONTAINER_NAME" -- tailscale status &>/dev/null; then
                ts_status="Connected"
            else
                ts_status="Disconnected"
            fi
        else
            ts_status="Container not found"
        fi
    fi
    
    # Get public IP
    local public_ip
    public_ip=$(curl -s -4 icanhazip.com 2>/dev/null || echo "Unable to determine")
    
    # Display status
    echo "🔒 VPN Status:"
    if [[ "$wg_status" == "Connected" ]]; then
        echo "  ✓ WireGuard: Connected"
        echo "  📍 Public IP: $public_ip (via VPN)"
        if [[ -n "$wg_info" ]]; then
            echo "  📊 Details:"
            echo "$wg_info" | sed 's/^/    /'
        fi
    else
        echo "  ✗ WireGuard: Not connected"
        echo "  📍 Public IP: $public_ip (direct)"
    fi
    
    echo ""
    echo "🌐 Tailscale Status:"
    case "$ts_status" in
        "Connected")
            echo "  ✓ Tailscale: Connected"
            echo "  🏠 Tailscale IP: $tailscale_ip"
            ;;
        "Disconnected")
            echo "  ✗ Tailscale: Not connected"
            echo "  🏠 Tailscale IP: $tailscale_ip (configured but offline)"
            ;;
        *)
            echo "  ⚠ Tailscale: $ts_status"
            ;;
    esac
    
    echo ""
    echo "📋 Network Configuration:"
    if [[ "$wg_status" == "Connected" ]]; then
        echo "  • Internet traffic: ✓ Routes through VPN"
        echo "  • Tailscale traffic: ✓ Direct connection (split tunnel)"
        echo "  • Local network: ✓ Direct connection"
        echo "  • Your services: ✓ Accessible via Tailscale IP"
    else
        echo "  • Internet traffic: Direct connection (no VPN)"
        echo "  • Tailscale traffic: Direct connection"
        echo "  • Local network: Direct connection"
    fi
    
    echo ""
    echo "🔧 Management Commands:"
    echo "  • Check VPN: sudo wg show"
    echo "  • Stop VPN: sudo wg-quick down wg0"
    echo "  • Start VPN: sudo wg-quick up wg0"
    echo "  • VPN config: sudo nano /etc/wireguard/wg0.conf"
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        echo "  • Check Tailscale: distrobox enter $CONTAINER_NAME -- tailscale status"
    fi
    echo ""
    
    read -p "Press Enter to return to main menu..."
    show_vpn_menu
}

remove_vpn_config() {
    echo ""
    echo "=============================================="
    echo "🗑️  Remove VPN Configuration"
    echo "=============================================="
    echo ""
    echo "This will:"
    echo "• Stop the WireGuard VPN"
    echo "• Remove the configuration file"
    echo "• Disable auto-start"
    echo "• Restore normal internet routing"
    echo ""
    
    read -p "Are you sure you want to remove VPN configuration? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "VPN removal cancelled"
        show_vpn_menu
        return
    fi
    
    log "Removing VPN configuration..."
    
    # Stop WireGuard if running
    if sudo wg show wg0 &>/dev/null; then
        log "Stopping WireGuard VPN..."
        sudo wg-quick down wg0 || true
    fi
    
    # Disable auto-start
    sudo systemctl disable wg-quick@wg0 &>/dev/null || true
    
    # Remove configuration file
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        sudo rm -f /etc/wireguard/wg0.conf
        log_success "Configuration file removed"
    fi
    
    # Remove VPN info from config
    local vpn_info_file="$DATA_DIR/config/vpn.env"
    if [[ -f "$vpn_info_file" ]]; then
        rm -f "$vpn_info_file"
    fi
    
    log_success "VPN configuration removed successfully"
    log "Your internet connection will now use direct routing"
    echo ""
    
    read -p "Press Enter to return to main menu..."
    show_vpn_menu
}

main() {
    echo "🔒 BlueLab VPN Setup Script"
    echo ""
    
    check_requirements
    show_vpn_menu
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n\nSetup cancelled by user"; exit 1' INT

main "$@"
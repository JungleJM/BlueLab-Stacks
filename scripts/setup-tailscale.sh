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

main() {
    log "BlueLab Stacks - Tailscale Setup"
    log "================================"
    
    setup_tailscale
    show_access_info
    
    log_success "Tailscale setup completed!"
}

main "$@"
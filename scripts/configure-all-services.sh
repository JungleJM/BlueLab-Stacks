#!/bin/bash

# BlueLab Stacks - Master Service Configuration Script
# Orchestrates the auto-configuration of all BlueLab services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="/var/lib/bluelab"

# Logging function
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

# Initialize service credentials file
init_credentials_file() {
    local config_file="$DATA_DIR/config/service-credentials.env"
    
    # Create the file with header
    cat > "$config_file" << EOF
# BlueLab Stacks - Service Credentials
# Generated on $(date)
# This file contains auto-generated credentials for all BlueLab services

EOF

    chmod 600 "$config_file"
    log_success "Service credentials file initialized"
}

# Wait for all containers to be running
wait_for_containers() {
    log "Waiting for all containers to be running..."
    
    local max_attempts=60
    local attempt=1
    local required_containers=(
        "bluelab-deluge"
        "bluelab-qbittorrent"
        "bluelab-homepage"
        "bluelab-adguard"
        "bluelab-postgres"
        "bluelab-redis"
        "bluelab-samba"
    )
    
    while [ $attempt -le $max_attempts ]; do
        local running_count=0
        
        for container in "${required_containers[@]}"; do
            if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
                ((running_count++))
            fi
        done
        
        if [ $running_count -eq ${#required_containers[@]} ]; then
            log_success "All required containers are running"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts - $running_count/${#required_containers[@]} containers running..."
        sleep 5
        ((attempt++))
    done
    
    log_error "Not all containers started within timeout"
    return 1
}

# Configure individual services
configure_deluge() {
    log "Configuring Deluge..."
    
    if [[ -f "$SCRIPT_DIR/configure-deluge.sh" ]]; then
        chmod +x "$SCRIPT_DIR/configure-deluge.sh"
        if "$SCRIPT_DIR/configure-deluge.sh"; then
            log_success "Deluge configuration completed"
        else
            log_error "Deluge configuration failed"
            return 1
        fi
    else
        log_error "Deluge configuration script not found"
        return 1
    fi
}

configure_qbittorrent() {
    log "Configuring qBittorrent..."
    
    if [[ -f "$SCRIPT_DIR/configure-qbittorrent.sh" ]]; then
        chmod +x "$SCRIPT_DIR/configure-qbittorrent.sh"
        if "$SCRIPT_DIR/configure-qbittorrent.sh"; then
            log_success "qBittorrent configuration completed"
        else
            log_error "qBittorrent configuration failed"
            return 1
        fi
    else
        log_error "qBittorrent configuration script not found"
        return 1
    fi
}

configure_homepage() {
    log "Configuring Homepage..."
    
    if [[ -f "$SCRIPT_DIR/configure-homepage.sh" ]]; then
        chmod +x "$SCRIPT_DIR/configure-homepage.sh"
        if "$SCRIPT_DIR/configure-homepage.sh"; then
            log_success "Homepage configuration completed"
        else
            log_error "Homepage configuration failed"
            return 1
        fi
    else
        log_error "Homepage configuration script not found"
        return 1
    fi
}

# Configure additional services that don't need special scripts
configure_basic_services() {
    log "Configuring additional services..."
    
    local config_file="$DATA_DIR/config/service-credentials.env"
    local host_ip=$(hostname -I | awk '{print $1}')
    
    # AdGuard Home (uses default admin/admin initially)
    echo "# AdGuard Home Configuration" >> "$config_file"
    echo "ADGUARD_URL=http://${host_ip}:3001" >> "$config_file"
    echo "ADGUARD_USERNAME=admin" >> "$config_file"
    echo "ADGUARD_PASSWORD=admin" >> "$config_file"
    echo "" >> "$config_file"
    
    # Dockge (uses default admin/admin)
    echo "# Dockge Configuration" >> "$config_file"
    echo "DOCKGE_URL=http://${host_ip}:5001" >> "$config_file"
    echo "DOCKGE_USERNAME=admin" >> "$config_file"
    echo "DOCKGE_PASSWORD=admin" >> "$config_file"
    echo "" >> "$config_file"
    
    # SMB Configuration
    echo "# SMB Share Configuration" >> "$config_file"
    echo "SMB_HOST=${host_ip}" >> "$config_file"
    echo "SMB_USERNAME=bluelab" >> "$config_file"
    echo "SMB_PASSWORD=bluelab123" >> "$config_file"
    echo "SMB_SHARE_PATH=//\${host_ip}/bluelab" >> "$config_file"
    echo "" >> "$config_file"
    
    log_success "Additional services configured"
}

# Create a summary of all services and credentials
create_service_summary() {
    log "Creating service access summary..."
    
    local summary_file="$DATA_DIR/config/service-summary.md"
    local host_ip=$(hostname -I | awk '{print $1}')
    
    cat > "$summary_file" << EOF
# BlueLab Stacks - Service Access Summary

Generated on: $(date)
Host IP: ${host_ip}

## Core Services

### Download Clients
- **Deluge (Primary)**
  - URL: http://${host_ip}:8112
  - Password: \`bluelab123\`
  - Pre-configured with labels for Movies, TV, Music, Books

- **qBittorrent (Secondary)**
  - URL: http://${host_ip}:8080
  - Username: \`admin\`
  - Password: \`bluelab123\`
  - Pre-configured with categories for media organization

### Management & Monitoring
- **Homepage Dashboard**
  - URL: http://${host_ip}:3000
  - Features: Service monitoring, widgets, quick access
  - Auto-configured with all service integrations

- **Dockge (Container Manager)**
  - URL: http://${host_ip}:5001
  - Username: \`admin\`
  - Password: \`admin\`

- **AdGuard Home (DNS)**
  - URL: http://${host_ip}:3001
  - Username: \`admin\`
  - Password: \`admin\`
  - DNS Server: ${host_ip}:5353

### File Sharing
- **SMB Shares**
  - Share Path: \`\\\\${host_ip}\\bluelab\`
  - Username: \`bluelab\`
  - Password: \`bluelab123\`
  - Accessible from any device on network

### Databases
- **PostgreSQL**
  - Host: ${host_ip}:5432
  - Database: bluelab
  - Username: bluelab
  - Password: (auto-generated, see service-credentials.env)

- **Redis**
  - Host: ${host_ip}:6379
  - Password: (auto-generated, see service-credentials.env)

## Media Organization

All download clients are pre-configured with the following structure:
- Movies → \`/data/media/movies\`
- TV Shows → \`/data/media/tv\`
- Music → \`/data/media/music\`
- Books → \`/data/media/books\`

## Security Notes

1. Default passwords are set for initial access
2. Change default passwords after first login for production use
3. All services are configured for local network access
4. Use Tailscale for secure remote access

## Next Steps

1. Access Homepage at http://${host_ip}:3000 for central dashboard
2. Configure Tailscale for remote access: \`./scripts/setup-tailscale.sh\`
3. Set up your router to use ${host_ip}:5353 as DNS server
4. Add your first torrents to test the download clients
5. Ready for Phase 2 (Media Stack) deployment

EOF

    log_success "Service summary created at $summary_file"
}

# Run configuration health check
run_health_check() {
    log "Running configuration health check..."
    
    local failed_services=()
    local host_ip=$(hostname -I | awk '{print $1}')
    
    # Test service accessibility
    local services=(
        "http://${host_ip}:3000:Homepage"
        "http://${host_ip}:5001:Dockge"
        "http://${host_ip}:3001:AdGuard"
        "http://${host_ip}:8112:Deluge"
        "http://${host_ip}:8080:qBittorrent"
    )
    
    for service in "${services[@]}"; do
        local url=$(echo "$service" | cut -d: -f1-3)
        local name=$(echo "$service" | cut -d: -f4)
        
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
            log_success "$name is accessible"
        else
            log_warning "$name is not accessible"
            failed_services+=("$name")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "All services passed health check"
        return 0
    else
        log_warning "Health check failed for: ${failed_services[*]}"
        return 1
    fi
}

# Main configuration orchestration
main() {
    echo "=========================================="
    echo "🔧 BlueLab Stacks Service Configuration"
    echo "=========================================="
    echo ""
    
    log "Starting comprehensive service configuration..."
    
    # Initialize
    init_credentials_file
    
    # Wait for containers to be ready
    wait_for_containers
    
    # Configure each service in optimal order
    log "Phase 1: Core Service Configuration"
    configure_basic_services
    
    log "Phase 2: Download Client Configuration"
    configure_deluge
    sleep 5
    configure_qbittorrent
    
    log "Phase 3: Dashboard Configuration"
    sleep 5
    configure_homepage
    
    log "Phase 4: Finalization"
    create_service_summary
    
    # Final health check
    sleep 10
    if run_health_check; then
        echo ""
        echo "🎉 All services successfully configured!"
        echo ""
        echo "📊 Access your dashboard: http://$(hostname -I | awk '{print $1}'):3000"
        echo "📋 Service summary: $DATA_DIR/config/service-summary.md"
        echo "🔑 All credentials: $DATA_DIR/config/service-credentials.env"
        echo ""
        echo "✨ BlueLab Phase 1 is ready for use!"
    else
        echo ""
        echo "⚠️  Configuration completed with some issues"
        echo "📋 Check service summary: $DATA_DIR/config/service-summary.md"
        echo "🔧 Run health check: $DATA_DIR/scripts/health-check.sh"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
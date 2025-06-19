#!/bin/bash

# BlueLab Stacks - Homepage Auto-Configuration Script
# Sets up Homepage dashboard with API integrations and service discovery

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DATA_DIR="/var/lib/bluelab"
CONTAINER_NAME="bluelab-homepage"

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

# Load environment variables and credentials
load_config() {
    if [[ -f "$DATA_DIR/config/global.env" ]]; then
        source "$DATA_DIR/config/global.env"
    fi
    
    if [[ -f "$DATA_DIR/config/service-credentials.env" ]]; then
        source "$DATA_DIR/config/service-credentials.env"
    fi
}

# Get host IP address
get_host_ip() {
    hostname -I | awk '{print $1}'
}

# Create Homepage configuration structure
create_homepage_config() {
    log "Creating Homepage configuration structure..."
    
    local config_dir="$DATA_DIR/stacks/monitoring/homepage-config"
    mkdir -p "$config_dir"/{config,icons}
    
    local host_ip=$(get_host_ip)
    
    # Create settings.yaml
    cat > "$config_dir/config/settings.yaml" << EOF
---
title: BlueLab Dashboard
theme: dark
color: slate
headerStyle: clean
layout:
  Infrastructure:
    style: row
    columns: 4
  Downloads:
    style: row
    columns: 3
  Media:
    style: row
    columns: 4
  Management:
    style: row
    columns: 3

providers:
  openweathermap: ${OPENWEATHER_API_KEY:-}
  
target: _self
cardBlur: md
favicon: https://raw.githubusercontent.com/gethomepage/homepage/main/public/android-chrome-192x192.png

quicklaunch:
  searchDescriptions: true
  hideInternetSearch: false
  hideVisitURL: false

options:
  cardBlur: md
  theme: dark
  hideVersion: false
  useEqualHeights: true
EOF

    log_success "Homepage settings.yaml created"
}

# Create services configuration
create_services_config() {
    log "Creating Homepage services configuration..."
    
    local config_dir="$DATA_DIR/stacks/monitoring/homepage-config"
    local host_ip=$(get_host_ip)
    
    # Create services.yaml with all BlueLab services
    cat > "$config_dir/config/services.yaml" << EOF
---
- Infrastructure:
    - AdGuard Home:
        icon: adguard-home.png
        href: http://${host_ip}:3001
        description: DNS filtering and ad blocking
        server: ${host_ip}
        container: bluelab-adguard
        widget:
          type: adguard
          url: http://${host_ip}:3001
          username: admin
          password: admin

    - Dockge:
        icon: dockge.png
        href: http://${host_ip}:5001
        description: Docker compose manager
        server: ${host_ip}
        container: bluelab-dockge
        widget:
          type: dockge
          url: http://${host_ip}:5001
          username: admin
          password: admin

    - Tailscale:
        icon: tailscale.png
        description: VPN and secure remote access
        server: ${host_ip}
        container: bluelab-tailscale

    - PostgreSQL:
        icon: postgres.png
        description: Primary database
        server: ${host_ip}
        container: bluelab-postgres
        widget:
          type: postgres
          url: postgresql://${POSTGRES_USER:-bluelab}:${POSTGRES_PASSWORD}@${host_ip}:5432/${POSTGRES_DB:-bluelab}

- Downloads:
    - Deluge:
        icon: deluge.png
        href: http://${host_ip}:8112
        description: Primary BitTorrent client
        server: ${host_ip}
        container: bluelab-deluge
        widget:
          type: deluge
          url: http://${host_ip}:8112
          password: ${DELUGE_PASSWORD:-bluelab123}

    - qBittorrent:
        icon: qbittorrent.png
        href: http://${host_ip}:8080
        description: Secondary BitTorrent client
        server: ${host_ip}
        container: bluelab-qbittorrent
        widget:
          type: qbittorrent
          url: http://${host_ip}:8080
          username: ${QBITTORRENT_USERNAME:-admin}
          password: ${QBITTORRENT_PASSWORD:-bluelab123}

    - FileBot:
        icon: filebot.png
        href: http://${host_ip}:5800
        description: Automated file renaming and organization
        server: ${host_ip}
        container: bluelab-filebot

- Media:
    - SMB Shares:
        icon: samba.png
        description: Network file sharing
        server: ${host_ip}
        container: bluelab-samba
        widget:
          type: customapi
          url: http://${host_ip}/api/smb/status
          method: GET

- Management:
    - Redis:
        icon: redis.png
        description: Cache and session store
        server: ${host_ip}
        container: bluelab-redis
        widget:
          type: redis
          url: redis://${host_ip}:6379
          password: ${REDIS_PASSWORD}

    - System Monitor:
        icon: glances.png
        description: System resource monitoring
        widget:
          type: glances
          url: http://${host_ip}:61208
          username: admin
          password: admin
          version: 4

    - Watchtower:
        icon: watchtower.png
        description: Automatic container updates
        server: ${host_ip}
        container: bluelab-watchtower
EOF

    log_success "Homepage services.yaml created"
}

# Create widgets configuration
create_widgets_config() {
    log "Creating Homepage widgets configuration..."
    
    local config_dir="$DATA_DIR/stacks/monitoring/homepage-config"
    local host_ip=$(get_host_ip)
    
    # Create widgets.yaml
    cat > "$config_dir/config/widgets.yaml" << EOF
---
- logo:
    icon: https://raw.githubusercontent.com/gethomepage/homepage/main/public/android-chrome-192x192.png

- greeting:
    text_size: xl
    text: "Welcome to BlueLab!"

- search:
    provider: duckduckgo
    target: _blank

- datetime:
    text_size: l
    format:
      timeStyle: short
      dateStyle: long
      hourCycle: h23

- openmeteo:
    label: Weather
    latitude: 40.7128
    longitude: -74.0060
    timezone: America/New_York
    units: metric
    cache: 5

- resources:
    label: System
    cpu: true
    memory: true
    disk: /
    expanded: true
    units: metric

- unifi_console:
    url: http://${host_ip}:8443
    username: \${UNIFI_USERNAME}
    password: \${UNIFI_PASSWORD}

- docker:
    server: ${host_ip}
    socket: /var/run/docker.sock
EOF

    log_success "Homepage widgets.yaml created"
}

# Create bookmarks configuration
create_bookmarks_config() {
    log "Creating Homepage bookmarks configuration..."
    
    local config_dir="$DATA_DIR/stacks/monitoring/homepage-config"
    
    # Create bookmarks.yaml
    cat > "$config_dir/config/bookmarks.yaml" << EOF
---
- Development:
    - GitHub:
        - abbr: GH
          href: https://github.com/JungleJM/BlueLab-Stacks
    - Docker Hub:
        - abbr: DH
          href: https://hub.docker.com

- Media:
    - Plex:
        - abbr: PX
          href: https://plex.tv
    - YouTube:
        - abbr: YT
          href: https://youtube.com
    - Netflix:
        - abbr: NF
          href: https://netflix.com

- Tools:
    - Portainer:
        - abbr: PT
          href: https://portainer.io
    - Grafana:
        - abbr: GF
          href: https://grafana.com

- Documentation:
    - BlueLab Docs:
        - abbr: BL
          href: https://github.com/JungleJM/BlueLab-Stacks/tree/main/Docs
    - Homepage Docs:
        - abbr: HP
          href: https://gethomepage.dev
EOF

    log_success "Homepage bookmarks.yaml created"
}

# Create custom CSS for branding
create_custom_css() {
    log "Creating custom CSS for BlueLab branding..."
    
    local config_dir="$DATA_DIR/stacks/monitoring/homepage-config"
    mkdir -p "$config_dir/config/custom"
    
    cat > "$config_dir/config/custom/custom.css" << EOF
/* BlueLab Custom Styling */
.greeting {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    font-weight: bold;
}

.service-card {
    transition: transform 0.2s ease-in-out;
}

.service-card:hover {
    transform: translateY(-2px);
}

/* Custom logo styling */
.logo img {
    border-radius: 50%;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
}
EOF

    log_success "Custom CSS created"
}

# Update docker-compose file to include config mounts
update_docker_compose() {
    log "Updating Homepage docker-compose configuration..."
    
    local compose_file="$DATA_DIR/stacks/monitoring/docker-compose.yml"
    
    # Check if the volumes section needs updating
    if ! grep -q "homepage-config" "$compose_file"; then
        # Add config volume mount to homepage service
        sed -i '/volumes:/a\      - ./homepage-config/config:/app/config' "$compose_file"
        log_success "Updated docker-compose.yml with config mount"
    else
        log "Docker-compose already has config mount"
    fi
}

# Store Homepage configuration details
store_homepage_config() {
    local config_file="$DATA_DIR/config/service-credentials.env"
    local host_ip=$(get_host_ip)
    
    echo "# Homepage Configuration" >> "$config_file"
    echo "HOMEPAGE_URL=http://${host_ip}:3000" >> "$config_file"
    echo "HOMEPAGE_CONFIG_DIR=$DATA_DIR/stacks/monitoring/homepage-config" >> "$config_file"
    echo "" >> "$config_file"
    
    log_success "Homepage configuration stored"
}

# Wait for Homepage to be ready
wait_for_homepage() {
    local max_attempts=20
    local attempt=1
    
    log "Waiting for Homepage to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ | grep -q "200"; then
            log_success "Homepage is ready"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts - Homepage not ready yet..."
        sleep 3
        ((attempt++))
    done
    
    log_error "Homepage failed to become ready after $max_attempts attempts"
    return 1
}

# Main configuration function
main() {
    log "Starting Homepage auto-configuration..."
    
    # Load configuration
    load_config
    
    # Create all configuration files
    create_homepage_config
    create_services_config
    create_widgets_config
    create_bookmarks_config
    create_custom_css
    
    # Update docker-compose and store config
    update_docker_compose
    store_homepage_config
    
    # Restart Homepage container to apply configuration
    log "Restarting Homepage container to apply configuration..."
    docker restart "$CONTAINER_NAME"
    
    # Wait for it to come back up
    sleep 10
    wait_for_homepage
    
    log_success "Homepage auto-configuration completed!"
    echo ""
    echo "Homepage Dashboard:"
    echo "  URL: http://$(get_host_ip):3000"
    echo "  Features:"
    echo "    - Service monitoring with widgets"
    echo "    - System resource monitoring"
    echo "    - Quick access to all BlueLab services"
    echo "    - Automatic service discovery"
    echo "    - Custom BlueLab branding"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
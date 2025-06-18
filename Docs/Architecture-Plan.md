# BlueLab Stacks - Architecture Plan

## Executive Summary

BlueLab Stacks is a containerized homelab management system designed to provide Netflix-level user experience for self-hosted services. The architecture prioritizes simplicity, reliability, and automatic management while supporting both BlueLab custom ISO users and existing Linux distribution users.

## Core Architecture Principles

### 1. Distrobox-First Strategy
- **Primary Container**: Ubuntu 22.04 LTS in Distrobox for maximum compatibility
- **Benefits**: Isolated environment, easy uninstallation, consistent package management
- **Fallback**: Native installation for systems where Distrobox isn't feasible

### 2. Dual-Audience Support
- **BlueLab Users**: Automatic integration via first-boot scripts
- **Linux Users**: Standalone installer detecting distribution and environment

### 3. Zero-Configuration Philosophy
- All inter-service communication configured automatically
- Shared dependencies handled by dedicated core stacks
- No manual API key exchange or service linking required

## System Architecture

### Container Strategy

```
┌─────────────────────────────────────────────────────────────┐
│ Host Linux System (Any Distribution)                        │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Distrobox Container (Ubuntu 22.04 LTS)                 │ │
│ │ ┌─────────────────────────────────────────────────────┐ │ │
│ │ │ Docker Engine + Docker Compose                     │ │ │
│ │ │ ┌─────────────────────────────────────────────────┐ │ │ │
│ │ │ │ BlueLab Stacks (Individual Service Containers) │ │ │ │
│ │ │ └─────────────────────────────────────────────────┘ │ │ │
│ │ └─────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Rationale**: This approach provides:
- Complete isolation from host system
- Consistent Ubuntu environment regardless of host distro
- Easy removal without affecting host system
- Compatibility with immutable distros (Silverblue, etc.)

### Directory Structure

```
/var/lib/bluelab/                           # Host-mounted persistent data
├── distrobox/                              # Distrobox configuration
│   ├── bluelab-container.conf              # Container definition
│   └── init-scripts/                       # Container setup scripts
├── stacks/                                 # Individual stack configurations
│   ├── core-networking/                    # Tailscale + DNS services
│   ├── core-download/                      # Shared download clients
│   ├── core-database/                      # Shared PostgreSQL/Redis
│   ├── monitoring/                         # Homepage + Dockge + Grafana
│   ├── media/                              # Jellyfin ecosystem
│   ├── audio/                              # Navidrome ecosystem
│   ├── photos/                             # Immich
│   ├── books/                              # Calibre ecosystem
│   ├── productivity/                       # Nextcloud
│   ├── gaming/                             # Steam (if needed)
│   └── smb-share/                          # Samba file sharing
├── data/                                   # User data (media, photos, etc.)
│   ├── media/
│   ├── music/
│   ├── photos/
│   ├── books/
│   └── documents/
├── config/                                 # Global configuration
│   ├── global.env                          # Global environment variables
│   ├── docker.env                          # Docker-specific settings
│   └── tailscale.conf                      # Tailscale configuration
└── backups/                                # Configuration backups
    ├── daily/
    └── pre-update/
```

## Core Stack Architecture

### Core Stacks (Always Installed)

#### 1. Core Networking Stack
**Purpose**: Handles Tailscale integration and DNS services for easy access patterns

**Services**:
- **Tailscale**: Provides secure remote access and IP addressing
- **Headscale** (Optional): Self-hosted Tailscale coordination server
- **AdGuard Home**: DNS server with ad-blocking and custom domain routing

**Access Pattern Implementation**:
```yaml
# Custom DNS entries for easy access
bluelab.local → 192.168.1.100 (Local IP)
bluelab.movies → 192.168.1.100:7878 (Radarr)
bluelab.tv → 192.168.1.100:8989 (Sonarr)
bluelab.music → 192.168.1.100:4533 (Navidrome)
bluelab.photos → 192.168.1.100:2283 (Immich)
bluelab.calendar → 192.168.1.100:8080/apps/calendar (Nextcloud)
```

#### 2. Core Download Stack
**Purpose**: Shared download clients for multiple stacks

**Services**:
- **qBittorrent**: Primary torrent client with WebUI
- **Transmission**: Backup/alternative torrent client
- **yt-dlp**: YouTube and web content downloader
- **Filebot**: File organization and naming

**Shared Usage**: Used by Media, Audio, and Books stacks automatically

#### 3. Core Database Stack
**Purpose**: Shared database services to reduce resource usage

**Services**:
- **PostgreSQL**: Primary database for Nextcloud, Immich, etc.
- **Redis**: Caching and session storage
- **Database backup automation**

#### 4. Monitoring Stack
**Purpose**: System monitoring, management interface, and dashboard

**Services**:
- **Homepage**: Main dashboard with service discovery
- **Dockge**: Visual Docker Compose management
- **Uptime Kuma**: Service availability monitoring
- **Grafana**: System metrics visualization
- **Prometheus**: Metrics collection
- **Watchtower**: Automated container updates

### Optional Stacks

#### Media Stack
**Components**: Jellyfin, Sonarr, Radarr, Bazarr, Jellyseerr
**Dependencies**: Core Download, Core Database
**Auto-Configuration**: All services pre-linked with API keys

#### Audio Stack
**Components**: Navidrome, Lidarr, Podgrab
**Dependencies**: Core Download
**Integration**: Shares download client with Media stack

#### Photos Stack
**Components**: Immich (app, ML, database)
**Dependencies**: Core Database (PostgreSQL, Redis)
**Features**: Mobile sync, face recognition, automatic organization

#### Books Stack
**Components**: Calibre-Web, Readarr
**Dependencies**: Core Download
**Integration**: Automatic ebook organization and management

#### Productivity Stack
**Components**: Nextcloud (files, calendar, tasks, contacts)
**Dependencies**: Core Database, Core Networking
**Features**: WebDAV, CalDAV, CardDAV integration

#### Gaming Stack
**Components**: Steam (containerized if not present)
**Special Handling**: Installs natively if available, containerized if not
**Purpose**: Ensures easy removal with rest of BlueLab system

#### SMB Share Stack
**Components**: Samba server with Tailscale integration
**Purpose**: Easy file access from any device on network
**Integration**: Serves media files for direct access

## Installation Architecture

### Distrobox Setup Process

```bash
# 1. Detect host system and install Distrobox if needed
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    fi
}

install_distrobox() {
    local distro=$(detect_distro)
    case "$distro" in
        "fedora"|"silverblue")
            rpm-ostree install distrobox || dnf install distrobox
            ;;
        "ubuntu"|"debian")
            apt update && apt install distrobox
            ;;
        *)
            # Use curl method for other distros
            curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh
            ;;
    esac
}

# 2. Create BlueLab container
create_bluelab_container() {
    distrobox create \
        --name bluelab \
        --image ubuntu:22.04 \
        --volume /var/lib/bluelab:/var/lib/bluelab:rw \
        --volume /home/$USER:/home/$USER:rw \
        --additional-packages "docker.io docker-compose curl wget git"
}
```

### Service Discovery and Auto-Configuration

#### Homepage Integration
```yaml
# Automatic service discovery via Docker labels
version: '3.8'
services:
  radarr:
    image: linuxserver/radarr
    labels:
      - "bluelab.service=true"
      - "bluelab.name=Radarr"
      - "bluelab.category=Media"
      - "bluelab.port=7878"
      - "bluelab.icon=radarr.png"
      - "bluelab.description=Movie management"
      - "bluelab.subdomain=movies"
    environment:
      - PUID=1000
      - PGID=1000
```

#### Automatic API Key Management
```bash
# Generate and share API keys between services
generate_api_key() {
    openssl rand -hex 32
}

configure_service_links() {
    local radarr_key=$(get_service_api_key "radarr")
    local qbittorrent_url="http://qbittorrent:8080"
    
    # Configure Radarr to use qBittorrent
    curl -X POST "http://radarr:7878/api/v3/downloadclient" \
        -H "X-Api-Key: $radarr_key" \
        -d @radarr-qbit-config.json
}
```

## Network Architecture

### Tailscale Integration

#### Access Patterns
```bash
# DNS Configuration in AdGuard Home
bluelab.local         → 100.64.x.x (Tailscale IP)
*.bluelab.local       → 100.64.x.x (All subdomains)

# Service-specific subdomains
movies.bluelab.local  → 100.64.x.x:7878
tv.bluelab.local      → 100.64.x.x:8989
music.bluelab.local   → 100.64.x.x:4533
photos.bluelab.local  → 100.64.x.x:2283
```

#### Tailscale Setup Automation
```bash
setup_tailscale() {
    # Install Tailscale in container
    distrobox enter bluelab -- \
        'curl -fsSL https://tailscale.com/install.sh | sh'
    
    # Generate auth URL for user
    echo "Please visit this URL to authorize Tailscale:"
    distrobox enter bluelab -- tailscale up --authkey=<interactive>
    
    # Get Tailscale IP for configuration
    TAILSCALE_IP=$(distrobox enter bluelab -- tailscale ip -4)
    echo "TAILSCALE_IP=$TAILSCALE_IP" >> /var/lib/bluelab/config/global.env
}
```

### Port Management

#### Automatic Port Assignment
```bash
# Port assignment with conflict detection
declare -A DEFAULT_PORTS=(
    ["homepage"]="3000"
    ["dockge"]="5001"
    ["jellyfin"]="8096"
    ["radarr"]="7878"
    ["sonarr"]="8989"
    ["qbittorrent"]="8080"
    ["navidrome"]="4533"
    ["immich"]="2283"
)

find_available_port() {
    local service=$1
    local preferred_port=${DEFAULT_PORTS[$service]}
    local current_port=$preferred_port
    
    while port_in_use "$current_port"; do
        current_port=$((current_port + 1))
    done
    
    echo "$current_port"
}
```

## Data Management Architecture

### Storage Strategy
```
/var/lib/bluelab/data/
├── media/
│   ├── movies/           # Shared by Radarr, Jellyfin
│   ├── tv/              # Shared by Sonarr, Jellyfin
│   └── downloads/       # qBittorrent downloads
├── music/               # Shared by Lidarr, Navidrome
├── photos/              # Immich storage
├── books/               # Calibre library
├── documents/           # Nextcloud files
└── backups/             # Application backups
```

### Backup Strategy
```bash
# Automated configuration backup
backup_configs() {
    local backup_dir="/var/lib/bluelab/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup all stack configurations
    for stack in /var/lib/bluelab/stacks/*/; do
        stack_name=$(basename "$stack")
        cp -r "$stack" "$backup_dir/$stack_name"
    done
    
    # Backup global configuration
    cp -r /var/lib/bluelab/config "$backup_dir/"
    
    # Create restoration script
    cat > "$backup_dir/restore.sh" << 'EOF'
#!/bin/bash
# Auto-generated restoration script
RESTORE_DIR="$(dirname "$0")"
cp -r "$RESTORE_DIR"/* /var/lib/bluelab/
EOF
    chmod +x "$backup_dir/restore.sh"
}
```

## Security Architecture

### Container Security
- All services run as non-root users (PUID/PGID)
- Distrobox provides additional isolation layer
- No services exposed directly to internet
- All external access via Tailscale tunnel

### Secrets Management
```bash
# Centralized secrets management
generate_service_secrets() {
    local secrets_file="/var/lib/bluelab/config/secrets.env"
    
    # Generate unique passwords for each service
    cat > "$secrets_file" << EOF
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JELLYFIN_API_KEY=$(openssl rand -hex 32)
RADARR_API_KEY=$(openssl rand -hex 32)
SONARR_API_KEY=$(openssl rand -hex 32)
EOF
    
    chmod 600 "$secrets_file"
}
```

### Access Control
- Tailscale provides device-based access control
- Homepage serves as central authentication point
- Individual services use generated API keys
- SMB shares use system user authentication

## Update and Maintenance Architecture

### Automated Updates
```bash
# Coordinated update system
update_system() {
    log "Starting BlueLab system update"
    
    # 1. Backup current configuration
    backup_configs
    
    # 2. Update container images
    distrobox enter bluelab -- \
        'docker compose --parallel --project-directory /var/lib/bluelab/stacks pull'
    
    # 3. Restart services with health checks
    for stack in /var/lib/bluelab/stacks/*/; do
        update_stack "$(basename "$stack")"
        verify_stack_health "$(basename "$stack")"
    done
    
    # 4. Update Homepage configuration
    regenerate_homepage_config
    
    log "System update completed successfully"
}
```

### Health Monitoring
```bash
# Comprehensive health monitoring
monitor_system_health() {
    local unhealthy_services=()
    
    for stack in /var/lib/bluelab/stacks/*/; do
        stack_name=$(basename "$stack")
        if ! check_stack_health "$stack_name"; then
            unhealthy_services+=("$stack_name")
        fi
    done
    
    if [ ${#unhealthy_services[@]} -gt 0 ]; then
        log "ALERT: Unhealthy services detected: ${unhealthy_services[*]}"
        attempt_service_recovery "${unhealthy_services[@]}"
    fi
}
```

## Integration Points

### BlueLab ISO Integration
When integrated with the main BlueLab project:

```bash
# Enhanced first-boot script
if [ -f /etc/bluelab-release ]; then
    log "BlueLab system detected"
    export BLUELAB_AUTO_INSTALL=true
    export BLUELAB_TAILSCALE_KEY="$TAILSCALE_AUTH_KEY"
    
    # Download and install BlueLab Stacks
    git clone https://github.com/JungleJM/BlueLab-Stacks.git /opt/bluelab-stacks
    cd /opt/bluelab-stacks
    ./scripts/install.sh --automated --stacks="$SELECTED_STACKS"
fi
```

### External Integration Points
- **Mobile Apps**: Jellyfin, Immich, Nextcloud clients
- **Desktop Integration**: SMB mounts, calendar sync, file sync
- **Browser Bookmarks**: Automatic bookmark generation for Tailscale addresses
- **API Access**: All services maintain API access for automation

## Performance Considerations

### Resource Management
- **Minimum Requirements**: 8GB RAM, 100GB storage
- **Recommended**: 16GB RAM, 500GB storage
- **Service Limits**: CPU and memory limits per stack
- **Storage Optimization**: Shared volumes, efficient file organization

### Optimization Strategies
- Shared database containers reduce memory usage
- Lazy loading of optional stacks
- Intelligent caching with Redis
- Compressed backups and log rotation

## Disaster Recovery

### Recovery Scenarios
1. **Container Corruption**: Recreate from backup configurations
2. **Data Loss**: Restore from automated backups
3. **Host System Issues**: Complete reinstallation with data preservation
4. **Service Conflicts**: Automatic port reassignment and conflict resolution

### Recovery Procedures
```bash
# Complete system restoration
restore_bluelab_system() {
    local backup_path=$1
    
    log "Starting BlueLab system restoration"
    
    # 1. Recreate Distrobox container
    distrobox rm bluelab -f
    create_bluelab_container
    
    # 2. Restore configurations
    cp -r "$backup_path"/* /var/lib/bluelab/
    
    # 3. Redeploy all stacks
    for stack in /var/lib/bluelab/stacks/*/; do
        deploy_stack "$(basename "$stack")"
    done
    
    log "System restoration completed"
}
```

This architecture provides a robust, scalable foundation for BlueLab Stacks that prioritizes user experience while maintaining technical excellence and reliability.
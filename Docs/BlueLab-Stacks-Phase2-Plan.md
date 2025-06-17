# BlueLab Stacks - Phase 2 Development Plan

## Project Overview

**BlueLab Stacks** is a standalone repository that provides the complete Docker stack management system for the BlueLab homelab project. This decouples the core functionality from the custom ISO build process, allowing:

- **Parallel Development** - Work on stacks while ISO issues are resolved
- **Broader Compatibility** - Works on any Linux system with Docker
- **Independent Testing** - Faster iteration without full ISO rebuilds
- **Modular Architecture** - Proves stack system works independently

## Phase 2 Goals

Transform BlueLab from a basic monitoring-only system into a comprehensive homelab solution with:

1. **Complete Stack System** - All 8 predefined stacks working
2. **Dockge Integration** - Visual container management interface
3. **Enhanced Homepage** - Dynamic service discovery and dashboard
4. **Installation Scripts** - Easy deployment on any Linux system

## Target Architecture

### Repository Structure
```
BlueLab-Stacks/
├── README.md
├── docs/
│   ├── INSTALLATION.md
│   ├── STACK-GUIDE.md
│   └── TROUBLESHOOTING.md
├── scripts/
│   ├── install.sh              # Main installation script
│   ├── deploy-stack.sh         # Stack deployment manager
│   ├── setup-homepage.sh       # Homepage configuration
│   └── update-system.sh        # Update orchestrator
├── stacks/
│   ├── monitoring/             # Homepage + Dockge + Grafana
│   ├── media/                  # Jellyfin, Sonarr, Radarr, etc.
│   ├── audio/                  # Navidrome, Lidarr, etc.
│   ├── photos/                 # Immich
│   ├── books/                  # Calibre, Readarr
│   ├── productivity/           # Nextcloud
│   ├── gaming/                 # Steam, Lutris integration
│   └── smb-share/              # Samba file sharing
├── config/
│   ├── homepage/               # Homepage dashboard templates
│   ├── docker.env.template     # Docker environment
│   └── global.env.template     # Global configuration
└── templates/
    ├── docker-compose.yml.template
    └── stack-specific templates
```

## Phase 2 Components

### 1. Core Monitoring Stack Enhancement

**Current State**: Basic Homepage + Dockge
**Phase 2 Goal**: Comprehensive monitoring and management

#### Components:
- **Homepage** - Enhanced dashboard with service discovery
- **Dockge** - Visual Docker Compose management
- **Grafana** - System metrics and monitoring
- **Prometheus** - Metrics collection
- **Uptime Kuma** - Service availability monitoring
- **Watchtower** - Automated container updates

#### Implementation Details:
```yaml
# stacks/monitoring/docker-compose.yml
version: '3.8'
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: bluelab-homepage
    ports:
      - "3000:3000"
    volumes:
      - ./homepage:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - PUID=1000
      - PGID=1000
    restart: unless-stopped

  dockge:
    image: louislam/dockge:1
    container_name: bluelab-dockge
    ports:
      - "5001:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./dockge:/app/data
      - ../:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks
    restart: unless-stopped
```

### 2. Media Stack Implementation

**Goal**: Complete media management and streaming solution

#### Services:
- **Jellyfin** - Media streaming server (Port 8096)
- **Sonarr** - TV series management (Port 8989)
- **Radarr** - Movie management (Port 7878)
- **Deluge** - BitTorrent client (Port 8112)
- **Jellyseerr** - Request management (Port 5055)
- **Filebot** - Media file organization

#### Storage Architecture:
```
/var/lib/bluelab/data/media/
├── movies/           # Radarr + Jellyfin
├── tv/              # Sonarr + Jellyfin
├── downloads/       # Deluge downloads
├── processing/      # Filebot workspace
└── config/          # Service configurations
```

### 3. Audio Stack Implementation

**Goal**: Complete music management and streaming

#### Services:
- **Navidrome** - Music streaming server (Port 4533)
- **Lidarr** - Music collection management (Port 8686)
- **Podgrab** - Podcast management (Port 8080)

#### Integration Notes:
- Smart dependency with Media Stack (no port conflicts)
- Shared download client with Media Stack
- Integrated with Homepage for unified access

### 4. Photos Stack Implementation

**Goal**: Personal photo management and sharing

#### Services:
- **Immich** - Photo management platform
  - Main app (Port 2283)
  - Machine learning (Internal)
  - PostgreSQL database (Internal)
  - Redis cache (Internal)

#### Features:
- Mobile app sync
- Face recognition
- Automatic backup
- Album organization

### 5. Books Stack Implementation

**Goal**: Digital library management

#### Services:
- **Calibre-Web** - Ebook server (Port 8083)
- **Readarr** - Book collection management (Port 8787)

### 6. Productivity Stack Implementation

**Goal**: Personal cloud and collaboration

#### Services:
- **Nextcloud** - File sync and collaboration (Port 8080)
- **PostgreSQL** - Database for Nextcloud
- **Redis** - Caching for performance

### 7. Gaming Stack Integration

**Goal**: Gaming service management via ujust commands

#### Components:
- Integration with existing Bluefin gaming tools
- Steam management
- Lutris/Heroic launcher management
- Game library organization

### 8. SMB Share Stack Implementation

**Goal**: Network file sharing with optional ZFS

#### Services:
- **Samba** - SMB/CIFS file sharing
- **ZFS integration** (when available)
- **Tailscale integration** for remote access

## Dynamic Homepage System

### Service Discovery Architecture

```javascript
// Homepage service discovery
const discoverServices = () => {
  const services = [];
  
  // Scan running Docker containers
  const containers = docker.listContainers({ all: false });
  
  containers.forEach(container => {
    const labels = container.Labels;
    if (labels['bluelab.service']) {
      services.push({
        name: labels['bluelab.service.name'],
        icon: labels['bluelab.service.icon'],
        url: `http://${getHostIP()}:${labels['bluelab.service.port']}`,
        description: labels['bluelab.service.description'],
        category: labels['bluelab.service.category']
      });
    }
  });
  
  return services;
};
```

### Homepage Configuration Template

```yaml
# config/homepage/services.yaml.template
---
- Media:
    - Jellyfin:
        icon: jellyfin.png
        href: http://{{BLUELAB_IP}}:8096
        description: Media streaming server
        widget:
          type: jellyfin
          url: http://{{BLUELAB_IP}}:8096
          key: {{JELLYFIN_API_KEY}}
    
    - Sonarr:
        icon: sonarr.png
        href: http://{{BLUELAB_IP}}:8989
        description: TV series management
        widget:
          type: sonarr
          url: http://{{BLUELAB_IP}}:8989
          key: {{SONARR_API_KEY}}

- Audio:
    - Navidrome:
        icon: navidrome.png
        href: http://{{BLUELAB_IP}}:4533
        description: Music streaming server
```

## Installation and Deployment Scripts

### Main Installation Script

```bash
#!/bin/bash
# scripts/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

main() {
    log "Starting BlueLab Stacks installation"
    
    # System requirements check
    check_requirements
    
    # Create directory structure
    setup_directories
    
    # Configure environment
    setup_environment
    
    # Install monitoring stack (mandatory)
    deploy_stack "monitoring"
    
    # Interactive stack selection
    select_additional_stacks
    
    # Setup homepage
    configure_homepage
    
    log "BlueLab Stacks installation completed!"
    show_access_info
}

check_requirements() {
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        log "ERROR: Docker is required but not installed"
        exit 1
    fi
    
    # Check for Docker Compose
    if ! docker compose version &> /dev/null; then
        log "ERROR: Docker Compose is required but not found"
        exit 1
    fi
    
    log "Requirements check passed"
}
```

### Stack Deployment Manager

```bash
#!/bin/bash
# scripts/deploy-stack.sh

deploy_stack() {
    local stack_name=$1
    local stack_dir="$PROJECT_DIR/stacks/$stack_name"
    local config_dir="/var/lib/bluelab/stacks/$stack_name"
    
    log "Deploying $stack_name stack"
    
    # Validate stack exists
    if [[ ! -d "$stack_dir" ]]; then
        log "ERROR: Stack $stack_name not found"
        return 1
    fi
    
    # Create configuration directory
    mkdir -p "$config_dir"
    
    # Process templates
    process_templates "$stack_dir" "$config_dir"
    
    # Deploy stack
    cd "$config_dir"
    docker compose up -d
    
    # Verify deployment
    verify_stack_health "$stack_name"
    
    log "Stack $stack_name deployed successfully"
}
```

## Advanced Features

### Port Management System

```bash
# Automatic port conflict resolution
find_available_port() {
    local preferred_port=$1
    local current_port=$preferred_port
    
    while port_in_use "$current_port"; do
        current_port=$((current_port + 1))
    done
    
    echo "$current_port"
}

port_in_use() {
    local port=$1
    
    # Check if port is in use by system
    if ss -tuln | grep -q ":${port} "; then
        return 0
    fi
    
    # Check if port is used by other stacks
    if find /var/lib/bluelab/stacks -name "docker-compose.yml" -exec grep -q "${port}:" {} \; 2>/dev/null; then
        return 0
    fi
    
    return 1
}
```

### Health Monitoring

```bash
# Comprehensive health checks
check_stack_health() {
    local stack_name=$1
    local health_score=0
    
    # Check if containers are running
    local containers=$(docker compose -f "/var/lib/bluelab/stacks/$stack_name/docker-compose.yml" ps -q)
    
    for container in $containers; do
        if docker inspect "$container" | jq -r '.[0].State.Health.Status' | grep -q "healthy\|starting"; then
            health_score=$((health_score + 1))
        fi
    done
    
    # Return success if majority of containers are healthy
    local total_containers=$(echo "$containers" | wc -l)
    local healthy_threshold=$((total_containers / 2))
    
    [[ $health_score -gt $healthy_threshold ]]
}
```

## Testing Strategy

### Development Environment Setup

1. **Base VM Requirements**:
   - Standard Bluefin or Ubuntu/Fedora
   - Docker and Docker Compose installed
   - 8GB RAM minimum
   - 100GB+ storage

2. **Testing Approach**:
   ```bash
   # Clone BlueLab-Stacks repository
   git clone https://github.com/JungleJM/BlueLab-Stacks.git
   cd BlueLab-Stacks
   
   # Run installation script
   ./scripts/install.sh
   
   # Test individual stack deployment
   ./scripts/deploy-stack.sh media
   
   # Verify services
   curl http://localhost:3000  # Homepage
   curl http://localhost:5001  # Dockge
   ```

## Integration with BlueLab ISO

### Future Integration Plan

Once BlueLab Stacks is complete and tested:

1. **Repository Integration**: Add BlueLab-Stacks as a git submodule to the main BlueLab repository
2. **First-Boot Enhancement**: Modify first-boot script to clone/download BlueLab-Stacks
3. **Unified Experience**: Combine ISO automation with stack deployment
4. **Update Mechanism**: Implement auto-updates from BlueLab-Stacks repository

```bash
# Enhanced first-boot script integration
if [ "$BLUELAB_AUTO_DOWNLOAD" = "true" ]; then
    log_info "Downloading latest BlueLab Stacks"
    git clone https://github.com/JungleJM/BlueLab-Stacks.git /opt/bluelab-stacks
    cd /opt/bluelab-stacks
    ./scripts/install.sh --automated --stacks="$BLUELAB_STACK_SELECTION"
fi
```

## Success Criteria

### Phase 2 Completion Requirements

- [ ] All 8 stacks deployable via script
- [ ] Dockge providing visual stack management
- [ ] Homepage auto-discovering and displaying services
- [ ] Port conflict resolution working automatically
- [ ] Health monitoring reporting service status
- [ ] Installation script working on clean Linux systems
- [ ] Documentation complete and tested
- [ ] Integration plan defined for BlueLab ISO

### Performance Targets

- **Installation Time**: < 30 minutes for full stack deployment
- **Resource Usage**: < 4GB RAM for monitoring + 2 additional stacks
- **Service Startup**: All services healthy within 5 minutes
- **Homepage Load Time**: < 3 seconds to load full dashboard

## Risk Mitigation

### Technical Risks

1. **Port Conflicts**: Automatic port assignment system
2. **Resource Exhaustion**: Resource monitoring and limits
3. **Service Dependencies**: Robust dependency resolution
4. **Data Loss**: Automatic configuration backups

### Development Risks

1. **Scope Creep**: Strict adherence to Phase 2 requirements
2. **Testing Complexity**: Automated testing on multiple distributions
3. **Documentation Drift**: Documentation-driven development

## Next Steps

1. **Create BlueLab-Stacks Repository**
2. **Implement Monitoring Stack Enhancement**
3. **Develop Media Stack (highest user value)**
4. **Add Dockge Integration**
5. **Implement Dynamic Homepage**
6. **Add Remaining Stacks**
7. **Create Installation Scripts**
8. **Comprehensive Testing**
9. **Integration Planning**

This Phase 2 plan provides a clear roadmap for developing BlueLab Stacks as a standalone system that can later be integrated with the BlueLab ISO once Phase 1 issues are resolved.
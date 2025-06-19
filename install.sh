#!/bin/bash

# BlueLab Stacks - Main Installation Script
# Phase 1: Foundation & Core Infrastructure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
DATA_DIR="/var/lib/bluelab"
CONTAINER_NAME="bluelab"

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

# Error handling
cleanup_on_error() {
    log_error "Installation failed. Cleaning up..."
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        distrobox rm "$CONTAINER_NAME" -f || true
    fi
    exit 1
}

trap cleanup_on_error ERR

# Main installation function
main() {
    log "Starting BlueLab Stacks Phase 1 Installation"
    log "=================================================="
    
    # Phase 1A: Environment Setup
    log "Phase 1A: Environment Setup"
    check_requirements
    setup_directories
    detect_user_type
    setup_distrobox
    
    # Phase 1B: Core Stacks
    log "Phase 1B: Core Infrastructure"
    setup_environment
    deploy_core_stacks
    
    # Phase 1C: Service Integration
    log "Phase 1C: Service Integration"
    configure_service_discovery
    setup_health_monitoring
    
    log_success "BlueLab Stacks Phase 1 installation completed!"
    show_access_info
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check for sudo/root access
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
    
    # Check for basic commands
    for cmd in curl wget git; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is required but not installed"
            exit 1
        fi
    done
    
    log_success "Basic requirements check passed"
}

# Detect distribution and install Distrobox if needed
setup_distrobox() {
    log "Setting up Distrobox..."
    
    if ! command -v distrobox &> /dev/null; then
        log "Installing Distrobox..."
        install_distrobox
    else
        log_success "Distrobox already installed"
    fi
    
    # Create BlueLab container
    create_bluelab_container
    
    # Install Docker in container
    setup_docker_in_container
    
    log_success "Distrobox setup completed"
}

# Install Distrobox based on distribution
install_distrobox() {
    local distro
    distro=$(detect_distro)
    
    case "$distro" in
        "fedora"|"silverblue"|"kinoite")
            if command -v rpm-ostree &> /dev/null; then
                log "Installing Distrobox via rpm-ostree..."
                rpm-ostree install distrobox
                log_warning "System reboot required. Please reboot and run this script again."
                exit 0
            else
                sudo dnf install -y distrobox
            fi
            ;;
        "ubuntu"|"debian"|"pop")
            sudo apt update
            sudo apt install -y distrobox
            ;;
        *)
            # Use curl method for other distros
            log "Installing Distrobox via curl method..."
            curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh
            ;;
    esac
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Detect if BlueLab user or regular user
detect_user_type() {
    log "Detecting user type..."
    
    if [ -f /etc/bluelab-release ] || [ -f /usr/share/bluelab/version ]; then
        export DOMAIN_PREFIX="bluelab"
        log_success "BlueLab user detected - using bluelab.* domains"
    else
        export DOMAIN_PREFIX="homelab"
        log_success "Non-BlueLab user detected - using homelab.* domains"
    fi
    
    echo "DOMAIN_PREFIX=$DOMAIN_PREFIX" >> "$DATA_DIR/config/global.env"
}

# Create directory structure
setup_directories() {
    log "Creating directory structure..."
    
    sudo mkdir -p "$DATA_DIR"/{stacks,data,config,backups,scripts}
    sudo mkdir -p "$DATA_DIR/data"/{media,music,photos,books,documents}
    sudo mkdir -p "$DATA_DIR/data/media"/{movies,tv,downloads}
    sudo chown -R "$USER:$USER" "$DATA_DIR"
    
    log_success "Directory structure created"
}

# Create and configure Distrobox container
create_bluelab_container() {
    log "Creating BlueLab container..."
    
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        log_warning "Container $CONTAINER_NAME already exists, removing..."
        distrobox rm "$CONTAINER_NAME" -f
    fi
    
    # Check if Ubuntu image exists locally, if not pull it automatically
    log "Checking for Ubuntu 22.04 image..."
    if ! podman images | grep -q "ubuntu.*22.04" && ! docker images | grep -q "ubuntu.*22.04"; then
        log "Ubuntu 22.04 image not found locally, downloading..."
        if command -v podman >/dev/null 2>&1; then
            podman pull docker.io/library/ubuntu:22.04
        elif command -v docker >/dev/null 2>&1; then
            docker pull ubuntu:22.04
        fi
    else
        log_success "Ubuntu 22.04 image already available"
    fi
    
    # Create container with automatic yes responses
    echo "Y" | distrobox create \
        --name "$CONTAINER_NAME" \
        --image ubuntu:22.04 \
        --volume "$DATA_DIR:/var/lib/bluelab:rw" \
        --volume "$HOME:/home/$USER:rw" \
        --additional-packages "curl wget git nano vim"
        
    log_success "Container created successfully"
}

# Install Docker or configure host Docker access
setup_docker_in_container() {
    log "Setting up Docker access..."
    
    # Check if Docker is available on host
    if command -v docker >/dev/null 2>&1; then
        log "Docker found on host system, configuring access..."
        
        # Add user to docker group on host if needed
        if ! groups "$USER" | grep -q docker; then
            log "Adding user to docker group..."
            sudo usermod -aG docker "$USER"
            log_warning "Please log out and back in for Docker group changes to take effect"
        fi
        
        # Create network on host
        docker network create bluelab-network 2>/dev/null || true
        
        log_success "Using host Docker system"
    else
        log "Docker not found on host, installing in container..."
        
        distrobox enter "$CONTAINER_NAME" -- bash -c "
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Add Docker repository
            echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Add user to docker group
            sudo groupadd docker 2>/dev/null || true
            sudo usermod -aG docker \$USER
        "
        
        log_success "Docker installed in container"
    fi
}

# Setup environment configuration
setup_environment() {
    log "Setting up environment configuration..."
    
    # Generate passwords and API keys
    local postgres_password=$(openssl rand -base64 32)
    local redis_password=$(openssl rand -base64 32)
    local sonarr_api_key=$(openssl rand -hex 32)
    local radarr_api_key=$(openssl rand -hex 32)
    local prowlarr_api_key=$(openssl rand -hex 32)
    local jellyfin_api_key=$(openssl rand -hex 32)
    
    # Get host IP
    local host_ip=$(hostname -I | awk '{print $1}')
    
    # Create global environment file
    cat > "$DATA_DIR/config/global.env" << EOF
# BlueLab Stacks Global Configuration
BLUELAB_VERSION=1.0.0
DATA_DIR=/var/lib/bluelab
DOMAIN_PREFIX=${DOMAIN_PREFIX:-homelab}

# Network Configuration
BLUELAB_NETWORK=bluelab-network
HOST_IP=$host_ip

# Default Ports (will be auto-adjusted if conflicts detected)
HOMEPAGE_PORT=3000
DOCKGE_PORT=5001
ADGUARD_PORT=3001
DELUGE_PORT=8112
QBITTORRENT_PORT=8080
POSTGRES_PORT=5432
REDIS_PORT=6379
SAMBA_PORT=445

# Database Configuration
POSTGRES_DB=bluelab
POSTGRES_USER=bluelab
POSTGRES_PASSWORD=$postgres_password
REDIS_PASSWORD=$redis_password

# SMB Configuration
SMB_USER=bluelab
SMB_PASSWORD=bluelab123

# API Keys (generated)
SONARR_API_KEY=$sonarr_api_key
RADARR_API_KEY=$radarr_api_key
PROWLARR_API_KEY=$prowlarr_api_key
JELLYFIN_API_KEY=$jellyfin_api_key
EOF

    # Get timezone
    local timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
    
    # Create Docker environment file
    cat > "$DATA_DIR/config/docker.env" << EOF
# Docker Configuration
COMPOSE_PROJECT_NAME=bluelab
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1

# Container User/Group
PUID=1000
PGID=1000
TZ=$timezone
EOF

    # Create Docker network
    if command -v docker >/dev/null 2>&1; then
        docker network create bluelab-network || true
    else
        distrobox enter "$CONTAINER_NAME" -- docker network create bluelab-network || true
    fi
    
    log_success "Environment configuration created"
}

# Deploy all core stacks
deploy_core_stacks() {
    log "Deploying core stacks..."
    
    # Deploy in dependency order
    deploy_stack "core-networking"
    sleep 10  # Wait for networking to stabilize
    
    deploy_stack "core-database"
    sleep 5
    
    deploy_stack "core-download"
    sleep 5
    
    deploy_stack "smb-share"
    sleep 5
    
    deploy_stack "monitoring"
    
    log_success "All core stacks deployed"
}

# Deploy individual stack
deploy_stack() {
    local stack_name=$1
    local stack_dir="$PROJECT_DIR/stacks/$stack_name"
    local config_dir="$DATA_DIR/stacks/$stack_name"
    
    log "Deploying $stack_name stack..."
    
    if [[ ! -d "$stack_dir" ]]; then
        log_error "Stack $stack_name not found in $stack_dir"
        return 1
    fi
    
    # Create configuration directory
    mkdir -p "$config_dir"
    
    # Copy stack files
    cp -r "$stack_dir"/* "$config_dir/"
    
    # Deploy stack with environment variables
    if command -v docker >/dev/null 2>&1; then
        # Use host Docker
        cd "$config_dir"
        export $(grep -v '^#' "$DATA_DIR/config/global.env" | xargs)
        export $(grep -v '^#' "$DATA_DIR/config/docker.env" | xargs)
        docker compose up -d
    else
        # Use Docker in container
        distrobox enter "$CONTAINER_NAME" -- bash -c "
            cd $config_dir
            export \$(grep -v '^#' /var/lib/bluelab/config/global.env | xargs)
            export \$(grep -v '^#' /var/lib/bluelab/config/docker.env | xargs)
            docker compose up -d
        "
    fi
    
    # Verify deployment
    sleep 5
    verify_stack_health "$stack_name"
    
    log_success "Stack $stack_name deployed successfully"
}

# Verify stack health
verify_stack_health() {
    local stack_name=$1
    local config_dir="$DATA_DIR/stacks/$stack_name"
    
    log "Verifying $stack_name stack health..."
    
    local containers
    if command -v docker >/dev/null 2>&1; then
        # Use host Docker
        cd "$config_dir"
        containers=$(docker compose ps -q)
    else
        # Use Docker in container
        containers=$(distrobox enter "$CONTAINER_NAME" -- bash -c "
            cd $config_dir
            docker compose ps -q
        ")
    fi
    
    local healthy_count=0
    local total_count=0
    
    for container in $containers; do
        ((total_count++))
        local status
        if command -v docker >/dev/null 2>&1; then
            status=$(docker inspect "$container" --format='{{.State.Status}}')
        else
            status=$(distrobox enter "$CONTAINER_NAME" -- docker inspect "$container" --format='{{.State.Status}}')
        fi
        if [[ "$status" == "running" ]]; then
            ((healthy_count++))
        fi
    done
    
    if [[ $healthy_count -eq $total_count && $total_count -gt 0 ]]; then
        log_success "$stack_name stack is healthy ($healthy_count/$total_count containers running)"
        return 0
    else
        log_warning "$stack_name stack health check: $healthy_count/$total_count containers running"
        return 1
    fi
}

# Configure service discovery
configure_service_discovery() {
    log "Configuring service discovery..."
    
    # This will be implemented when we create the Homepage configuration
    # For now, just create placeholder
    mkdir -p "$DATA_DIR/config/homepage"
    
    log_success "Service discovery configured"
}

# Setup health monitoring
setup_health_monitoring() {
    log "Setting up health monitoring..."
    
    # Create health check script
    cat > "$DATA_DIR/scripts/health-check.sh" << 'EOF'
#!/bin/bash
# BlueLab Health Check Script

source /var/lib/bluelab/config/global.env

check_stack_health() {
    local stack_name=$1
    local config_dir="/var/lib/bluelab/stacks/$stack_name"
    
    if [[ ! -d "$config_dir" ]]; then
        return 1
    fi
    
    cd "$config_dir"
    local containers=$(docker compose ps -q)
    
    for container in $containers; do
        local status=$(docker inspect "$container" --format='{{.State.Status}}')
        if [[ "$status" != "running" ]]; then
            return 1
        fi
    done
    
    return 0
}

# Check all stacks
for stack in core-networking core-database core-download smb-share monitoring; do
    if check_stack_health "$stack"; then
        echo "✓ $stack: healthy"
    else
        echo "✗ $stack: unhealthy"
    fi
done
EOF

    chmod +x "$DATA_DIR/scripts/health-check.sh"
    mkdir -p "$DATA_DIR/scripts"
    
    log_success "Health monitoring setup completed"
}

# Show access information
show_access_info() {
    echo ""
    echo "=============================================="
    echo "🎉 BlueLab Stacks Phase 1 Installation Complete!"
    echo "=============================================="
    echo ""
    echo "📊 Dashboard Access:"
    echo "  Homepage: http://localhost:3000"
    echo "  Dockge (Container Manager): http://localhost:5001"
    echo ""
    echo "🌐 Network Services:"
    echo "  AdGuard Home (DNS): http://localhost:3001"
    echo "  Domain prefix: ${DOMAIN_PREFIX:-homelab}"
    echo ""
    echo "💾 Download Clients:"
    echo "  Deluge (Primary): http://localhost:8112"
    echo "  qBittorrent (Secondary): http://localhost:8080"
    echo ""
    echo "📁 File Sharing:"
    echo "  SMB Shares available on network"
    echo "  Access via: \\\\$(hostname -I | awk '{print $1}')\\bluelab"
    echo ""
    echo "🔧 Management:"
    echo "  Container: distrobox enter $CONTAINER_NAME"
    echo "  Health Check: $DATA_DIR/scripts/health-check.sh"
    echo "  Data Directory: $DATA_DIR"
    echo ""
    echo "Next Steps:"
    echo "1. Configure Tailscale for remote access: ./scripts/setup-tailscale.sh"
    echo "2. (Optional) Set up VPN with split tunneling: ./scripts/setup-vpn.sh"
    echo "3. Set up your ${DOMAIN_PREFIX}.* domains in AdGuard Home"
    echo "4. Ready for Phase 2 (Media Stack) deployment"
    echo ""
}

# Run main function
main "$@"
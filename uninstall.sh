#!/bin/bash

# BlueLab Stacks - Uninstall Script
# Removes all BlueLab components and restores system to pre-install state

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
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

main() {
    log "Starting BlueLab Stacks Uninstall"
    log "=================================="
    
    # Stop and remove all containers
    stop_containers
    
    # Remove Distrobox container
    remove_distrobox_container
    
    # Remove Docker network
    remove_docker_network
    
    # Remove data directory (with confirmation)
    remove_data_directory
    
    log_success "BlueLab Stacks uninstall completed!"
    log "System restored to pre-install state"
}

stop_containers() {
    log "Stopping and removing BlueLab containers..."
    
    # Stop any running BlueLab containers
    local containers
    containers=$(docker ps -q --filter "name=bluelab-*" 2>/dev/null || true)
    
    if [[ -n "$containers" ]]; then
        log "Stopping running containers..."
        docker stop $containers
        docker rm $containers
        log_success "Containers stopped and removed"
    else
        log "No running BlueLab containers found"
    fi
    
    # Remove images if requested
    read -p "Remove BlueLab Docker images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local images
        images=$(docker images -q --filter "reference=*bluelab*" 2>/dev/null || true)
        if [[ -n "$images" ]]; then
            docker rmi $images || true
            log_success "Docker images removed"
        fi
    fi
}

remove_distrobox_container() {
    log "Removing Distrobox container..."
    
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        distrobox rm "$CONTAINER_NAME" -f
        log_success "Distrobox container removed"
    else
        log "No BlueLab Distrobox container found"
    fi
}

remove_docker_network() {
    log "Removing Docker network..."
    
    if docker network ls | grep -q "bluelab-network"; then
        docker network rm bluelab-network || true
        log_success "Docker network removed"
    else
        log "No BlueLab Docker network found"
    fi
}

remove_data_directory() {
    log "Checking data directory..."
    
    if [[ -d "$DATA_DIR" ]]; then
        log_warning "This will remove ALL BlueLab data including:"
        log_warning "  - Configuration files"
        log_warning "  - Downloaded media"
        log_warning "  - Database data"
        log_warning "  - Backups"
        echo
        read -p "Are you sure you want to remove $DATA_DIR? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo rm -rf "$DATA_DIR"
            log_success "Data directory removed"
        else
            log_warning "Data directory preserved at $DATA_DIR"
            log "You can manually remove it later with: sudo rm -rf $DATA_DIR"
        fi
    else
        log "No BlueLab data directory found"
    fi
}

# Run main function
main "$@"
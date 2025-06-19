#!/bin/bash

# BlueLab Stacks - Deluge Auto-Configuration Script
# Sets up Deluge with default credentials and optimal settings

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DATA_DIR="/var/lib/bluelab"
CONTAINER_NAME="bluelab-deluge"

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

# Wait for Deluge to be ready
wait_for_deluge() {
    local max_attempts=30
    local attempt=1
    
    log "Waiting for Deluge to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8112/ | grep -q "200"; then
            log_success "Deluge is ready"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts - Deluge not ready yet..."
        sleep 5
        ((attempt++))
    done
    
    log_error "Deluge failed to become ready after $max_attempts attempts"
    return 1
}

# Configure Deluge settings
configure_deluge() {
    log "Configuring Deluge settings..."
    
    # Default password is 'deluge' - we'll set it to something more secure
    local deluge_password="bluelab123"
    
    # Create configuration directory if it doesn't exist
    local config_dir="$DATA_DIR/stacks/core-download/deluge-config"
    mkdir -p "$config_dir"
    
    # Create Deluge daemon configuration
    cat > "$config_dir/core.conf" << EOF
{
    "file": 1,
    "format": 1
}{
    "add_paused": false,
    "allow_remote": true,
    "auto_managed": true,
    "auto_manage_prefer_seeds": false,
    "cache_expiry": 60,
    "cache_size": 512,
    "copy_torrent_file": true,
    "daemon_port": 58846,
    "del_copy_torrent_file": false,
    "download_location": "/data/downloads/complete",
    "enabled_plugins": ["Label"],
    "enc_in_policy": 1,
    "enc_level": 2,
    "enc_out_policy": 1,
    "geoip_db_location": "/usr/share/GeoIP/GeoIP.dat",
    "ignore_limits_on_local_network": true,
    "incoming_port": 58946,
    "listen_interface": "",
    "listen_ports": [58946, 58946],
    "listen_random_port": false,
    "listen_reuse_port": true,
    "listen_use_sys_port": false,
    "max_active_downloading": 8,
    "max_active_limit": 15,
    "max_active_seeding": 5,
    "max_connections_global": 200,
    "max_connections_per_torrent": 50,
    "max_download_speed": -1.0,
    "max_download_speed_per_torrent": -1,
    "max_half_open_connections": 50,
    "max_upload_slots_global": 4,
    "max_upload_slots_per_torrent": -1,
    "max_upload_speed": -1.0,
    "max_upload_speed_per_torrent": -1,
    "move_completed": true,
    "move_completed_path": "/data/downloads/complete",
    "natpmp": true,
    "new_release_check": false,
    "peer_tos": "0x00",
    "plugins_location": "/config/plugins",
    "pre_allocate_storage": false,
    "prioritize_first_last_pieces": true,
    "queue_new_to_top": false,
    "random_outgoing_ports": true,
    "random_port": true,
    "rate_limit_ip_overhead": true,
    "remove_seed_at_ratio": false,
    "seed_time_limit": 180,
    "seed_time_ratio_limit": 7.0,
    "send_info": false,
    "sequential_download": false,
    "share_ratio_limit": 2.0,
    "stop_seed_at_ratio": false,
    "stop_seed_ratio": 2.0,
    "torrentfiles_location": "/data/downloads/torrents",
    "upnp": true,
    "utpex": true
}
EOF

    # Create web UI configuration
    cat > "$config_dir/web.conf" << EOF
{
    "file": 1,
    "format": 1
}{
    "base": "/",
    "cert": "ssl/daemon.cert",
    "default_daemon": "127.0.0.1:58846",
    "enabled_plugins": [],
    "https": false,
    "interface": "0.0.0.0",
    "language": "",
    "pkey": "ssl/daemon.pkey",
    "port": 8112,
    "pwd_md5": "$(echo -n "$deluge_password" | md5sum | cut -d' ' -f1)",
    "pwd_salt": "$(openssl rand -hex 32)",
    "session_timeout": 3600,
    "sessions": {},
    "show_session_speed": false,
    "show_sidebar": true,
    "sidebar_multiple_filters": true,
    "sidebar_show_zero": false,
    "theme": "gray"
}
EOF

    # Create auth file for daemon
    cat > "$config_dir/auth" << EOF
localclient:$deluge_password:10
admin:$deluge_password:10
EOF

    # Set proper permissions
    chmod 600 "$config_dir/auth"
    
    log_success "Deluge configuration created"
}

# Configure Deluge Labels plugin
configure_deluge_labels() {
    log "Configuring Deluge Labels plugin..."
    
    local config_dir="$DATA_DIR/stacks/core-download/deluge-config"
    
    # Create labels configuration
    cat > "$config_dir/label.conf" << EOF
{
    "file": 1,
    "format": 1
}{
    "torrent_labels": {
        "movies": {
            "apply_max_connections": false,
            "apply_max_download_speed": false,
            "apply_max_upload_slots": false,
            "apply_max_upload_speed": false,
            "apply_queue": false,
            "auto_add": false,
            "auto_add_trackers": [],
            "is_auto_managed": false,
            "max_connections": -1,
            "max_download_speed": -1.0,
            "max_upload_slots": -1,
            "max_upload_speed": -1.0,
            "move_completed": true,
            "move_completed_path": "/data/media/movies",
            "prioritize_first_last": false,
            "queue": false,
            "remove_at_ratio": false,
            "stop_at_ratio": false,
            "stop_ratio": 2.0
        },
        "tv": {
            "apply_max_connections": false,
            "apply_max_download_speed": false,
            "apply_max_upload_slots": false,
            "apply_max_upload_speed": false,
            "apply_queue": false,
            "auto_add": false,
            "auto_add_trackers": [],
            "is_auto_managed": false,
            "max_connections": -1,
            "max_download_speed": -1.0,
            "max_upload_slots": -1,
            "max_upload_speed": -1.0,
            "move_completed": true,
            "move_completed_path": "/data/media/tv",
            "prioritize_first_last": false,
            "queue": false,
            "remove_at_ratio": false,
            "stop_at_ratio": false,
            "stop_ratio": 2.0
        },
        "music": {
            "apply_max_connections": false,
            "apply_max_download_speed": false,
            "apply_max_upload_slots": false,
            "apply_max_upload_speed": false,
            "apply_queue": false,
            "auto_add": false,
            "auto_add_trackers": [],
            "is_auto_managed": false,
            "max_connections": -1,
            "max_download_speed": -1.0,
            "max_upload_slots": -1,
            "max_upload_speed": -1.0,
            "move_completed": true,
            "move_completed_path": "/data/media/music",
            "prioritize_first_last": false,
            "queue": false,
            "remove_at_ratio": false,
            "stop_at_ratio": false,
            "stop_ratio": 2.0
        },
        "books": {
            "apply_max_connections": false,
            "apply_max_download_speed": false,
            "apply_max_upload_slots": false,
            "apply_max_upload_speed": false,
            "apply_queue": false,
            "auto_add": false,
            "auto_add_trackers": [],
            "is_auto_managed": false,
            "max_connections": -1,
            "max_download_speed": -1.0,
            "max_upload_slots": -1,
            "max_upload_speed": -1.0,
            "move_completed": true,
            "move_completed_path": "/data/media/books",
            "prioritize_first_last": false,
            "queue": false,
            "remove_at_ratio": false,
            "stop_at_ratio": false,
            "stop_ratio": 2.0
        }
    }
}
EOF

    log_success "Deluge Labels plugin configured"
}

# Store credentials for other services
store_deluge_credentials() {
    local config_file="$DATA_DIR/config/service-credentials.env"
    
    echo "# Deluge Credentials" >> "$config_file"
    echo "DELUGE_PASSWORD=bluelab123" >> "$config_file"
    echo "DELUGE_WEB_PASSWORD=bluelab123" >> "$config_file"
    echo "" >> "$config_file"
    
    log_success "Deluge credentials stored"
}

# Main configuration function
main() {
    log "Starting Deluge auto-configuration..."
    
    # Wait for container to be ready
    wait_for_deluge
    
    # Configure Deluge
    configure_deluge
    configure_deluge_labels
    store_deluge_credentials
    
    # Restart container to apply configuration
    log "Restarting Deluge container to apply configuration..."
    docker restart "$CONTAINER_NAME"
    
    # Wait for it to come back up
    sleep 10
    wait_for_deluge
    
    log_success "Deluge auto-configuration completed!"
    echo ""
    echo "Deluge Access:"
    echo "  URL: http://localhost:8112"
    echo "  Password: bluelab123"
    echo ""
    echo "Pre-configured Labels:"
    echo "  - movies (saves to: /data/media/movies)"
    echo "  - tv (saves to: /data/media/tv)"
    echo "  - music (saves to: /data/media/music)"
    echo "  - books (saves to: /data/media/books)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
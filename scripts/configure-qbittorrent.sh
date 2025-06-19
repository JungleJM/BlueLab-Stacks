#!/bin/bash

# BlueLab Stacks - qBittorrent Auto-Configuration Script
# Sets up qBittorrent with default credentials and optimal settings

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DATA_DIR="/var/lib/bluelab"
CONTAINER_NAME="bluelab-qbittorrent"

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

# Wait for qBittorrent to be ready
wait_for_qbittorrent() {
    local max_attempts=30
    local attempt=1
    
    log "Waiting for qBittorrent to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200"; then
            log_success "qBittorrent is ready"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts - qBittorrent not ready yet..."
        sleep 5
        ((attempt++))
    done
    
    log_error "qBittorrent failed to become ready after $max_attempts attempts"
    return 1
}

# Generate password hash for qBittorrent
generate_password_hash() {
    local password="$1"
    # qBittorrent uses PBKDF2 with SHA256, but for initial setup we can use a simpler method
    # The container will generate the proper hash on first login
    echo -n "$password"
}

# Configure qBittorrent settings
configure_qbittorrent() {
    log "Configuring qBittorrent settings..."
    
    local qb_password="bluelab123"
    local config_dir="$DATA_DIR/stacks/core-download/qbittorrent-config"
    
    # Create configuration directory if it doesn't exist
    mkdir -p "$config_dir/config"
    
    # Create qBittorrent configuration file
    cat > "$config_dir/config/qBittorrent.conf" << EOF
[Application]
FileLogger\Enabled=true
FileLogger\Age=1
FileLogger\DeleteOld=true
FileLogger\Backup=true
FileLogger\MaxSizeBytes=66560

[BitTorrent]
Session\DefaultSavePath=/data/downloads/complete
Session\Port=6881
Session\TempPath=/data/downloads/incomplete
Session\TempPathEnabled=true
Session\UseRandomPort=false
Session\GlobalMaxSeedingMinutes=10080
Session\GlobalMaxRatio=2
Session\GlobalMaxRatioAction=0
Session\AlternativeGlobalDLSpeedLimit=10240
Session\AlternativeGlobalUPSpeedLimit=10240
Session\UseAlternativeGlobalSpeedLimit=false
Session\BTProtocol=Both
Session\CreateTorrentSubfolder=true
Session\DisableAutoTMMByDefault=false
Session\DisableAutoTMMTriggers\CategoryChanged=false
Session\DisableAutoTMMTriggers\CategorySavePathChanged=true
Session\DisableAutoTMMTriggers\DefaultSavePathChanged=true
Session\GlobalMaxConnections=200
Session\GlobalMaxConnectionsPerTorrent=100
Session\GlobalMaxUploads=-1
Session\GlobalMaxUploadsPerTorrent=-1
Session\IgnoreSlowTorrentsForQueueing=false
Session\IncludeOverheadInLimits=false
Session\Interface=
Session\InterfaceAddress=0.0.0.0
Session\InterfaceName=
Session\MaxActiveDownloads=8
Session\MaxActiveTorrents=15
Session\MaxActiveUploads=8
Session\MaxConnections=200
Session\MaxConnectionsPerTorrent=100
Session\MaxRatioAction=0
Session\MaxUploads=-1
Session\MaxUploadsPerTorrent=-1
Session\QueueingSystemEnabled=true
Session\SlowTorrentsDownloadRate=2
Session\SlowTorrentsInactivityTimer=60
Session\SlowTorrentsUploadRate=2

[Core]
AutoDeleteAddedTorrentFile=Never

[Meta]
MigrationVersion=4

[Network]
Cookies=@Invalid()
PortForwardingEnabled=true
Proxy\OnlyForTorrents=false

[Preferences]
Advanced\RecheckOnCompletion=false
Advanced\TrayIconStyle=Normal
Bittorrent\AddTrackers=false
Bittorrent\DHT=true
Bittorrent\Encryption=0
Bittorrent\LSD=true
Bittorrent\MaxConnecs=200
Bittorrent\MaxConnecsPerTorrent=100
Bittorrent\MaxRatio=2
Bittorrent\MaxRatioAction=0
Bittorrent\MaxUploads=-1
Bittorrent\MaxUploadsPerTorrent=-1
Bittorrent\PeX=true
Bittorrent\SameTorrentThrottleMode=Global
Bittorrent\TorrentContentLayout=Subfolder
Bittorrent\uTP=true
Bittorrent\uTP_rate_limited=true
Connection\GlobalDLLimit=0
Connection\GlobalDLLimitAlt=10240
Connection\GlobalUPLimit=0
Connection\GlobalUPLimitAlt=10240
Connection\Interface=
Connection\InterfaceAddress=0.0.0.0
Connection\InterfaceName=
Connection\PortRangeMin=6881
Connection\PortRangeMax=6881
Connection\RandomPort=false
Connection\ResolvePeerCountries=true
Connection\ResolvePeerHostNames=false
Connection\UPnP=true
Downloads\DblClOnTorDl=0
Downloads\DblClOnTorFn=1
Downloads\NewAdditionDialog=false
Downloads\NewAdditionDialogFront=true
Downloads\PreAllocation=false
Downloads\SavePath=/data/downloads/complete
Downloads\ScanDirsV2=@Variant(\\0\\0\\0\\x1c\\0\\0\\0\\0)
Downloads\StartInPause=false
Downloads\TempPath=/data/downloads/incomplete
Downloads\TempPathEnabled=true
Downloads\TorrentExportDir=
Downloads\UseIncompleteExtension=false
DynDNS\DomainName=changeme.dyndns.org
DynDNS\Enabled=false
DynDNS\Password=
DynDNS\Service=0
DynDNS\Username=
General\AlternatingRowColors=true
General\CloseToTray=true
General\CloseToTrayNotified=true
General\CustomUIThemePath=
General\ExitConfirm=true
General\HideZeroComboValues=0
General\HideZeroValues=false
General\Locale=
General\MinimizeToTray=false
General\NoSplashScreen=true
General\PreventFromSuspendWhenDownloading=false
General\PreventFromSuspendWhenSeeding=false
General\StartMinimized=false
General\SystrayEnabled=true
General\UseCustomUITheme=false
MailNotification\email=
MailNotification\enabled=false
MailNotification\password=
MailNotification\req_auth=true
MailNotification\req_ssl=false
MailNotification\sender=qBittorrent_notification@example.com
MailNotification\smtp_server=smtp.changeme.com
MailNotification\username=
Scheduler\days=EveryDay
Scheduler\end_time=@Variant(\\0\\0\\0\\xf\\x4J\\xa2\\0)
Scheduler\start_time=@Variant(\\0\\0\\0\\xf\\x1b\\xef\\x80)
Search\SearchEnabled=true
WebUI\Address=*
WebUI\AlternativeUIEnabled=false
WebUI\AuthSubnetWhitelist=@Invalid()
WebUI\AuthSubnetWhitelistEnabled=false
WebUI\BanDuration=3600
WebUI\CSRFProtection=true
WebUI\ClickjackingProtection=true
WebUI\CustomHTTPHeaders=
WebUI\CustomHTTPHeadersEnabled=false
WebUI\HTTPS\\CertificatePath=
WebUI\HTTPS\\Enabled=false
WebUI\HTTPS\\KeyPath=
WebUI\HostHeaderValidation=true
WebUI\LocalHostAuth=false
WebUI\MaxAuthenticationFailCount=5
WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUwfENgyMTDTciHbu1Q=:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR2gYrBBY5GUDp2as6UsZorZmPvOkd+1O2kWe1z+i6D6DYD2dL1yLj6w==)"
WebUI\Port=8080
WebUI\RootFolder=
WebUI\SecureCookie=true
WebUI\ServerDomains=*
WebUI\SessionTimeout=3600
WebUI\UseUPnP=false
WebUI\Username=admin
EOF

    log_success "qBittorrent configuration created"
}

# Configure qBittorrent categories for media organization
configure_qbittorrent_categories() {
    log "Configuring qBittorrent categories..."
    
    local config_dir="$DATA_DIR/stacks/core-download/qbittorrent-config"
    
    # Create categories configuration
    mkdir -p "$config_dir/config"
    cat > "$config_dir/config/categories.json" << EOF
{
    "movies": {
        "savePath": "/data/media/movies"
    },
    "tv": {
        "savePath": "/data/media/tv"
    },
    "music": {
        "savePath": "/data/media/music"
    },
    "books": {
        "savePath": "/data/media/books"
    },
    "software": {
        "savePath": "/data/downloads/software"
    }
}
EOF

    log_success "qBittorrent categories configured"
}

# Store credentials for other services
store_qbittorrent_credentials() {
    local config_file="$DATA_DIR/config/service-credentials.env"
    
    echo "# qBittorrent Credentials" >> "$config_file"
    echo "QBITTORRENT_USERNAME=admin" >> "$config_file"
    echo "QBITTORRENT_PASSWORD=bluelab123" >> "$config_file"
    echo "QBITTORRENT_URL=http://localhost:8080" >> "$config_file"
    echo "" >> "$config_file"
    
    log_success "qBittorrent credentials stored"
}

# Configure qBittorrent via API after initial setup
configure_via_api() {
    log "Configuring qBittorrent via API..."
    
    local cookie_jar="/tmp/qb_cookies.txt"
    local login_url="http://localhost:8080/api/v2/auth/login"
    local base_url="http://localhost:8080/api/v2"
    
    # Login to get session cookie
    curl -s -c "$cookie_jar" -d "username=admin&password=bluelab123" "$login_url" > /dev/null
    
    # Set download path
    curl -s -b "$cookie_jar" -d "json=%7B%22save_path%22%3A%22%2Fdata%2Fdownloads%2Fcomplete%22%7D" "$base_url/app/setPreferences" > /dev/null
    
    # Set incomplete downloads path
    curl -s -b "$cookie_jar" -d "json=%7B%22temp_path_enabled%22%3Atrue%2C%22temp_path%22%3A%22%2Fdata%2Fdownloads%2Fincomplete%22%7D" "$base_url/app/setPreferences" > /dev/null
    
    # Create categories
    curl -s -b "$cookie_jar" -d "category=movies&savePath=%2Fdata%2Fmedia%2Fmovies" "$base_url/torrents/createCategory" > /dev/null
    curl -s -b "$cookie_jar" -d "category=tv&savePath=%2Fdata%2Fmedia%2Ftv" "$base_url/torrents/createCategory" > /dev/null
    curl -s -b "$cookie_jar" -d "category=music&savePath=%2Fdata%2Fmedia%2Fmusic" "$base_url/torrents/createCategory" > /dev/null
    curl -s -b "$cookie_jar" -d "category=books&savePath=%2Fdata%2Fmedia%2Fbooks" "$base_url/torrents/createCategory" > /dev/null
    
    # Clean up
    rm -f "$cookie_jar"
    
    log_success "qBittorrent API configuration completed"
}

# Main configuration function
main() {
    log "Starting qBittorrent auto-configuration..."
    
    # Wait for container to be ready
    wait_for_qbittorrent
    
    # Configure qBittorrent
    configure_qbittorrent
    configure_qbittorrent_categories
    store_qbittorrent_credentials
    
    # Restart container to apply configuration
    log "Restarting qBittorrent container to apply configuration..."
    docker restart "$CONTAINER_NAME"
    
    # Wait for it to come back up and configure via API
    sleep 15
    wait_for_qbittorrent
    sleep 5  # Give it a bit more time for API to be ready
    
    # Configure via API
    configure_via_api
    
    log_success "qBittorrent auto-configuration completed!"
    echo ""
    echo "qBittorrent Access:"
    echo "  URL: http://localhost:8080"
    echo "  Username: admin"
    echo "  Password: bluelab123"
    echo ""
    echo "Pre-configured Categories:"
    echo "  - movies (saves to: /data/media/movies)"
    echo "  - tv (saves to: /data/media/tv)"
    echo "  - music (saves to: /data/media/music)"
    echo "  - books (saves to: /data/media/books)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
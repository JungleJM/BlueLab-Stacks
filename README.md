# BlueLab Stacks

A comprehensive homelab automation system that transforms complex self-hosting infrastructure into a consumer-grade experience.

## Quick Start

### One-Command Installation

```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/JungleJM/BlueLab-Stacks/main/install.sh | bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/JungleJM/BlueLab-Stacks.git
cd BlueLab-Stacks

# Run the installer
chmod +x install.sh
./install.sh
```

## What Gets Installed (Phase 1)

### Core Infrastructure
- **Distrobox Container**: Ubuntu 22.04 LTS environment for maximum compatibility
- **Docker & Docker Compose**: Container runtime and orchestration
- **Network Stack**: Tailscale VPN + AdGuard Home DNS with smart domain routing
- **Optional VPN**: WireGuard VPN with split tunneling support

### File Sharing
- **SMB/CIFS Server**: Cross-platform file sharing accessible from any device
- **Automatic Shares**: Pre-configured shares for media, downloads, photos, music, books, documents

### Download Management  
- **Deluge**: Primary torrent client with Labels plugin auto-configured
- **qBittorrent**: Secondary torrent client
- **FileBot**: Automated file organization and naming

### Database Services
- **PostgreSQL**: Primary database for applications
- **Redis**: Caching and session storage
- **Automated Backups**: Daily database backups with retention

### Monitoring & Management
- **Homepage Dashboard**: Beautiful dashboard with automatic service discovery
- **Dockge**: Visual Docker Compose stack manager
- **Watchtower**: Automated container updates
- **Health Monitoring**: Service health checks and alerting

## Smart Domain Routing

The system automatically detects your environment and configures appropriate domains:

**BlueLab Users** (custom ISO):
- `bluelab.movies` → Radarr (when Phase 2 is installed)
- `bluelab.tv` → Sonarr
- `bluelab.music` → Navidrome
- `bluelab.photos` → Immich

**Regular Linux Users**:
- `homelab.movies` → Radarr
- `homelab.tv` → Sonarr  
- `homelab.music` → Navidrome
- `homelab.photos` → Immich

## Access Your Services

After installation, access your services at:

- **Dashboard**: http://localhost:3000
- **Container Manager**: http://localhost:5001
- **DNS Server**: http://localhost:3001
- **Downloads**: http://localhost:8112 (Deluge), http://localhost:8080 (qBittorrent)
- **File Shares**: `\\YOUR_IP\bluelab` (Windows) or `smb://YOUR_IP/bluelab` (Mac/Linux)

## VPN Setup (Optional)

BlueLab Stacks supports WireGuard VPN with split tunneling, allowing you to route your internet traffic through a VPN while keeping Tailscale and local network traffic direct.

### Quick VPN Setup

```bash
# Run the VPN setup script
./scripts/setup-vpn.sh
```

### VPN Options

#### Free VPN: ProtonVPN
- **No data limits**
- **Strong privacy protection** (Switzerland-based)
- **3 server locations** (Japan, Netherlands, US)
- **Setup**: [account.protonvpn.com/signup](https://account.protonvpn.com/signup)

#### Paid VPN: AirVPN  
- **Excellent privacy policies** (Italy-based, no logs)
- **200+ servers worldwide**
- **Port forwarding support**
- **Starting at €4.50/month**
- **Setup**: [airvpn.org](https://airvpn.org)

### How Split Tunneling Works

```
Internet Traffic → VPN Server → Internet
Tailscale Traffic → Direct Connection
Local Network → Direct Connection
Your Services → Accessible via Tailscale IP
```

### VPN Management Commands

```bash
# Check VPN status
sudo wg show

# Start VPN
sudo wg-quick up wg0

# Stop VPN  
sudo wg-quick down wg0

# Check both VPN and Tailscale status
./scripts/setup-vpn.sh  # Choose option 5
```

## System Requirements

### Minimum Requirements
- 8GB RAM
- 100GB available storage
- Any modern Linux distribution
- Internet connection for initial setup

### Recommended Requirements
- 16GB RAM
- 500GB+ available storage
- SSD storage for better performance

### Supported Distributions
- Ubuntu 20.04+
- Fedora 35+
- Fedora Silverblue/Kinoite
- Debian 11+
- Pop!_OS 20.04+
- Most other systemd-based distributions

## Architecture

BlueLab Stacks uses a **Distrobox-first** approach:

```
Host Linux System (Any Distribution)
├── Distrobox Container (Ubuntu 22.04 LTS)
│   ├── Docker Engine
│   ├── All BlueLab Services
│   └── Service Management
└── Persistent Data (/var/lib/bluelab)
    ├── Configuration
    ├── User Data
    └── Backups
```

**Benefits**:
- Works on any Linux distribution (including immutable ones)
- Complete isolation from host system
- Easy removal without affecting host
- Consistent environment regardless of host distro

## Data Locations

All data is stored in `/var/lib/bluelab/`:

```
/var/lib/bluelab/
├── stacks/          # Service configurations
├── data/            # User data
│   ├── media/       # Movies, TV shows, downloads
│   ├── music/       # Music library
│   ├── photos/      # Photo storage
│   ├── books/       # Book library
│   └── documents/   # Document storage
├── config/          # Global configuration
└── backups/         # Automated backups
```

## Uninstallation

To completely remove BlueLab Stacks:

```bash
# Stop all services
distrobox enter bluelab -- docker compose -f /var/lib/bluelab/stacks/*/docker-compose.yml down

# Remove the container
distrobox rm bluelab -f

# Remove data (optional - you may want to keep your media files)
sudo rm -rf /var/lib/bluelab
```

## Troubleshooting

### Check System Status
```bash
# Enter the BlueLab container
distrobox enter bluelab

# Check service status
docker ps

# View logs
docker compose -f /var/lib/bluelab/stacks/monitoring/docker-compose.yml logs

# Run health check
/var/lib/bluelab/scripts/health-check.sh
```

### Common Issues

**Installation fails on immutable distros**: System will prompt for reboot if Distrobox needs to be installed via rpm-ostree.

**Services not starting**: Check Docker daemon status in container: `distrobox enter bluelab -- systemctl status docker`

**Can't access services**: Verify firewall settings allow traffic on required ports.

**SMB shares not accessible**: Ensure SMB/CIFS client is installed on client devices.

## Next Steps (Future Phases)

This installer provides Phase 1 (Foundation). Future phases will add:

- **Phase 2**: Complete media stack (Jellyfin, Sonarr, Radarr, etc.)
- **Phase 3**: User experience improvements and photo management
- **Phase 4**: Extended functionality (audio, books, productivity, gaming)

## Support

- **Documentation**: See `Docs/` directory for detailed architecture and planning
- **Issues**: Report bugs and request features via GitHub Issues
- **Community**: Join the BlueLab community for support and discussion

## License

This project is open source and available under the MIT License.

---

**Built with ❤️ for the self-hosting community**
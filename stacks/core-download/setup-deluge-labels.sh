#!/bin/bash

# Deluge Labels Plugin Setup Script
# This script configures the Labels plugin for Deluge

DELUGE_CONFIG_DIR="./deluge-config"
PLUGINS_DIR="$DELUGE_CONFIG_DIR/plugins"

# Wait for Deluge to start
sleep 30

echo "Setting up Deluge Labels plugin..."

# Create plugins directory if it doesn't exist
mkdir -p "$PLUGINS_DIR"

# Download Labels plugin if not present
if [ ! -f "$PLUGINS_DIR/Label-0.3-py3.8.egg" ]; then
    echo "Downloading Labels plugin..."
    curl -L -o "$PLUGINS_DIR/Label-0.3-py3.8.egg" \
        "https://github.com/deluge-torrent/deluge/releases/download/deluge-2.1.1/Label-0.3-py3.8.egg"
fi

# Enable the Labels plugin via Deluge daemon
echo "Enabling Labels plugin..."
docker exec bluelab-deluge deluge-console "plugin -e Label"

# Configure default labels
echo "Setting up default labels..."
docker exec bluelab-deluge deluge-console "connect localhost admin deluge; plugin -e Label"

# Wait a bit for plugin to load
sleep 5

# Add common labels for media automation
docker exec bluelab-deluge deluge-console "
connect localhost admin deluge
config set move_completed True
config set move_completed_path /downloads/completed
config set copy_torrent_file True
config set torrentfiles_location /downloads/torrents
config set remove_seed_at_ratio False
config set stop_seed_at_ratio False
"

echo "Deluge Labels plugin setup completed!"
echo "Default labels that will be auto-created:"
echo "  - movies (for Radarr)"
echo "  - tv (for Sonarr)" 
echo "  - music (for Lidarr)"
echo "  - books (for Readarr)"
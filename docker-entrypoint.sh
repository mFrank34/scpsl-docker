#!/bin/bash
PORT=${PORT:-7777}
CONFIG_DIR="/config"
GAME_CONFIG_LOC="/home/scpsl/.config/SCP Secret Laboratory/config"

# Ensure host config directory exists
mkdir -p "$CONFIG_DIR"

# Link the entire config path instead of just the port folder
mkdir -p "$(dirname "$GAME_CONFIG_LOC")"
rm -rf "$GAME_CONFIG_LOC"
ln -s "$CONFIG_DIR" "$GAME_CONFIG_LOC"

# Check for initial configuration file
if [ ! -f "$CONFIG_DIR/$PORT/config_localadmin.txt" ]; then
  echo "First run detected. Automatically accepting EULA and initializing configs..."
  printf "yes\nkeep\nthis\n" | ./LocalAdmin "$PORT"
fi

exec ./LocalAdmin "$PORT"

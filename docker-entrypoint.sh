#!/bin/bash
set -e

PORT=${PORT:-7777}
CONFIG_DIR="/config"
GAME_CONFIG_DIR="/home/scpsl/.config/SCP Secret Laboratory/config"

# Ensure the mounted host volume and config paths are owned by the game user
chown -R scpsl:scpsl "$CONFIG_DIR"
mkdir -p "$GAME_CONFIG_DIR"
chown -R scpsl:scpsl /home/scpsl/.config

rm -rf "$GAME_CONFIG_DIR/$PORT"
ln -s "$CONFIG_DIR" "$GAME_CONFIG_DIR/$PORT"
chown -h scpsl:scpsl "$GAME_CONFIG_DIR/$PORT"

cd "$INSTALL_LOC"

# If config files don't exist yet, automate the first-run prompts as user scpsl
if [ ! -f "$CONFIG_DIR/config_gameplay.txt" ]; then
  echo "First run detected. Automatically accepting EULA and initializing configs..."
  runuser -u scpsl -- bash -c "printf 'yes\nkeep\nthis\n' | ./LocalAdmin $PORT"
else
  echo "Launching SCP:SL Server on port $PORT..."
  exec runuser -u scpsl -- ./LocalAdmin "$PORT"
fi

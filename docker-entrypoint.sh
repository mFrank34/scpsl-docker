#!/bin/bash
set -e

PORT=${PORT:-7777}
CONFIG_DIR="/config"
GAME_CONFIG_DIR="/root/.config/SCP Secret Laboratory/config"

mkdir -p "$GAME_CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

rm -rf "$GAME_CONFIG_DIR/$PORT"
ln -s "$CONFIG_DIR" "$GAME_CONFIG_DIR/$PORT"

cd "$INSTALL_LOC"

if [ ! -f "$CONFIG_DIR/config_gameplay.txt" ]; then
  echo "First run detected. Automatically accepting EULA and initializing configs..."
  printf "yes\nkeep\nthis\n" | ./LocalAdmin "$PORT"
else
  echo "Launching SCP:SL Server on port $PORT..."
  exec ./LocalAdmin "$PORT"
fi

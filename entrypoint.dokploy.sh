#!/bin/sh
set -eu

CONFIG_DIR="${NANOBOT_CONFIG_DIR:-/data/nanobot}"
HOME_CONFIG_DIR="/home/nanobot/.nanobot"

mkdir -p "$CONFIG_DIR"

# Dokploy volume umumnya dibuat root-owned. Samakan ownership agar user nanobot bisa tulis.
if [ "$(id -u)" -eq 0 ]; then
    chown -R 1000:1000 "$CONFIG_DIR"
fi

# Pertahankan path default aplikasi di $HOME/.nanobot melalui symlink ke volume persisten.
if [ -e "$HOME_CONFIG_DIR" ] && [ ! -L "$HOME_CONFIG_DIR" ]; then
    rm -rf "$HOME_CONFIG_DIR"
fi
ln -sfn "$CONFIG_DIR" "$HOME_CONFIG_DIR"

if [ "$(id -u)" -eq 0 ]; then
    exec su -s /bin/sh nanobot -c 'exec nanobot "$@"' -- "$@"
fi

exec nanobot "$@"

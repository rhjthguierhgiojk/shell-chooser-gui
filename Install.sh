#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/quickshell/shell-selector"

echo "Installing Shell Selector..."

mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

echo "[+] Installing launcher..."

install -Dm755 \
    "$REPO_DIR/scripts/launch-shell.sh" \
    "$CONFIG_DIR/launch-shell.sh"

echo "[+] Installing menu..."

install -Dm755 \
    "$REPO_DIR/scripts/shell-menu" \
    "$BIN_DIR/shell-menu"

echo "[+] Checking dependencies..."

deps=(
    qs
    hyprctl
)

for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing dependency: $cmd"
    fi
done

echo
echo "Done!"
echo
echo "Run:"
echo "  shell-menu"

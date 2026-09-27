#!/usr/bin/env bash

set -uo pipefail

# ═══════════════════════════════════════════════
# Shell Selector Installer
# ═══════════════════════════════════════════════

# ─────────────────────────────────────────────
# User / XDG directories
# ─────────────────────────────────────────────

USER_HOME="${HOME}"

CONFIG_HOME="${XDG_CONFIG_HOME:-${USER_HOME}/.config}"
DATA_HOME="${XDG_DATA_HOME:-${USER_HOME}/.local/share}"
CACHE_HOME="${XDG_CACHE_HOME:-${USER_HOME}/.cache}"
STATE_HOME="${XDG_STATE_HOME:-${USER_HOME}/.local/state}"

BIN_DIR="${USER_HOME}/.local/bin"

INSTALL_DIR="${CONFIG_HOME}/quickshell/shell-selector"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

pause() {
    echo
    read -rp "Press Enter to continue..."
}

run_optional() {
    "$@"
    local status=$?

    if [[ $status -ne 0 ]]; then
        echo
        echo "⚠ Command failed."
        echo "  Exit code: $status"
        echo
        echo "Command:"
        printf '  %q ' "$@"
        echo
        echo
        echo "Continuing installation..."
        echo
    fi

    return 0
}

# ─────────────────────────────────────────────
# Header
# ─────────────────────────────────────────────

clear

cat <<'EOF'
╔══════════════════════════════════════════════╗
║                                              ║
║              SHELL SELECTOR                 ║
║                 Installer                   ║
║                                              ║
╚══════════════════════════════════════════════╝
EOF

echo
echo "This installer will detect your Linux environment"
echo "and configure Shell Selector."
echo

# ─────────────────────────────────────────────
# Detect Linux distribution
# ─────────────────────────────────────────────

DISTRO_ID="unknown"
DISTRO_VERSION="unknown"
DISTRO_NAME="Unknown Linux"

if [[ -f /etc/os-release ]]; then
    . /etc/os-release

    DISTRO_ID="${ID:-unknown}"
    DISTRO_VERSION="${VERSION_ID:-unknown}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
fi

echo "╭──────────────────────────────────────────────╮"
echo "│ Linux detection                              │"
echo "╰──────────────────────────────────────────────╯"
echo

echo "Detected Linux:"
echo "  $DISTRO_NAME"
echo

echo "Is this correct?"
echo
echo "  1) Yes"
echo "  2) No, choose manually"
echo

read -rp "Select [1-2]: " distro_choice

if [[ "$distro_choice" == "2" ]]; then

    echo
    echo "Choose your Linux family:"
    echo
    echo "  1) Debian / Ubuntu based"
    echo "  2) Arch based"
    echo "  3) Fedora based"
    echo "  4) openSUSE"
    echo "  5) Alpine"
    echo "  6) NixOS"
    echo "  7) Other"
    echo

    read -rp "Select [1-7]: " manual_distro

    case "$manual_distro" in

        1)
            DISTRO_ID="debian"
            ;;

        2)
            DISTRO_ID="arch"
            ;;

        3)
            DISTRO_ID="fedora"
            ;;

        4)
            DISTRO_ID="opensuse"
            ;;

        5)
            DISTRO_ID="alpine"
            ;;

        6)
            DISTRO_ID="nixos"
            ;;

        *)
            DISTRO_ID="other"
            ;;

    esac

fi

# ─────────────────────────────────────────────
# Package manager detection
# ─────────────────────────────────────────────

PACKAGE_MANAGER="none"

if command_exists pacman; then

    PACKAGE_MANAGER="pacman"

elif command_exists apt-get; then

    PACKAGE_MANAGER="apt"

elif command_exists dnf; then

    PACKAGE_MANAGER="dnf"

elif command_exists zypper; then

    PACKAGE_MANAGER="zypper"

elif command_exists apk; then

    PACKAGE_MANAGER="apk"

elif command_exists nix; then

    PACKAGE_MANAGER="nix"

fi

echo
echo "Package manager:"
echo "  $PACKAGE_MANAGER"

# ─────────────────────────────────────────────
# Display system
# ─────────────────────────────────────────────

echo
echo "╭──────────────────────────────────────────────╮"
echo "│ Display system                               │"
echo "╰──────────────────────────────────────────────╯"
echo

SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

case "$SESSION_TYPE" in

    wayland)
        echo "✓ Wayland session detected."
        ;;

    x11)
        echo "✓ X11 session detected."
        ;;

    *)
        echo "? Could not determine the session type."
        ;;

esac

echo
echo "What display system are you using?"
echo
echo "  1) Wayland"
echo "  2) X11"
echo "  3) Use detected value"
echo

read -rp "Select [1-3]: " display_choice

case "$display_choice" in

    1)
        DISPLAY_SYSTEM="wayland"
        ;;

    2)
        DISPLAY_SYSTEM="x11"
        ;;

    *)
        DISPLAY_SYSTEM="$SESSION_TYPE"
        ;;

esac

echo
echo "Display system: $DISPLAY_SYSTEM"

# ─────────────────────────────────────────────
# Hyprland detection
# ─────────────────────────────────────────────

echo
echo "╭──────────────────────────────────────────────╮"
echo "│ Hyprland                                     │"
echo "╰──────────────────────────────────────────────╯"
echo

HAVE_HYPRLAND="no"
HYPRLAND_ACTION="skip"

if command_exists hyprctl || command_exists Hyprland; then

    HAVE_HYPRLAND="yes"

    echo "✓ Hyprland is already installed."
    echo

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo "✓ Hyprland session appears to be running."
        echo
    fi

    echo "What would you like to do?"
    echo
    echo "  1) Keep existing Hyprland"
    echo "  2) Configure Hyprland integration"
    echo "  3) Skip Hyprland setup"
    echo

    read -rp "Select [1-3]: " hypr_choice

    case "$hypr_choice" in

        1)
            HYPRLAND_ACTION="keep"
            ;;

        2)
            HYPRLAND_ACTION="configure"
            ;;

        3)
            HYPRLAND_ACTION="skip"
            ;;

        *)
            HYPRLAND_ACTION="keep"
            ;;

    esac

else

    echo "✗ Hyprland was not detected."
    echo
    echo "  1) Continue without Hyprland"
    echo "  2) Try to install Hyprland"
    echo "  3) Skip Hyprland setup"
    echo

    read -rp "Select [1-3]: " hypr_choice

    case "$hypr_choice" in

        2)

            HYPRLAND_ACTION="install"

            echo

            case "$PACKAGE_MANAGER" in

                pacman)

                    echo "Arch-based system detected."
                    echo

                    read -rp \
                        "Install Hyprland with pacman? [y/N]: " \
                        answer

                    if [[ "$answer" =~ ^[Yy]$ ]]; then
                        run_optional sudo pacman -S --needed hyprland
                    fi

                    ;;

                dnf)

                    echo "Fedora-based system detected."
                    echo

                    read -rp \
                        "Try installing Hyprland with dnf? [y/N]: " \
                        answer

                    if [[ "$answer" =~ ^[Yy]$ ]]; then
                        run_optional sudo dnf install hyprland
                    fi

                    ;;

                apt)

                    echo
                    echo "Debian/Ubuntu-based system detected."
                    echo
                    echo "Automatic Hyprland installation is not enabled"
                    echo "because package availability varies by release."
                    echo

                    ;;

                nix)

                    echo
                    echo "NixOS detected."
                    echo
                    echo "Configure Hyprland through your Nix configuration."
                    echo

                    ;;

                zypper)

                    echo
                    echo "openSUSE detected."
                    echo
                    echo "Please install Hyprland using the appropriate"
                    echo "openSUSE repository/package."
                    echo

                    ;;

                apk)

                    echo
                    echo "Alpine detected."
                    echo
                    echo "Automatic Hyprland installation is not enabled."
                    echo

                    ;;

                *)

                    echo
                    echo "No supported automatic Hyprland installer."
                    echo

                    ;;

            esac

            ;;

        1|3)

            HYPRLAND_ACTION="skip"

            ;;

        *)

            HYPRLAND_ACTION="skip"

            ;;

    esac

fi

# ─────────────────────────────────────────────
# Quickshell detection
# ─────────────────────────────────────────────

echo
echo "╭──────────────────────────────────────────────╮"
echo "│ Quickshell                                   │"
echo "╰──────────────────────────────────────────────╯"
echo

HAVE_QUICKSHELL="no"
QUICKSHELL_ACTION="skip"

if command_exists qs; then

    HAVE_QUICKSHELL="yes"

    echo "✓ Quickshell is already installed."
    echo

    qs --version 2>/dev/null || true

    echo
    echo "What would you like to do?"
    echo
    echo "  1) Keep existing Quickshell"
    echo "  2) Configure Quickshell"
    echo "  3) Skip Quickshell setup"
    echo

    read -rp "Select [1-3]: " qs_choice

    case "$qs_choice" in

        1)
            QUICKSHELL_ACTION="keep"
            ;;

        2)
            QUICKSHELL_ACTION="configure"
            ;;

        3)
            QUICKSHELL_ACTION="skip"
            ;;

        *)
            QUICKSHELL_ACTION="keep"
            ;;

    esac

else

    echo "✗ Quickshell was not detected."
    echo
    echo "  1) Try to install Quickshell"
    echo "  2) Skip Quickshell"
    echo

    read -rp "Select [1-2]: " qs_choice

    case "$qs_choice" in

        1)

            QUICKSHELL_ACTION="install"

            echo

            case "$PACKAGE_MANAGER" in

                pacman)

                    echo "Installing Quickshell with pacman..."
                    run_optional sudo pacman -S --needed quickshell
                    ;;

                dnf)

                    echo "Installing Quickshell with dnf..."
                    run_optional sudo dnf install quickshell
                    ;;

                apt)

                    echo
                    echo "Debian/Ubuntu-based system detected."
                    echo
                    echo "Automatic Quickshell installation is not enabled"
                    echo "because package availability varies by release."
                    echo

                    ;;

                zypper)

                    echo
                    echo "openSUSE detected."
                    echo
                    echo "Please install Quickshell using your repositories."
                    echo

                    ;;

                apk)

                    echo
                    echo "Alpine detected."
                    echo
                    echo "Automatic Quickshell installation is not enabled."
                    echo

                    ;;

                nix)

                    echo
                    echo "Nix detected."
                    echo
                    echo "Install Quickshell through your Nix configuration."
                    echo

                    ;;

                *)

                    echo
                    echo "No supported automatic Quickshell installer."
                    echo

                    ;;

            esac

            ;;

        2)

            QUICKSHELL_ACTION="skip"
            ;;

        *)

            QUICKSHELL_ACTION="skip"
            ;;

    esac

fi

# ─────────────────────────────────────────────
# Install Shell Selector
# ─────────────────────────────────────────────

echo
echo "╭──────────────────────────────────────────────╮"
echo "│ Installing Shell Selector                    │"
echo "╰──────────────────────────────────────────────╯"
echo

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# ─────────────────────────────────────────────
# shell-menu
# ─────────────────────────────────────────────

if [[ -f "$REPO_DIR/shell-menu" ]]; then

    install -Dm755 \
        "$REPO_DIR/shell-menu" \
        "$BIN_DIR/shell-menu"

    echo "✓ Installed shell-menu"

else

    echo "⚠ shell-menu was not found in repository."

fi

# ─────────────────────────────────────────────
# launch-shell.sh
# ─────────────────────────────────────────────

if [[ -f "$REPO_DIR/launch-shell.sh" ]]; then

    install -Dm755 \
        "$REPO_DIR/launch-shell.sh" \
        "$INSTALL_DIR/launch-shell.sh"

    echo "✓ Installed launch-shell.sh"

else

    echo "⚠ launch-shell.sh was not found in repository."

fi

# ─────────────────────────────────────────────
# shell-db.sh
# ─────────────────────────────────────────────

if [[ -f "$REPO_DIR/shell-db.sh" ]]; then

    install -Dm644 \
        "$REPO_DIR/shell-db.sh" \
        "$INSTALL_DIR/shell-db.sh"

    echo "✓ Installed shell-db.sh"

else

    echo "⚠ shell-db.sh was not found in repository."

fi

# ─────────────────────────────────────────────
# PATH configuration
# ─────────────────────────────────────────────

add_path() {

    local rc_file="$1"

    [[ -f "$rc_file" ]] || touch "$rc_file"

    if ! grep -Fq \
        'export PATH="$HOME/.local/bin:$PATH"' \
        "$rc_file"; then

        cat >> "$rc_file" <<'EOF'

# Shell Selector
export PATH="$HOME/.local/bin:$PATH"
EOF

    fi
}

add_path "$USER_HOME/.bashrc"

if [[ -f "$USER_HOME/.zshrc" ]]; then
    add_path "$USER_HOME/.zshrc"
fi

export PATH="$BIN_DIR:$PATH"

echo "✓ PATH configured"

# ─────────────────────────────────────────────
# Save detected configuration
# ─────────────────────────────────────────────

cat > "$INSTALL_DIR/system.conf" <<EOF
# Shell Selector detected configuration

DISTRO_ID="$DISTRO_ID"
DISTRO_VERSION="$DISTRO_VERSION"
DISTRO_NAME="$DISTRO_NAME"

PACKAGE_MANAGER="$PACKAGE_MANAGER"

DISPLAY_SYSTEM="$DISPLAY_SYSTEM"

HYPRLAND="$HAVE_HYPRLAND"
HYPRLAND_ACTION="$HYPRLAND_ACTION"

QUICKSHELL="$HAVE_QUICKSHELL"
QUICKSHELL_ACTION="$QUICKSHELL_ACTION"

USER_HOME="$USER_HOME"
CONFIG_HOME="$CONFIG_HOME"
DATA_HOME="$DATA_HOME"
CACHE_HOME="$CACHE_HOME"
STATE_HOME="$STATE_HOME"
BIN_DIR="$BIN_DIR"
INSTALL_DIR="$INSTALL_DIR"
EOF

echo "✓ Configuration saved"

# ─────────────────────────────────────────────
# Installation summary
# ─────────────────────────────────────────────

echo

cat <<'EOF'
╔══════════════════════════════════════════════╗
║             INSTALLATION DONE               ║
╚══════════════════════════════════════════════╝
EOF

echo
echo "System:"
echo "  Linux:           $DISTRO_NAME"
echo "  Package manager: $PACKAGE_MANAGER"
echo "  Display:         $DISPLAY_SYSTEM"
echo

echo "Components:"
echo "  Hyprland:        $HAVE_HYPRLAND ($HYPRLAND_ACTION)"
echo "  Quickshell:      $HAVE_QUICKSHELL ($QUICKSHELL_ACTION)"
echo

echo "Installation:"
echo "  User home:       $USER_HOME"
echo "  Config:          $INSTALL_DIR"
echo "  Binary:          $BIN_DIR/shell-menu"
echo

echo "Start Shell Selector:"
echo
echo "  shell-menu"
echo

echo "If the command is not found yet:"
echo
echo "  source ~/.bashrc"
echo
echo "or:"
echo
echo "  source ~/.zshrc"
echo

echo "Direct path:"
echo
echo "  $BIN_DIR/shell-menu"
echo

echo "Done."

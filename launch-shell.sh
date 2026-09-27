#!/usr/bin/env bash

set -u

SHELL_NAME="${1:-}"

LOG_DIR="/tmp/shell-selector"
mkdir -p "$LOG_DIR"

# ─────────────────────────────────────────────
# Environment
# ─────────────────────────────────────────────

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    WAYLAND_DISPLAY="$(
        find "$XDG_RUNTIME_DIR" \
            -maxdepth 1 \
            -type s \
            -name 'wayland-*' \
            ! -name '*.lock' \
            -printf '%f\n' 2>/dev/null |
        head -n1
    )"

    export WAYLAND_DISPLAY
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE="$(
        find "$XDG_RUNTIME_DIR/hypr" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf '%T@ %f\n' 2>/dev/null |
        sort -nr |
        head -n1 |
        cut -d' ' -f2-
    )"

    export HYPRLAND_INSTANCE_SIGNATURE
fi

# ─────────────────────────────────────────────
# Custom Qt
# ─────────────────────────────────────────────

if [[ -d "/opt/qt6/6.11.2/gcc_64" ]]; then

    export QT_PREFIX="/opt/qt6/6.11.2/gcc_64"
    export QML2_IMPORT_PATH="$QT_PREFIX/qml"
    export QT_PLUGIN_PATH="$QT_PREFIX/plugins"
    export CMAKE_PREFIX_PATH="$QT_PREFIX"

fi

# ─────────────────────────────────────────────
# Stop running shells
# ─────────────────────────────────────────────

stop_shells() {

    echo "→ Stopping currently running shells..."

    pkill -f 'quickshell.*-c ii' 2>/dev/null || true
    pkill -f 'quickshell.*end4-pC' 2>/dev/null || true
    pkill -f 'quickshell.*caelestia-shell' 2>/dev/null || true

    if command -v serpentinumd >/dev/null 2>&1; then
        serpentinumd stop 2>/dev/null || true
    elif [[ -x "$HOME/.local/bin/serpantinumd" ]]; then
        "$HOME/.local/bin/serpantinumd" stop 2>/dev/null || true
    fi

    sleep 1
}

# ─────────────────────────────────────────────
# Start shell
# ─────────────────────────────────────────────

start_shell() {

    case "$SHELL_NAME" in

        ii)

            echo "→ Starting ii / illogical-impulse..."

            if ! command -v qs >/dev/null 2>&1; then
                echo "✗ Quickshell (qs) is not installed."
                return 1
            fi

            nohup qs -c ii \
                > "$LOG_DIR/ii.log" 2>&1 &

            ;;

        end4)

            echo "→ Starting end4-pC..."

            if ! command -v qs >/dev/null 2>&1; then
                echo "✗ Quickshell (qs) is not installed."
                return 1
            fi

            nohup qs -c end4-pC \
                > "$LOG_DIR/end4-pC.log" 2>&1 &

            ;;

        serpentinum)

            echo "→ Starting Serpantinum..."

            if [[ ! -x "$HOME/.local/bin/serpantinumd" ]]; then
                echo "✗ serpentinumd was not found."
                return 1
            fi

            nohup "$HOME/.local/bin/serpantinumd" start \
                > "$LOG_DIR/serpantinum.log" 2>&1 &

            ;;

        caelestia)

            echo "→ Starting Caelestia..."

            CAELESTIA="$HOME/.local/bin/caelestia-shell"

            if [[ ! -x "$CAELESTIA" ]]; then
                CAELESTIA="$HOME/.local/opt/caelestia/bin/caelestia-shell"
            fi

            if [[ ! -x "$CAELESTIA" ]]; then
                echo "✗ Caelestia shell was not found."
                echo "  Expected:"
                echo "  $HOME/.local/bin/caelestia-shell"
                return 1
            fi

            : > "$LOG_DIR/caelestia.log"

            if command -v hyprctl >/dev/null 2>&1; then

                hyprctl dispatch \
                    "exec sh -lc 'QS_CONFIG_PATH=\"$HOME/.config/quickshell/caelestia\" \"$CAELESTIA\" --daemonize > \"$LOG_DIR/caelestia.log\" 2>&1'" \
                    >/dev/null 2>&1

            else

                nohup env \
                    QS_CONFIG_PATH="$HOME/.config/quickshell/caelestia" \
                    "$CAELESTIA" \
                    --daemonize \
                    > "$LOG_DIR/caelestia.log" 2>&1 &

            fi

            ;;

        *)

            echo "✗ Unknown shell: $SHELL_NAME"
            return 1
            ;;

    esac

    return 0
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

if [[ -z "$SHELL_NAME" ]]; then
    echo "Usage:"
    echo "  launch-shell.sh {ii|end4|serpentininum|caelestia}"
    exit 1
fi

stop_shells

if start_shell; then
    sleep 2

    echo
    echo "✓ $SHELL_NAME launch command completed."
    echo "Logs: $LOG_DIR/"
    exit 0
else
    echo
    echo "⚠ $SHELL_NAME could not be started."
    echo
    echo "Check logs in:"
    echo "  $LOG_DIR/"
    exit 1
fi

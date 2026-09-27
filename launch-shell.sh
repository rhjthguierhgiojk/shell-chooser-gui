#!/usr/bin/env bash

set -u

# ═══════════════════════════════════════════════
# Shell Selector - Portable Launcher
# ═══════════════════════════════════════════════

HOME_DIR="$HOME"
LOG_DIR="${XDG_RUNTIME_DIR:-/tmp}/shell-selector"

mkdir -p "$LOG_DIR"

# ───────────────────────────────────────────────
# Environment
# ───────────────────────────────────────────────

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"

# Automatically find Wayland display
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

# Automatically find Hyprland instance
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

# ───────────────────────────────────────────────
# Optional Qt detection
# ───────────────────────────────────────────────

if [[ -d "/opt/qt6/6.11.2/gcc_64" ]]; then
    QT_PREFIX="/opt/qt6/6.11.2/gcc_64"

    export QT_PREFIX
    export QML2_IMPORT_PATH="${QML2_IMPORT_PATH:-$QT_PREFIX/qml}"
    export QT_PLUGIN_PATH="${QT_PLUGIN_PATH:-$QT_PREFIX/plugins}"
    export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-$QT_PREFIX}"
fi

# ───────────────────────────────────────────────
# Find commands
# ───────────────────────────────────────────────

QS_BIN="$(command -v qs 2>/dev/null || true)"
SERPANTINUM_BIN="$HOME_DIR/.local/bin/serpantinumd"
CAELESTIA_BIN="$HOME_DIR/.local/opt/caelestia/bin/caelestia-shell"

# Fallback Caelestia lookup
if [[ ! -x "$CAELESTIA_BIN" ]]; then
    CAELESTIA_BIN="$(command -v caelestia-shell 2>/dev/null || true)"
fi

# ───────────────────────────────────────────────
# Stop currently running shells
# ───────────────────────────────────────────────

stop_shells() {
    echo "→ Stopping currently running shells..."

    pkill -f 'quickshell.*-c ii' 2>/dev/null || true
    pkill -f 'quickshell.*end4-pC' 2>/dev/null || true
    pkill -f 'quickshell.*caelestia-shell' 2>/dev/null || true

    if [[ -x "$SERPANTINUM_BIN" ]]; then
        "$SERPANTINUM_BIN" stop >/dev/null 2>&1 || true
    fi

    sleep 1
}

# ───────────────────────────────────────────────
# Check if shell is running
# ───────────────────────────────────────────────

shell_running() {
    case "$1" in
        ii)
            pgrep -af 'quickshell.*-c ii' >/dev/null 2>&1
            ;;

        end4)
            pgrep -af 'quickshell.*end4-pC' >/dev/null 2>&1
            ;;

        serpantinum)
            pgrep -af 'serpantinum' >/dev/null 2>&1
            ;;

        caelestia)
            pgrep -af 'quickshell.*caelestia-shell' >/dev/null 2>&1
            ;;

        *)
            return 1
            ;;
    esac
}

# ───────────────────────────────────────────────
# Start shell
# ───────────────────────────────────────────────

start_shell() {
    SHELL_NAME="$1"

    stop_shells

    echo
    echo "→ Starting $SHELL_NAME..."
    echo

    case "$SHELL_NAME" in

        # ───────────────────────────────────────
        # ii / illogical-impulse
        # ───────────────────────────────────────

        ii)
            if [[ -z "$QS_BIN" ]]; then
                echo "✗ Quickshell (qs) was not found."
                return 1
            fi

            nohup "$QS_BIN" -c ii \
                > "$LOG_DIR/ii.log" 2>&1 &

            sleep 3

            if shell_running ii; then
                echo "✓ ii started successfully."
                return 0
            fi
            ;;

        # ───────────────────────────────────────
        # end4-pC
        # ───────────────────────────────────────

        end4)
            if [[ -z "$QS_BIN" ]]; then
                echo "✗ Quickshell (qs) was not found."
                return 1
            fi

            nohup "$QS_BIN" -c end4-pC \
                > "$LOG_DIR/end4-pC.log" 2>&1 &

            sleep 3

            if shell_running end4; then
                echo "✓ end4-pC started successfully."
                return 0
            fi
            ;;

        # ───────────────────────────────────────
        # Serpantinum
        # ───────────────────────────────────────

        serpantinum)
            if [[ ! -x "$SERPANTINUM_BIN" ]]; then
                echo "✗ serpantinumd was not found:"
                echo "  $SERPANTINUM_BIN"
                return 1
            fi

            nohup "$SERPANTINUM_BIN" start \
                > "$LOG_DIR/serpantinum.log" 2>&1 &

            sleep 4

            if shell_running serpantinum; then
                echo "✓ Serpantinum started successfully."
                return 0
            fi
            ;;

        # ───────────────────────────────────────
        # Caelestia
        # ───────────────────────────────────────

        caelestia)
            if ! command -v hyprctl >/dev/null 2>&1; then
                echo "✗ hyprctl was not found."
                return 1
            fi

            if [[ ! -x "$CAELESTIA_BIN" ]]; then
                echo "✗ Caelestia shell was not found."

                if [[ -n "$CAELESTIA_BIN" ]]; then
                    echo "  $CAELESTIA_BIN"
                fi

                return 1
            fi

            : > "$LOG_DIR/caelestia.log"

            CAELESTIA_CONFIG="$HOME_DIR/.config/quickshell/caelestia"

            hyprctl dispatch \
                "hl.dsp.exec_cmd(\"sh -lc 'QS_CONFIG_PATH=\\\"$CAELESTIA_CONFIG\\\" \\\"$CAELESTIA_BIN\\\" --daemonize > \\\"$LOG_DIR/caelestia.log\\\" 2>&1'\")" \
                >/dev/null 2>&1 || true

            sleep 4

            if shell_running caelestia; then
                echo "✓ Caelestia started successfully."
                return 0
            fi
            ;;

        *)
            echo "✗ Unknown shell: $SHELL_NAME"
            return 1
            ;;
    esac

    echo
    echo "⚠ $SHELL_NAME could not be started."
    echo
    echo "Check logs:"
    echo "  $LOG_DIR/"
    echo

    return 1
}

# ───────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "Usage:"
    echo "  $0 {ii|end4|serpantinum|caelestia}"
    exit 1
fi

start_shell "$1"

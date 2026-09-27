#!/usr/bin/env bash

# ═══════════════════════════════════════════════
# Shell Selector - Shell Database
# ═══════════════════════════════════════════════

# User directories
USER_HOME="${HOME}"

CONFIG_HOME="${XDG_CONFIG_HOME:-$USER_HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$USER_HOME/.local/share}"
BIN_HOME="${USER_HOME}/.local/bin"

QUICKSHELL_CONFIG="${CONFIG_HOME}/quickshell"
SELECTOR_CONFIG="${QUICKSHELL_CONFIG}/shell-selector"

# ═══════════════════════════════════════════════
# ii / illogical-impulse
# ═══════════════════════════════════════════════

shell_ii_name="ii / illogical-impulse"

shell_ii_start="qs -c ii"

shell_ii_stop="pkill -f 'quickshell.*-c ii'"

shell_ii_check="pgrep -af 'quickshell.*-c ii'"

# ═══════════════════════════════════════════════
# end4-pC
# ═══════════════════════════════════════════════

shell_end4_name="end4-pC"

shell_end4_start="qs -c end4-pC"

shell_end4_stop="pkill -f 'quickshell.*end4-pC'"

shell_end4_check="pgrep -af 'quickshell.*end4-pC'"

# ═══════════════════════════════════════════════
# Serpantinum
# ═══════════════════════════════════════════════

shell_serpantinum_name="Serpantinum"

shell_serpantinum_start="${BIN_HOME}/serpantinumd start"

shell_serpantinum_stop="${BIN_HOME}/serpantinumd stop"

shell_serpantinum_check="pgrep -af 'serpantinum'"

# ═══════════════════════════════════════════════
# Caelestia
# ═══════════════════════════════════════════════

shell_caelestia_name="Caelestia"

CAELESTIA_BIN="${BIN_HOME}/caelestia-shell"

if [[ ! -x "$CAELESTIA_BIN" ]]; then
    CAELESTIA_BIN="${USER_HOME}/.local/opt/caelestia/bin/caelestia-shell"
fi

CAELESTIA_CONFIG="${QUICKSHELL_CONFIG}/caelestia"

shell_caelestia_start="QS_CONFIG_PATH=\"${CAELESTIA_CONFIG}\" \"${CAELESTIA_BIN}\" --daemonize"

shell_caelestia_stop="pkill -f 'quickshell.*caelestia-shell'"

shell_caelestia_check="pgrep -af 'quickshell.*caelestia-shell'"

# ═══════════════════════════════════════════════
# Supported shell IDs
# ═══════════════════════════════════════════════

SHELL_IDS=(
    ii
    end4
    serpantinum
    caelestia
)

# ═══════════════════════════════════════════════
# Shell name
# ═══════════════════════════════════════════════

shell_name() {

    case "$1" in

        ii)
            echo "$shell_ii_name"
            ;;

        end4)
            echo "$shell_end4_name"
            ;;

        serpantinum)
            echo "$shell_serpantinum_name"
            ;;

        caelestia)
            echo "$shell_caelestia_name"
            ;;

        *)
            return 1
            ;;

    esac
}

# ═══════════════════════════════════════════════
# Shell start command
# ═══════════════════════════════════════════════

shell_start_command() {

    case "$1" in

        ii)
            echo "$shell_ii_start"
            ;;

        end4)
            echo "$shell_end4_start"
            ;;

        serpantinum)
            echo "$shell_serpantinum_start"
            ;;

        caelestia)
            echo "$shell_caelestia_start"
            ;;

        *)
            return 1
            ;;

    esac
}

# ═══════════════════════════════════════════════
# Stop shell
# ═══════════════════════════════════════════════

shell_stop() {

    case "$1" in

        ii)
            eval "$shell_ii_stop" 2>/dev/null || true
            ;;

        end4)
            eval "$shell_end4_stop" 2>/dev/null || true
            ;;

        serpantinum)
            eval "$shell_serpantinum_stop" 2>/dev/null || true
            ;;

        caelestia)
            eval "$shell_caelestia_stop" 2>/dev/null || true
            ;;

        *)
            return 1
            ;;

    esac
}

# ═══════════════════════════════════════════════
# Check whether shell is running
# ═══════════════════════════════════════════════

shell_running() {

    case "$1" in

        ii)
            eval "$shell_ii_check" >/dev/null 2>&1
            ;;

        end4)
            eval "$shell_end4_check" >/dev/null 2>&1
            ;;

        serpantinum)
            eval "$shell_serpantinum_check" >/dev/null 2>&1
            ;;

        caelestia)
            eval "$shell_caelestia_check" >/dev/null 2>&1
            ;;

        *)
            return 1
            ;;

    esac
}

#!/usr/bin/env bash
# Script to launch the application-specific interactive menu
# Usage: ./scripts/app/interactive.sh [options]

set -e  # Exit on any error

APP_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_ROOT="$(dirname "$APP_SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$SCRIPTS_ROOT")"
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="$SCRIPTS_ROOT/output"
LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"

mkdir -p "$OUTPUT_DIR"
> "$LOG_FILE"

# Source shared utilities
# shellcheck disable=SC1090,SC1091
source "$SCRIPTS_ROOT/utils.sh"

show_usage() {
    echo -e "${BOLD}${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BOLD}${GREEN}Description:${NC}"
    echo "  Present the application-level interactive menu"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}    Show this help message"
    echo ""
    echo -e "${BOLD}${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0${NC}            # Enter the application control panel"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."

DIALOG_USED=false

cleanup_screen() {
    if [ "$DIALOG_USED" = true ]; then
        # Send escape sequences to close any open dialog
        printf '\033c'  # Full terminal reset
        clear
        tput sgr0 2>/dev/null || true  # Reset all attributes
    fi
}

trap cleanup_screen EXIT

CONFIG_SCRIPT="$APP_SCRIPT_DIR/interactive_configuration.sh"
BUILD_SCRIPT="$APP_SCRIPT_DIR/build.sh"
RUN_SCRIPT="$APP_SCRIPT_DIR/run.sh"

ensure_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        print_error "The 'dialog' command is required. Install it via your package manager (e.g. sudo apt install dialog)."
        exit 1
    fi
}

load_current_config() {
    if [ ! -f "$CONFIG_SCRIPT" ]; then
        print_error "Missing configuration helper at $CONFIG_SCRIPT"
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$CONFIG_SCRIPT"
    CURRENT_CONFIG="${CURRENT_CONFIG:-debug}"
}

run_build_script() {
    load_current_config
    local flag="--debug"
    if [ "$CURRENT_CONFIG" = "release" ]; then
        flag="--release"
    fi

    print_status "Invoking build script with $flag"
    if bash "$BUILD_SCRIPT" "$flag"; then
        dialog --title "Build" --msgbox "Build completed successfully using $CURRENT_CONFIG configuration." 8 70
    else
        dialog --title "Build Failed" --msgbox "Build failed using $CURRENT_CONFIG configuration. Review logs for details." 8 70
    fi
}

run_application() {
    load_current_config
    local flag="--debug"
    if [ "$CURRENT_CONFIG" = "release" ]; then
        flag="--release"
    fi

    print_status "Invoking run script with $flag"
    if bash "$RUN_SCRIPT" "$flag"; then
        dialog --title "Application" --msgbox "Application exited cleanly using $CURRENT_CONFIG configuration." 8 70
    else
        dialog --title "Application" --msgbox "Application terminated with an error using $CURRENT_CONFIG configuration." 8 70
    fi
}

run_tailwind_watch() {
    local tailwind_dir="$PROJECT_ROOT/static/0_stylus/tailwind"
    
    if [ ! -d "$tailwind_dir" ]; then
        dialog --title "Tailwind Watch" --msgbox "Tailwind directory not found at $tailwind_dir" 8 70
        return
    fi
    
    if [ ! -f "$tailwind_dir/package.json" ]; then
        dialog --title "Tailwind Watch" --msgbox "package.json not found in $tailwind_dir" 8 70
        return
    fi
    
    print_status "Starting Tailwind CSS watch mode"
    
    # Change to the tailwind directory and run npm watch
    if (cd "$tailwind_dir" && npm run watch); then
        dialog --title "Tailwind Watch" --msgbox "Tailwind CSS watch mode exited cleanly." 8 70
    else
        dialog --title "Tailwind Watch" --msgbox "Tailwind CSS watch mode terminated with an error." 8 70
    fi
}

set_configuration() {
    load_current_config

    local selection
    selection=$(dialog \
        --clear \
        --no-ok \
        --no-cancel \
        --backtitle "App Configuration" \
        --title "Select Build Configuration" \
        --menu "Choose configuration:" 12 50 4 \
        debug "Debug build (current: $CURRENT_CONFIG)" \
        release "Release build (current: $CURRENT_CONFIG)" \
        3>&1 1>&2 2>&3)
    local status=$?
    
    # Always reset terminal after dialog, regardless of how it exited
    printf '\033c'  # Full terminal reset
    clear
    printf '\033[0m'  # Reset colors
    tput sgr0 2>/dev/null || true  # Reset all attributes

    if [ $status -ne 0 ]; then
        print_status "Configuration selection cancelled."
        return
    fi

    if [ "$selection" = "$CURRENT_CONFIG" ]; then
        dialog --title "Configuration" --msgbox "Configuration already set to $CURRENT_CONFIG." 7 60
        return
    fi

    print_status "Updating configuration to $selection"
    if bash "$CONFIG_SCRIPT" --set "$selection"; then
        dialog --title "Configuration" --msgbox "Configuration updated to $selection." 7 60
    else
        dialog --title "Configuration" --msgbox "Failed to update configuration. Check logs for details." 7 60
    fi
}

show_menu() {
    ensure_dialog

    while true; do
        load_current_config
        local build_desc="Run build.sh (current: $CURRENT_CONFIG)"
        local run_desc="Run run.sh (current: $CURRENT_CONFIG)"
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --no-ok \
            --no-cancel \
            --backtitle "Wt App Management" \
            --title "App Control Panel" \
            --menu "Available Operations:" 20 80 8 \
            run "$run_desc" \
            build "$build_desc" \
            tailwind "Start Tailwind CSS watch mode" \
            configure "Set build configuration" \
            back "Back" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local status=$?
        
        # Always reset terminal after dialog, regardless of how it exited
        printf '\033c'  # Full terminal reset
        clear
        printf '\033[0m'  # Reset colors
        tput sgr0 2>/dev/null || true  # Reset all attributes

        if [ $status -ne 0 ]; then
            print_status "User exited from the app menu."
            break
        fi

        case "$choice" in
            build)
                run_build_script
                ;;
            run)
                run_application
                ;;
            tailwind)
                run_tailwind_watch
                ;;
            configure)
                set_configuration
                ;;
            back)
                print_status "Back selected from app menu."
                break
                ;;
            *)
                print_warning "Unknown menu selection: $choice"
                ;;
        esac
    done
}

show_menu

print_success "${SCRIPT_NAME%.sh} completed successfully!"

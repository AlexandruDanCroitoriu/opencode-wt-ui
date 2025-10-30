#!/usr/bin/env bash
# Script to launch the top-level interactive control panel
# Usage: ./scripts/interactive.sh [options]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="$SCRIPT_DIR/output"
LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"

mkdir -p "$OUTPUT_DIR"
> "$LOG_FILE"

# Source shared utilities
# shellcheck disable=SC1090,SC1091
source "$SCRIPT_DIR/utils.sh"

show_usage() {
    echo -e "${BOLD}${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BOLD}${GREEN}Description:${NC}"
    echo "  Launch the interactive menu for managing project tooling"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}    Show this help message"
    echo ""
    echo -e "${BOLD}${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0${NC}            # Open the interactive dashboard"
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

ensure_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        print_error "The 'dialog' command is required. Install it via your package manager (e.g. sudo apt install dialog)."
        exit 1
    fi
}

launch_app_menu() {
    local app_script="$SCRIPT_DIR/app/interactive.sh"
    if [ ! -f "$app_script" ]; then
        print_error "App interactive script not found at $app_script"
        return 1
    fi
    if ! bash "$app_script"; then
        print_error "App interactive script exited with an error"
        return 1
    fi
    return 0
}

launch_wt_menu() {
    local wt_script="$SCRIPT_DIR/libs/wt/interactive.sh"
    if [ ! -f "$wt_script" ]; then
        print_error "Wt interactive script not found at $wt_script"
        return 1
    fi
    if ! bash "$wt_script"; then
        print_error "Wt interactive script exited with an error"
        return 1
    fi
    return 0
}

show_main_menu() {
    ensure_dialog

    while true; do
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --no-ok \
            --no-cancel \
            --backtitle "Wt Library Management" \
            --title "Interactive Control Panel" \
            --menu "Available Operations:" 16 70 7 \
            app "Interactive app Management System" \
            wt "Wt Library Management" \
            quit "Exit" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local status=$?

        # Always reset terminal after dialog, regardless of how it exited
        printf '\033c'  # Full terminal reset
        clear
        printf '\033[0m'  # Reset colors
        tput sgr0 2>/dev/null || true  # Reset all attributes

        if [ $status -ne 0 ]; then
            print_status "User exited from the main menu."
            break
        fi

        case "$choice" in
            app)
                print_status "Launching App interactive menu..."
                if launch_app_menu; then
                    print_success "Returned from App interactive menu"
                else
                    dialog --title "Error" --msgbox "App menu exited with an error. Check the logs at $LOG_FILE." 8 60
                fi
                ;;
            wt)
                print_status "Launching Wt Library management menu..."
                if launch_wt_menu; then
                    print_success "Returned from Wt Library management menu"
                else
                    dialog --title "Error" --msgbox "Wt Library menu exited with an error. Check the logs at $LOG_FILE." 8 60
                fi
                ;;
            quit)
                print_status "Quit selected from the main menu."
                break
                ;;
            *)
                print_warning "Unknown menu selection: $choice"
                ;;
        esac
    done
}

show_main_menu

print_success "${SCRIPT_NAME%.sh} completed successfully!"

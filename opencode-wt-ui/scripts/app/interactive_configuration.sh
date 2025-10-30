#!/usr/bin/env bash
# Script to manage the application interactive configuration state
# Usage: ./scripts/app/interactive_configuration.sh [options]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_ROOT="$(dirname "$SCRIPT_DIR")"
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
    echo "  Persist and manage the build configuration used by the interactive menus"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}--get${NC}             Print the current configuration"
    echo -e "  ${CYAN}--set <value>${NC}     Update the configuration (allowed: debug, release)"
    echo -e "  ${CYAN}-h, --help${NC}    Show this help message"
    echo ""
    echo -e "${BOLD}${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0 --get${NC}         # Show current configuration"
    echo -e "  ${GREEN}$0 --set release${NC} # Persist release configuration"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

CURRENT_CONFIG="debug"
CONFIG_SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
ALLOWED_CONFIGS=("debug" "release")

escape_sed() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

validate_config_value() {
    local value="$1"
    local valid=false
    local entry
    for entry in "${ALLOWED_CONFIGS[@]}"; do
        if [ "$entry" = "$value" ]; then
            valid=true
            break
        fi
    done
    if [ "$valid" = false ]; then
        print_error "Unsupported configuration '$value'. Allowed values: ${ALLOWED_CONFIGS[*]}"
        exit 1
    fi
}

update_config_assignment() {
    local new_value="$1"
    local escaped
    escaped=$(escape_sed "$new_value")

    if ! command -v sed >/dev/null 2>&1; then
        print_error "The 'sed' command is required to update configuration."
        exit 1
    fi

    if ! grep -q '^CURRENT_CONFIG="' "$CONFIG_SCRIPT_PATH"; then
        print_error "Configuration marker not found in $CONFIG_SCRIPT_PATH"
        exit 1
    fi

    if ! sed -i "s/^CURRENT_CONFIG=\"[^\"]*\"/CURRENT_CONFIG=\"$escaped\"/" "$CONFIG_SCRIPT_PATH"; then
        print_error "Failed to persist configuration to $CONFIG_SCRIPT_PATH"
        exit 1
    fi

    CURRENT_CONFIG="$new_value"
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."

action="${1:-}"
case "$action" in
    --get)
        print_status "Current configuration is $CURRENT_CONFIG"
        echo "$CURRENT_CONFIG"
        ;;
    --set)
        if [ $# -lt 2 ]; then
            print_error "Missing configuration value for --set"
            show_usage
            exit 1
        fi
        new_value="$2"
        validate_config_value "$new_value"
        update_config_assignment "$new_value"
        print_status "Configuration updated to $new_value"
        ;;
    "")
        show_usage
        exit 1
        ;;
    *)
        print_error "Unknown option: $action"
        show_usage
        exit 1
        ;;
esac

print_success "${SCRIPT_NAME%.sh} completed successfully!"
exit 0

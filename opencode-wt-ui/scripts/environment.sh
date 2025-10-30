#!/usr/bin/env bash

# Script to set up shared environment context for project scripts
# Usage: ./scripts/environment.sh [options]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="$SCRIPT_DIR/output"
LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"

# Source shared utilities for colors and print functions
# shellcheck disable=SC1090,SC1091
source "$SCRIPT_DIR/utils.sh"

show_usage() {
    echo -e "${BOLD}${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BOLD}${GREEN}Description:${NC}"
    echo "  Provides helpers to initialise environment variables for project scripts"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}    Show this help message"
    echo ""
    echo -e "${BOLD}${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0${NC}            # Display info about the helpers"
}

SCRIPT_IS_SOURCED=false
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    SCRIPT_IS_SOURCED=true
fi

if $SCRIPT_IS_SOURCED; then
    LOG_FILE="/dev/null"
else
    mkdir -p "$OUTPUT_DIR"
    > "$LOG_FILE"
fi

if ! $SCRIPT_IS_SOURCED; then
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_usage
        exit 0
    fi
fi

init_script_environment() {
    local caller_source="$1"

    if [ -z "$caller_source" ]; then
        print_error "init_script_environment requires the caller script path"
        return 1
    fi

    local caller_dir
    caller_dir="$(cd "$(dirname "$caller_source")" && pwd)"

    SCRIPT_DIR="$caller_dir"
    SCRIPT_NAME="$(basename "$caller_source")"

    PROJECT_ROOT="$SCRIPT_DIR"
    while [ "$PROJECT_ROOT" != "/" ] && [ ! -f "$PROJECT_ROOT/CMakeLists.txt" ]; do
        PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
    done

    if [ ! -f "$PROJECT_ROOT/CMakeLists.txt" ]; then
        print_error "Unable to locate project root relative to $SCRIPT_DIR"
        return 1
    fi

    SCRIPTS_ROOT="$PROJECT_ROOT/scripts"
    RELATIVE_SCRIPT_PATH="${SCRIPT_DIR#$SCRIPTS_ROOT}"
    RELATIVE_SCRIPT_PATH="${RELATIVE_SCRIPT_PATH#/}"

    BASE_OUTPUT_DIR="$SCRIPTS_ROOT/output"
    if [ -n "$RELATIVE_SCRIPT_PATH" ]; then
        OUTPUT_DIR="$BASE_OUTPUT_DIR/$RELATIVE_SCRIPT_PATH"
    else
        OUTPUT_DIR="$BASE_OUTPUT_DIR"
    fi

    mkdir -p "$OUTPUT_DIR"

    LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"
    > "$LOG_FILE"

    return 0
}

if $SCRIPT_IS_SOURCED; then
    return 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."
print_status "Environment helpers ready. Source this script from other scripts and call init_script_environment"
print_success "${SCRIPT_NAME%.sh} completed successfully!"

#!/usr/bin/env bash

# Script to provide reusable utility helpers for project scripts
# Usage: ./scripts/utils.sh [options]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="$SCRIPT_DIR/output"
LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_status() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $msg" >> "$LOG_FILE"
}

print_success() {
    local msg="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $msg" >> "$LOG_FILE"
}

print_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARNING]${NC} $msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $msg" >> "$LOG_FILE"
}

print_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $msg" >> "$LOG_FILE"
}

show_usage() {
    echo -e "${BOLD}${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BOLD}${GREEN}Description:${NC}"
    echo "  Provides shared shell utility helpers for project scripts"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}    Show this help message"
    echo ""
    echo -e "${BOLD}${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0${NC}            # Display available helpers"
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

require_command() {
    local cmd_name="$1"
    local install_hint="$2"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        return 0
    fi

    if [ -n "$install_hint" ]; then
        print_error "$cmd_name is not installed or not in PATH. $install_hint"
    else
        print_error "$cmd_name is not installed or not in PATH"
    fi
    return 1
}

get_cpu_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    elif [ -r /proc/cpuinfo ]; then
        grep -c ^processor /proc/cpuinfo
    else
        echo "4"
    fi
}

with_logged_command() {
    local description="$1"
    shift

    print_status "$description"
    if "$@" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "$description succeeded"
        return 0
    fi

    print_error "$description failed"
    return 1
}

if $SCRIPT_IS_SOURCED; then
    return 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."
print_status "Available helpers: require_command, get_cpu_cores, with_logged_command"
print_success "${SCRIPT_NAME%.sh} completed successfully!"

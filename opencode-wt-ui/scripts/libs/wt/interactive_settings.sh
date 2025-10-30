#!/usr/bin/env bash
# Interactive configuration management for Wt library settings
# Usage: ./scripts/libs/wt/interactive_settings.sh

set -e  # Exit on any error

WT_SETTINGS_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_ROOT="$(dirname "$(dirname "$WT_SETTINGS_SCRIPT_DIR")")"
PROJECT_ROOT="$(dirname "$SCRIPTS_ROOT")"
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="$SCRIPTS_ROOT/output/libs/wt"
LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"

mkdir -p "$OUTPUT_DIR"
> "$LOG_FILE"

# Source shared utilities
# shellcheck disable=SC1090,SC1091
source "$SCRIPTS_ROOT/utils.sh"

# Source configuration management
# shellcheck disable=SC1090,SC1091
source "$WT_SETTINGS_SCRIPT_DIR/interactive_configuration.sh"

DIALOG_USED=false

cleanup_screen() {
    if [ "$DIALOG_USED" = true ]; then
        printf '\033c'  # Full terminal reset
        clear
        printf '\033[0m'  # Reset colors
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

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

Description:
  Interactive configuration management for Wt library settings

Options:
  -h, --help    Show this help messaged

Examples:
  $SCRIPT_NAME    # Open the interactive settings menu
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Show version selection menu
show_version_menu() {
    local version
    version=$(dialog \
        --colors \
        --clear \
        --title "Wt Version Selection" \
        --menu "Select Wt version (current: $CURRENT_WT_VERSION):" 20 80 12 \
        "latest" "Latest stable version" \
        "4.10.4" "Stable release 4.10.4" \
        "4.10.3" "Stable release 4.10.3" \
        "4.10.2" "Stable release 4.10.2" \
        "4.10.1" "Stable release 4.10.1" \
        "4.10.0" "Release 4.10.0" \
        "4.9.2" "Legacy release 4.9.2" \
        "4.9.1" "Legacy release 4.9.1" \
        "4.9.0" "Legacy release 4.9.0" \
        "master" "Development branch" \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$version" ] && [ "$version" != "$CURRENT_WT_VERSION" ]; then
        if update_wt_version "$version"; then
            dialog --title "Success" --msgbox "Wt version updated to: $version" 7 60
            DIALOG_USED=true
        else
            dialog --title "Error" --msgbox "Failed to update Wt version." 7 50
            DIALOG_USED=true
        fi
    fi
}

# Show build configuration selection menu
show_config_menu() {
    local config
    config=$(dialog \
        --colors \
        --clear \
        --title "Build Configuration Selection" \
        --menu "Select build configuration (current: $CURRENT_BUILD_CONFIG):" 18 90 10 \
        "debug" "Development build with debug symbols" \
        "default" "Standard release build with optimizations" \
        "minimal" "Lightweight build with only essential features" \
        "release" "Production build with full optimizations" \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$config" ] && [ "$config" != "$CURRENT_BUILD_CONFIG" ]; then
        if update_build_config "$config"; then
            dialog --title "Success" --msgbox "Build configuration updated to: $config" 7 60
            DIALOG_USED=true
        else
            dialog --title "Error" --msgbox "Failed to update build configuration." 7 50
            DIALOG_USED=true
        fi
    fi
}

# Load configuration values from file
load_config_values() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Read all configuration values
    BUILD_TYPE=$(grep "^BUILD_TYPE=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "Release")
    INSTALL_PREFIX_CONF=$(grep "^INSTALL_PREFIX_CONF=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "/usr/local")
    JOBS=$(grep "^JOBS=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "auto")
    CLEAN_BUILD=$(grep "^CLEAN_BUILD=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "false")
    SHARED_LIBS=$(grep "^SHARED_LIBS=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "ON")
    MULTI_THREADED=$(grep "^MULTI_THREADED=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "ON")
    ENABLE_SQLITE=$(grep "^ENABLE_SQLITE=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "ON")
    ENABLE_POSTGRES=$(grep "^ENABLE_POSTGRES=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_MYSQL=$(grep "^ENABLE_MYSQL=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_FIREBIRD=$(grep "^ENABLE_FIREBIRD=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_MSSQLSERVER=$(grep "^ENABLE_MSSQLSERVER=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_SSL=$(grep "^ENABLE_SSL=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "ON")
    ENABLE_HARU=$(grep "^ENABLE_HARU=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_PANGO=$(grep "^ENABLE_PANGO=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_OPENGL=$(grep "^ENABLE_OPENGL=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_SAML=$(grep "^ENABLE_SAML=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_QT4=$(grep "^ENABLE_QT4=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_QT5=$(grep "^ENABLE_QT5=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_EXAMPLES=$(grep "^ENABLE_EXAMPLES=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
    ENABLE_TESTS=$(grep "^ENABLE_TESTS=" "$config_file" | cut -d= -f2 | tr -d '"' || echo "OFF")
}

# Save configuration values to file
save_config_values() {
    local config_file="$1"
    local config_name="$2"
    
    # Get description from existing file or create default
    local description="Standard Wt build configuration"
    if [ -f "$config_file" ]; then
        description=$(grep "^# Description:" "$config_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "$description")
    fi
    
    # Write configuration file
    cat > "$config_file" << EOF
# Wt Library Build Configuration - $(echo "${config_name^}")
# Description: $description
# This file contains build configuration settings for the Wt library

# Build Configuration
BUILD_TYPE="$BUILD_TYPE"
INSTALL_PREFIX_CONF="$INSTALL_PREFIX_CONF"
JOBS="$JOBS"
CLEAN_BUILD="$CLEAN_BUILD"

# Library Options
SHARED_LIBS="$SHARED_LIBS"
MULTI_THREADED="$MULTI_THREADED"

# Database Backends
ENABLE_SQLITE="$ENABLE_SQLITE"
ENABLE_POSTGRES="$ENABLE_POSTGRES"
ENABLE_MYSQL="$ENABLE_MYSQL"
ENABLE_FIREBIRD="$ENABLE_FIREBIRD"
ENABLE_MSSQLSERVER="$ENABLE_MSSQLSERVER"

# Security & Graphics
ENABLE_SSL="$ENABLE_SSL"
ENABLE_HARU="$ENABLE_HARU"
ENABLE_PANGO="$ENABLE_PANGO"
ENABLE_OPENGL="$ENABLE_OPENGL"
ENABLE_SAML="$ENABLE_SAML"

# Qt Integration
ENABLE_QT4="$ENABLE_QT4"
ENABLE_QT5="$ENABLE_QT5"

# Additional Options
ENABLE_EXAMPLES="$ENABLE_EXAMPLES"
ENABLE_TESTS="$ENABLE_TESTS"

# Additional CMake Options
# You can add custom CMake options here
CMAKE_EXTRA_OPTS=""
EOF
    
    return 0
}

# Toggle ON/OFF values
toggle_value() {
    local current_value="$1"
    if [ "$current_value" = "ON" ] || [ "$current_value" = "true" ]; then
        echo "OFF"
    else
        echo "ON"
    fi
}

# Show configuration editor for a specific config
edit_single_config() {
    local config_name="$1"
    local config_file="$WT_SETTINGS_SCRIPT_DIR/build_configurations/${config_name}.conf"
    
    # Load current configuration
    if [ -f "$config_file" ]; then
        load_config_values "$config_file"
    else
        # Set defaults for new configuration
        BUILD_TYPE="Release"
        INSTALL_PREFIX_CONF="/usr/local"
        JOBS="auto"
        CLEAN_BUILD="false"
        SHARED_LIBS="ON"
        MULTI_THREADED="ON"
        ENABLE_SQLITE="ON"
        ENABLE_POSTGRES="OFF"
        ENABLE_MYSQL="OFF"
        ENABLE_FIREBIRD="OFF"
        ENABLE_MSSQLSERVER="OFF"
        ENABLE_SSL="ON"
        ENABLE_HARU="OFF"
        ENABLE_PANGO="OFF"
        ENABLE_OPENGL="OFF"
        ENABLE_SAML="OFF"
        ENABLE_QT4="OFF"
        ENABLE_QT5="OFF"
        ENABLE_EXAMPLES="OFF"
        ENABLE_TESTS="OFF"
    fi
    
    # Configuration editor loop
    while true; do
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --title "Edit Configuration: $config_name" \
            --menu "Configure build settings:" 25 90 18 \
            "build_type" "Build Type: $BUILD_TYPE" \
            "prefix" "Install Prefix: $INSTALL_PREFIX_CONF" \
            "jobs" "Parallel Jobs: $JOBS" \
            "clean" "Clean Build: $CLEAN_BUILD" \
            "shared" "Shared Libraries: $SHARED_LIBS" \
            "threads" "Multi-Threading: $MULTI_THREADED" \
            "sqlite" "SQLite Database: $ENABLE_SQLITE" \
            "postgres" "PostgreSQL Database: $ENABLE_POSTGRES" \
            "mysql" "MySQL Database: $ENABLE_MYSQL" \
            "firebird" "Firebird Database: $ENABLE_FIREBIRD" \
            "mssql" "MS SQL Server: $ENABLE_MSSQLSERVER" \
            "ssl" "SSL/TLS Support: $ENABLE_SSL" \
            "haru" "Haru PDF Library: $ENABLE_HARU" \
            "pango" "Pango Text Rendering: $ENABLE_PANGO" \
            "opengl" "OpenGL Support: $ENABLE_OPENGL" \
            "saml" "SAML Authentication: $ENABLE_SAML" \
            "qt4" "Qt4 Integration: $ENABLE_QT4" \
            "qt5" "Qt5 Integration: $ENABLE_QT5" \
            "examples" "Build Examples: $ENABLE_EXAMPLES" \
            "tests" "Build Tests: $ENABLE_TESTS" \
            "save" "Save Configuration" \
            "cancel" "Cancel Changes" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local status=$?
        
        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
        
        if [ $status -ne 0 ]; then
            break
        fi
        
        case "$choice" in
            "build_type")
                local new_build_type
                new_build_type=$(dialog \
                    --colors \
                    --clear \
                    --title "Build Type" \
                    --menu "Select build type:" 12 60 4 \
                    "Debug" "Debug build with symbols" \
                    "Release" "Optimized release build" \
                    "RelWithDebInfo" "Release with debug info" \
                    "MinSizeRel" "Minimum size release" \
                    3>&1 1>&2 2>&3)
                DIALOG_USED=true
                local build_status=$?
                printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                if [ $build_status -eq 0 ] && [ -n "$new_build_type" ]; then
                    BUILD_TYPE="$new_build_type"
                fi
                ;;
            "prefix")
                local new_prefix
                new_prefix=$(dialog \
                    --colors \
                    --clear \
                    --title "Install Prefix" \
                    --inputbox "Enter installation prefix:" 8 70 "$INSTALL_PREFIX_CONF" \
                    3>&1 1>&2 2>&3)
                DIALOG_USED=true
                local prefix_status=$?
                printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                if [ $prefix_status -eq 0 ] && [ -n "$new_prefix" ]; then
                    INSTALL_PREFIX_CONF="$new_prefix"
                fi
                ;;
            "jobs")
                local new_jobs
                new_jobs=$(dialog \
                    --colors \
                    --clear \
                    --title "Parallel Jobs" \
                    --inputbox "Number of parallel jobs (auto for automatic):" 8 60 "$JOBS" \
                    3>&1 1>&2 2>&3)
                DIALOG_USED=true
                local jobs_status=$?
                printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                if [ $jobs_status -eq 0 ] && [ -n "$new_jobs" ]; then
                    JOBS="$new_jobs"
                fi
                ;;
            "clean")
                CLEAN_BUILD=$(toggle_value "$CLEAN_BUILD")
                ;;
            "shared")
                SHARED_LIBS=$(toggle_value "$SHARED_LIBS")
                ;;
            "threads")
                MULTI_THREADED=$(toggle_value "$MULTI_THREADED")
                ;;
            "sqlite")
                ENABLE_SQLITE=$(toggle_value "$ENABLE_SQLITE")
                ;;
            "postgres")
                ENABLE_POSTGRES=$(toggle_value "$ENABLE_POSTGRES")
                ;;
            "mysql")
                ENABLE_MYSQL=$(toggle_value "$ENABLE_MYSQL")
                ;;
            "firebird")
                ENABLE_FIREBIRD=$(toggle_value "$ENABLE_FIREBIRD")
                ;;
            "mssql")
                ENABLE_MSSQLSERVER=$(toggle_value "$ENABLE_MSSQLSERVER")
                ;;
            "ssl")
                ENABLE_SSL=$(toggle_value "$ENABLE_SSL")
                ;;
            "haru")
                ENABLE_HARU=$(toggle_value "$ENABLE_HARU")
                ;;
            "pango")
                ENABLE_PANGO=$(toggle_value "$ENABLE_PANGO")
                ;;
            "opengl")
                ENABLE_OPENGL=$(toggle_value "$ENABLE_OPENGL")
                ;;
            "saml")
                ENABLE_SAML=$(toggle_value "$ENABLE_SAML")
                ;;
            "qt4")
                ENABLE_QT4=$(toggle_value "$ENABLE_QT4")
                ;;
            "qt5")
                ENABLE_QT5=$(toggle_value "$ENABLE_QT5")
                ;;
            "examples")
                ENABLE_EXAMPLES=$(toggle_value "$ENABLE_EXAMPLES")
                ;;
            "tests")
                ENABLE_TESTS=$(toggle_value "$ENABLE_TESTS")
                ;;
            "save")
                if save_config_values "$config_file" "$config_name"; then
                    dialog --title "Success" --msgbox "Configuration '$config_name' saved successfully!" 7 60
                    DIALOG_USED=true
                    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                    break
                else
                    dialog --title "Error" --msgbox "Failed to save configuration '$config_name'." 7 60
                    DIALOG_USED=true
                    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                fi
                ;;
            "cancel")
                break
                ;;
        esac
    done
}

# Show configuration editor menu
show_edit_menu() {
    while true; do
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --title "Configuration Editor" \
            --menu "Select configuration to edit:" 18 80 10 \
            "debug" "Edit debug configuration" \
            "default" "Edit default configuration" \
            "minimal" "Edit minimal configuration" \
            "release" "Edit release configuration" \
            "new" "Create new configuration" \
            "back" "Back to settings menu" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local status=$?
        
        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
        
        if [ $status -ne 0 ]; then
            break
        fi
        
        case "$choice" in
            "debug"|"default"|"minimal"|"release")
                edit_single_config "$choice"
                ;;
            "new")
                local new_name
                new_name=$(dialog \
                    --colors \
                    --clear \
                    --title "New Configuration" \
                    --inputbox "Enter name for new configuration:" 8 60 \
                    3>&1 1>&2 2>&3)
                DIALOG_USED=true
                local new_status=$?
                printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                
                if [ $new_status -eq 0 ] && [ -n "$new_name" ]; then
                    # Validate configuration name (alphanumeric and underscore only)
                    if [[ "$new_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
                        edit_single_config "$new_name"
                    else
                        dialog --title "Invalid Name" --msgbox "Configuration name can only contain letters, numbers, and underscores." 8 70
                        DIALOG_USED=true
                        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
                    fi
                fi
                ;;
            "back")
                break
                ;;
        esac
    done
}

# Main settings menu
show_settings_menu() {
    ensure_dialog
    
    while true; do
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --no-ok \
            --no-cancel \
            --backtitle "Wt Library Settings" \
            --title "Configuration Management" \
            --menu "Current Settings:\n\nWt Version: $CURRENT_WT_VERSION\nBuild Config: $CURRENT_BUILD_CONFIG\n\nAvailable Options:" 18 80 8 \
            "version" "Change Wt version" \
            "config" "Change build configuration" \
            "edit" "Edit configuration files" \
            "back" "Back to main menu" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local menu_status=$?
        
        # Always reset terminal after dialog
        printf '\033c'  # Full terminal reset
        clear
        printf '\033[0m'  # Reset colors
        tput sgr0 2>/dev/null || true  # Reset all attributes
        
        if [ $menu_status -ne 0 ]; then
            print_status "User exited from settings menu."
            break
        fi
        
        case "$choice" in
            "version")
                show_version_menu
                ;;
            "config")
                show_config_menu
                ;;
            "edit")
                show_edit_menu
                ;;
            "back")
                break
                ;;
            *)
                print_warning "Unknown menu selection: $choice"
                ;;
        esac
    done
}

show_settings_menu
print_success "${SCRIPT_NAME%.sh} completed successfully!"

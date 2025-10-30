#!/usr/bin/env bash
# Script to launch interactive menu for Wt library management
# Usage: ./scripts/libs/wt/interactive.sh

set -e  # Exit on any error

WT_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_ROOT="$(dirname "$(dirname "$WT_SCRIPT_DIR")")"
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
source "$WT_SCRIPT_DIR/interactive_configuration.sh"

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

# Check Wt library status
check_wt_status() {
    local wt_source="$PROJECT_ROOT/build/wt"
    local installed_status="Not installed"
    local source_status="Not downloaded"
    
    # Check if source exists
    if [ -d "$wt_source" ]; then
        if [ -d "$wt_source/.git" ]; then
            source_status="Downloaded ($(cd "$wt_source" && git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown"))"
        else
            source_status="Downloaded (unknown version)"
        fi
    fi
    
    # Check if Wt is installed
    if command -v wt-config >/dev/null 2>&1; then
        local version
        version=$(wt-config --version 2>/dev/null || echo "unknown")
        installed_status="Installed (v$version)"
    elif pkg-config --exists wt 2>/dev/null; then
        local version
        version=$(pkg-config --modversion wt 2>/dev/null || echo "unknown")
        installed_status="Installed (v$version)"
    elif [ -f "/usr/local/lib/libwt.so" ] || [ -f "/usr/lib/libwt.so" ] || [ -f "/usr/lib/x86_64-linux-gnu/libwt.so" ]; then
        installed_status="Installed (version unknown)"
    fi
    
    echo "$source_status|$installed_status"
}

# Load available build configurations
load_build_configs() {
    local configs=""
    local config_dir="$WT_SCRIPT_DIR/build_configurations"
    
    if [ -d "$config_dir" ]; then
        for config_file in "$config_dir"/*.conf; do
            if [ -f "$config_file" ]; then
                local config_name
                config_name=$(basename "$config_file" .conf)
                local description
                description=$(grep "^# Description:" "$config_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "No description")
                local current_marker=""
                if [ "$config_name" = "$CURRENT_BUILD_CONFIG" ]; then
                    current_marker=" (current)"
                fi
                configs="$configs$config_name \"$description$current_marker\" "
            fi
        done
    fi
    
    if [ -z "$configs" ]; then
        local current_marker=""
        if [ "default" = "$CURRENT_BUILD_CONFIG" ]; then
            current_marker=" (current)"
        fi
        configs="default \"Standard Wt build configuration$current_marker\" "
    fi
    
    echo "$configs"
}

# Run download script
run_download() {
    local args=()
    
    # Use current configuration version by default
    local default_version="$CURRENT_WT_VERSION"
    
    # Ask for version with current config as default
    local version
    version=$(dialog \
        --colors \
        --clear \
        --title "Download Wt Library" \
        --inputbox "Enter Wt version to download (current: $CURRENT_WT_VERSION):" 8 70 "$default_version" \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -ne 0 ]; then
        return 0  # User cancelled
    fi
    
    if [ -n "$version" ] && [ "$version" != "latest" ]; then
        args+=("--version" "$version")
    fi
    
    # Ask about force download
    if dialog \
        --colors \
        --clear \
        --title "Download Options" \
        --yesno "Force download (overwrite existing)?" 7 50; then
        args+=("--force")
    fi
    DIALOG_USED=true
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    # Update configuration if version was changed
    if [ -n "$version" ] && [ "$version" != "$CURRENT_WT_VERSION" ]; then
        update_wt_version "$version"
    fi
    
    print_status "Downloading Wt library..."
    if bash "$WT_SCRIPT_DIR/download.sh" "${args[@]}"; then
        dialog --title "Success" --msgbox "Wt library downloaded successfully." 7 60
    else
        dialog --title "Error" --msgbox "Download failed. Check logs at $LOG_FILE for details." 8 70
    fi
    DIALOG_USED=true
}

# Run install script
run_install() {
    local configs
    configs=$(load_build_configs)
    
    if [ -z "$configs" ]; then
        dialog --title "Error" --msgbox "No build configurations available." 7 60
        DIALOG_USED=true
        return 1
    fi
    
    local config
    config=$(dialog \
        --colors \
        --clear \
        --title "Install Wt Library" \
        --menu "Select build configuration (current: $CURRENT_BUILD_CONFIG):" 15 80 8 \
        $configs \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -ne 0 ]; then
        return 0  # User cancelled
    fi
    
    local args=()
    if [ "$config" != "default" ]; then
        args+=("--config" "$config")
    fi
    
    # Ask for parallel jobs
    local jobs
    jobs=$(dialog \
        --colors \
        --clear \
        --title "Build Options" \
        --inputbox "Number of parallel build jobs:" 8 50 "$(nproc)" \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$jobs" ] && [ "$jobs" -gt 0 ] 2>/dev/null; then
        args+=("--jobs" "$jobs")
    fi
    
    # Update configuration if changed
    if [ "$config" != "$CURRENT_BUILD_CONFIG" ]; then
        update_build_config "$config"
    fi
    
    print_status "Installing Wt library with configuration: $config"
    if bash "$WT_SCRIPT_DIR/install.sh" "${args[@]}"; then
        dialog --title "Success" --msgbox "Wt library installed successfully." 7 60
    else
        dialog --title "Error" --msgbox "Installation failed. Check logs at $LOG_FILE for details." 8 70
    fi
    DIALOG_USED=true
}

# Run build script
run_build() {
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    print_status "Running Wt library build script..."
    if bash "$WT_SCRIPT_DIR/build.sh"; then
        dialog --title "Success" --msgbox "Wt library built successfully." 7 60
    else
        dialog --title "Error" --msgbox "Build failed. Check logs at $LOG_FILE for details." 8 70
    fi
    DIALOG_USED=true
}

# Run examples script
run_examples() {
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    print_status "Opening Wt examples manager..."
    bash "$WT_SCRIPT_DIR/interactive_examples.sh"
}

# Run settings script
run_settings() {
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    print_status "Opening Wt library settings..."
    bash "$WT_SCRIPT_DIR/interactive_settings.sh"
    
    # Reload configuration after settings changes
    # shellcheck disable=SC1090,SC1091
    source "$WT_SCRIPT_DIR/interactive_configuration.sh"
}

# Run uninstall script
run_uninstall() {
    if dialog \
        --colors \
        --clear \
        --title "Uninstall Wt Library" \
        --yesno "Are you sure you want to uninstall Wt library?\n\nThis will remove all Wt files from the system." 9 60; then
        
        local dry_run=""
        if dialog \
            --colors \
            --clear \
            --title "Uninstall Options" \
            --yesno "Perform dry run first (show what would be removed)?" 7 60; then
            dry_run="--dry-run"
        fi
        DIALOG_USED=true
        
        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
        
        local args=()
        if [ -n "$dry_run" ]; then
            args+=("$dry_run")
        fi
        
        print_status "Uninstalling Wt library..."
        if bash "$WT_SCRIPT_DIR/uninstall.sh" "${args[@]}"; then
            if [ -n "$dry_run" ]; then
                dialog --title "Dry Run Complete" --msgbox "Dry run completed. Check output for files that would be removed." 8 70
            else
                dialog --title "Success" --msgbox "Wt library uninstalled successfully." 7 60
            fi
        else
            dialog --title "Error" --msgbox "Uninstall failed. Check logs at $LOG_FILE for details." 8 70
        fi
    fi
    DIALOG_USED=true
}

# Show build configurations
show_configurations() {
    local config_dir="$WT_SCRIPT_DIR/build_configurations"
    local config_list=""
    
    if [ -d "$config_dir" ]; then
        for config_file in "$config_dir"/*.conf; do
            if [ -f "$config_file" ]; then
                local config_name
                config_name=$(basename "$config_file" .conf)
                local description
                description=$(grep "^# Description:" "$config_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "No description")
                config_list="$config_list$config_name: $description\n"
            fi
        done
    fi
    
    if [ -z "$config_list" ]; then
        config_list="No build configurations found.\n"
    fi
    
    dialog \
        --colors \
        --clear \
        --title "Available Build Configurations" \
        --msgbox "$config_list" 15 80
    DIALOG_USED=true
}

show_menu() {
    ensure_dialog
    
    while true; do
        local status_info
        status_info=$(check_wt_status)
        local source_status
        local install_status
        source_status=$(echo "$status_info" | cut -d'|' -f1)
        install_status=$(echo "$status_info" | cut -d'|' -f2)
        
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --no-ok \
            --no-cancel \
            --backtitle "Wt Library Management" \
            --title "Wt Library Control Panel" \
            --menu "Available Operations:\n\nSource: $source_status\nSystem: $install_status\nConfig: v$CURRENT_WT_VERSION | $CURRENT_BUILD_CONFIG" 24 90 12 \
            download "Download Wt source code" \
            build "Build Wt library" \
            install "Build and install Wt library" \
            uninstall "Remove Wt library from system" \
            examples "Build and run Wt examples" \
            settings "Configure Wt version and build settings" \
            back "Back to main menu" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local menu_status=$?
        
        # Always reset terminal after dialog
        printf '\033c'  # Full terminal reset
        clear
        printf '\033[0m'  # Reset colors
        tput sgr0 2>/dev/null || true  # Reset all attributes
        
        if [ $menu_status -ne 0 ]; then
            print_status "User exited from Wt library menu."
            break
        fi
        
        case "$choice" in
            download)
                run_download
                ;;
            build)
                run_build
                ;;
            install)
                run_install
                ;;
            uninstall)
                run_uninstall
                ;;
            examples)
                run_examples
                ;;
            settings)
                run_settings
                ;;
            back)
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
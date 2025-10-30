#!/usr/bin/env bash
# Configuration state management for Wt library scripts
# This script can be sourced or executed directly
# Usage: source ./scripts/libs/wt/interactive_configuration.sh
#        ./scripts/libs/wt/interactive_configuration.sh

# Current configuration state
CURRENT_WT_VERSION="latest"
CURRENT_BUILD_CONFIG="debug"

# Script detection
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    EXECUTED_DIRECTLY=true
    set -e  # Exit on any error
    
    WT_CONFIG_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    SCRIPTS_ROOT="$(cd "$WT_CONFIG_SCRIPT_DIR/../.." && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPTS_ROOT")"
    SCRIPT_NAME="$(basename "$0")"
    OUTPUT_DIR="$SCRIPTS_ROOT/output/libs/wt"
    LOG_FILE="$OUTPUT_DIR/${SCRIPT_NAME%.sh}.log"
    
    mkdir -p "$OUTPUT_DIR"
    > "$LOG_FILE"
    
    # Source shared utilities
    # shellcheck disable=SC1090,SC1091
    source "$SCRIPTS_ROOT/utils.sh"
else
    # Script is being sourced
    EXECUTED_DIRECTLY=false
fi

# Update download version in this script
update_wt_version() {
    local new_version="$1"
    if [ -z "$new_version" ]; then
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;31mError: Version argument is required\033[0m" >&2
        else
            echo "Error: Version argument is required" >&2
        fi
        return 1
    fi
    
    local script_path="${BASH_SOURCE[0]}"
    if [ "$EXECUTED_DIRECTLY" = true ]; then
        echo -e "\033[1;33mUpdating Wt version configuration to: $new_version\033[0m"
    fi
    
    # Update the CURRENT_WT_VERSION assignment in this script
    sed -i "s/^CURRENT_WT_VERSION=.*/CURRENT_WT_VERSION=\"$new_version\"/" "$script_path"
    
    if [ $? -eq 0 ]; then
        CURRENT_WT_VERSION="$new_version"
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;32mWt version configuration updated successfully\033[0m"
        fi
        return 0
    else
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;31mFailed to update Wt version configuration\033[0m" >&2
        else
            echo "Error: Failed to update Wt version configuration" >&2
        fi
        return 1
    fi
}

# Update build configuration in this script
update_build_config() {
    local new_config="$1"
    if [ -z "$new_config" ]; then
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;31mError: Configuration argument is required\033[0m" >&2
        else
            echo "Error: Configuration argument is required" >&2
        fi
        return 1
    fi
    
    local script_path="${BASH_SOURCE[0]}"
    if [ "$EXECUTED_DIRECTLY" = true ]; then
        echo -e "\033[1;33mUpdating build configuration to: $new_config\033[0m"
    fi
    
    # Update the CURRENT_BUILD_CONFIG assignment in this script
    sed -i "s/^CURRENT_BUILD_CONFIG=.*/CURRENT_BUILD_CONFIG=\"$new_config\"/" "$script_path"
    
    if [ $? -eq 0 ]; then
        CURRENT_BUILD_CONFIG="$new_config"
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;32mBuild configuration updated successfully\033[0m"
        fi
        return 0
    else
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;31mFailed to update build configuration\033[0m" >&2
        else
            echo "Error: Failed to update build configuration" >&2
        fi
        return 1
    fi
}

# Get available build configurations
get_available_build_configs() {
    local wt_script_dir
    if [ "$EXECUTED_DIRECTLY" = true ]; then
        wt_script_dir="$WT_CONFIG_SCRIPT_DIR"
    else
        wt_script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    fi
    
    local config_dir="$wt_script_dir/build_configurations"
    local configs=()
    
    # Add default configuration
    configs+=("default")
    
    if [ -d "$config_dir" ]; then
        for config_file in "$config_dir"/*.conf; do
            if [ -f "$config_file" ]; then
                local config_name
                config_name=$(basename "$config_file" .conf)
                if [ "$config_name" != "default" ]; then
                    configs+=("$config_name")
                fi
            fi
        done
    fi
    
    printf '%s\n' "${configs[@]}"
}

# Validate build configuration exists
validate_build_config() {
    local config="$1"
    local available_configs
    available_configs=$(get_available_build_configs)
    
    while IFS= read -r available_config; do
        if [ "$config" = "$available_config" ]; then
            return 0
        fi
    done <<< "$available_configs"
    
    return 1
}

# Show current configuration
show_current_config() {
    if [ "$EXECUTED_DIRECTLY" = true ]; then
        echo -e "\033[1;34mCurrent Wt Library Configuration:\033[0m"
        echo -e "  \033[1;36mDownload Version:\033[0m $CURRENT_WT_VERSION"
        echo -e "  \033[1;36mBuild Configuration:\033[0m $CURRENT_BUILD_CONFIG"
        echo ""
        
        echo -e "\033[1;34mAvailable Build Configurations:\033[0m"
        local configs
        configs=$(get_available_build_configs)
        while IFS= read -r config; do
            if [ "$config" = "$CURRENT_BUILD_CONFIG" ]; then
                echo -e "  \033[1;32m● $config\033[0m (current)"
            else
                echo -e "  \033[1;36m○ $config\033[0m"
            fi
        done <<< "$configs"
    else
        echo "Download Version: $CURRENT_WT_VERSION"
        echo "Build Configuration: $CURRENT_BUILD_CONFIG"
    fi
}

# Interactive configuration menu (can be called from sourced scripts too)
interactive_config_menu() {
    if ! command -v dialog >/dev/null 2>&1; then
        if [ "$EXECUTED_DIRECTLY" = true ]; then
            echo -e "\033[1;31mError: The 'dialog' command is required for interactive configuration.\033[0m" >&2
            echo -e "\033[1;33mInstall it via your package manager (e.g. sudo apt install dialog)\033[0m"
        else
            echo "Error: The 'dialog' command is required for interactive configuration." >&2
            echo "Install it via your package manager (e.g. sudo apt install dialog)"
        fi
        return 1
    fi
    
    local dialog_used=false
    local original_trap
    original_trap=$(trap -p EXIT)
    
    # Cleanup function for dialog
    cleanup_dialog() {
        if [ "$dialog_used" = true ]; then
            printf '\033c'  # Full terminal reset
            clear
            printf '\033[0m'  # Reset colors
            tput sgr0 2>/dev/null || true  # Reset all attributes
        fi
        # Restore original trap
        eval "$original_trap"
    }
    
    trap cleanup_dialog EXIT
    
    while true; do
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --no-ok \
            --no-cancel \
            --backtitle "Wt Library Configuration" \
            --title "Configuration Settings" \
            --menu "Current Settings:\n\nDownload Version: \Z1$CURRENT_WT_VERSION\Zn\nBuild Config: \Z1$CURRENT_BUILD_CONFIG\Zn" 16 70 6 \
            version "$CURRENT_WT_VERSION (change version)" \
            config "$CURRENT_BUILD_CONFIG (change configuration)" \
            back "Back to main menu" \
            3>&1 1>&2 2>&3)
        dialog_used=true
        local status=$?
        
        # Reset terminal after dialog
        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
        
        if [ $status -ne 0 ]; then
            if [ "$EXECUTED_DIRECTLY" = true ]; then
                echo -e "\033[1;33mConfiguration menu exited.\033[0m"
            fi
            break
        fi
        
        case "$choice" in
            version)
                configure_version
                ;;
            config)
                configure_build_config
                ;;
            back)
                break
                ;;
            *)
                if [ "$EXECUTED_DIRECTLY" = true ]; then
                    echo -e "\033[1;33mWarning: Unknown menu selection: $choice\033[0m"
                fi
                ;;
        esac
    done
    
    # Clean up the trap
    trap - EXIT
    eval "$original_trap"
}

# Configure download version interactively
configure_version() {
    local new_version
    new_version=$(dialog \
        --colors \
        --clear \
        --title "Configure Download Version" \
        --inputbox "Enter Wt version to download:\n(e.g., 'latest', '4.10.0', '4.9.2')" 10 60 "$CURRENT_WT_VERSION" \
        3>&1 1>&2 2>&3)
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$new_version" ]; then
        if update_wt_version "$new_version"; then
            dialog --title "Success" --msgbox "Download version updated to: $new_version" 7 60
        else
            dialog --title "Error" --msgbox "Failed to update download version." 7 60
        fi
    fi
}

# Configure build configuration interactively
configure_build_config() {
    local configs
    configs=$(get_available_build_configs)
    
    # Get the correct script directory for both sourced and direct execution
    local wt_script_dir
    if [ "$EXECUTED_DIRECTLY" = true ]; then
        wt_script_dir="$WT_CONFIG_SCRIPT_DIR"
    else
        wt_script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    fi
    
    local menu_items=""
    while IFS= read -r config; do
        local description="Standard configuration"
        if [ "$config" != "default" ]; then
            # Try to get description from config file
            local config_file="$wt_script_dir/build_configurations/$config.conf"
            if [ -f "$config_file" ]; then
                description=$(grep "^# Description:" "$config_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "No description")
            fi
        fi
        menu_items="$menu_items$config \"$description\" "
    done <<< "$configs"
    
    if [ -z "$menu_items" ]; then
        dialog --title "Error" --msgbox "No build configurations available." 7 60
        return 1
    fi
    
    local new_config
    new_config=$(dialog \
        --colors \
        --clear \
        --title "Select Build Configuration" \
        --menu "Available build configurations:" 15 80 8 \
        $menu_items \
        3>&1 1>&2 2>&3)
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$new_config" ]; then
        if update_build_config "$new_config"; then
            dialog --title "Success" --msgbox "Build configuration updated to: $new_config" 7 60
        else
            dialog --title "Error" --msgbox "Failed to update build configuration." 7 60
        fi
    fi
}

# Main execution (only when script is executed directly)
if [ "$EXECUTED_DIRECTLY" = true ]; then
    show_usage() {
        echo -e "${BOLD}${BLUE}Usage:${NC} $0 [command] [arguments]"
        echo ""
        echo -e "${BOLD}${GREEN}Description:${NC}"
        echo "  Manage Wt library configuration settings"
        echo ""
        echo -e "${BOLD}${YELLOW}Commands:${NC}"
        echo -e "  ${CYAN}show${NC}                    Show current configuration"
        echo -e "  ${CYAN}set-version VERSION${NC}     Set download version"
        echo -e "  ${CYAN}set-config CONFIG${NC}       Set build configuration"
        echo -e "  ${CYAN}list-configs${NC}            List available build configurations"
        echo -e "  ${CYAN}interactive${NC}             Launch interactive configuration menu"
        echo -e "  ${CYAN}-h, --help${NC}              Show this help message"
        echo ""
        echo -e "${BOLD}${YELLOW}Examples:${NC}"
        echo -e "  ${CYAN}$0 show${NC}"
        echo -e "  ${CYAN}$0 set-version 4.10.0${NC}"
        echo -e "  ${CYAN}$0 set-config debug${NC}"
        echo -e "  ${CYAN}$0 interactive${NC}"
        echo ""
    }
    
    if [ $# -eq 0 ]; then
        interactive_config_menu
    else
        case "$1" in
            show)
                show_current_config
                ;;
            set-version)
                if [ -z "$2" ]; then
                    echo -e "\033[1;31mError: Version argument is required\033[0m" >&2
                    echo "Usage: $0 set-version VERSION"
                    exit 1
                fi
                update_wt_version "$2"
                ;;
            set-config)
                if [ -z "$2" ]; then
                    echo -e "\033[1;31mError: Configuration argument is required\033[0m" >&2
                    echo "Usage: $0 set-config CONFIG"
                    exit 1
                fi
                if validate_build_config "$2"; then
                    update_build_config "$2"
                else
                    echo -e "\033[1;31mError: Invalid build configuration: $2\033[0m" >&2
                    echo -e "\033[1;33mAvailable configurations:\033[0m"
                    get_available_build_configs
                    exit 1
                fi
                ;;
            list-configs)
                echo -e "\033[1;34mAvailable build configurations:\033[0m"
                get_available_build_configs
                ;;
            interactive)
                interactive_config_menu
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                echo -e "\033[1;31mError: Unknown command: $1\033[0m" >&2
                show_usage
                exit 1
                ;;
        esac
    fi
    
    echo -e "\033[1;32m${SCRIPT_NAME%.sh} completed successfully!\033[0m"
fi
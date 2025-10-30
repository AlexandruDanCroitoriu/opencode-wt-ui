#!/usr/bin/env bash
# Script to uninstall Wt library from system
# Usage: ./scripts/libs/wt/uninstall.sh [options]

set -e  # Exit on any error

WT_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_ROOT="$(cd "$WT_SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_ROOT")"
SCRIPT_NAME="$(basename "$0")"
OUTPUT_DIR="$SCRIPTS_ROOT/output/libs/wt"
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
    echo "  Uninstall Wt library from system-wide installation"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}         Show this help message"
    echo -e "  ${CYAN}-f, --force${NC}        Force uninstall without confirmation"
    echo -e "  ${CYAN}-v, --verbose${NC}      Show verbose output"
    echo -e "  ${CYAN}--dry-run${NC}          Show what would be removed without actually removing"
    echo -e "  ${CYAN}--prefix PATH${NC}      Uninstall from specific prefix (default: /usr/local)"
    echo ""
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."

# Default values
FORCE_UNINSTALL=false
VERBOSE=false
DRY_RUN=false
INSTALL_PREFIX="/usr/local"

# Argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_UNINSTALL=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --prefix)
            if [ -z "$2" ]; then
                print_error "Installation prefix is required"
                show_usage
                exit 1
            fi
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Confirmation dialog
confirm_action() {
    local message="$1"
    local default_yes="${2:-false}"
    
    if [ "$FORCE_UNINSTALL" = true ]; then
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}$message${NC}"
    
    if [ "$default_yes" = true ]; then
        echo -e "${YELLOW}Continue? (Y/n):${NC} "
        read -r confirm
        [[ "$confirm" =~ ^[Nn]$ ]] && return 1
    else
        echo -e "${YELLOW}Continue? (y/N):${NC} "
        read -r confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && return 1
    fi
    
    return 0
}

# Find Wt files in the system
find_wt_files() {
    print_status "Scanning for Wt installation files in $INSTALL_PREFIX..."
    
    local wt_files=()
    
    # Find library files
    if [ -d "$INSTALL_PREFIX/lib" ]; then
        while IFS= read -r -d '' file; do
            wt_files+=("$file")
        done < <(find "$INSTALL_PREFIX/lib" -name "libwt*" -print0 2>/dev/null || true)
    fi
    
    # Find header files
    if [ -d "$INSTALL_PREFIX/include/Wt" ]; then
        wt_files+=("$INSTALL_PREFIX/include/Wt")
    fi
    
    # Find CMake files
    if [ -d "$INSTALL_PREFIX/lib/cmake" ]; then
        while IFS= read -r -d '' file; do
            wt_files+=("$file")
        done < <(find "$INSTALL_PREFIX/lib/cmake" -name "*wt*" -print0 2>/dev/null || true)
    fi
    
    # Find pkg-config files
    if [ -d "$INSTALL_PREFIX/lib/pkgconfig" ]; then
        while IFS= read -r -d '' file; do
            wt_files+=("$file")
        done < <(find "$INSTALL_PREFIX/lib/pkgconfig" -name "*wt*" -print0 2>/dev/null || true)
    fi
    
    # Find binary files
    if [ -d "$INSTALL_PREFIX/bin" ]; then
        while IFS= read -r -d '' file; do
            wt_files+=("$file")
        done < <(find "$INSTALL_PREFIX/bin" -name "*wt*" -print0 2>/dev/null || true)
    fi
    
    # Find share files
    if [ -d "$INSTALL_PREFIX/share" ]; then
        while IFS= read -r -d '' file; do
            wt_files+=("$file")
        done < <(find "$INSTALL_PREFIX/share" -name "*wt*" -print0 2>/dev/null || true)
    fi
    
    printf '%s\n' "${wt_files[@]}"
}

# Display files to be removed
display_removal_list() {
    local files=("$@")
    
    if [ ${#files[@]} -eq 0 ]; then
        print_warning "No Wt installation files found in $INSTALL_PREFIX"
        return 1
    fi
    
    echo ""
    print_status "Files to be removed:"
    echo ""
    
    local total_size=0
    local file_count=0
    
    for file in "${files[@]}"; do
        if [ -e "$file" ]; then
            file_count=$((file_count + 1))
            
            if [ "$VERBOSE" = true ]; then
                local size
                if [ -f "$file" ]; then
                    size=$(du -h "$file" 2>/dev/null | cut -f1 || echo "0")
                    total_size=$((total_size + $(du -k "$file" 2>/dev/null | cut -f1 || echo "0")))
                else
                    size="<dir>"
                fi
                echo -e "  ${RED}[-]${NC} $file ${CYAN}($size)${NC}"
            else
                echo -e "  ${RED}[-]${NC} $file"
            fi
        fi
    done
    
    echo ""
    if [ "$VERBOSE" = true ] && [ $total_size -gt 0 ]; then
        local total_size_mb=$((total_size / 1024))
        print_status "Total: $file_count files, approximately ${total_size_mb}MB"
    else
        print_status "Total: $file_count files"
    fi
    echo ""
    
    return 0
}

# Remove Wt files
remove_wt_files() {
    local files=("$@")
    local removed_count=0
    local failed_count=0
    
    print_status "Removing Wt installation files..."
    
    for file in "${files[@]}"; do
        if [ -e "$file" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "  ${YELLOW}[DRY RUN]${NC} Would remove: $file"
            else
                if [ "$VERBOSE" = true ]; then
                    echo -e "  ${RED}Removing:${NC} $file"
                fi
                
                # Check if we need sudo
                local parent_dir
                parent_dir=$(dirname "$file")
                if [ ! -w "$parent_dir" ]; then
                    if sudo rm -rf "$file" 2>>"$LOG_FILE"; then
                        removed_count=$((removed_count + 1))
                    else
                        print_error "Failed to remove: $file"
                        failed_count=$((failed_count + 1))
                    fi
                else
                    if rm -rf "$file" 2>>"$LOG_FILE"; then
                        removed_count=$((removed_count + 1))
                    else
                        print_error "Failed to remove: $file"
                        failed_count=$((failed_count + 1))
                    fi
                fi
            fi
        fi
    done
    
    if [ "$DRY_RUN" = true ]; then
        print_status "Dry run completed. No files were actually removed."
    else
        if [ $failed_count -eq 0 ]; then
            print_success "Successfully removed $removed_count files"
        else
            print_warning "Removed $removed_count files, $failed_count failed"
        fi
    fi
}

# Update library cache
update_library_cache() {
    if [ "$DRY_RUN" = true ]; then
        print_status "Would update library cache with ldconfig"
        return
    fi
    
    if command -v ldconfig >/dev/null 2>&1; then
        print_status "Updating library cache..."
        if sudo ldconfig 2>>"$LOG_FILE"; then
            print_success "Library cache updated"
        else
            print_warning "Failed to update library cache"
        fi
    else
        print_warning "ldconfig not found, skipping library cache update"
    fi
}

# Remove build directory
remove_build_directory() {
    local libs_dir="$PROJECT_ROOT/libs"
    local wt_source_dir="$libs_dir/wt"
    local build_dir="$wt_source_dir/build"
    
    if [ -d "$build_dir" ]; then
        if confirm_action "Remove build directory: $build_dir?" false; then
            if [ "$DRY_RUN" = true ]; then
                print_status "Would remove build directory: $build_dir"
            else
                print_status "Removing build directory: $build_dir"
                if rm -rf "$build_dir"; then
                    print_success "Build directory removed"
                else
                    print_error "Failed to remove build directory"
                fi
            fi
        fi
    fi
}

# Verify uninstallation
verify_uninstallation() {
    if [ "$DRY_RUN" = true ]; then
        return
    fi
    
    print_status "Verifying uninstallation..."
    
    local remaining_files
    remaining_files=($(find_wt_files))
    
    if [ ${#remaining_files[@]} -eq 0 ]; then
        print_success "Wt library has been completely removed from $INSTALL_PREFIX"
    else
        print_warning "Some Wt files may still remain:"
        for file in "${remaining_files[@]}"; do
            echo -e "  ${YELLOW}[!]${NC} $file"
        done
    fi
}

# Main execution
print_status "Scanning for Wt installation in: $INSTALL_PREFIX"

# Find all Wt files
wt_files=($(find_wt_files))

# Display what will be removed
if ! display_removal_list "${wt_files[@]}"; then
    print_status "Nothing to uninstall"
    exit 0
fi

# Confirm uninstallation
if [ "$DRY_RUN" = false ]; then
    if ! confirm_action "This will remove all Wt library files from $INSTALL_PREFIX. Are you sure?" false; then
        print_status "Uninstallation cancelled by user"
        exit 0
    fi
fi

# Remove the files
remove_wt_files "${wt_files[@]}"

# Update library cache
update_library_cache

# Offer to remove build directory
remove_build_directory

# Verify uninstallation
verify_uninstallation

if [ "$DRY_RUN" = false ]; then
    print_success "${SCRIPT_NAME%.sh} completed successfully!"
else
    print_success "Dry run completed successfully!"
fi
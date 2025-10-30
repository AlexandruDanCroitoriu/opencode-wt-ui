#!/usr/bin/env bash
# Script to download the Wt library source code
# Usage: ./scripts/libs/wt/download.sh [options]

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
    echo "  Downloads the Wt library source code from the official repository"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}        Show this help message"
    echo -e "  ${CYAN}--version VERSION${NC} Download specific version (default: latest)"
    echo -e "  ${CYAN}--force${NC}           Force re-download even if already exists"
    echo ""
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."

# Default values
WT_VERSION="latest"
FORCE_DOWNLOAD=false
BUILD_DIR="$PROJECT_ROOT/build"
WT_SOURCE_DIR="$BUILD_DIR/wt"

# Argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            if [ -z "$2" ]; then
                print_error "Version argument is required"
                show_usage
                exit 1
            fi
            WT_VERSION="$2"
            shift 2
            ;;
        --force)
            FORCE_DOWNLOAD=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if git is available
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
}

# Check if Wt is already downloaded
check_existing_wt() {
    if [ -d "$WT_SOURCE_DIR" ] && [ "$FORCE_DOWNLOAD" = false ]; then
        print_warning "Wt source already exists at: $WT_SOURCE_DIR"
        print_status "Use --force to re-download or remove the directory manually"
        
        # Check if it's a valid git repository
        if [ -d "$WT_SOURCE_DIR/.git" ]; then
            cd "$WT_SOURCE_DIR"
            local current_version
            current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
            print_status "Current version: $current_version"
        fi
        
        return 1
    fi
    return 0
}

# Download Wt source code
download_wt() {
    local repo_url="https://github.com/emweb/wt.git"
    
    print_status "Creating build directory: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    # Remove existing directory if force download
    if [ "$FORCE_DOWNLOAD" = true ] && [ -d "$WT_SOURCE_DIR" ]; then
        print_warning "Removing existing Wt source directory"
        rm -rf "$WT_SOURCE_DIR"
    fi
    
    print_status "Downloading Wt library source code..."
    print_status "Repository: $repo_url"
    print_status "Target directory: $WT_SOURCE_DIR"
    
    if [ "$WT_VERSION" = "latest" ]; then
        print_status "Cloning latest version..."
        if git clone "$repo_url" "$WT_SOURCE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
            cd "$WT_SOURCE_DIR"
            local latest_tag
            latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "main")
            print_success "Downloaded Wt source code (version: $latest_tag)"
        else
            print_error "Failed to clone Wt repository"
            return 1
        fi
    else
        print_status "Cloning and checking out version: $WT_VERSION"
        if git clone "$repo_url" "$WT_SOURCE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
            cd "$WT_SOURCE_DIR"
            if git checkout "tags/$WT_VERSION" 2>/dev/null || git checkout "$WT_VERSION"; then
                print_success "Downloaded Wt source code version: $WT_VERSION"
            else
                print_error "Failed to checkout version: $WT_VERSION"
                print_warning "Available tags:"
                git tag --list | tail -10
                return 1
            fi
        else
            print_error "Failed to clone Wt repository"
            return 1
        fi
    fi
}

# Verify download
verify_download() {
    if [ ! -d "$WT_SOURCE_DIR" ]; then
        print_error "Wt source directory not found after download"
        return 1
    fi
    
    if [ ! -f "$WT_SOURCE_DIR/CMakeLists.txt" ]; then
        print_error "CMakeLists.txt not found in Wt source directory"
        return 1
    fi
    
    print_success "Wt source code verification passed"
    
    # Show download summary
    cd "$WT_SOURCE_DIR"
    local version
    local commit
    local size
    version=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
    commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    size=$(du -sh . 2>/dev/null | cut -f1 || echo "unknown")
    
    echo ""
    print_status "Download Summary:"
    echo -e "  ${CYAN}Version:${NC} $version"
    echo -e "  ${CYAN}Commit:${NC} $commit"
    echo -e "  ${CYAN}Size:${NC} $size"
    echo -e "  ${CYAN}Location:${NC} $WT_SOURCE_DIR"
    echo ""
}

# Main execution
print_status "Starting Wt library download..."

check_git

if check_existing_wt; then
    download_wt
    verify_download
    
    print_success "Wt library download completed successfully!"
else
    print_status "Wt library already available"
fi

print_success "${SCRIPT_NAME%.sh} completed successfully!"
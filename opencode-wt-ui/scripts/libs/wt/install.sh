#!/usr/bin/env bash
# Script to build and install the Wt library
# Usage: ./scripts/libs/wt/install.sh [options]

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
    echo "  Builds and installs the Wt library from source using configuration files"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}               Show this help message"
    echo -e "  ${CYAN}-c, --config CONFIG${NC}      Use specific configuration (default: default)"
    echo -e "  ${CYAN}--config-file PATH${NC}       Use custom configuration file"
    echo -e "  ${CYAN}--prefix PATH${NC}            Installation prefix (overrides config)"
    echo -e "  ${CYAN}--clean${NC}                  Clean build directory before building"
    echo ""
    echo -e "${BOLD}${YELLOW}Available Configurations:${NC}"
    if [ -d "$WT_SCRIPT_DIR/build_configurations" ]; then
        for config_file in "$WT_SCRIPT_DIR/build_configurations"/*.conf; do
            if [ -f "$config_file" ]; then
                basename_conf=$(basename "$config_file" .conf)
                echo -e "  ${CYAN}$basename_conf${NC}"
            fi
        done
    fi
    echo ""
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

print_status "Starting ${SCRIPT_NAME%.sh}..."

# Default values
CONFIG_NAME="default"
CONFIG_FILE=""
INSTALL_PREFIX=""
CLEAN_BUILD=false
BUILD_ROOT_DIR="$PROJECT_ROOT/build"
WT_SOURCE_DIR="$BUILD_ROOT_DIR/wt"
BUILD_DIR="$WT_SOURCE_DIR/build"

# Argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            if [ -z "$2" ]; then
                print_error "Configuration name is required"
                show_usage
                exit 1
            fi
            CONFIG_NAME="$2"
            shift 2
            ;;
        --config-file)
            if [ -z "$2" ]; then
                print_error "Configuration file path is required"
                show_usage
                exit 1
            fi
            CONFIG_FILE="$2"
            shift 2
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
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check dependencies
require_command cmake "Install cmake via your package manager (e.g. sudo apt install cmake)" || exit 1
require_command make "Install make via your package manager (e.g. sudo apt install build-essential)" || exit 1

# Load configuration
load_config() {
    if [ -n "$CONFIG_FILE" ]; then
        if [ ! -f "$CONFIG_FILE" ]; then
            print_error "Configuration file not found: $CONFIG_FILE"
            exit 1
        fi
        print_status "Loading custom configuration: $CONFIG_FILE"
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    else
        local config_path="$WT_SCRIPT_DIR/build_configurations/${CONFIG_NAME}.conf"
        if [ ! -f "$config_path" ]; then
            print_error "Configuration not found: $config_path"
            exit 1
        fi
        print_status "Loading configuration: $CONFIG_NAME"
        # shellcheck disable=SC1090
        source "$config_path"
    fi
    
    # Override prefix if specified on command line
    if [ -n "$INSTALL_PREFIX" ]; then
        INSTALL_PREFIX_CONF="$INSTALL_PREFIX"
    fi
}

# Check if Wt source is available
check_wt_source() {
    if [ ! -d "$WT_SOURCE_DIR" ]; then
        print_error "Wt source directory not found: $WT_SOURCE_DIR"
        print_status "Run ./scripts/libs/wt/download.sh to download Wt source first"
        exit 1
    fi
    
    if [ ! -f "$WT_SOURCE_DIR/CMakeLists.txt" ]; then
        print_error "Invalid Wt source directory: CMakeLists.txt not found"
        exit 1
    fi
    
    print_success "Wt source directory verified"
}

# Configure build
configure_build() {
    print_status "Configuring Wt build..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        print_status "Cleaning build directory"
        rm -rf "$BUILD_DIR"/*
    fi
    
    cd "$BUILD_DIR"
    
    # Build CMAKE arguments from configuration
    local cmake_args=(
        "-DCMAKE_BUILD_TYPE=${BUILD_TYPE:-Release}"
        "-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX_CONF:-/usr/local}"
        "-DBUILD_SHARED_LIBS=${SHARED_LIBS:-ON}"
        "-DWT_MULTI_THREADED=${MULTI_THREADED:-ON}"
    )
    
    # Database backends
    [ -n "$ENABLE_SQLITE" ] && cmake_args+=("-DENABLE_SQLITE=${ENABLE_SQLITE}")
    [ -n "$ENABLE_POSTGRES" ] && cmake_args+=("-DENABLE_POSTGRES=${ENABLE_POSTGRES}")
    [ -n "$ENABLE_MYSQL" ] && cmake_args+=("-DENABLE_MYSQL=${ENABLE_MYSQL}")
    [ -n "$ENABLE_FIREBIRD" ] && cmake_args+=("-DENABLE_FIREBIRD=${ENABLE_FIREBIRD}")
    [ -n "$ENABLE_MSSQLSERVER" ] && cmake_args+=("-DENABLE_MSSQLSERVER=${ENABLE_MSSQLSERVER}")
    
    # Security & Graphics
    [ -n "$ENABLE_SSL" ] && cmake_args+=("-DENABLE_SSL=${ENABLE_SSL}")
    [ -n "$ENABLE_HARU" ] && cmake_args+=("-DENABLE_HARU=${ENABLE_HARU}")
    [ -n "$ENABLE_PANGO" ] && cmake_args+=("-DENABLE_PANGO=${ENABLE_PANGO}")
    [ -n "$ENABLE_OPENGL" ] && cmake_args+=("-DENABLE_OPENGL=${ENABLE_OPENGL}")
    [ -n "$ENABLE_SAML" ] && cmake_args+=("-DENABLE_SAML=${ENABLE_SAML}")
    
    # Qt Integration
    [ -n "$ENABLE_QT4" ] && cmake_args+=("-DENABLE_QT4=${ENABLE_QT4}")
    [ -n "$ENABLE_QT5" ] && cmake_args+=("-DENABLE_QT5=${ENABLE_QT5}")
    
    print_status "CMake arguments: ${cmake_args[*]}"
    
    if cmake "${cmake_args[@]}" .. 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Configuration completed successfully"
    else
        print_error "Configuration failed! Check log file: $LOG_FILE"
        exit 1
    fi
}

# Build Wt
build_wt() {
    print_status "Building Wt library..."
    
    cd "$BUILD_DIR"
    
    local cpu_cores
    cpu_cores=$(get_cpu_cores)
    local jobs="${JOBS:-$cpu_cores}"
    if [ "$jobs" = "auto" ]; then
        jobs="$cpu_cores"
    fi
    
    print_status "Building with $jobs parallel jobs..."
    
    if make -j"$jobs" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Build completed successfully!"
    else
        print_error "Build failed! Check log file: $LOG_FILE"
        exit 1
    fi
}

# Install Wt
install_wt() {
    print_status "Installing Wt library..."
    
    cd "$BUILD_DIR"
    
    # Check if we need sudo
    local install_prefix="${INSTALL_PREFIX_CONF:-/usr/local}"
    if [ ! -w "$install_prefix" ] && [ "$install_prefix" != "$HOME"* ]; then
        print_status "Root privileges required for installation to $install_prefix"
        if sudo make install 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Installation completed successfully!"
        else
            print_error "Installation failed! Check log file: $LOG_FILE"
            exit 1
        fi
    else
        if make install 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Installation completed successfully!"
        else
            print_error "Installation failed! Check log file: $LOG_FILE"
            exit 1
        fi
    fi
    
    # Update library cache
    if command -v ldconfig >/dev/null 2>&1; then
        print_status "Updating library cache..."
        sudo ldconfig 2>/dev/null || true
    fi
}

# Verify installation
verify_installation() {
    local install_prefix="${INSTALL_PREFIX_CONF:-/usr/local}"
    
    print_status "Verifying installation..."
    
    # Check for library files
    if [ -d "$install_prefix/lib" ]; then
        local wt_libs
        wt_libs=$(find "$install_prefix/lib" -name "libwt*" 2>/dev/null | wc -l)
        if [ "$wt_libs" -gt 0 ]; then
            print_success "Found $wt_libs Wt library files"
        else
            print_warning "No Wt library files found in $install_prefix/lib"
        fi
    fi
    
    # Check for header files
    if [ -d "$install_prefix/include/Wt" ]; then
        print_success "Wt header files found in $install_prefix/include/Wt"
    else
        print_warning "Wt header files not found in $install_prefix/include/Wt"
    fi
    
    # Show installation summary
    echo ""
    print_status "Installation Summary:"
    echo -e "  ${CYAN}Configuration:${NC} ${CONFIG_NAME}"
    echo -e "  ${CYAN}Build Type:${NC} ${BUILD_TYPE:-Release}"
    echo -e "  ${CYAN}Install Prefix:${NC} $install_prefix"
    echo -e "  ${CYAN}Build Directory:${NC} $BUILD_DIR"
    echo ""
}

# Main execution
load_config
check_wt_source
configure_build
build_wt
install_wt
verify_installation

print_success "${SCRIPT_NAME%.sh} completed successfully!"
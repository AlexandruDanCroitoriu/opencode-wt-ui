#!/usr/bin/env bash
# Script to build the Wt library using configuration files
# Usage: ./scripts/libs/wt/build.sh [options]

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
    echo "  Builds the Wt library from source using configuration files"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-h, --help${NC}               Show this help message"
    echo -e "  ${CYAN}-c, --config CONFIG${NC}      Use specific configuration (default: default)"
    echo -e "  ${CYAN}--config-file PATH${NC}       Use custom configuration file"
    echo -e "  ${CYAN}--prefix PATH${NC}            Installation prefix (overrides config)"
    echo -e "  ${CYAN}--jobs N${NC}                 Number of parallel build jobs"
    echo -e "  ${CYAN}--clean${NC}                  Clean build directory before building"
    echo -e "  ${CYAN}--dry-run${NC}                Show what would be done without building"
    echo -e "  ${CYAN}--verbose${NC}                Enable verbose build output"
    echo ""
    echo -e "${BOLD}${YELLOW}Available Configurations:${NC}"
    if [ -d "$WT_SCRIPT_DIR/build_configurations" ]; then
        for config_file in "$WT_SCRIPT_DIR/build_configurations"/*.conf; do
            if [ -f "$config_file" ]; then
                local basename_conf=$(basename "$config_file" .conf)
                local description=$(grep "^# Description:" "$config_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "No description")
                echo -e "  ${CYAN}$basename_conf${NC} - $description"
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

# Default build settings
BUILD_TYPE="Release"
INSTALL_PREFIX_CONF="/usr/local"
JOBS="auto"
CLEAN_BUILD="false"
DRY_RUN="false"
VERBOSE="false"

# Library configuration - defaults
SHARED_LIBS="ON"
MULTI_THREADED="ON"

# Database backends - defaults
ENABLE_SQLITE="ON"
ENABLE_POSTGRES="ON"
ENABLE_MYSQL="OFF"
ENABLE_FIREBIRD="OFF"
ENABLE_MSSQLSERVER="OFF"

# Security & Graphics - defaults
ENABLE_SSL="ON"
ENABLE_HARU="ON"
ENABLE_PANGO="ON"
ENABLE_OPENGL="ON"
ENABLE_SAML="OFF"

# Qt integration - defaults
ENABLE_QT4="ON"
ENABLE_QT5="OFF"
ENABLE_QT6="OFF"

# Libraries & Components - defaults
ENABLE_LIBWTDBO="ON"
ENABLE_LIBWTTEST="ON"
ENABLE_UNWIND="OFF"

# Installation options - defaults
BUILD_EXAMPLES="ON"
BUILD_TESTS="ON"
INSTALL_EXAMPLES="OFF"
INSTALL_DOCUMENTATION="OFF"
INSTALL_RESOURCES="ON"
INSTALL_THEMES="ON"

# Connector options - defaults
CONNECTOR_HTTP="ON"
CONNECTOR_FCGI="ON"
EXAMPLES_CONNECTOR="wthttp"

# Development options
DEBUG_JS="OFF"

# Directory options - defaults
CONFIGDIR="/etc/wt"
RUNDIR="/var/run/wt"
WTHTTP_CONFIGURATION="/etc/wt/wthttpd"

# Advanced options
ADDITIONAL_CMAKE_ARGS=""

# Configuration variables
CONFIG_NAME="default"
CONFIG_FILE=""
INSTALL_PREFIX=""

BUILD_ROOT_DIR="$PROJECT_ROOT/build"
WT_SOURCE_DIR="$BUILD_ROOT_DIR/wt"

# Argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            if [ -z "$2" ]; then
                print_error "Configuration argument is required"
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
        --jobs)
            if [ -z "$2" ]; then
                print_error "Number of jobs is required"
                show_usage
                exit 1
            fi
            JOBS="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Load configuration from file
load_config_file() {
    # Determine which config file to use
    if [ -z "$CONFIG_FILE" ]; then
        CONFIG_FILE="$WT_SCRIPT_DIR/build_configurations/$CONFIG_NAME.conf"
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    print_status "Loading configuration from: $(basename "$CONFIG_FILE")"
    
    # Source the configuration file
    source "$CONFIG_FILE"
    
    # Handle special cases for numeric values
    if [ "$JOBS" = "auto" ]; then
        JOBS=$(nproc 2>/dev/null || echo "4")
    fi
    
    # Convert string boolean values to actual booleans for scripts
    case "$CLEAN_BUILD" in
        "true"|"TRUE"|"1") CLEAN_BUILD=true ;;
        *) CLEAN_BUILD=false ;;
    esac
    
    case "$DRY_RUN" in
        "true"|"TRUE"|"1") DRY_RUN=true ;;
        *) DRY_RUN=false ;;
    esac
    
    case "$VERBOSE" in
        "true"|"TRUE"|"1") VERBOSE=true ;;
        *) VERBOSE=false ;;
    esac
    
    # Override with command line options if provided
    if [ -n "$INSTALL_PREFIX" ]; then
        INSTALL_PREFIX_CONF="$INSTALL_PREFIX"
    fi
    
    print_success "Configuration loaded successfully"
}

# Set build directory based on configuration
set_build_directory() {
    BUILD_DIR="$WT_SOURCE_DIR/build/$CONFIG_NAME"
    print_status "Using configuration-specific build directory: build/$CONFIG_NAME/"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Wt source exists
    if [ ! -d "$WT_SOURCE_DIR" ]; then
        print_error "Wt source not found at: $WT_SOURCE_DIR"
        print_status "Please run download script first to get Wt source code"
        exit 1
    fi
    
    if [ ! -f "$WT_SOURCE_DIR/CMakeLists.txt" ]; then
        print_error "Invalid Wt source directory (CMakeLists.txt not found)"
        exit 1
    fi
    
    # Check essential tools
    local missing_tools=()
    
    if ! command -v cmake &> /dev/null; then
        missing_tools+=("cmake")
    fi
    
    if ! command -v make &> /dev/null; then
        missing_tools+=("make")
    fi
    
    if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
        missing_tools+=("g++ or clang++")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install the required build tools"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Prepare build directory
prepare_build_dir() {
    if [ "$CLEAN_BUILD" = true ] && [ -d "$BUILD_DIR" ]; then
        print_warning "Cleaning existing build directory"
        rm -rf "$BUILD_DIR"
    fi
    
    print_status "Creating build directory: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Show configuration summary
show_configuration() {
    echo ""
    print_status "Build Configuration Summary:"
    echo -e "  ${CYAN}Configuration:${NC} $CONFIG_NAME"
    echo -e "  ${CYAN}Build Type:${NC} $BUILD_TYPE"
    echo -e "  ${CYAN}Install Prefix:${NC} $INSTALL_PREFIX_CONF"
    echo -e "  ${CYAN}Parallel Jobs:${NC} $JOBS"
    echo -e "  ${CYAN}Source Directory:${NC} $WT_SOURCE_DIR"
    echo -e "  ${CYAN}Build Directory:${NC} $BUILD_DIR"
    echo ""
    
    echo -e "${BOLD}${YELLOW}Library Configuration:${NC}"
    echo -e "  ${CYAN}Shared Libraries:${NC} $([ "$SHARED_LIBS" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}Multi-threaded:${NC} $([ "$MULTI_THREADED" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo ""
    
    echo -e "${BOLD}${YELLOW}Database Backends:${NC}"
    echo -e "  ${CYAN}SQLite:${NC} $([ "$ENABLE_SQLITE" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}PostgreSQL:${NC} $([ "$ENABLE_POSTGRES" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}MySQL/MariaDB:${NC} $([ "$ENABLE_MYSQL" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo ""
    
    echo -e "${BOLD}${YELLOW}Security & Graphics:${NC}"
    echo -e "  ${CYAN}SSL/TLS:${NC} $([ "$ENABLE_SSL" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}Haru PDF:${NC} $([ "$ENABLE_HARU" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}Pango Fonts:${NC} $([ "$ENABLE_PANGO" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}OpenGL:${NC} $([ "$ENABLE_OPENGL" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo ""
    
    echo -e "${BOLD}${YELLOW}Components:${NC}"
    echo -e "  ${CYAN}Wt::Dbo ORM:${NC} $([ "$ENABLE_LIBWTDBO" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}Wt::Test:${NC} $([ "$ENABLE_LIBWTTEST" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo -e "  ${CYAN}Build Examples:${NC} $([ "$BUILD_EXAMPLES" = "ON" ] && echo "${GREEN}enabled${NC}" || echo "${RED}disabled${NC}")"
    echo ""
}

# Configure build with CMake
configure_build() {
    print_status "Configuring Wt build with CMake..."
    
    cd "$BUILD_DIR"
    
    local cmake_args=(
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_CONF"
        "-DSHARED_LIBS=$SHARED_LIBS"
        "-DMULTI_THREADED=$MULTI_THREADED"
        
        # Database backends
        "-DENABLE_SQLITE=$ENABLE_SQLITE"
        "-DENABLE_POSTGRES=$ENABLE_POSTGRES"
        "-DENABLE_MYSQL=$ENABLE_MYSQL"
        "-DENABLE_FIREBIRD=$ENABLE_FIREBIRD"
        "-DENABLE_MSSQLSERVER=$ENABLE_MSSQLSERVER"
        
        # Security & Graphics
        "-DENABLE_SSL=$ENABLE_SSL"
        "-DENABLE_HARU=$ENABLE_HARU"
        "-DENABLE_PANGO=$ENABLE_PANGO"
        "-DENABLE_OPENGL=$ENABLE_OPENGL"
        "-DENABLE_SAML=$ENABLE_SAML"
        
        # Qt integration
        "-DENABLE_QT4=$ENABLE_QT4"
        "-DENABLE_QT5=$ENABLE_QT5"
        "-DENABLE_QT6=$ENABLE_QT6"
        
        # Libraries & Components
        "-DENABLE_LIBWTDBO=$ENABLE_LIBWTDBO"
        "-DENABLE_LIBWTTEST=$ENABLE_LIBWTTEST"
        "-DENABLE_UNWIND=$ENABLE_UNWIND"
        
        # Installation options
        "-DBUILD_EXAMPLES=$BUILD_EXAMPLES"
        "-DBUILD_TESTS=$BUILD_TESTS"
        "-DINSTALL_EXAMPLES=$INSTALL_EXAMPLES"
        "-DINSTALL_DOCUMENTATION=$INSTALL_DOCUMENTATION"
        "-DINSTALL_RESOURCES=$INSTALL_RESOURCES"
        "-DINSTALL_THEMES=$INSTALL_THEMES"
        
        # Connector options
        "-DCONNECTOR_HTTP=$CONNECTOR_HTTP"
        "-DCONNECTOR_FCGI=$CONNECTOR_FCGI"
        "-DEXAMPLES_CONNECTOR=$EXAMPLES_CONNECTOR"
        
        # Development options
        "-DDEBUG_JS=$DEBUG_JS"
        
        # Directory configuration
        "-DCONFIGDIR=$CONFIGDIR"
        "-DRUNDIR=$RUNDIR"
        "-DWTHTTP_CONFIGURATION=$WTHTTP_CONFIGURATION"
    )
    
    # Add additional CMake arguments if provided
    if [ -n "$ADDITIONAL_CMAKE_ARGS" ]; then
        IFS=' ' read -ra EXTRA_ARGS <<< "$ADDITIONAL_CMAKE_ARGS"
        cmake_args+=("${EXTRA_ARGS[@]}")
    fi
    
    if [ "$VERBOSE" = true ]; then
        print_status "CMake command:"
        echo "  cmake ${cmake_args[*]} $WT_SOURCE_DIR"
        echo ""
    fi
    
    if cmake "${cmake_args[@]}" "$WT_SOURCE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "CMake configuration completed"
    else
        print_error "CMake configuration failed"
        exit 1
    fi
}

# Build Wt
build_wt() {
    print_status "Building Wt library..."
    print_status "Using $JOBS parallel jobs"
    
    cd "$BUILD_DIR"
    
    local start_time=$(date +%s)
    local make_args=("-j$JOBS")
    
    if [ "$VERBOSE" = true ]; then
        make_args+=("VERBOSE=1")
    fi
    
    if make "${make_args[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "Wt library built successfully in ${duration}s"
    else
        print_error "Wt library build failed"
        print_error "Check the log file for details: $LOG_FILE"
        exit 1
    fi
}

# Show build summary
show_build_summary() {
    echo ""
    print_status "Build Summary:"
    echo -e "  ${CYAN}Configuration:${NC} $CONFIG_NAME"
    echo -e "  ${CYAN}Build completed successfully${NC}"
    echo -e "  ${CYAN}Build directory:${NC} $BUILD_DIR"
    echo -e "  ${CYAN}Install prefix:${NC} $INSTALL_PREFIX_CONF"
    echo ""
    
    if [ -d "$BUILD_DIR" ]; then
        local lib_files=($(find "$BUILD_DIR" -name "libwt*" -type f 2>/dev/null))
        if [ ${#lib_files[@]} -gt 0 ]; then
            echo -e "  ${CYAN}Built Libraries:${NC}"
            for lib in "${lib_files[@]}"; do
                local size=$(du -h "$lib" 2>/dev/null | cut -f1 || echo "unknown")
                echo -e "    $(basename "$lib") (${size})"
            done
            echo ""
        fi
        
        if [ "$BUILD_EXAMPLES" = "ON" ] && [ -d "$BUILD_DIR/examples" ]; then
            local example_count=$(find "$BUILD_DIR/examples" -type f -executable 2>/dev/null | wc -l)
            if [ "$example_count" -gt 0 ]; then
                echo -e "  ${CYAN}Built Examples:${NC} $example_count"
                echo ""
            fi
        fi
    fi
    
    print_info "Next steps:"
    echo -e "  ${CYAN}• To install the library, run the install script${NC}"
    echo -e "  ${CYAN}• Build artifacts are located in: $BUILD_DIR${NC}"
    echo ""
}

# Main execution
main() {
    print_status "Starting Wt library build..."
    
    # Load configuration file
    load_config_file
    
    # Set build directory based on configuration
    set_build_directory
    
    # Show configuration
    show_configuration
    
    # Exit early if dry run
    if [ "$DRY_RUN" = true ]; then
        print_status "Dry run mode - exiting without building"
        exit 0
    fi
    
    # Perform the build
    check_prerequisites
    prepare_build_dir
    configure_build
    build_wt
    
    show_build_summary
    
    print_success "Wt library build completed successfully!"
}

# Run main function
main "$@"

print_success "${SCRIPT_NAME%.sh} completed successfully!"
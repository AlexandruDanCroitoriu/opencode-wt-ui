#!/usr/bin/env bash

# Unified script to build the application
# Usage: ./scripts/app/build.sh [--debug|-d|--release|-r] [clean]

set -e  # Exit on any error
set -o pipefail  # Propagate failures from pipelines

SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
SCRIPTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1090,SC1091
source "$SCRIPTS_ROOT/utils.sh"
# shellcheck disable=SC1090,SC1091
source "$SCRIPTS_ROOT/environment.sh"

APP_BINARY_NAME="app"

# Default configuration
BUILD_TYPE="debug"
CLEAN_BUILD=false

# Function to show usage
show_usage() {
    echo -e "${BOLD}${BLUE}Usage:${NC} $0 [options]"
    echo ""
    echo -e "${BOLD}${GREEN}Description:${NC}"
    echo "  Build the Wt application with CMake"
    echo ""
    echo -e "${BOLD}${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-d, --debug${NC}        Build debug version (default)"
    echo -e "  ${CYAN}-r, --release${NC}      Build release version"
    echo -e "  ${CYAN}clean${NC}              Perform a clean build"
    echo -e "  ${CYAN}-h, --help${NC}         Show this help message"
    echo ""
}

# Function to build the application
build_application() {
    local build_type="$1"
    local clean_build="$2"
    local build_dir="$PROJECT_ROOT/build/$build_type"

    print_status "Starting $build_type build process..."
    print_status "Build directory: $build_dir"
    print_status "Log file: $LOG_FILE"
    
    # Create build directory
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Clean build if requested
    if [ "$clean_build" = true ]; then
        print_status "Performing clean build..."
        if [ -f "Makefile" ]; then
            make clean 2>&1 | tee -a "$LOG_FILE" || true
        fi
        # Remove CMake cache files
        rm -f CMakeCache.txt
        rm -rf CMakeFiles/
    fi
    
    # Set CMAKE_BUILD_TYPE
    local cmake_build_type
    if [ "$build_type" = "debug" ]; then
        cmake_build_type="Debug"
    else
        cmake_build_type="Release"
    fi
    
    # Configure with CMake
    print_status "Configuring CMake for $build_type build..."
    if cmake -DCMAKE_BUILD_TYPE="$cmake_build_type" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON "$PROJECT_ROOT" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "CMake configuration completed successfully"
    else
        print_error "CMake configuration failed! Check log file: $LOG_FILE"
        return 1
    fi
    
    # Build the application
    local cpu_cores
    cpu_cores=$(get_cpu_cores)
    print_status "Building with $cpu_cores parallel jobs..."
    
    if make -j"$cpu_cores" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "$build_type build completed successfully!"
        print_status "Executable location: $build_dir/$APP_BINARY_NAME"
    else
        print_error "Build failed! Check log file: $LOG_FILE"
        return 1
    fi
    
    # Check if executable exists and is executable
    local binary_path="$build_dir/$APP_BINARY_NAME"

    if [ ! -f "$binary_path" ]; then
        print_error "Application binary not found at: $binary_path"
        return 1
    fi
    
    if [ ! -x "$binary_path" ]; then
        print_error "Application binary is not executable: $binary_path"
        return 1
    fi
    
    print_success "Application binary created successfully"
    print_status "Binary size: $(du -h "$binary_path" | cut -f1)"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug|-d)
            BUILD_TYPE="debug"
            shift
            ;;
        --release|-r)
            BUILD_TYPE="release"
            shift
            ;;
        clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $1"
            show_usage
            exit 1
            ;;
    esac
done

if ! init_script_environment "$SCRIPT_SOURCE"; then
    print_error "Failed to initialise shared environment for $SCRIPT_SOURCE"
    exit 1
fi

# Check dependencies
require_command cmake "Install cmake via your package manager (e.g. sudo apt install cmake)" || exit 1
require_command make "Install make via your package manager (e.g. sudo apt install build-essential)" || exit 1

# Start the build process
print_status "Starting build process..."
print_status "Build type: $BUILD_TYPE"
print_status "Clean build: $CLEAN_BUILD"

# Build the application
if build_application "$BUILD_TYPE" "$CLEAN_BUILD"; then
    print_success "Build completed successfully!"
    print_status "You can now run the application using:"
    print_status "  ./scripts/app/run.sh --$BUILD_TYPE"
    exit 0
else
    print_error "Build failed!"
    exit 1
fi

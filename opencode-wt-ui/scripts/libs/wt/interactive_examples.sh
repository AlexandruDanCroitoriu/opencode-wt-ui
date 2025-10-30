#!/usr/bin/env bash
# Interactive Wt Examples Manager
# Usage: ./scripts/libs/wt/interactive_examples.sh

set -e  # Exit on any error

WT_EXAMPLES_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_ROOT="$(dirname "$(dirname "$WT_EXAMPLES_SCRIPT_DIR")")"
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
source "$WT_EXAMPLES_SCRIPT_DIR/interactive_configuration.sh"

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
  Interactive Wt examples builder and runner

Options:
  -h, --help    Show this help message

Examples:
  $SCRIPT_NAME    # Open the interactive examples menu
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

# ===================================================================
# Configuration and Constants
# ===================================================================

# Wt Examples Configuration
WT_EXAMPLES_BUILD_DIR="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}/examples"
WT_EXAMPLES_DIR="$WT_EXAMPLES_BUILD_DIR"
WT_EXAMPLES_SOURCE_DIR="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}/examples"
WT_RESOURCES_DIR="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}/resources"
WT_EXAMPLES_PORT_BASE=8080

# Basic examples (main page)
WT_BASIC_EXAMPLES=(
    "authentication"
    "blog"
    "charts"
    "chart3D"
    "codeview"
    "composer"
    "custom-bs-theme"
    "dbo-form"
    "dialog"
    "dragdrop"
    "filedrop"
    "filetreetable"
    "form"
    "gitmodel"
    "hangman"
    "hello"
    "http-client"
    "javascript"
    "leaflet"
    "mandelbrot"
    "mission"
    "onethread"
    "painting"
    "planner"
    "qrlogin"
    "simplechat"
    "style"
    "tableview-dragdrop"
    "te-benchmark"
    "treelist"
    "treeview"
    "treeview-dragdrop"
    "webgl"
    "websockets"
    "widgetgallery"
    "wt-homepage"
)

# Feature examples  
WT_FEATURE_EXAMPLES=(
    "feature/auth1"
    "feature/auth2"
    "feature/broadcast"
    "feature/client-ssl-auth"
    "feature/custom_layout"
    "feature/dbo/tutorial1"
    "feature/dbo/tutorial2"
    "feature/dbo/tutorial3"
    "feature/dbo/tutorial4"
    "feature/dbo/tutorial5"
    "feature/dbo/tutorial6"
    "feature/dbo/tutorial7"
    "feature/dbo/tutorial8"
    "feature/dbo/tutorial9"
    "feature/locale"
    "feature/mediaplayer"
    "feature/miniwebgl"
    "feature/multiple_servers"
    "feature/oauth"
    "feature/oidc"
    "feature/paypal"
    "feature/postall"
    "feature/scrollvisibility"
    "feature/serverpush"
    "feature/socketnotifier"
    "feature/suggestionpopup"
    "feature/template-fun"
    "feature/urlparams"
    "feature/video"
    "feature/widgetset"
)

# Example descriptions
declare -A WT_EXAMPLE_INFO
WT_EXAMPLE_INFO=(
    ["authentication"]="Comprehensive authentication framework with login/logout"
    ["blog"]="Simple blogging application with MVC architecture"
    ["charts"]="Interactive charts and graphs showcase"
    ["chart3D"]="3D charting examples with advanced visualization"
    ["codeview"]="Source code viewer with syntax highlighting"
    ["composer"]="Email composition interface with rich text editing"
    ["custom-bs-theme"]="Bootstrap theme customization demonstration"
    ["dbo-form"]="Database object forms with rich text editing"
    ["dialog"]="Modal dialogs and popup windows demonstration"
    ["dragdrop"]="Drag and drop interactions and file uploads"
    ["filetreetable"]="File system browser with tree table interface"
    ["filedrop"]="File drag-and-drop upload interface"
    ["form"]="Form widgets and validation examples"
    ["gitmodel"]="Git repository browser using MVC framework"
    ["hangman"]="Classic hangman word game implementation"
    ["hello"]="Simple Hello World application"
    ["http-client"]="HTTP client functionality and web services"
    ["javascript"]="JavaScript integration and client-server communication"
    ["leaflet"]="Interactive maps using Leaflet.js integration"
    ["mandelbrot"]="Interactive Mandelbrot fractal explorer"
    ["mission"]="Space mission control dashboard simulation"
    ["onethread"]="Single-threaded server application example"
    ["painting"]="Vector graphics and painting API demonstration"
    ["planner"]="Calendar and event planning application"
    ["qrlogin"]="QR code authentication and login system"
    ["simplechat"]="Real-time chat application with WebSockets"
    ["style"]="Custom widget styling with rounded corners"
    ["tableview-dragdrop"]="Table view with drag and drop reordering"
    ["te-benchmark"]="Text editor performance benchmarking"
    ["treelist"]="Tree list widget demonstrations"
    ["treeview"]="Tree view widget with hierarchical data"
    ["treeview-dragdrop"]="Tree view with drag and drop capabilities"
    ["webgl"]="WebGL 3D graphics integration"
    ["websockets"]="WebSocket communication examples"
    ["widgetgallery"]="Comprehensive showcase of all Wt widgets"
    ["wt-homepage"]="Complete Wt homepage with blog and authentication"
    # Feature examples
    ["feature/auth1"]="Basic authentication example"
    ["feature/auth2"]="Advanced authentication with database"
    ["feature/broadcast"]="Server-side broadcasting to multiple clients"
    ["feature/client-ssl-auth"]="SSL client certificate authentication"
    ["feature/custom_layout"]="Custom layout and template examples"
    ["feature/dbo/tutorial1"]="Wt::Dbo Tutorial 1: Basic mapping"
    ["feature/dbo/tutorial2"]="Wt::Dbo Tutorial 2: One-to-many relations"
    ["feature/dbo/tutorial3"]="Wt::Dbo Tutorial 3: Many-to-many relations"
    ["feature/dbo/tutorial4"]="Wt::Dbo Tutorial 4: Schema specification"
    ["feature/dbo/tutorial5"]="Wt::Dbo Tutorial 5: Schema versioning"
    ["feature/dbo/tutorial6"]="Wt::Dbo Tutorial 6: Joining objects"
    ["feature/dbo/tutorial7"]="Wt::Dbo Tutorial 7: Transactions"
    ["feature/dbo/tutorial8"]="Wt::Dbo Tutorial 8: Web application"
    ["feature/dbo/tutorial9"]="Wt::Dbo Tutorial 9: Multi-file structure"
    ["feature/locale"]="Localization and internationalization"
    ["feature/mediaplayer"]="Media player widget demonstration"
    ["feature/miniwebgl"]="Minimal WebGL integration example"
    ["feature/multiple_servers"]="Multiple server instance management"
    ["feature/oauth"]="OAuth authentication integration"
    ["feature/oidc"]="OpenID Connect authentication"
    ["feature/paypal"]="PayPal payment integration"
    ["feature/postall"]="HTTP POST handling examples"
    ["feature/scrollvisibility"]="Scroll visibility and lazy loading"
    ["feature/serverpush"]="Server-side push notifications"
    ["feature/socketnotifier"]="Socket notification handling"
    ["feature/suggestionpopup"]="Auto-suggestion popup widgets"
    ["feature/template-fun"]="Template function examples"
    ["feature/urlparams"]="URL parameter handling"
    ["feature/video"]="Video streaming and playback"
    ["feature/widgetset"]="Custom widget set creation"
)

# ===================================================================
# Utility Functions
# ===================================================================

# Check if Wt library is built
check_wt_library() {
    local wt_build_dir="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}"
    
    if [ ! -d "$wt_build_dir" ]; then
        return 1
    fi
    
    if [ -f "$wt_build_dir/src/libwt.so" ] || [ -f "$wt_build_dir/src/libwt.a" ]; then
        return 0
    fi
    
    return 1
}

# Check if example is built
check_example_built() {
    local example_name="$1"
    local example_path="$WT_EXAMPLES_DIR/$example_name"
    
    # Check common executable patterns
    if [ -f "$example_path/$example_name.wt" ] || 
       [ -f "$example_path/$example_name" ] ||
       [ -f "$example_path/${example_name}.exe" ]; then
        return 0
    fi
    
    # Check specific patterns
    case "$example_name" in
        "hello")
            [ -f "$example_path/hello.wt" ]
            ;;
        "blog")
            [ -f "$example_path/blog.wt" ]
            ;;
        "charts")
            [ -f "$example_path/charts.wt" ]
            ;;
        "authentication")
            [ -f "$example_path/authentication.wt" ] || [ -f "$example_path/mfa/pin/pin-login.wt" ]
            ;;
        "widgetgallery")
            [ -f "$example_path/widgetgallery.wt" ]
            ;;
        *)
            [ -f "$example_path/$example_name.wt" ]
            ;;
    esac
}

# Get example status for menu display
get_example_status() {
    local example_name="$1"
    
    if check_example_built "$example_name"; then
        echo "(Built)"
    else
        echo "(Not Built)"
    fi
}

# Get available port
get_available_port() {
    local base_port=$1
    local port=$base_port
    
    if command -v ss >/dev/null 2>&1; then
        while ss -tuln 2>/dev/null | grep -q ":$port "; do
            ((port++))
        done
    else
        while [ $port -lt $((base_port + 100)) ]; do
            if ! (echo >/dev/tcp/localhost/$port) 2>/dev/null; then
                break
            fi
            ((port++))
        done
    fi
    
    echo $port
}

# ===================================================================
# Build Functions
# ===================================================================

# Setup examples build environment
setup_examples_build() {
    local wt_build_dir="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}"
    
    if [ ! -d "$wt_build_dir" ]; then
        dialog --title "Error" --msgbox "Wt library not found!\n\nPlease build Wt library first:\n1. Go to Wt Library Management\n2. Build or install Wt library\n3. Return to examples" 12 70
        DIALOG_USED=true
        return 1
    fi
    
    cd "$wt_build_dir" || return 1
    
    # Enable examples if not already enabled
    if ! grep -q "BUILD_EXAMPLES:BOOL=ON" CMakeCache.txt 2>/dev/null; then
        cmake -DBUILD_EXAMPLES=ON . >/dev/null 2>&1 || return 1
    fi
    
    return 0
}

# Build single example
build_single_example() {
    local example_name="$1"
    
    if ! setup_examples_build; then
        return 1
    fi
    
    local wt_build_dir="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}"
    cd "$wt_build_dir" || return 1
    
    # Build the example
    local target_name="$example_name.wt"
    
    dialog --title "Building Example" --infobox "Building $example_name...\n\nThis may take a few minutes.\nPlease wait..." 8 50
    DIALOG_USED=true
    
    if make -j$(nproc) "$target_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Build all examples
build_all_examples() {
    if ! setup_examples_build; then
        return 1
    fi
    
    local wt_build_dir="$PROJECT_ROOT/build/wt-${CURRENT_WT_VERSION:-latest}"
    cd "$wt_build_dir" || return 1
    
    dialog --title "Building All Examples" --infobox "Building all Wt examples...\n\nThis will take several minutes.\nPlease wait..." 8 50
    DIALOG_USED=true
    
    if make -j$(nproc) examples >/dev/null 2>&1; then
        dialog --title "Success" --msgbox "All examples built successfully!" 7 50
        DIALOG_USED=true
        return 0
    else
        dialog --title "Error" --msgbox "Failed to build all examples.\n\nSome examples may have missing dependencies." 8 60
        DIALOG_USED=true
        return 1
    fi
}

# ===================================================================
# Run Functions
# ===================================================================

# Run specific example
run_example() {
    local example_name="$1"
    local example_dir="$WT_EXAMPLES_DIR/$example_name"
    local example_path=""
    
    # Find executable
    if [ -f "$example_dir/$example_name.wt" ]; then
        example_path="$example_dir/$example_name.wt"
    elif [ -f "$example_dir/$example_name" ]; then
        example_path="$example_dir/$example_name"
    else
        dialog --title "Error" --msgbox "Example executable not found: $example_name\n\nTry building it first." 8 60
        DIALOG_USED=true
        return 1
    fi
    
    # Get available port
    local port=$(get_available_port $WT_EXAMPLES_PORT_BASE)
    
    # Clear screen and show running message
    printf '\033c'
    clear
    printf '\033[0m'
    tput sgr0 2>/dev/null || true
    
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}🚀 Starting $example_name Example${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}🌐 Browser URL: ${BOLD}http://localhost:$port${NC}"
    echo -e "${GREEN}📁 Working Dir: $example_dir${NC}"
    echo -e "${GREEN}📁 Resources: $WT_RESOURCES_DIR${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    echo -e "${BLUE}📋 About this example:${NC}"
    echo -e "${WT_EXAMPLE_INFO[$example_name]}"
    echo ""
    echo -e "${YELLOW}📝 How to use:${NC}"
    echo -e "   1. Wait for 'started server' message"
    echo -e "   2. Open browser: ${BOLD}http://localhost:$port${NC}"
    echo -e "   3. Press Ctrl+C to stop server"
    echo ""
    echo -e "${BLUE}📋 Server Output:${NC}"
    echo ""
    
    # Change to example directory
    cd "$example_dir" || {
        print_error "Failed to change to example directory: $example_dir"
        return 1
    }
    
    # Run the example with proper Wt arguments
    "$example_path" \
        --docroot=. \
        --approot=. \
        --http-port="$port" \
        --http-address=0.0.0.0 \
        --resources-dir="$WT_RESOURCES_DIR"
    
    local exit_code=$?
    
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    if [ $exit_code -eq 0 ]; then
        print_success "Example '$example_name' finished successfully"
    else
        print_error "Example '$example_name' exited with code: $exit_code"
    fi
    echo -e "${BLUE}================================================================${NC}"
    echo ""
    echo -e "${DIM}Press any key to return to examples menu...${NC}"
    read -n 1 -s
    
    return $exit_code
}

# ===================================================================
# Menu Functions
# ===================================================================

# Show example selection menu
show_examples_menu() {
    local category="$1"  # "basic" or "feature"
    local examples=()
    
    if [ "$category" = "basic" ]; then
        examples=("${WT_BASIC_EXAMPLES[@]}")
    else
        examples=("${WT_FEATURE_EXAMPLES[@]}")
    fi
    
    local menu_items=()
    for example in "${examples[@]}"; do
        local status=$(get_example_status "$example")
        local display_name="$example"
        if [[ "$example" == feature/* ]]; then
            display_name=$(echo "$example" | sed 's|feature/||')
        fi
        menu_items+=("$example" "$display_name $status")
    done
    
    local choice
    choice=$(dialog \
        --colors \
        --clear \
        --title "Wt Examples - $(echo "$category" | tr '[:lower:]' '[:upper:]')" \
        --menu "Select example to run:" 25 80 18 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$choice" ]; then
        handle_example_selection "$choice"
    fi
}

# Handle example selection
handle_example_selection() {
    local example_name="$1"
    
    if ! check_example_built "$example_name"; then
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --title "Example Not Built" \
            --menu "Example '$example_name' is not built.\n\nWhat would you like to do?" 12 70 3 \
            "build" "Build this example now" \
            "cancel" "Go back to examples menu" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local status=$?
        
        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
        
        if [ $status -ne 0 ] || [ "$choice" = "cancel" ]; then
            return 0
        fi
        
        if [ "$choice" = "build" ]; then
            if build_single_example "$example_name"; then
                dialog --title "Success" --msgbox "Example '$example_name' built successfully!\n\nStarting example..." 8 60
                DIALOG_USED=true
                printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
            else
                dialog --title "Error" --msgbox "Failed to build example '$example_name'.\n\nCheck if Wt library is properly built." 8 70
                DIALOG_USED=true
                return 1
            fi
        fi
    fi
    
    run_example "$example_name"
}

# Show build menu
show_build_menu() {
    while true; do
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --title "Build Examples" \
            --menu "Build Wt Examples:" 15 70 8 \
            "all" "Build all examples" \
            "basic" "Build all basic examples" \
            "feature" "Build all feature examples" \
            "single" "Build single example" \
            "status" "Show build status" \
            "back" "Back to main menu" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local status=$?
        
        printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
        
        if [ $status -ne 0 ]; then
            break
        fi
        
        case "$choice" in
            "all")
                build_all_examples
                ;;
            "basic")
                build_category_examples "basic"
                ;;
            "feature")
                build_category_examples "feature"
                ;;
            "single")
                build_single_example_menu
                ;;
            "status")
                show_build_status
                ;;
            "back")
                break
                ;;
        esac
    done
}

# Build examples by category
build_category_examples() {
    local category="$1"
    local examples=()
    
    if [ "$category" = "basic" ]; then
        examples=("${WT_BASIC_EXAMPLES[@]}")
    else
        examples=("${WT_FEATURE_EXAMPLES[@]}")
    fi
    
    dialog --title "Building Examples" --infobox "Building all $category examples...\n\nThis may take several minutes.\nPlease wait..." 8 50
    DIALOG_USED=true
    
    local built=0
    local failed=0
    
    for example in "${examples[@]}"; do
        if build_single_example "$example"; then
            ((built++))
        else
            ((failed++))
        fi
    done
    
    dialog --title "Build Complete" --msgbox "Build summary:\n\nBuilt: $built examples\nFailed: $failed examples" 10 50
    DIALOG_USED=true
}

# Show single example build menu
build_single_example_menu() {
    local all_examples=("${WT_BASIC_EXAMPLES[@]}" "${WT_FEATURE_EXAMPLES[@]}")
    local menu_items=()
    
    for example in "${all_examples[@]}"; do
        local status=$(get_example_status "$example")
        local display_name="$example"
        if [[ "$example" == feature/* ]]; then
            display_name=$(echo "$example" | sed 's|feature/||')
        fi
        menu_items+=("$example" "$display_name $status")
    done
    
    local choice
    choice=$(dialog \
        --colors \
        --clear \
        --title "Build Single Example" \
        --menu "Select example to build:" 25 80 18 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ] && [ -n "$choice" ]; then
        if build_single_example "$choice"; then
            dialog --title "Success" --msgbox "Example '$choice' built successfully!" 7 50
            DIALOG_USED=true
        else
            dialog --title "Error" --msgbox "Failed to build example '$choice'." 7 50
            DIALOG_USED=true
        fi
    fi
}

# Show build status
show_build_status() {
    local all_examples=("${WT_BASIC_EXAMPLES[@]}" "${WT_FEATURE_EXAMPLES[@]}")
    local built_count=0
    local total_count=${#all_examples[@]}
    local status_text=""
    
    for example in "${all_examples[@]}"; do
        local display_name="$example"
        if [[ "$example" == feature/* ]]; then
            display_name=$(echo "$example" | sed 's|feature/||')
        fi
        
        if check_example_built "$example"; then
            status_text="${status_text}✓ $display_name (Built)\n"
            ((built_count++))
        else
            status_text="${status_text}✗ $display_name (Not Built)\n"
        fi
    done
    
    dialog --title "Build Status" --msgbox "Examples Build Status:\n\nBuilt: $built_count / $total_count\n\n$status_text" 25 80
    DIALOG_USED=true
}

# Main examples menu
show_main_menu() {
    ensure_dialog
    
    while true; do
        local wt_status="Not Available"
        if check_wt_library; then
            wt_status="Available"
        fi
        
        local choice
        choice=$(dialog \
            --colors \
            --clear \
            --no-ok \
            --no-cancel \
            --backtitle "Wt Examples Manager" \
            --title "Interactive Wt Examples" \
            --menu "Wt Library: $wt_status | Version: $CURRENT_WT_VERSION | Config: $CURRENT_BUILD_CONFIG\n\nSelect action:" 20 80 10 \
            "run_basic" "Run Basic Examples" \
            "run_feature" "Run Feature Examples" \
            "build" "Build Examples" \
            "info" "Example Information" \
            "clean" "Clean Examples" \
            "back" "Back to main menu" \
            3>&1 1>&2 2>&3)
        DIALOG_USED=true
        local menu_status=$?
        
        printf '\033c'
        clear
        printf '\033[0m'
        tput sgr0 2>/dev/null || true
        
        if [ $menu_status -ne 0 ]; then
            print_status "User exited from examples menu."
            break
        fi
        
        case "$choice" in
            "run_basic")
                show_examples_menu "basic"
                ;;
            "run_feature")
                show_examples_menu "feature"
                ;;
            "build")
                show_build_menu
                ;;
            "info")
                show_examples_info
                ;;
            "clean")
                clean_examples
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

# Show examples information
show_examples_info() {
    local info_text=""
    local total_basic=${#WT_BASIC_EXAMPLES[@]}
    local total_feature=${#WT_FEATURE_EXAMPLES[@]}
    
    info_text="Wt Examples Collection\n\n"
    info_text="${info_text}Basic Examples: $total_basic\n"
    info_text="${info_text}Feature Examples: $total_feature\n"
    info_text="${info_text}Total Examples: $((total_basic + total_feature))\n\n"
    info_text="${info_text}Port Range: $WT_EXAMPLES_PORT_BASE+\n"
    info_text="${info_text}Build Directory: $WT_EXAMPLES_BUILD_DIR\n"
    info_text="${info_text}Resources: $WT_RESOURCES_DIR\n\n"
    info_text="${info_text}Popular Examples:\n"
    info_text="${info_text}• hello - Simple Hello World\n"
    info_text="${info_text}• charts - Interactive charts\n"
    info_text="${info_text}• widgetgallery - All Wt widgets\n"
    info_text="${info_text}• authentication - Login system\n"
    info_text="${info_text}• blog - Blogging application\n"
    
    dialog --title "Examples Information" --msgbox "$info_text" 25 80
    DIALOG_USED=true
}

# Clean examples
clean_examples() {
    local choice
    choice=$(dialog \
        --colors \
        --clear \
        --title "Clean Examples" \
        --yesno "This will remove all built examples.\n\nContinue?" 8 50)
    DIALOG_USED=true
    local status=$?
    
    printf '\033c'; clear; printf '\033[0m'; tput sgr0 2>/dev/null || true
    
    if [ $status -eq 0 ]; then
        if [ -d "$WT_EXAMPLES_DIR" ]; then
            rm -rf "$WT_EXAMPLES_DIR"
            dialog --title "Success" --msgbox "Examples cleaned successfully!" 7 50
            DIALOG_USED=true
        else
            dialog --title "Info" --msgbox "No examples directory found to clean." 7 50
            DIALOG_USED=true
        fi
    fi
}

# ===================================================================
# Main Entry Point
# ===================================================================

show_main_menu
print_success "${SCRIPT_NAME%.sh} completed successfully!"
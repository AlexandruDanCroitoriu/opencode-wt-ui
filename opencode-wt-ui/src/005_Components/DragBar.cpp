#include "005_Components/DragBar.h"
#include <Wt/WApplication.h>
#include <memory>
#include <sstream>

DragBar::DragBar(Wt::WWidget* target_widget, int initial_width, int min_width, int max_width)
    : target_widget_(target_widget), 
      current_width_(initial_width),
      min_width_(min_width),
      max_width_(max_width),
      js_width_changed_(this, "widthChanged")
{
    // Connect the JavaScript signal to the onWidthChanged method
    js_width_changed_.connect(this, &DragBar::onWidthChanged);
    
    initializeDragBar();
    setupJavaScriptHandlers();
}

void DragBar::onWidthChanged(int new_width) {
    current_width_ = new_width;
    width_changed_.emit(new_width);
}

void DragBar::initializeDragBar() {
    // Set initial styling for the drag bar
    addStyleClass("flex-none cursor-col-resize bg-gray-300 hover:bg-gray-400 transition-colors duration-200");
    setAttributeValue("style", "width: 8px; user-select: none;");
    
    // Set initial width of target widget
    if (target_widget_) {
        std::stringstream width_style;
        width_style << "width: " << current_width_ << "px;";
        target_widget_->setAttributeValue("style", width_style.str());
        target_widget_->addStyleClass("flex-none");
    }
}

void DragBar::setupJavaScriptHandlers() {
    // Generate unique IDs for the drag bar and target widget
    std::string drag_bar_id = id();
    std::string target_id = target_widget_ ? target_widget_->id() : "";
    
    if (target_id.empty()) {
        return; // Cannot setup handlers without target widget ID
    }

    // JavaScript code for drag functionality
    std::stringstream js_stream;
    js_stream << 
    "var dragBar" << drag_bar_id << " = document.getElementById('" << drag_bar_id << "');\n"
    "var targetWidget" << target_id << " = document.getElementById('" << target_id << "');\n"
    "var isDragging" << drag_bar_id << " = false;\n"
    "var startX" << drag_bar_id << " = 0;\n"
    "var startWidth" << drag_bar_id << " = " << current_width_ << ";\n"
    "\n"
    "dragBar" << drag_bar_id << ".addEventListener('mousedown', function(e) {\n"
    "    isDragging" << drag_bar_id << " = true;\n"
    "    startX" << drag_bar_id << " = e.clientX;\n"
    "    startWidth" << drag_bar_id << " = parseInt(targetWidget" << target_id << ".offsetWidth);\n"
    "    document.body.style.cursor = 'col-resize';\n"
    "    document.body.style.userSelect = 'none';\n"
    "    e.preventDefault();\n"
    "});\n"
    "\n"
    "document.addEventListener('mousemove', function(e) {\n"
    "    if (!isDragging" << drag_bar_id << ") return;\n"
    "    \n"
    "    var deltaX = e.clientX - startX" << drag_bar_id << ";\n"
    "    var newWidth = startWidth" << drag_bar_id << " + deltaX;\n"
    "    \n"
    "    // Apply constraints\n"
    "    if (newWidth < " << min_width_ << ") newWidth = " << min_width_ << ";\n"
    "    if (newWidth > " << max_width_ << ") newWidth = " << max_width_ << ";\n"
    "    \n"
    "    targetWidget" << target_id << ".style.width = newWidth + 'px';\n"
    "    e.preventDefault();\n"
    "});\n"
    "\n"
    "document.addEventListener('mouseup', function(e) {\n"
    "    if (isDragging" << drag_bar_id << ") {\n"
    "        isDragging" << drag_bar_id << " = false;\n"
    "        document.body.style.cursor = '';\n"
    "        document.body.style.userSelect = '';\n"
    "        \n"
    "        // Get the final width and emit signal to server\n"
    "        var finalWidth = parseInt(targetWidget" << target_id << ".offsetWidth);\n"
    "        Wt.emit('" << drag_bar_id << "', 'widthChanged', finalWidth);\n"
    "    }\n"
    "});\n"
    "\n"
    "// Prevent text selection during drag\n"
    "dragBar" << drag_bar_id << ".addEventListener('selectstart', function(e) {\n"
    "    e.preventDefault();\n"
    "});\n";

    drag_js_code_ = js_stream.str();
    
    // Execute the JavaScript when the widget is rendered
    Wt::WApplication::instance()->doJavaScript(drag_js_code_);
}

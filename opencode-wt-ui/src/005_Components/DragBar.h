#pragma once

#include <Wt/WContainerWidget.h>
#include <Wt/WJavaScript.h>
#include <Wt/WSignal.h>

/**
 * @brief A custom drag bar widget for resizing adjacent widgets
 * 
 * DragBar provides a draggable separator that can resize a target widget's width.
 * It implements JavaScript-based mouse drag functionality with proper visual feedback
 * and constraints for minimum/maximum widths.
 */
class DragBar : public Wt::WContainerWidget {
public:
    /**
     * @brief Constructor - creates a drag bar for resizing the target widget
     * @param target_widget The widget whose width will be controlled by dragging
     * @param initial_width Initial width of the target widget in pixels
     * @param min_width Minimum allowed width in pixels (default: 200)
     * @param max_width Maximum allowed width in pixels (default: 800)
     */
    DragBar(Wt::WWidget* target_widget, 
            int initial_width = 500, 
            int min_width = 200, 
            int max_width = 800);

    /**
     * @brief Signal emitted when drag operation ends with the new width
     * @return Signal that provides the new width in pixels
     */
    Wt::Signal<int>& widthChanged() { return width_changed_; }

private:
    /**
     * @brief Initializes the drag bar styling and behavior
     */
    void initializeDragBar();
    
    /**
     * @brief Sets up JavaScript event handlers for drag functionality
     */
    void setupJavaScriptHandlers();

    /**
     * @brief Callback function for when drag ends with new width
     * @param new_width The new width in pixels
     */
    void onWidthChanged(int new_width);

    Wt::WWidget* target_widget_;           ///< Widget to resize
    int current_width_;                    ///< Current width of target widget
    int min_width_;                        ///< Minimum allowed width
    int max_width_;                        ///< Maximum allowed width
    
    std::string drag_js_code_;             ///< JavaScript code for drag functionality
    Wt::Signal<int> width_changed_;        ///< Signal emitted when width changes
    Wt::JSignal<int> js_width_changed_;    ///< JavaScript signal for width changes
};

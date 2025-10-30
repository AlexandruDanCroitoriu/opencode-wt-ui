#include "Theme.h"

#include <initializer_list>
#include <sstream>

#include <Wt/DomElement.h>
#include <Wt/WApplication.h>
#include <Wt/WCheckBox.h>
#include <Wt/WDialog.h>
#include <Wt/WLink.h>
#include <Wt/WMenuItem.h>
#include <Wt/WPanel.h>
#include <Wt/WPopupMenu.h>
#include <Wt/WPopupWidget.h>
#include <Wt/WProgressBar.h>
#include <Wt/WPushButton.h>
#include <Wt/WRadioButton.h>
#include <Wt/WString.h>
#include <Wt/WSuggestionPopup.h>
#include <Wt/WTabWidget.h>
#include <Wt/WWidget.h>
#include <Wt/WRandom.h>

namespace {

void addClasses(Wt::DomElement& element, std::initializer_list<const char*> classes)
{
    for (const char* cls : classes) {
        element.addPropertyWord(Wt::Property::Class, cls);
    }
}

std::string classesFromMessage(const char* messageId)
{
    if (!messageId) {
        return {};
    }

    const std::string classes = Wt::WString::tr(messageId).toUTF8();
    if (classes.size() >= 4 && classes[0] == '?' && classes[1] == '?') {
        return {};
    }

    return classes;
}

void addClassesFromMessage(Wt::DomElement& element, const char* messageId)
{
    const std::string classes = classesFromMessage(messageId);
    if (classes.empty()) {
        return;
    }

    std::istringstream stream(classes);
    std::string cls;
    while (stream >> cls) {
        element.addPropertyWord(Wt::Property::Class, cls);
    }
}

void addClassesFromMessage(Wt::WWidget* widget, const char* messageId)
{
    if (!widget) {
        return;
    }

    const std::string classes = classesFromMessage(messageId);
    if (classes.empty()) {
        return;
    }

    widget->addStyleClass(classes);
}

}

Theme::Theme(const std::string& name)
    : WTheme()
    , name_(name.empty() ? "tailwind" : name)
{
    wApp->messageResourceBundle().use(wApp->docRoot() + "/static/0_stylus/xml/000_General/General_components");
}

Theme::~Theme() = default;

std::string Theme::name() const
{
    return name_;
}

std::vector<Wt::WLinkedCssStyleSheet> Theme::styleSheets() const
{
    std::vector<Wt::WLinkedCssStyleSheet> sheets;

    auto* app = Wt::WApplication::instance();
    if (!app) {
        return sheets;
    }

#ifdef DEBUG
    const std::string cssPath = "static/css/tailwind.css?v=" + Wt::WRandom::generateId();
#else
    const std::string cssPath = "static/css/tailwind.minify.css";
#endif

    sheets.emplace_back(Wt::WLinkedCssStyleSheet(Wt::WLink(cssPath)));
    return sheets;
}

void Theme::apply(Wt::WWidget* widget, Wt::WWidget* child, int widgetRole) const
{
    if (!widget->isThemeStyleEnabled()) {
        return;
    }

    switch (widgetRole) {
    case Wt::MenuItemIcon:
        child->addStyleClass("w-4 h-4 text-gray-500 dark:text-gray-400");
        break;
    case Wt::MenuItemCheckBox:
        addClassesFromMessage(child, "checkbox.default");
        break;
    case Wt::MenuItemClose:
        widget->addStyleClass("relative");
        child->addStyleClass("absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600");
        break;
    case Wt::DialogCoverWidget:
        child->setStyleClass("fixed inset-0 bg-gray-900/60 backdrop-blur-sm transition-opacity");
        break;
    case Wt::DialogTitleBar:
        child->addStyleClass("px-6 py-4 text-lg font-semibold text-gray-900 dark:text-gray-100 border-b border-gray-200 dark:border-gray-700");
        break;
    case Wt::DialogBody:
        child->addStyleClass("px-6 py-4 space-y-4");
        break;
    case Wt::DialogFooter:
        child->addStyleClass("px-6 py-4 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 flex justify-end gap-2");
        break;
    case Wt::DialogCloseIcon:
        child->addStyleClass("text-gray-400 hover:text-gray-600 transition-colors");
        break;
    case Wt::PanelTitleBar:
        child->addStyleClass("px-4 py-2 font-semibold text-gray-900 dark:text-gray-100 border-b border-gray-200 dark:border-gray-700");
        break;
    case Wt::PanelBody:
        child->addStyleClass("px-4 py-3 space-y-3");
        break;
    case Wt::PanelCollapseButton:
        child->setFloatSide(Wt::Side::Right);
        break;
    case Wt::AuthWidgets:
        if (auto* app = Wt::WApplication::instance()) {
            app->useStyleSheet(Wt::WApplication::relativeResourcesUrl() + "form.css");
        }
        break;
    default:
        break;
    }
}

void Theme::apply(Wt::WWidget* widget, Wt::DomElement& element, int elementRole) const
{
    if (!widget->isThemeStyleEnabled()) {
        return;
    }

    const bool creating = element.mode() == Wt::DomElement::Mode::Create;

    if (auto* popup = dynamic_cast<Wt::WPopupWidget*>(widget)) {
        addClasses(element, {
            "shadow-xl",
            "rounded-xl",
            "border",
            "border-gray-200",
            "dark:border-gray-700",
            "bg-white",
            "dark:bg-gray-800"
        });
    }

    switch (element.type()) {
    case Wt::DomElementType::BUTTON:
        if (creating) {
            addClassesFromMessage(element, "btn.default");
        }

        (void)widget;
        break;

    case Wt::DomElementType::DIV:
        if (auto* dialog = dynamic_cast<Wt::WDialog*>(widget)) {
            addClasses(element, {
                "bg-white",
                "dark:bg-gray-900",
                "rounded-2xl",
                "shadow-2xl",
                "border",
                "border-gray-200",
                "dark:border-gray-700"
            });
            return;
        }

        if (auto* panel = dynamic_cast<Wt::WPanel*>(widget)) {
            addClasses(element, {
                "rounded-xl",
                "border",
                "border-gray-200",
                "dark:border-gray-700",
                "bg-white",
                "dark:bg-gray-800",
                "shadow"
            });
            return;
        }

        if (auto* bar = dynamic_cast<Wt::WProgressBar*>(widget)) {
            switch (elementRole) {
            case Wt::MainElement:
                addClasses(element, {
                    "h-2",
                    "rounded-full",
                    "bg-gray-200",
                    "dark:bg-gray-700",
                    "overflow-hidden"
                });
                break;
            case Wt::ProgressBarBar:
                addClasses(element, {
                    "h-full",
                    "bg-blue-600",
                    "dark:bg-blue-400",
                    "transition-all"
                });
                break;
            case Wt::ProgressBarLabel:
                addClasses(element, {
                    "mt-2",
                    "text-sm",
                    "font-medium",
                    "text-gray-600",
                    "dark:text-gray-300"
                });
                break;
            default:
                break;
            }
            return;
        }
        break;

    case Wt::DomElementType::UL:
        if (dynamic_cast<Wt::WPopupMenu*>(widget)) {
            addClasses(element, {
                "bg-white",
                "dark:bg-gray-800",
                "rounded-lg",
                "shadow-xl",
                "border",
                "border-gray-200",
                "dark:border-gray-700",
                "py-2"
            });
        } else if (dynamic_cast<Wt::WSuggestionPopup*>(widget)) {
            addClasses(element, {
                "bg-white",
                "dark:bg-gray-800",
                "rounded-lg",
                "shadow-lg",
                "border",
                "border-gray-200",
                "dark:border-gray-700",
                "divide-y",
                "divide-gray-200",
                "dark:divide-gray-700"
            });
        } else {
            auto* parent = widget ? widget->parent() : nullptr;
            auto* grandParent = parent ? parent->parent() : nullptr;
            if (auto* tabs = dynamic_cast<Wt::WTabWidget*>(grandParent)) {
                (void)tabs;
                addClasses(element, {
                    "flex",
                    "gap-2",
                    "border-b",
                    "border-gray-200",
                    "dark:border-gray-700"
                });
            }
        }
        break;

    case Wt::DomElementType::LI:
        if (auto* item = dynamic_cast<Wt::WMenuItem*>(widget)) {
            if (item->isSeparator()) {
                addClasses(element, {
                    "my-2",
                    "border-t",
                    "border-gray-200",
                    "dark:border-gray-700"
                });
            } else {
                addClasses(element, {
                    "text-sm",
                    "text-gray-700",
                    "dark:text-gray-200",
                    "hover:bg-gray-100",
                    "dark:hover:bg-gray-700",
                    "transition-colors"
                });
            }

            if (item->menu()) {
                addClasses(element, {"relative"});
            }
        }
        break;

    case Wt::DomElementType::INPUT:
        if (creating) {
            if (dynamic_cast<Wt::WCheckBox*>(widget)) {
                addClassesFromMessage(element, "checkbox.default");
            } else if (!dynamic_cast<Wt::WRadioButton*>(widget)) {
                addClassesFromMessage(element, "lineedit.default");
            }
        }
        break;

    case Wt::DomElementType::TEXTAREA:
        if (creating) {
            addClassesFromMessage(element, "lineedit.default");
        }
        break;

    case Wt::DomElementType::SELECT:
        if (creating) {
            addClassesFromMessage(element, "combobox.default");
        }
        break;

    default:
        break;
    }
}

std::string Theme::disabledClass() const
{
    return "opacity-60";
}

std::string Theme::activeClass() const
{
    return "bg-blue-600";
}

std::string Theme::utilityCssClass(int utilityCssClassRole) const
{
    switch (utilityCssClassRole) {
    case Wt::ToolTipOuter:
        return "rounded-md";
    default:
        return std::string();
    }
}

bool Theme::canStyleAnchorAsButton() const
{
    return true;
}

void Theme::applyValidationStyle(Wt::WWidget* widget,
                                 const Wt::WValidator::Result& validation,
                                 Wt::WFlags<Wt::ValidationStyleFlag> styles) const
{
    const bool isValid = validation.state() == Wt::ValidationState::Valid;
    const bool applyValidStyle = isValid && styles.test(Wt::ValidationStyleFlag::ValidStyle);
    const bool applyInvalidStyle = !isValid && styles.test(Wt::ValidationStyleFlag::InvalidStyle);

    widget->toggleStyleClass("border-green-500", applyValidStyle);
    widget->toggleStyleClass("focus:ring-green-500", applyValidStyle);
    widget->toggleStyleClass("border-red-500", applyInvalidStyle);
    widget->toggleStyleClass("focus:ring-red-500", applyInvalidStyle);
}

bool Theme::canBorderBoxElement(const Wt::DomElement& element) const
{
    (void)element;
    return true;
}

#pragma once

#include <string>
#include <vector>

#include <Wt/WFlags.h>
#include <Wt/WLinkedCssStyleSheet.h>
#include <Wt/WTheme.h>
#include <Wt/WValidator.h>

namespace Wt {
class DomElement;
class WWidget;
}

class Theme : public Wt::WTheme
{
public:
    explicit Theme(const std::string& name = "tailwind");
    ~Theme() override;

    std::string name() const override;
    std::vector<Wt::WLinkedCssStyleSheet> styleSheets() const override;
    void apply(Wt::WWidget* widget, Wt::WWidget* child, int widgetRole) const override;
    void apply(Wt::WWidget* widget, Wt::DomElement& element, int elementRole) const override;
    std::string disabledClass() const override;
    std::string activeClass() const override;
    std::string utilityCssClass(int utilityCssClassRole) const override;
    bool canStyleAnchorAsButton() const override;
    void applyValidationStyle(Wt::WWidget* widget,
                              const Wt::WValidator::Result& validation,
                              Wt::WFlags<Wt::ValidationStyleFlag> styles) const override;
    bool canBorderBoxElement(const Wt::DomElement& element) const override;

private:
    std::string name_;
};

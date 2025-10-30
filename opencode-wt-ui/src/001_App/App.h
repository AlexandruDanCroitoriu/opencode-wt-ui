#pragma once

#include <Wt/WApplication.h>

#include "002_Dbo/Session.h"

#include "006_Stylus/Stylus.h"
#include "007_Opencode/Opencode.h"
#include "003_Auth/AuthWidget.h"
#include "004_Theme/Theme.h"

namespace Wt {
    class WContainerWidget;
    class WDialog;
}

class App : public Wt::WApplication
{
public:
    App(const Wt::WEnvironment& env);

    // Wt::Signal<bool> dark_mode_changed_;
    // Wt::Signal<ThemeConfig> theme_changed_;
    
private:
    Wt::WDialog* authDialog_ = nullptr;
    Session session_;
    Stylus::Stylus* stylus_ = nullptr;
    Opencode::Opencode* opencode_ = nullptr;
    void authEvent();
    // Wt::WContainerWidget* app_content_;
    void createApp();
    AuthWidget* authWidget_ = nullptr;
    Wt::WContainerWidget* appRoot_ = nullptr;
};
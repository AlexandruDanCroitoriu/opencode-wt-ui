#pragma once

#include <Wt/WDialog.h>
#include <Wt/WMenu.h>
#include <Wt/WMenuItem.h>
#include <Wt/WContainerWidget.h>
#include <Wt/WStackedWidget.h>
#include "002_Dbo/Session.h"
#include "Sessions.h"

namespace Opencode {

class Opencode : public Wt::WDialog
{
public:
    Opencode(Session& session);

private:
    void initializeDialog();
    void setupContent();
    void setupKeyboardShortcuts();
    void keyWentDown(Wt::WKeyEvent e);

    Session& session_;

    Wt::WContainerWidget* sessions_wrapper_;
    Wt::WMenu* sessions_menu_;
    Wt::WStackedWidget* content_stack_;

    // Wt::WContainerWidget* left_panel_;
    // Wt::WContainerWidget* main_content_;
    
    Sessions* sessions_widget_;
};

}
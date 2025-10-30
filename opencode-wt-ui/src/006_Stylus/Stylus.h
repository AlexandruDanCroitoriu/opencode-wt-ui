#pragma once

#include <Wt/WDialog.h>
#include <Wt/WMenu.h>
#include <Wt/WMenuItem.h>
#include <Wt/WContainerWidget.h>
#include <Wt/WStackedWidget.h>
#include "002_Dbo/Session.h"

namespace Stylus {

class Stylus : public Wt::WDialog
{
public:
    Stylus(Session& session);

private:
    void initializeDialog();
    void setupContent();
    void setupKeyboardShortcuts();
    void keyWentDown(Wt::WKeyEvent e);

    Session& session_;

    Wt::WContainerWidget* navbar_wrapper_;
    Wt::WMenu* menu_;
    Wt::WStackedWidget* content_stack_;

    Wt::WContainerWidget* xml_files_wrapper_;
    Wt::WContainerWidget* css_files_wrapper_;
    Wt::WContainerWidget* js_files_wrapper_;
    Wt::WContainerWidget* tailwind_files_wrapper_;
    Wt::WContainerWidget* images_files_wrapper_;
    Wt::WContainerWidget* settings_wrapper_;

    Wt::WMenuItem* xml_menu_item_;
    Wt::WMenuItem* css_menu_item_;
    Wt::WMenuItem* js_menu_item_;
    Wt::WMenuItem* tailwind_menu_item_;
    Wt::WMenuItem* images_menu_item_;
    Wt::WMenuItem* settings_menu_item_;
};

}
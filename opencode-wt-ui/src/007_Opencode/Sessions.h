#pragma once

#include <Wt/WContainerWidget.h>
#include <Wt/WVBoxLayout.h>
#include <Wt/WHBoxLayout.h>
#include <Wt/WText.h>
#include <Wt/WPushButton.h>
#include <Wt/WLineEdit.h>
#include "002_Dbo/Session.h"

namespace Opencode {

class Sessions : public Wt::WContainerWidget
{
public:
    Sessions(Session& session);

private:
    void setupLayout();
    void setupSessionList();
    void setupSessionControls();
    void refreshSessionList();
    void createNewSession();
    void loadSession();
    void deleteSession();
    void sessionSelected();

    Session& session_;
    
    Wt::WText* title_;
    Wt::WContainerWidget* session_list_;
    Wt::WPushButton* new_session_btn_;
    Wt::WPushButton* load_session_btn_;
    Wt::WPushButton* delete_session_btn_;
    Wt::WLineEdit* session_name_edit_;
    Wt::WPushButton* selected_session_;
};

}
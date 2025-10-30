#include "007_Opencode/Sessions.h"
#include <Wt/WVBoxLayout.h>
#include <Wt/WHBoxLayout.h>
#include <Wt/WMessageBox.h>
#include <Wt/WApplication.h>
#include <Wt/WLogger.h>

namespace Opencode {

Sessions::Sessions(Session& session)
    : Wt::WContainerWidget(), 
      session_(session)
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::Sessions() - Constructor called";
    #endif
    
    setupLayout();
    setupSessionList();
    setupSessionControls();
    refreshSessionList();
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::Sessions() - Constructor completed";
    #endif
}

void Sessions::setupLayout()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupLayout() - Setting up layout";
    #endif
    
    setStyleClass("p-4 h-full");
    setLayout(std::make_unique<Wt::WVBoxLayout>());
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupLayout() - Layout setup completed";
    #endif
}

void Sessions::setupSessionList()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionList() - Setting up session list";
    #endif
    
    // Title
    title_ = addNew<Wt::WText>("Sessions");
    title_->setStyleClass("text-lg font-bold mb-2");
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionList() - Title widget created: " << title_;
    #endif
    
    // Session name input
    session_name_edit_ = addNew<Wt::WLineEdit>();
    session_name_edit_->setPlaceholderText("Session name...");
    session_name_edit_->setStyleClass("w-full p-2 border rounded mb-2");
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionList() - Session name input created: " << session_name_edit_;
    #endif
    
    // Session list container
    session_list_ = addNew<Wt::WContainerWidget>();
    session_list_->setStyleClass("flex-1 w-full border rounded p-2 bg-white overflow-y-auto");
    session_list_->setLayout(std::make_unique<Wt::WVBoxLayout>());
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionList() - Session list container created: " << session_list_;
    #endif
    
    selected_session_ = nullptr;
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionList() - Session list setup completed";
    #endif
}

void Sessions::setupSessionControls()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionControls() - Setting up session controls";
    #endif
    
    // Button container
    auto button_container = addNew<Wt::WContainerWidget>();
    button_container->setLayout(std::make_unique<Wt::WVBoxLayout>());
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionControls() - Button container created: " << button_container;
    #endif
    
    // New session button
    new_session_btn_ = button_container->addNew<Wt::WPushButton>("New Session");
    new_session_btn_->setStyleClass("w-full p-2 bg-blue-500 text-white rounded hover:bg-blue-600");
    new_session_btn_->clicked().connect([=]() {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::setupSessionControls() - New Session button clicked";
        #endif
        createNewSession();
    });
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionControls() - New session button created: " << new_session_btn_;
    #endif
    
    // Load session button
    load_session_btn_ = button_container->addNew<Wt::WPushButton>("Load Session");
    load_session_btn_->setStyleClass("w-full p-2 bg-green-500 text-white rounded hover:bg-green-600");
    load_session_btn_->setEnabled(false);
    load_session_btn_->clicked().connect([=]() {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::setupSessionControls() - Load Session button clicked";
        #endif
        loadSession();
    });
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionControls() - Load session button created: " << load_session_btn_;
    #endif
    
    // Delete session button
    delete_session_btn_ = button_container->addNew<Wt::WPushButton>("Delete Session");
    delete_session_btn_->setStyleClass("w-full p-2 bg-red-500 text-white rounded hover:bg-red-600");
    delete_session_btn_->setEnabled(false);
    delete_session_btn_->clicked().connect([=]() {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::setupSessionControls() - Delete Session button clicked";
        #endif
        deleteSession();
    });
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionControls() - Delete session button created: " << delete_session_btn_;
    #endif
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::setupSessionControls() - Session controls setup completed";
    #endif
}

void Sessions::refreshSessionList()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::refreshSessionList() - Refreshing session list";
    #endif
    
    session_list_->clear();
    selected_session_ = nullptr;
    
    // TODO: Replace with actual database query to get sessions
    // For now, add some sample sessions
    std::vector<std::string> session_names = {"Default Session", "Project Alpha", "Experimental"};
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::refreshSessionList() - Adding " << session_names.size() << " sample sessions";
    #endif
    
    for (const auto& name : session_names) {
        auto session_btn = session_list_->addNew<Wt::WPushButton>(name);
        session_btn->setStyleClass("w-full p-2 text-left border rounded mb-1 hover:bg-gray-100");
        
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::refreshSessionList() - Created session button: " << name << " (" << session_btn << ")";
        #endif
        
        session_btn->clicked().connect([=, this]() {
            #ifdef DEBUG
            Wt::log("debug") << "Sessions::refreshSessionList() - Session button clicked: " << name;
            #endif
            
            // Deselect previous selection
            if (selected_session_) {
                selected_session_->setStyleClass("w-full p-2 text-left border rounded mb-1 hover:bg-gray-100");
                #ifdef DEBUG
                Wt::log("debug") << "Sessions::refreshSessionList() - Deselected previous session: " << selected_session_->text().toUTF8();
                #endif
            }
            
            // Select new session
            selected_session_ = session_btn;
            session_btn->setStyleClass("w-full p-2 text-left border rounded mb-1 bg-blue-100 border-blue-300");
            
            #ifdef DEBUG
            Wt::log("debug") << "Sessions::refreshSessionList() - Selected new session: " << name;
            #endif
            
            sessionSelected();
        });
    }
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::refreshSessionList() - Session list refresh completed";
    #endif
}

void Sessions::createNewSession()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::createNewSession() - Creating new session";
    #endif
    
    std::string session_name = session_name_edit_->text().toUTF8();
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::createNewSession() - Session name: '" << session_name << "'";
    #endif
    
    if (session_name.empty()) {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::createNewSession() - Session name is empty, showing error";
        #endif
        
        auto messageBox = addChild(std::make_unique<Wt::WMessageBox>(
            "Error", 
            "Please enter a session name.", 
            Wt::Icon::Warning, 
            Wt::StandardButton::Ok
        ));
        messageBox->show();
        return;
    }
    
    // TODO: Add session to database
    // For now, just add to the list
    auto session_btn = session_list_->addNew<Wt::WPushButton>(session_name);
    session_btn->setStyleClass("w-full p-2 text-left border rounded mb-1 hover:bg-gray-100");
    
    session_btn->clicked().connect([=, this]() {
        // Deselect previous selection
        if (selected_session_) {
            selected_session_->setStyleClass("w-full p-2 text-left border rounded mb-1 hover:bg-gray-100");
        }
        
        // Select new session
        selected_session_ = session_btn;
        session_btn->setStyleClass("w-full p-2 text-left border rounded mb-1 bg-blue-100 border-blue-300");
        
        sessionSelected();
    });
    
    // Clear input field
    session_name_edit_->setText("");
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::createNewSession() - Session '" << session_name << "' created successfully";
    #endif
    
    // Show success message
    auto messageBox = addChild(std::make_unique<Wt::WMessageBox>(
        "Success", 
        "Session '" + session_name + "' created successfully.", 
        Wt::Icon::Information, 
        Wt::StandardButton::Ok
    ));
    messageBox->show();
}

void Sessions::loadSession()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::loadSession() - Loading session";
    #endif
    
    if (!selected_session_) {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::loadSession() - No session selected, returning";
        #endif
        return;
    }
    
    std::string session_name = selected_session_->text().toUTF8();
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::loadSession() - Loading session: '" << session_name << "'";
    #endif
    
    // TODO: Load session data from database
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::loadSession() - Session '" << session_name << "' loaded successfully";
    #endif
    
    // Show success message
    auto messageBox = addChild(std::make_unique<Wt::WMessageBox>(
        "Session Loaded", 
        "Session '" + session_name + "' loaded successfully.", 
        Wt::Icon::Information, 
        Wt::StandardButton::Ok
    ));
    messageBox->show();
}

void Sessions::deleteSession()
{
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::deleteSession() - Deleting session";
    #endif
    
    if (!selected_session_) {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::deleteSession() - No session selected, returning";
        #endif
        return;
    }
    
    std::string session_name = selected_session_->text().toUTF8();
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::deleteSession() - Deleting session: '" << session_name << "'";
    #endif
    
    // Show confirmation dialog
    auto messageBox = addChild(std::make_unique<Wt::WMessageBox>(
        "Confirm Delete", 
        "Are you sure you want to delete session '" + session_name + "'?", 
        Wt::Icon::Question, 
        Wt::StandardButton::Yes | Wt::StandardButton::No
    ));
    
    messageBox->buttonClicked().connect([=](Wt::StandardButton button) {
        #ifdef DEBUG
        Wt::log("debug") << "Sessions::deleteSession() - Confirmation dialog result: " << (button == Wt::StandardButton::Yes ? "Yes" : "No");
        #endif
        
        if (button == Wt::StandardButton::Yes) {
            // TODO: Delete from database
            
            #ifdef DEBUG
            Wt::log("debug") << "Sessions::deleteSession() - Removing session from UI: '" << session_name << "'";
            #endif
            
            // Remove from list
            if (selected_session_) {
                selected_session_->removeFromParent();
                selected_session_ = nullptr;
            }
            
            // Disable buttons
            load_session_btn_->setEnabled(false);
            delete_session_btn_->setEnabled(false);
            
            #ifdef DEBUG
            Wt::log("debug") << "Sessions::deleteSession() - Session '" << session_name << "' deleted successfully";
            #endif
        }
    });
    
    messageBox->show();
}

void Sessions::sessionSelected()
{
    bool has_selection = (selected_session_ != nullptr);
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::sessionSelected() - Session selection changed. Has selection: " << (has_selection ? "true" : "false");
    if (has_selection) {
        Wt::log("debug") << "Sessions::sessionSelected() - Selected session: '" << selected_session_->text().toUTF8() << "'";
    }
    #endif
    
    load_session_btn_->setEnabled(has_selection);
    delete_session_btn_->setEnabled(has_selection);
    
    #ifdef DEBUG
    Wt::log("debug") << "Sessions::sessionSelected() - Load button enabled: " << (has_selection ? "true" : "false");
    Wt::log("debug") << "Sessions::sessionSelected() - Delete button enabled: " << (has_selection ? "true" : "false");
    #endif
}

}
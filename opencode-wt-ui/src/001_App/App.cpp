#include "App.h"
// #include "006-Navigation/Navigation.h"

#include "004_Theme/DarkModeToggle.h"
// #include "004_Theme/ThemeSwitcher.h"

// #include "005_Components/ComponentsDisplay.h"
// #include "008-AboutMe/AboutMe.h"
// #include "101-StarWarsApi/StarWarsApi.h"

#include <Wt/WStackedWidget.h>
#include <Wt/WPushButton.h>
#include <Wt/WMenu.h>
#include <Wt/WLabel.h>
#include <Wt/WTheme.h>
#include <Wt/WContainerWidget.h>
#include <Wt/WDialog.h>
#include <memory>
#include <Wt/WRandom.h>

// #include "101-Stylus/000-Utils/StylusState.h"

App::App(const Wt::WEnvironment& env)
    : Wt::WApplication(env),
      session_(appRoot() + "../dbo.db")
{
#ifdef DEBUG
    Wt::log("debug") << "App::App() - application starting";
#endif
    // Title
    setTitle("Wt CPP app title");
    setHtmlClass("dark");
    // setCssTheme("polished");
    // #ifdef DEBUG
    // useStyleSheet(docRoot() + "/static/css/tailwind.css?v=" + Wt::WRandom::generateId()); // Cache busting
    // #elif RELEASE
    // useStyleSheet(docRoot() + "/static/css/tailwind.minify.css");
    // #endif
    setBodyClass("min-h-screen min-w-screen bg-gray-50 text-gray-900 font-sans antialiased dark:bg-gray-900 dark:text-gray-100 transition-colors");
    // require("https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4");
    // require("https://unpkg.com/vue@3/dist/vue.global.prod.js");
    // require("https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js");
    
    {
        // Load XML bundles that override the default Wt authentication templates.
        auto& bundle = wApp->messageResourceBundle();
        
        // bundle.use(docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-auth");
        // bundle.use(docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-auth-login");
        // bundle.use(docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-auth-strings");
        // bundle.use(docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-registration-view");
    }
    setTheme(std::make_shared<Theme>());

    authDialog_ = wApp->root()->addNew<Wt::WDialog>("");
    authDialog_->keyWentDown().connect([=](Wt::WKeyEvent e) {
        wApp->globalKeyWentDown().emit(e); // Emit the global key event
    });
    authDialog_->setTitleBarEnabled(false);
    authDialog_->setClosable(false);
    authDialog_->setModal(true);
    authDialog_->escapePressed().connect([this]() {
        if (authDialog_ != nullptr) {
            authDialog_->hide();
        }
    });
    authDialog_->setMinimumSize(Wt::WLength(100, Wt::LengthUnit::ViewportWidth), Wt::WLength(100, Wt::LengthUnit::ViewportHeight));
    authDialog_->setMaximumSize(Wt::WLength(100, Wt::LengthUnit::ViewportWidth), Wt::WLength(100, Wt::LengthUnit::ViewportHeight));
    authDialog_->setStyleClass("absolute top-0 left-0 right-0 bottom-0 w-screen h-screen !bg-white dark:!bg-gray-900");
    // authDialog_->setMargin(Wt::WLength("-21em"), Wt::Side::Left); // .Wt-form width
    // authDialog_->setMargin(Wt::WLength("-200px"), Wt::Side::Top); // ???
    // authDialog_->contents()->setStyleClass("min-h-screen min-w-screen m-1 p-1 flex items-center justify-center");
    authWidget_ = authDialog_->contents()->addWidget(std::make_unique<AuthWidget>(session_));
    // authWidget_->addStyleClass("w-full max-w-md bg-white text-gray-900 border border-gray-200 rounded-xl shadow-lg p-6 space-y-4 dark:bg-gray-800 dark:text-gray-100 dark:border-gray-700 transition-colors");
    appRoot_ = root()->addNew<Wt::WContainerWidget>();
    stylus_ = root()->addChild(std::make_unique<Stylus::Stylus>(session_));
    opencode_ = root()->addChild(std::make_unique<Opencode::Opencode>(session_));
    
    session_.login().changed().connect(this, &App::authEvent);
    authWidget_->processEnvironment();
    if (!session_.login().loggedIn()) {
        session_.login().changed().emit();
    }

    #ifdef DEBUG
    Wt::log("debug") << "App::App() - Application instantiated";
    #endif

    wApp->globalKeyWentDown().connect([=](Wt::WKeyEvent e)
    {
        // Handle global key events here
        if(e.modifiers().test(Wt::KeyboardModifier::Shift)){
            if(e.key() == Wt::Key::Q){
                if(authDialog_->isHidden()){
                    authDialog_->show();
                }else {
                    authDialog_->hide();
                }
            }
        }

    });
}

void App::authEvent() {
    if (session_.login().loggedIn()) {
        const Wt::Auth::User& u = session_.login().user();
        #ifdef DEBUG
        log("debug") << "User " << u.id() << " (" << u.identity(Wt::Auth::Identity::LoginName) << ")" << " logged in.";
        #endif
        // if (authDialog_->isVisible()) {
        //     authDialog_->hide();
        // }
    } else {
        #ifdef DEBUG
        log("debug") << "User logged out.";
        #endif
        // if (!authDialog_->isVisible()) {
        //     authDialog_->show();
        // }
    }
    createApp();
}

void App::createApp()
{
    if (appRoot_ != nullptr && !appRoot_->children().empty()) {
        appRoot_->clear();
    }

    if (session_.login().loggedIn()) {
        Wt::Dbo::Transaction transaction(session_);

        // Query for STYLUS permission, taking first result if multiple exist
        auto stylusPermission = session_.find<Permission>()
            .where("name = ?")
            .bind("STYLUS")
            .resultValue();
        if (stylusPermission && session_.user()->hasPermission(stylusPermission)){
            #ifdef DEBUG
            Wt::log("debug") << "Permission STYLUS found, Stylus will be available.";
            #endif
            // stylus_ = appRoot_->addChild(std::make_unique<Stylus::Stylus>(session_));
        } else {
            #ifdef DEBUG
            Wt::log("debug") << "Permission STYLUS not found, Stylus will not be available.";
            #endif
        }
        transaction.commit();
    }
    auto dark_mode_toggle = appRoot_->addNew<DarkModeToggle>(session_);
    opencode_ = appRoot_->addNew<Opencode::Opencode>(session_);


}

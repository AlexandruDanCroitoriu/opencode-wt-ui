#include "004_Theme/DarkModeToggle.h"

#include <Wt/Dbo/Transaction.h>
#include <Wt/WApplication.h>
#include <Wt/WLogger.h>
#include <Wt/WString.h>

DarkModeToggle::DarkModeToggle(Session& session)
    : Wt::WCheckBox("")
    , session_(session)
{
    const std::string iconStyles = "[&>input]:hidden [&>input]:[&~span]:before:content-['☀'] [&>input]:checked:[&~span]:before:content-['🌙']";
    setStyleClass(Wt::WString::tr("btn.default") + " " + Wt::WString::tr("btn.primary-outline"));
    addStyleClass(iconStyles + " flex items-center justify-center z-20 p-2 text-md font-bold z-20 !rounded-full w-10 bg-primary/20");
    setChecked(wApp->htmlClass().find("dark") != std::string::npos);

    changed().connect(this, [this]() {
        if (session_.login().loggedIn()) {
            Wt::Dbo::Transaction transaction(session_);
            auto user = session_.user(session_.login().user());
            if (user) {
                user.modify()->uiDarkMode_ = isChecked();
            }
            transaction.commit();
            Wt::log("info") << "Dark mode preference persisted for the current user.";
        }
        wApp->setHtmlClass(isChecked() ? "dark" : "");
    });

    keyWentDown().connect([this](const Wt::WKeyEvent& event) {
        wApp->globalKeyWentDown().emit(event);
    });
}
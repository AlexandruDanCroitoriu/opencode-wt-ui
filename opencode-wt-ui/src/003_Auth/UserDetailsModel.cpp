#include "003_Auth/UserDetailsModel.h"
#include "002_Dbo/Tables/User.h"
#include "002_Dbo/Session.h"


#include <Wt/Auth/Identity.h>
#include <Wt/WApplication.h>
#include <Wt/WTheme.h>

// const Wt::WFormModel::Field
// UserDetailsModel::FavouritePetField = "favourite-pet";

UserDetailsModel::UserDetailsModel(Session& session)
  : WFormModel(),
    session_(session)
{
  // addField(FavouritePetField, Wt::WString::tr("Auth:favourite-pet-info"));
}

void UserDetailsModel::save(const Wt::Auth::User& authUser)
{
  Wt::Dbo::ptr<User> user = session_.user(authUser);
  // user.modify()->favouritePet_ = valueText(FavouritePetField).toUTF8();
  user.modify()->name_ = authUser.identity(Wt::Auth::Identity::LoginName).toUTF8();
  user.modify()->uiDarkMode_ = wApp->htmlClass().find("dark") != std::string::npos;
  std::string themeName = "arctic";
  if (auto theme = wApp->theme()) {
    themeName = theme->name();
  }
}

#pragma once

#include <memory>
#include <string>
#include <vector>

#include <Wt/Auth/Dbo/UserDatabase.h>
#include <Wt/Auth/Login.h>
#include <Wt/Auth/OAuthService.h>

#include <Wt/Dbo/Session.h>
#include <Wt/Dbo/ptr.h>

#include "002_Dbo/Tables/User.h"

namespace dbo = Wt::Dbo;

using UserDatabase = Wt::Auth::Dbo::UserDatabase<AuthInfo>;

class Session : public dbo::Session
{
public:
  // void configureAuth();

  explicit Session(const std::string& sqliteDb);

  dbo::ptr<User> user() const;
  dbo::ptr<User> user(const Wt::Auth::User& authUser);

  Wt::Auth::AbstractUserDatabase& users();
  Wt::Auth::Login& login() { return login_; }

  static const Wt::Auth::AuthService& auth();
  static const Wt::Auth::PasswordService& passwordAuth();
  static std::vector<const Wt::Auth::OAuthService *> oAuth();
private:
  std::unique_ptr<UserDatabase> users_;
  Wt::Auth::Login login_;
  bool created_ = false;

  void createInitialData();
};

#pragma once

#include <string>

#include <Wt/Dbo/Types.h>
#include <Wt/WGlobal.h>

#include "002_Dbo/Tables/Permission.h"

class User;
using AuthInfo = Wt::Auth::Dbo::AuthInfo<User>;

class User : public Wt::Dbo::Dbo<User>
{
public:
  User() = default;
  explicit User(const std::string& name);

  std::string name_;
  bool uiDarkMode_;
  Wt::Dbo::weak_ptr<AuthInfo> authInfo_;
  Wt::Dbo::collection< Wt::Dbo::ptr<Permission> > permissions_;

  bool hasPermission(const Wt::Dbo::ptr<Permission>& permission) const;

  template<class Action>
  void persist(Action& a)
  {
    Wt::Dbo::field(a, name_, "name");
    Wt::Dbo::field(a, uiDarkMode_, "ui_dark_mode");
    Wt::Dbo::hasOne(a, authInfo_, "user");
    Wt::Dbo::hasMany(a, permissions_, Wt::Dbo::ManyToMany, "users_permissions");
  }
private:
};



DBO_EXTERN_TEMPLATES(User)
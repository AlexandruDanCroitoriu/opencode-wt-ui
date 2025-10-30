#pragma once

#include <string>

#include <Wt/Dbo/Types.h>
#include <Wt/WGlobal.h>

class User;

class Permission {
public:
  Permission() = default;
  explicit Permission(const std::string& name);

  std::string name_;
  Wt::Dbo::collection< Wt::Dbo::ptr<User> > users_;

  template<class Action>
  void persist(Action& a)
  {
    Wt::Dbo::field(a, name_, "name");
    Wt::Dbo::hasMany(a, users_, Wt::Dbo::ManyToMany, "users_permissions");
  }
private:
};


DBO_EXTERN_TEMPLATES(Permission)
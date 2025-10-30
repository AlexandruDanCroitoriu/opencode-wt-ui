#include "002_Dbo/Tables/User.h"

#include <Wt/Dbo/Impl.h>
#include <Wt/Auth/Dbo/AuthInfo.h>

DBO_INSTANTIATE_TEMPLATES(User)

User::User(const std::string& name)
  : name_(name), uiDarkMode_(false)
{
}

bool User::hasPermission(const Wt::Dbo::ptr<Permission>& permission) const
{
  for (const auto& perm : permissions_) {
    if (perm->name_.compare(permission->name_) == 0) {
      return true;
    }
  }
  return false;
}

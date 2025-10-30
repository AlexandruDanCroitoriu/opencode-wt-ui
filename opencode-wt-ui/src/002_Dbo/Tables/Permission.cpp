#include "002_Dbo/Tables/Permission.h"
#include "002_Dbo/Tables/User.h"
#include <Wt/Dbo/Impl.h>
#include <Wt/Auth/Dbo/AuthInfo.h>

DBO_INSTANTIATE_TEMPLATES(Permission)

Permission::Permission(const std::string& name)
  : name_(name)
{
}

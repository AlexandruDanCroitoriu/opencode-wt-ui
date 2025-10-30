#pragma once
#include <Wt/WCheckBox.h>
#include "002_Dbo/Session.h"

class DarkModeToggle : public Wt::WCheckBox
{
public:
    DarkModeToggle(Session& session);
private:
    Session& session_;
};
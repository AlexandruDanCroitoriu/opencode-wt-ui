#pragma once
#include <Wt/WFormModel.h>


class Session;

class UserDetailsModel : public Wt::WFormModel
{
public:
  static const Field UI_DARK_MODE_FIELD;
  static const Field UI_PENGUIN_THEME_NAME_FIELD;

  UserDetailsModel(Session& session);

  void save(const Wt::Auth::User& user);

private:
  Session& session_;
};

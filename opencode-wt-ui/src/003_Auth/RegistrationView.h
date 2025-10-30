#pragma once

#include <memory>

#include <Wt/Auth/RegistrationWidget.h>

class Session;
class UserDetailsModel;

class RegistrationView : public Wt::Auth::RegistrationWidget
{
public:
  RegistrationView(Session& session, Wt::Auth::AuthWidget *authWidget = nullptr);

  /* specialize to create user details fields */
  std::unique_ptr<Wt::WWidget> createFormWidget(Wt::WFormModel::Field field) override;

protected:
  /* specialize to also validate the user details */
  bool validate() override;

  /* specialize to register user details */
  void registerUserDetails(Wt::Auth::User& user) override;

private:
  Session& session_;

  std::unique_ptr<UserDetailsModel> detailsModel_;
};

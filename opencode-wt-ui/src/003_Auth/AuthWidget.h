#pragma once
#include <memory>
#include <string>

#include <Wt/Auth/AuthWidget.h>

class Session;

class AuthWidget : public Wt::Auth::AuthWidget
{
public:
  explicit AuthWidget(Session& session);

  /* We will use a custom registration view */
  std::unique_ptr<Wt::WWidget> createRegistrationView(const Wt::Auth::Identity& id) override;
  void createLoginView() override;

protected:
  Wt::WDialog *showDialog(const Wt::WString& title, std::unique_ptr<Wt::WWidget> contents) override;

private:
  Session& session_;
  void createInitialData();
  std::string loginTemplateId_ = "Wt.Auth.template.login-v1"; // default template id
  // std::string loginTemplateId_ = "Wt.Auth.template.login"; // default template id
  std::unique_ptr<Wt::WDialog> dialog_;
};

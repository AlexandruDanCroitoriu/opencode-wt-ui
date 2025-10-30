#include "003_Auth/AuthWidget.h"
#include "003_Auth/RegistrationView.h"
#include "002_Dbo/Session.h"
#include "003_Auth/UserDetailsModel.h"
#include "002_Dbo/Tables/User.h"
#include "002_Dbo/Tables/Permission.h"

#include <Wt/Auth/PasswordService.h>
#include <Wt/WApplication.h>
#include <Wt/WButtonGroup.h>
#include <Wt/WDialog.h>
#include <Wt/WRadioButton.h>

AuthWidget::AuthWidget(Session& session)
  : Wt::Auth::AuthWidget(Session::auth(), session.users(), session.login()),
    session_(session)
{ 
  // setInternalBasePath("/user");
  wApp->messageResourceBundle().use(wApp->docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-auth");
  wApp->messageResourceBundle().use(wApp->docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-auth-login");
  wApp->messageResourceBundle().use(wApp->docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-auth-strings");
  wApp->messageResourceBundle().use(wApp->docRoot() + "/static/0_stylus/xml/001_Auth/ovrwt-registration-view");

  model()->addPasswordAuth(&Session::passwordAuth());
  model()->addOAuth(Session::oAuth());
  setRegistrationEnabled(true);

  keyWentDown().connect([=](Wt::WKeyEvent e)
  { 
      wApp->globalKeyWentDown().emit(e); // Emit the global key event
  });

  // processEnvironment();
}

std::unique_ptr<Wt::WWidget> AuthWidget::createRegistrationView(const Wt::Auth::Identity& id)
{
  auto registrationView = std::make_unique<RegistrationView>(session_, this);
  std::unique_ptr<Wt::Auth::RegistrationModel> registrationModel = createRegistrationModel();

  if (id.isValid())
    registrationModel->registerIdentified(id);

  registrationView->setModel(std::move(registrationModel));
  return registrationView;
}

void AuthWidget::createLoginView()
{
  setTemplateText(tr(loginTemplateId_)); // default wt template
  // setTemplateText(tr("Wt.Auth.template.login-v0")); // v0 nothing but the data and some basic structure
  // setTemplateText(tr("Wt.Auth.template.login-v1")); // custom implementation v1


  // auto container = bindWidget("template-changer-widget", std::make_unique<Wt::WContainerWidget>());
  // container->setStyleClass("flex items-center justify-start space-x-2");
  // auto group = std::make_shared<Wt::WButtonGroup>();

  // auto default_tmp_btn = container->addNew<Wt::WRadioButton>("default");
  // group->addButton(default_tmp_btn);

  // auto v0_tmp_btn = container->addNew<Wt::WRadioButton>("v0");
  // group->addButton(v0_tmp_btn);

  // auto v1_tmp_btn = container->addNew<Wt::WRadioButton>("v1");
  // group->addButton(v1_tmp_btn);

  // if(loginTemplateId_.compare("Wt.Auth.template.login") == 0)
  // {
  //   group->setSelectedButtonIndex(0); // Select the first button by default.
  // }else if(loginTemplateId_.compare("Wt.Auth.template.login-v0") == 0)
  // {
  //   group->setSelectedButtonIndex(1); // Select the second button by default.
  // }else if(loginTemplateId_.compare("Wt.Auth.template.login-v1") == 0)
  // {
  //   group->setSelectedButtonIndex(2); // Select the third button by default.
  // }

  // group->checkedChanged().connect(this, [=](Wt::WRadioButton *button) {
  //   if(button == default_tmp_btn) {
  //     loginTemplateId_ = "Wt.Auth.template.login";
  //   } else if(button == v0_tmp_btn) {
  //     loginTemplateId_ = "Wt.Auth.template.login-v0";
  //   } else if(button == v1_tmp_btn) {
  //     loginTemplateId_ = "Wt.Auth.template.login-v1";
  //   }
  //   // setTemplateText(tr(loginTemplateId_));
  //   model()->reset();
  //   createLoginView(); // Recreate the login view with the new template
  // });

  createPasswordLoginView();
  createOAuthLoginView();
#ifdef WT_HAS_SAML
  createSamlLoginView();
#endif // WT_HAS_SAML_
}

Wt::WDialog *AuthWidget::showDialog(const Wt::WString& title, std::unique_ptr<Wt::WWidget> contents) 
{
  if (contents) {
    dialog_ = std::make_unique<Wt::WDialog>(title);
    dialog_->contents()->addWidget(std::move(contents));
    dialog_->setMinimumSize(Wt::WLength(100, Wt::LengthUnit::ViewportWidth), Wt::WLength(100, Wt::LengthUnit::ViewportHeight));
    dialog_->setMaximumSize(Wt::WLength(100, Wt::LengthUnit::ViewportWidth), Wt::WLength(100, Wt::LengthUnit::ViewportHeight));
    dialog_->setStyleClass("absolute top-0 left-0 right-0 bottom-0 w-screen h-screen");
    dialog_->setTitleBarEnabled(false);
    dialog_->escapePressed().connect([this]() { dialog_.reset(); });
    dialog_->contents()->setStyleClass("min-h-screen min-w-screen m-1 p-1 flex items-center justify-center bg-white dark:bg-gray-900 text-gray-900 dark:text-white");
    dialog_->contents()->childrenChanged().connect(this, [this]() { dialog_.reset(); });

    dialog_->footer()->hide();

  if (!Wt::WApplication::instance()->environment().ajax()) {
      /*
       * try to center it better, we need to set the half width and
       * height as negative margins.
       */
      dialog_->setMargin(Wt::WLength("-21em"), Wt::Side::Left); // .Wt-form width
      dialog_->setMargin(Wt::WLength("-200px"), Wt::Side::Top); // ???
    }

    dialog_->show();
  }

  return dialog_.get();
}

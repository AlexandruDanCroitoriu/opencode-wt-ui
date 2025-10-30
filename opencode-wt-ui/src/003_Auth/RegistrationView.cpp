#include "003_Auth/RegistrationView.h"
#include "003_Auth/UserDetailsModel.h"


RegistrationView::RegistrationView(Session& session, Wt::Auth::AuthWidget *authWidget)
  : Wt::Auth::RegistrationWidget(authWidget),
    session_(session)
{
  setTemplateText(tr("template.registration"));
  detailsModel_ = std::make_unique<UserDetailsModel>(session_);

  updateView(detailsModel_.get());
}

std::unique_ptr<Wt::WWidget> RegistrationView::createFormWidget(Wt::WFormModel::Field field)
{
  // if (field == UserDetailsModel::FavouritePetField)
  //   return std::make_unique<Wt::WLineEdit>();
  // else
    return Wt::Auth::RegistrationWidget::createFormWidget(field);
}

bool RegistrationView::validate()
{
  bool result = Wt::Auth::RegistrationWidget::validate();

  updateModel(detailsModel_.get());
  if (!detailsModel_->validate())
    result = false;
  updateView(detailsModel_.get());

  return result;
}

void RegistrationView::registerUserDetails(Wt::Auth::User& user)
{
  detailsModel_->save(user);

}

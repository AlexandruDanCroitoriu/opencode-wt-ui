#include "006_Stylus/Stylus.h"
#include <Wt/WLength.h>
#include <Wt/WApplication.h>
#include <Wt/WTemplate.h>
#include <Wt/WAnchor.h>

namespace Stylus {

Stylus::Stylus(Session& session)
    : Wt::WDialog(),
      session_(session)
{
    initializeDialog();
    setupKeyboardShortcuts();
    setupContent();
}

void Stylus::initializeDialog()
{
    setOffsets(0, Wt::Side::Top | Wt::Side::Bottom | Wt::Side::Left | Wt::Side::Right);
    titleBar()->children()[0]->removeFromParent();
    setStyleClass("!border-0 overflow-auto bg-surface-alt");
    titleBar()->hide();
    titleBar()->setStyleClass("p-0 flex items-center overflow-x-visible h-[40px]");
    contents()->setStyleClass("h-[100vh] overflow-y-auto overflow-x-visible flex");
    setModal(false);
    setResizable(false);
    setMovable(false);

    setMinimumSize(Wt::WLength(100, Wt::LengthUnit::ViewportWidth), 
                   Wt::WLength(100, Wt::LengthUnit::ViewportHeight));
    setLayoutSizeAware(true);

    wApp->messageResourceBundle().use(wApp->docRoot() + "/static/0_stylus/xml/002_Stylus/stylus_svg");
}

void Stylus::setupKeyboardShortcuts()
{
    wApp->doJavaScript(WT_CLASS R"(
        .$(')" + id() + R"(').oncontextmenu = function() {
            event.cancelBubble = true;
            event.returnValue = false;
            return false;
        };
        document.addEventListener('keydown', function(event) {
            if (event.altKey && (event.key === 'ArrowLeft' || event.key === 'ArrowRight')) {
                event.preventDefault();
                // Your custom logic here if needed
            } else if ((event.ctrlKey || event.metaKey) && event.key === 's') {
                event.preventDefault();
            }
        });
    )");

    wApp->globalKeyWentDown().connect([=](Wt::WKeyEvent e) { keyWentDown(e); });
}

void Stylus::setupContent()
{

    navbar_wrapper_ = contents()->addNew<Wt::WContainerWidget>();
    content_stack_ = contents()->addNew<Wt::WStackedWidget>();
    menu_ = navbar_wrapper_->addNew<Wt::WMenu>(content_stack_);
    
    menu_->setStyleClass("flex flex-col items-center h-full");
    navbar_wrapper_->setStyleClass("flex flex-col items-center h-full border-r border-solid");

    std::unique_ptr<Wt::WContainerWidget> xml_files_wrapper = std::make_unique<Wt::WContainerWidget>();
    std::unique_ptr<Wt::WContainerWidget> css_files_wrapper = std::make_unique<Wt::WContainerWidget>();
    std::unique_ptr<Wt::WContainerWidget> js_files_wrapper = std::make_unique<Wt::WContainerWidget>();
    std::unique_ptr<Wt::WContainerWidget> tailwind_files_wrapper = std::make_unique<Wt::WContainerWidget>();
    std::unique_ptr<Wt::WContainerWidget> images_files_wrapper = std::make_unique<Wt::WContainerWidget>();
    std::unique_ptr<Wt::WContainerWidget> settings_wrapper = std::make_unique<Wt::WContainerWidget>();

    xml_files_wrapper_ = xml_files_wrapper.get();
    css_files_wrapper_ = css_files_wrapper.get();
    js_files_wrapper_ = js_files_wrapper.get();
    tailwind_files_wrapper_ = tailwind_files_wrapper.get();
    images_files_wrapper_ = images_files_wrapper.get();
    settings_wrapper_ = settings_wrapper.get();

    xml_menu_item_ = menu_->addItem("", std::move(xml_files_wrapper));
    css_menu_item_ = menu_->addItem("", std::move(css_files_wrapper));
    js_menu_item_ = menu_->addItem("", std::move(js_files_wrapper));
    tailwind_menu_item_ = menu_->addItem("", std::move(tailwind_files_wrapper));
    images_menu_item_ = menu_->addItem("", std::move(images_files_wrapper));
    settings_menu_item_ = menu_->addItem("", std::move(settings_wrapper));

    auto xml_icon = xml_menu_item_->anchor()->insertNew<Wt::WTemplate>(0, Wt::WString::tr("stylus-svg-xml-logo"));
    auto css_icon = css_menu_item_->anchor()->insertNew<Wt::WTemplate>(0, Wt::WString::tr("stylus-svg-css-logo"));
    auto js_icon = js_menu_item_->anchor()->insertNew<Wt::WTemplate>(0, Wt::WString::tr("stylus-svg-javascript-logo"));
    auto tailwind_icon = tailwind_menu_item_->anchor()->insertNew<Wt::WTemplate>(0, Wt::WString::tr("stylus-svg-tailwind-logo"));
    auto images_icon = images_menu_item_->anchor()->insertNew<Wt::WTemplate>(0, Wt::WString::tr("stylus-svg-images-logo"));
    auto settings_icon = settings_menu_item_->anchor()->insertNew<Wt::WTemplate>(0, Wt::WString::tr("stylus-svg-settings-logo"));

    std::string nav_btns_styles = "w-[35px] m-[3px] !p-1 cursor-pointer rounded-md flex items-center justify-center";

    xml_menu_item_->anchor()->setStyleClass(nav_btns_styles);
    css_menu_item_->anchor()->setStyleClass(nav_btns_styles);
    js_menu_item_->anchor()->setStyleClass(nav_btns_styles);
    tailwind_menu_item_->anchor()->setStyleClass(nav_btns_styles);
    images_menu_item_->anchor()->setStyleClass(nav_btns_styles);
    settings_menu_item_->anchor()->setStyleClass(nav_btns_styles);
}

void Stylus::keyWentDown(Wt::WKeyEvent e)
{
    if (e.modifiers().test(Wt::KeyboardModifier::Alt)) {
        if (e.key() == Wt::Key::Q) {
            if (isHidden()) {
                show();
            } else {
                hide();
            }
        } else if (e.key() == Wt::Key::Key_1) {
            menu_->select(0);
        } else if (e.key() == Wt::Key::Key_2) {
            menu_->select(1);
        } else if (e.key() == Wt::Key::Key_3) {
            menu_->select(2);
        } else if (e.key() == Wt::Key::Key_4) {
            menu_->select(3);
        } else if (e.key() == Wt::Key::Key_5) {
            menu_->select(4);
        } else if (e.key() == Wt::Key::Key_6) {
            menu_->select(5);
        }
        
        if (e.modifiers().test(Wt::KeyboardModifier::Shift)) {
            // Future keyboard shortcuts with Alt+Shift combination
        }
    }
}

}
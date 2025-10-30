#include "007_Opencode/Opencode.h"
#include <Wt/WLength.h>
#include <Wt/WApplication.h>
#include <Wt/WTemplate.h>
#include <Wt/WAnchor.h>
#include <Wt/WHBoxLayout.h>
#include <Wt/WLogger.h>

namespace Opencode
{

    Opencode::Opencode(Session &session)
        : Wt::WDialog(),
          session_(session)
    {
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::Opencode() - Constructor called";
        #endif
        
        initializeDialog();
        setupKeyboardShortcuts();
        setupContent();
        
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::Opencode() - Constructor completed";
        #endif
    }

    void Opencode::initializeDialog()
    {
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::initializeDialog() - Initializing dialog";
        #endif
        
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
        
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::initializeDialog() - Dialog initialization completed";
        #endif
    }

    void Opencode::setupKeyboardShortcuts()
    {
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::setupKeyboardShortcuts() - Setting up keyboard shortcuts";
        #endif
        
        wApp->doJavaScript(WT_CLASS R"(
        .$(')" + id() + R"(').oncontextmenu = function() {
            event.cancelBubble = true;
            event.returnValue = false;
            return false;
        };
        document.addEventListener('keydown', function(event) {
            if (event.ctrlKey && (event.key === 'ArrowLeft' || event.key === 'ArrowRight')) {
                event.preventDefault();
                // Your custom logic here if needed
            } else if ((event.ctrlKey || event.metaKey) && event.key === 's') {
                event.preventDefault();
            }
        });
    )");

        wApp->globalKeyWentDown().connect([=](Wt::WKeyEvent e)
                                          { keyWentDown(e); });
        
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::setupKeyboardShortcuts() - Keyboard shortcuts setup completed";
        #endif
    }

    void Opencode::setupContent()
    {
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::setupContent() - Setting up content";
        #endif
        
        sessions_widget_ = contents()->addWidget(std::make_unique<Sessions>(session_));
        
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::setupContent() - Sessions widget created: " << sessions_widget_;
        Wt::log("debug") << "Opencode::setupContent() - Content setup completed";
        #endif
    }

    void Opencode::keyWentDown(Wt::WKeyEvent e)
    {
        #ifdef DEBUG
        Wt::log("debug") << "Opencode::keyWentDown() - Key event received. Key: " << static_cast<int>(e.key()) << ", Modifiers: " << e.modifiers().value();
        #endif
        
        if (e.modifiers().test(Wt::KeyboardModifier::Control))
        {
            #ifdef DEBUG
            Wt::log("debug") << "Opencode::keyWentDown() - Control key modifier detected";
            #endif
            
            if (e.key() == Wt::Key::Q)
            {
                #ifdef DEBUG
                Wt::log("debug") << "Opencode::keyWentDown() - Ctrl+Q detected. Current state: " << (isHidden() ? "hidden" : "visible");
                #endif
                
                if (isHidden())
                {
                    #ifdef DEBUG
                    Wt::log("debug") << "Opencode::keyWentDown() - Showing Opencode dialog";
                    #endif
                    show();
                }
                else
                {
                    #ifdef DEBUG
                    Wt::log("debug") << "Opencode::keyWentDown() - Hiding Opencode dialog";
                    #endif
                    hide();
                }
            }

            if (e.modifiers().test(Wt::KeyboardModifier::Shift))
            {
                #ifdef DEBUG
                Wt::log("debug") << "Opencode::keyWentDown() - Ctrl+Shift combination detected";
                #endif
                // Future keyboard shortcuts with Ctrl+Shift combination
            }
        }
    }

}
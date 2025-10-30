#include "005_Components/MonacoEditor.h"
#include <Wt/WApplication.h>
#include <Wt/WRandom.h>
#include <Wt/WLogger.h>
#include <fstream>
#include <iostream>

MonacoEditor::MonacoEditor(std::string language)
    : js_signal_text_changed_(this, "editorTextChanged"),
      current_text_(""),
      unsaved_text_("")
{
    setLayoutSizeAware(true);
    setMinimumSize(Wt::WLength(1, Wt::LengthUnit::Pixel), Wt::WLength(1, Wt::LengthUnit::Pixel));
    wApp->require(wApp->docRoot() + "/static/stylus/monaco-edditor.js", "monaco-editor");

    // setMaximumSize(Wt::WLength::Auto, Wt::WLength(100, Wt::LengthUnit::ViewportHeight));
    // setStyleClass("h-fill");

    js_signal_text_changed_.connect(this, &MonacoEditor::editorTextChanged);
    doJavaScript(R"(require.config({ paths: { 'vs': 'https://unpkg.com/monaco-editor@0.34.1/min/vs' } });)");
    editor_js_var_name_ = language + Wt::WRandom::generateId() + "_editor";
    
    resize(Wt::WLength::Auto, Wt::WLength::Auto);
    // Check for dark theme globally
    bool isDarkMode = wApp->htmlClass().find("dark") != std::string::npos;
    
    std::string initializer =
        R"(
        require(['vs/editor/editor.main'], function () {
            window.)" + editor_js_var_name_ + R"(_current_text = `)" + current_text_ + R"(`;
            window.)" + editor_js_var_name_ + R"( = monaco.editor.create(document.getElementById(')" + id() + R"('), {
                language: ')" + language + R"(',
                theme: )" + (isDarkMode ? "'vs-dark'" : "'vs-light'") + R"(,
                wordWrap: 'on',
                lineNumbers: 'on',
                tabSize: 4,
                insertSpaces: false,
                detectIndentation: false,
                trimAutoWhitespace: false,
                lineEnding: '\n',
                minimap: { enabled: false },
                automaticLayout: true,
                scrollbar: {
                    vertical: 'auto',    // Show vertical scrollbar only if needed
                    horizontal: 'auto',  // Show horizontal scrollbar only if needed
                    handleMouseWheel: true
                },
                scrollBeyondLastLine: false
            });

            window.)" + editor_js_var_name_ + R"(.onDidChangeModelContent(function (event) {
                if (window.)" + editor_js_var_name_ + R"(_current_text !== window.)" + editor_js_var_name_ + R"(.getValue()) {
                    window.)" + editor_js_var_name_ + R"(_current_text = window.)" + editor_js_var_name_ + R"(.getValue();
                    Wt.emit(')" + id() + R"(', 'editorTextChanged', window.)" + editor_js_var_name_ + R"(.getValue());
                }
            });
            
            window.)" + editor_js_var_name_ + R"(.getDomNode().addEventListener('keydown', function(e) {
                if ((e.ctrlKey || e.metaKey)) {
                    if (e.key === 's') {
                        e.preventDefault();
                    }
                }
                if (e.altKey && e.key === 'x') {
                    const currentMinimap = window.)" + editor_js_var_name_ + R"(.getOptions().get(monaco.editor.EditorOption.minimap).enabled;
                    window.)" + editor_js_var_name_ + R"(.updateOptions({ minimap: { enabled: !currentMinimap } });
                }
                if (e.altKey && e.key === 'z') {
                    e.preventDefault();
                    const currentWordWrap = window.)" + editor_js_var_name_ + R"(.getOptions().get(monaco.editor.EditorOption.wordWrap);
                    const newWordWrap = currentWordWrap === 'off' ? 'on' : 'off';
                    window.)" + editor_js_var_name_ + R"(.updateOptions({ wordWrap: newWordWrap });
                }
            });
        });
    )";

    setJavaScriptMember("something", initializer);

    keyWentDown().connect([=](Wt::WKeyEvent e){ 
        Wt::WApplication::instance()->globalKeyWentDown().emit(e); // Emit the global key event
        if (e.modifiers().test(Wt::KeyboardModifier::Control))
        {
            if (e.key() == Wt::Key::S)
            {
                if(unsavedChanges()){
                    save_file_signal_.emit(unsaved_text_);
                }
            }
        } 
    });
}

void MonacoEditor::layoutSizeChanged(int width, int height)
{
    resetLayout();
    if(width > 1){
        width_changed_.emit(Wt::WString(std::to_string(width)));
    }
}


void MonacoEditor::editorTextChanged(std::string text)
{
    unsaved_text_ = text;
    available_save_.emit();
}

void MonacoEditor::textSaved()
{
    current_text_ = unsaved_text_;
    available_save_.emit();
}

void MonacoEditor::setReadOnly(bool read_only) { 
    doJavaScript("setTimeout(function() { if(window." + editor_js_var_name_ + ") window." + editor_js_var_name_ + ".updateOptions({ readOnly: " + std::to_string(read_only) + " }); }, 200);");
}

bool MonacoEditor::unsavedChanges()
{
    if (current_text_.compare(unsaved_text_) == 0)
    {
        return false;
    }
    return true;
}

void MonacoEditor::setEditorText(std::string resource_path)
{
    resetLayout();
    auto resource_path_url = resource_path + "?v=" + Wt::WRandom::generateId();
    doJavaScript(
        R"(
            setTimeout(function() {
                if(!window.)" + editor_js_var_name_ + R"() {
                    setTimeout(function() {
                        console.log("Setting editor text to: )" + resource_path_url + R"(");
                        if (window.)" + editor_js_var_name_ + R"() {
                            fetch(')" + resource_path_url + R"(')
                            .then(response => response.text())
                            .then(css => {
                                window.)" + editor_js_var_name_ + R"(_current_text = css;
                                window.)" + editor_js_var_name_ + R"(.setValue(css);
                            });
                        } else {
                            console.error("Editor instance is stil l not initialized.");
                        }
                    }, 2000);
                    return;
                }
                console.log("Setting editor text to: )" + resource_path_url + R"(");
                fetch(')" + resource_path_url + R"(')
                    .then(response => response.text())
                    .then(css => {
                        window.)" + editor_js_var_name_ + R"(_current_text = css;
                        window.)" + editor_js_var_name_ + R"(.setValue(css);
                    });
            }, 10); // Delay to ensure the editor is ready
        )");
    current_text_ = getFileText(resource_path);
    unsaved_text_ = current_text_;
    selected_file_path_ = resource_path;
    resetLayout();
}

void MonacoEditor::resetLayout()
{
    doJavaScript("setTimeout(function() { window." + editor_js_var_name_ + ".layout() }, 200);");
}

void MonacoEditor::setDarkTheme(bool dark)
{
    wApp->doJavaScript(R"(
        (function() {
            var interval = setInterval(function() {
                if (window.monaco) {
                    clearInterval(interval);
                    monaco.editor.setTheme(')" + std::string(dark ? "vs-dark" : "vs-light") + R"(');
                }
            }, 100);
        })();
    )");
}


std::string MonacoEditor::getFileText(std::string file_path)
{
    std::ifstream file(file_path);
    if (!file.is_open())
    {
        Wt::log("error") << "Failed to read file: " << file_path;
        return "!Failed to read file!";
    }

    std::string file_content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    file.close();
    Wt::WString file_content_wt = Wt::WString::fromUTF8(file_content);
    return file_content;
}

void MonacoEditor::saveFile()
{
    // Save the unsaved text to the file system
    if (unsaved_text_.empty())
    {
        Wt::log("info") << "No unsaved text to save.";
        return;
    }
    std::ofstream file(selected_file_path_);
    if (!file.is_open())
    {
        Wt::log("error") << "Failed to open file for writing: " << selected_file_path_;
        return;
    }
    file << unsaved_text_;
    file.close();
    Wt::log("info") << "File path: " << selected_file_path_ << " saved successfully.";
}

void MonacoEditor::toggleLineWrap()
{
    doJavaScript(R"(
        setTimeout(function() {
            if (window.)" + editor_js_var_name_ + R"() {
                const currentWordWrap = window.)" + editor_js_var_name_ + R"(.getOptions().get(monaco.editor.EditorOption.wordWrap);
                const newWordWrap = currentWordWrap === 'off' ? 'on' : 'off';
                window.)" + editor_js_var_name_ + R"(.updateOptions({ wordWrap: newWordWrap });
            }
        }, 20);
    )");
}
void MonacoEditor::toggleMinimap()
{
    doJavaScript(R"(
        setTimeout(function() {
            if (window.)" + editor_js_var_name_ + R"() {
                const currentMinimap = window.)" + editor_js_var_name_ + R"(.getOptions().get(monaco.editor.EditorOption.minimap).enabled;
                window.)" + editor_js_var_name_ + R"(.updateOptions({ minimap: { enabled: !currentMinimap } });
            }
        }, 20);
    )");
}

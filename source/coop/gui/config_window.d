module coop.gui.config_window;

import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;
import dlangui.dml.parser;
import dlangui.platforms.common.platform;
import dlangui.widgets.editors;
import dlangui.widgets.widget;

import coop.config;

auto showConfigWindow(Window parent, ref Config config)
{
    /// DlangUI 0.7.41 ではモーダルダイアログは未実装
    auto configWindow = Platform.instance.createWindow("設定"d, parent, WindowFlag.Modal);

    version(Windows) {
        enum directory = "フォルダ";
    } else {
        enum directory = "ディレクトリ";
    }

    auto wLayout = parseML(q{
            TableLayout {
                colCount: 4
                padding: 10
                TextWidget {
                    id: DLLCaption
                }
                EditLine {
                    id: migemoDLLPath
                }
                Button {
                    id: migemoDLLSelecter
                    text: "変更"
                }
                TextWidget {
                    id: DLLalert
                }

                TextWidget {
                    id: DictCaption
                }
                EditLine {
                    id: migemoDictPath
                }
                TextWidget {
                    // FileDialog はディレクトリを指定できない！
                    id: migemoDictSelecter
                    text: ""
                }
                TextWidget {
                    id: Dictalert
                }

                TextWidget {
                    text: ""
                }
                TextWidget {
                    text: ""
                }
                Button {
                    id: exit
                    text: "設定を終わる"
                }
            }
        });

    auto dllCaption = "Migemo ライブラリのパス"d;
    auto dictCaption = "Migemo 辞書のある"d~directory;

    wLayout.childById("DLLCaption").text = dllCaption;
    wLayout.childById("DictCaption").text = dictCaption;

    with(wLayout.childById("migemoDLLPath"))
    {
        text = config.migemoDLL;
        keyEvent = (Widget src, KeyEvent e) {
            import std.file;
            import dlangui.graphics.colors;
            auto alert = wLayout.childById("DLLalert");
            if (text.exists)
            {
                alert.text = "";
                alert.textColor = decodeHexColor("black");
            }
            else
            {

                alert.text = "ファイルがありません！";
                alert.textColor = decodeHexColor("red");
            }
            return false;
        };
    }

    wLayout.childById("migemoDLLSelecter").click = (Widget src) {
        auto dlg = new FileDialog(UIString(dllCaption), configWindow, null, FileDialogFlag.FileMustExist);
        dlg.dialogResult = (Dialog dlg, const Action result) {
            import dlangui.core.stdaction;
            if (result.id == ACTION_OPEN.id)
            {
                import std.conv;
                import std.file;
                auto path = result.stringParam.to!dstring;
                with(wLayout.childById!EditLine("migemoDLLPath"))
                {
                    text = path;
                    import dlangui.graphics.colors;
                    auto alert = wLayout.childById("DLLalert");
                    if (text.exists)
                    {
                        alert.text = "";
                        alert.textColor = decodeHexColor("black");
                    }
                    else
                    {
                        alert.text = "ファイルがありません！";
                        alert.textColor = decodeHexColor("red");
                    }
                }
            }
        };
        dlg.show;
        return true;
    };

    with(wLayout.childById("migemoDictPath"))
    {
        text = config.migemoDict;
        keyEvent = (Widget src, KeyEvent e) {
            import std.file;
            import dlangui.graphics.colors;
            auto alert = wLayout.childById("Dictalert");
            if (text.exists && text.isDir)
            {
                alert.text = "";
                alert.textColor = decodeHexColor("black");
            }
            else
            {
                import std.format;
                auto txt = text.exists ? "では" : "が";
                alert.text = format("%s%sありません！"d, directory, txt);
                alert.textColor = decodeHexColor("red");
            }
            return false;
        };
    }

    wLayout.childById("exit").click = (Widget src) {
        configWindow.close;
        return true;
    };
    configWindow.mainWidget = wLayout;
    configWindow.show;
    configWindow.onClose = {
        import std.stdio;
        config.migemoDLL = wLayout.childById("migemoDLLPath").text;
        config.migemoDict = wLayout.childById("migemoDictPath").text;
    };
}

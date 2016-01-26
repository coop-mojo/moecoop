/**
   MoeCoop
   Copyright (C) 2016  Mojo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
module coop.view.config_window;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;

import coop.model.config;

import std.algorithm;
import std.file;

class ConfigDialog: Dialog
{
    this(Window parent, Config con)
    {
        super(UIString("設定"d), parent, DialogFlag.Popup);
        config_ = con;
    }

    override void initialize()
    {
        version(Windows) {
            enum directory = "フォルダ";
        } else {
            enum directory = "ディレクトリ";
        }

        auto wLayout = parseML(q{
                TableLayout {
                colCount: 3
                padding: 10

                TextWidget {
                    text: "キャラクター管理(飾り)"
                }
                EditLine { id: toBeAdded }
                Button {
                    id: addCharacter
                    text: "追加"
                }
                TextWidget {
                    text: ""
                }
                ListWidget {
                    id: characters
                    backgroundColor: "white"
                }
                Button {
                    id: deleteCharacter
                    text: "選択したキャラクターを削除"
                }

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
                id: DictCaption
                }
                EditLine {
                id: migemoDictPath
                }
                TextWidget {
                id: migemoDictSelecter
                text: ""
                }
                }
            });

        StringListAdapter charList = new StringListAdapter;
        dstring[] chars = ["しらたま"d, "かきあげ"d];
        chars.each!(c => charList.add(c));
        wLayout.childById!ListWidget("characters").ownAdapter = charList;

        with(wLayout.childById("toBeAdded"))
        {
            keyEvent = (Widget src, KeyEvent e) {
                wLayout.childById("addCharacter").enabled = chars.any!(c => c == text);
                return false;
            };
        }
        wLayout.childById("addCharacter").click = (Widget src) {
            // auto newChar = wLayout.childById("toBeAdded").text;
            // charList.add(newChar);
            // chars ~= newChar;
            /// add newChar to the original character list
            return true;
        };
        wLayout.childById("deleteCharacter").click = (Widget src) {
            // auto list = wLayout.childById!ListWidget("characters");
            // auto deletedIdx = list.selectedItemIndex;
            // import std.stdio;
            // writeln("Idx: ", deletedIdx);
            // auto deleted = chars[deletedIdx];
            // // charList.remove(deletedIdx);
            // chars = chars[0..deletedIdx] ~ chars[deletedIdx+1..$];
            // auto newList = new StringListAdapter;
            // chars.each!(c => newList.add(c));
            // list.ownAdapter = newList;
            // /// delete oldChar to the original character list
            return true;
        };

        auto dllCaption = "Migemo ライブラリのパス"d;
        auto dictCaption = "Migemo 辞書のある"d~directory;

        wLayout.childById("DLLCaption").text = dllCaption;
        wLayout.childById("DictCaption").text = dictCaption;

        with(wLayout.childById("migemoDLLPath"))
        {
            text = config_.migemoDLL;
            if (!text.exists)
            {
                textColor = "red";
            }
            keyEvent = (Widget src, KeyEvent e) {
                import std.file;
                if (text.exists)
                {
                    textColor = "black";
                }
                else
                {

                    textColor = "red";
                }
                return false;
            };
        }

        wLayout.childById("migemoDLLSelecter").click = (Widget src) {
            auto dlg = new FileDialog(UIString(dllCaption), window, null, FileDialogFlag.FileMustExist);
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
                        if (text.exists)
                        {
                            textColor = "black";
                        }
                        else
                        {
                            textColor = "red";
                        }
                    }
                }
            };
            dlg.show;
            return true;
        };

        with(wLayout.childById("migemoDictPath"))
        {
            text = config_.migemoDict;
            if (!text.exists)
            {
                textColor = "red";
            }
            keyEvent = (Widget src, KeyEvent e) {
                import std.file;
                if (text.exists && text.isDir)
                {
                    textColor = "black";
                }
                else
                {
                    textColor = "red";
                }
                return false;
            };
        }

        wLayout.backgroundColor = 0xCCCCCC;
        addChild(wLayout);

        auto exits = new HorizontalLayout;
        auto spacer = new FrameLayout;
        spacer.layoutWidth(FILL_PARENT);
        spacer.minWidth(400);
        exits.addChild(spacer);
        exits.addChild(new Button(ACTION_OK));
        exits.addChild(new Button(ACTION_CANCEL));
        _buttonActions = [ACTION_OK, ACTION_CANCEL];
        addChild(exits);

    }

    override void close(const Action action)
    {
        if (action) {
            if (action.id == StandardAction.Ok)
            {
                config_.migemoDLL = childById("migemoDLLPath").text;
                config_.migemoDict = childById("migemoDictPath").text;
            }
        }
        _parentWindow.removePopup(_popup);
    }
private:
    Config config_;
}

auto showConfigWindow(Window parent, ref Config config)
{
    auto dlg = new ConfigDialog(parent, config);
    dlg.show;
}

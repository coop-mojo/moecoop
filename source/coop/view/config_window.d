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
import coop.model.character;
import coop.view.main_frame;
import coop.view.recipe_tab_frame;
import coop.view.recipe_material_tab_frame;

import std.algorithm;
import std.file;
import std.array;

class ConfigDialog: Dialog
{
    this(Window parent, Character[dstring] chars, Config con)
    {
        super(UIString("設定"d), parent, DialogFlag.Popup);
        chars_ = chars;
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
                        text: "キャラクター管理"
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
        chars_.keys.each!(c => charList.add(c));
        wLayout.childById!ListWidget("characters").ownAdapter = charList;
        dstring baseDir = chars_.values.front.baseDirectory;

        with(wLayout.childById("toBeAdded"))
        {
            keyEvent = (Widget src, KeyEvent e) {
                wLayout.childById("addCharacter").enabled = chars_.keys.all!(c => c != text);
                return false;
            };
        }
        wLayout.childById("addCharacter").click = (Widget src) {
            auto newChar = wLayout.childById("toBeAdded").text;
            chars_[newChar] = new Character(newChar, baseDir);
            charList.add(newChar);
            auto mainWidget = _parentWindow.mainWidget;
            with(mainWidget)
            {
                childById!RecipeTabFrame("binderFrame").characters = chars_.keys;
                childById!RecipeTabFrame("skillFrame").characters = chars_.keys;
                childById!RecipeMaterialTabFrame("materialFrame").characters = chars_.keys;
            }
            return true;
        };
        wLayout.childById("deleteCharacter").click = (Widget src) {
            auto list = wLayout.childById!ListWidget("characters");
            auto deletedIdx = list.selectedItemIndex;
            auto deleted = charList.items[deletedIdx];
            auto c = chars_[deleted];
            chars_.remove(deleted);
            c.deleteConfig;
            charList.clear;
            chars_.keys.each!(c => charList.add(c));
            auto mainWidget = _parentWindow.mainWidget;
            with(mainWidget)
            {
                childById!RecipeTabFrame("binderFrame").characters = chars_.keys;
                childById!RecipeTabFrame("skillFrame").characters = chars_.keys;
                childById!RecipeMaterialTabFrame("materialFrame").characters = chars_.keys;
            }
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
                (cast(MainFrame)_parentWindow.mainWidget).controller.loadMigemo;
            }
        }
        _parentWindow.removePopup(_popup);
    }
private:
    Config config_;
    Character[dstring] chars_;
}

auto showConfigWindow(Window parent, Character[dstring] chars, Config config)
{
    auto dlg = new ConfigDialog(parent, chars, config);
    dlg.show;
}

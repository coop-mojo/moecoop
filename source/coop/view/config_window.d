/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.config_window;

import dlangui;
import dlangui.dialogs.dialog;

import coop.core.character;

class ConfigDialog: Dialog
{
    this(Window parent, Character[dstring] chars)
    {
        super(UIString("設定"d), parent, DialogFlag.Popup);
        chars_ = chars;
    }

    override void initialize()
    {
        import std.file;
        import std.range;

        auto wLayout = parseML(q{
                VerticalLayout {
                    padding: 10
                    HorizontalLayout {
                        TextWidget {
                            text: "キャラクター管理"
                        }
                        VerticalLayout {
                            HorizontalLayout {
                                Button {
                                    id: addCharacter
                                    text: "追加..."
                                }
                                Button {
                                    id: deleteCharacter
                                    text: "削除"
                                }
                                Button {
                                    id: editCharacter
                                    text: "キャラクター情報編集..."
                                }
                            }
                            StringListWidget {
                                id: characters
                                backgroundColor: "white"
                            }
                        }
                    }
                }
            });

        wLayout.childById!StringListWidget("characters").items = chars_.keys;
        string baseDir = chars_.values.front.baseDirectory;

        if (chars_.keys.length == 1)
        {
            wLayout.childById("deleteCharacter").enabled = false;
        }

        wLayout.childById("addCharacter").click = (Widget src) {
            auto dlg = new CharacterSettingDialog(window, chars_);
            dlg.dialogResult = (Dialog dlg, const Action action) {
                if (action && action.id == StandardAction.Ok)
                {
                    import std.exception;
                    auto cdlg = cast(CharacterSettingDialog)dlg;
                    auto name = enforce(cdlg.charNameBox.text);
                    auto url = cdlg.urlBox.text;
                    chars_[name] = new Character(name.to!string, baseDir);
                    chars_[name].url = url.to!string;
                    wLayout.childById!StringListWidget("characters").items = chars_.keys;
                    wLayout.childById("deleteCharacter").enabled = true;
                }
            };
            dlg.show;
            return true;
        };

        wLayout.childById("editCharacter").click = (Widget src) {
            auto charName = wLayout.childById!StringListWidget("characters").selectedItem;
            auto ch = chars_[charName];
            auto url = ch.url.to!dstring;

            auto dlg = new CharacterSettingDialog(window, chars_, charName, url);
            dlg.dialogResult = (Dialog dlg, const Action action) {
                if (action && action.id == StandardAction.Ok)
                {
                    ch.url = (cast(CharacterSettingDialog)dlg).urlBox.text.to!string;
                }
            };
            dlg.show;
            return true;
        };

        wLayout.childById("deleteCharacter").click = (Widget src) {
            auto list = wLayout.childById!StringListWidget("characters");
            auto deletedIdx = list.selectedItemIndex;
            auto deleted = list.selectedItem;
            auto c = chars_[deleted];
            chars_.remove(deleted);
            c.deleteConfig;
            list.items = chars_.keys;
            if (chars_.keys.length == 1)
            {
                src.enabled = false;
            }
            return true;
        };

        addChild(wLayout);

        auto exits = new HorizontalLayout;
        auto spacer = new HSpacer;
        spacer.minWidth(300);
        spacer.layoutWidth(FILL_PARENT);
        exits.addChild(spacer);
        auto close = new Button(ACTION_CLOSE).minWidth(80).text = "閉じる";
        close.id = "close-button";
        exits.addChild(close);
        _buttonActions = [ACTION_CLOSE];
        addChild(exits);
    }
private:
    Character[dstring] chars_;
}

auto showConfigWindow(Window parent, Character[dstring] chars)
{
    auto dlg = new ConfigDialog(parent, chars);
    dlg.show;
}

class CharacterSettingDialog: Dialog
{
    this(Window parent, const Character[dstring] chars, dstring name = "", dstring url = "")
    {
        super(UIString("キャラクター設定"d), parent, DialogFlag.Popup);
        this.name = name;
        this.url = url;
        this.chars = chars;
    }

    override void initialize()
    {
        import std.range;

        import coop.view.editors;

        auto wLayout = parseML(q{
                VerticalLayout {
                    padding: 10
                    TableLayout {
                        colCount: 2
                        EditLine {
                            id: charNameBox
                            minWidth: 200
                        }
                        TextWidget {
                            id: "alert"
                            textColor: "red"
                        }
                        EditLine {
                            id: urlBox
                            minWidth: 200
                            maxWidth: 500
                        }
                        HorizontalLayout {
                            Button {
                                id: ponButton
                                text: "スキるぽん"
                            }
                        }
                    }
                }
            });

        addChild(wLayout);

        enum defaultCharName = "キャラクター名";
        charNameBox.popupMenu = editorPopupMenu;
        charNameBox.contentChange = (EditableContent con) {
            import std.algorithm;
            import std.range;

            auto txt = con.text;
            if (txt.empty || txt == defaultCharName)
            {
                childById("ok-button").enabled = false;
                childById("alert").text = "";
            }
            else if (charNameBox.enabled && chars.keys.canFind(txt))
            {
                childById("ok-button").enabled = false;
                childById("alert").text = "既に存在しています";
            }
            else
            {
                childById("ok-button").enabled = true;
                childById("alert").text = "";
            }
        };
        charNameBox.focusChange = (Widget src, bool focused) {
            if (focused)
            {
                if (src.text == defaultCharName)
                {
                    src.text = "";
                    src.textColor = "black";
                }
            }
            else
            {
                if (src.text == "")
                {
                    src.text = defaultCharName;
                    src.textColor = "gray";
                }
            }
            return true;
        };

        enum defaultURL = "スキルシミュレーターURL";
        urlBox.text = url == "" ? defaultURL : url;
        urlBox.popupMenu = editorPopupMenu;
        urlBox.contentChange = (EditableContent con) {
            auto txt = con.text;
            if (charNameBox.enabled)
            {
                import coop.core.skills;
                import std.exception;
                import std.traits;
                import std.typecons;
                auto tpl = parseSimulatorURL(txt.to!string).ifThrown(ReturnType!parseSimulatorURL.init);
                if (tpl[0] != "")
                {
                    charNameBox.text = tpl[0].to!dstring;
                    charNameBox.textColor = "black";
                }
            }
        };
        urlBox.focusChange = (Widget src, bool focused) {
            if (focused)
            {
                if (src.text == defaultURL)
                {
                    src.text = "";
                    src.textColor = "black";
                }
            }
            else
            {
                if (src.text == "")
                {
                    src.text = defaultURL;
                    src.textColor = "gray";
                }
            }
            return true;
        };
        if (urlBox.text == defaultURL)
        {
            urlBox.textColor = "gray";
        }

        childById("ponButton").click = (Widget src) {
            import std.range;

            dstring url;
            auto txt = urlBox.text;
            if (txt.empty || txt == defaultURL)
            {
                import coop.core.skills;
                if (charNameBox.text.empty || charNameBox.text == defaultCharName)
                {
                    import std.conv;
                    url = SkillPon.to!dstring;
                }
                else
                {
                    import std.format;
                    import std.uri;
                    url = format("%s?0&&%s"d, SkillPon, charNameBox.text.encode);
                }
            }
            else
            {
                url = txt;
            }
            Platform.instance.openURL(url.to!string);
            return true;
        };

        auto exits = new HorizontalLayout;
        auto spacer = new FrameLayout;
        spacer.minWidth(200);
        spacer.layoutWidth(FILL_PARENT);
        exits.addChild(spacer);
        auto ok = new Button(ACTION_OK).minWidth(80).text = "決定";
        ok.id = "ok-button";
        auto cancel = new Button(ACTION_CANCEL).minWidth(80).text = "キャンセル";
        cancel.id = "cancel-button";
        exits.addChildren([ok, cancel]);
        _buttonActions = [ACTION_OK, ACTION_CANCEL];
        addChild(exits);

        if (!name.empty)
        {
            charNameBox.enabled = false;
            charNameBox.text = name;
        }
        else
        {
            childById("ok-button").enabled = false;
            charNameBox.text = defaultCharName;
            charNameBox.textColor = "gray";
        }
    }

    @property auto charNameBox() {
        return cast(EditLine)childById("charNameBox");
    }

    @property auto urlBox() {
        return cast(EditLine)childById("urlBox");
    }
private:
    dstring name;
    dstring url;
    const Character[dstring] chars;
}

/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.config_window;

import dlangui;
import dlangui.dialogs.dialog;

import coop.model.config;
import coop.model.character;

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
                    HorizontalLayout {
                        TextWidget {
                            text: "Migemo ライブラリ"
                        }
                        FrameLayout {
                            minWidth: 130
                            layoutWidth: FILL_PARENT
                        }
                        Button {
                            id: migemoInstaller
                            text: "インストール"
                        }
                    }
                }
            });

        wLayout.childById!StringListWidget("characters").items = chars_.keys;
        dstring baseDir = chars_.values.front.baseDirectory;

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
                    chars_[name] = new Character(name, baseDir);
                    chars_[name].url = url;
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
            auto url = ch.url;

            auto dlg = new CharacterSettingDialog(window, chars_, charName, url);
            dlg.dialogResult = (Dialog dlg, const Action action) {
                if (action && action.id == StandardAction.Ok)
                {
                    ch.url = (cast(CharacterSettingDialog)dlg).urlBox.text;
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

        if (config_.migemoLib.exists)
        {
            with(wLayout.childById("migemoInstaller"))
            {
                text = "インストール済み";
                enabled = false;
            }
        }
        else
        {
            with(wLayout.childById("migemoInstaller"))
            {
                text = "インストール";
                version(Posix)
                {
                    enabled = false;
                }
                else version(Win32)
                {
                    enabled = false;
                }
            }
        }

        version(Windows)
        {
            wLayout.childById("migemoInstaller").click = (Widget src) {
                import std.path;

                wLayout.childById("migemoInstaller").enabled = false;
                childById("close-button").enabled = false;
                scope(exit) childById("close-button").enabled = true;

                wLayout.childById("migemoInstaller").text = "インストール中...";
                scope(success) wLayout.childById("migemoInstaller").text = "インストール済み";
                scope(failure) wLayout.childById("migemoInstallers").text = "インストールに失敗しました";
                installMigemo(config_.migemoLib.dirName);
                return true;
            };
        }

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

    override void close(const Action action)
    {
        if (action) {
            import std.file;
            if (action.id == StandardAction.Close &&
                config_.migemoLib.exists)
            {
                import std.algorithm;
                import coop.view.main_frame;

                auto main = cast(MainFrame)window.mainWidget;
                main.controller.loadMigemo;
                ["binderFrame", "skillFrame", "materialFrame"].each!((tabName) {
                        import coop.view.tab_frame_base;
                        auto tab = main.childById!TabFrameBase(tabName);
                        auto selected = tab.charactersBox.selectedItem;
                        tab.charactersBox.items = chars_.keys;
                        auto newIdx = chars_.keys.countUntil(selected).to!int;
                        tab.charactersBox.selectedItemIndex = newIdx == -1 ? 0 : newIdx;
                    });
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

auto installMigemo()(string dest)
{
    version(Windows)
    {
        import std.file: remove;
        import std.format;
        import std.net.curl;
        import std.path;
        import std.zip;

        enum baseURL = "http://files.kaoriya.net/cmigemo/";
        enum ver = "20110227";
        version(X86)
        {
            enum arch = "32";
        }
        else
        {
            enum arch = "64";
        }

        auto src = format("%s/cmigemo-default-win%s-%s.zip", baseURL, arch, ver);
        auto archive = src.baseName;
        download(src, archive);
        assert(archive.exists);
        scope(exit) archive.remove;

        unzip(archive, dest);
    }
    else
    {
        static assert(false, "It should not be called from non-Windows systems.");
    }
}

auto unzip(string srcFile, string destDir)
{
    import std.exception;
    import std.file;
    import std.zip;

    enforce(srcFile.exists);

    auto zip = new ZipArchive(read(srcFile));
    foreach(name, am; zip.directory)
    {
        import std.algorithm;
        import std.path;
        import std.regex;
        if (name.endsWith("/"))
        {
            continue;
        }
        auto target = buildPath(destDir, name.replaceFirst(ctRegex!r"^.+?/", ""));
        auto dir = target.dirName;
        mkdirRecurse(dir);
        assert(am.expandedData.length == 0);
        zip.expand(am);
        assert(am.expandedData.length == am.expandedSize);
        target.write(am.expandedData);
    }
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
                import coop.model.skills;
                import std.exception;
                import std.traits;
                import std.typecons;
                auto tpl = parseSimulatorURL(txt).ifThrown(ReturnType!parseSimulatorURL.init);
                if (tpl[0] != "")
                {
                    charNameBox.text = tpl[0];
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
                import coop.model.skills;
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

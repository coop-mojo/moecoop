/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.view.main_frame;

import dlangui;

immutable fontName = defaultFontName;

version(Windows) {
    immutable defaultFontName = "Meiryo UI";
}
else version(linux) {
    immutable defaultFontName = "源ノ角ゴシック JP,VL ゴシック,Takaoゴシック";
}
else version(OSX) {
    immutable defaultFontName = "游ゴシック体";
}

enum MENU_ACTION {
    EXIT,
    OPTION,
    VERSION,
}

mixin template TabFrame()
{
public:
    import std.format;
    mixin(format("alias Controller = %sController;", typeof(this).stringof));

    @property auto root()
    out(ret)
    {
        assert(ret !is null);
    } body {
        import dlangui;
        Widget parent_ = this;
        while(parent_.parent !is null)
        {
            parent_ = parent_.parent;
        }
        return cast(MainFrame)parent_;
    }

    Controller controller;
}

class MainFrame: AppFrame
{
    import coop.mui.model.character;
    import coop.mui.model.custom_info;
    import coop.mui.model.config;
    import coop.mui.model.wisdom_adapter;

    this(ModelAPI model, Character[dstring] chars, Config config, CustomInfo cInfo)
    {
        import std.array;
        import std.algorithm;

        import coop.mui.controller.binder_tab_frame_controller;
        import coop.mui.controller.recipe_material_tab_frame_controller;
        import coop.mui.controller.skill_tab_frame_controller;

        super();

        dstring msg;

        try{
            auto binders = model.getBinderCategories
                                .バインダー一覧
                               .map!"a.バインダー名"
                               .array
                               .to!(dstring[]);
            auto skills = model.getSkillCategories
                               .スキル一覧
                               .map!"a.スキル名"
                               .array
                               .to!(dstring[]);

            controller_ = new MainFrameController(this, model, chars, config, cInfo);
            binderTab.controller = new BinderTabFrameController(binderTab, binders);
            skillTab.controller = new SkillTabFrameController(skillTab, skills);
            materialTab.controller = new RecipeMaterialTabFrameController(materialTab);
            binderTab.controller.showRecipeNames;
        } catch (NetworkException e) {
            msg = "Link Dead: サーバーが落ちてるみたい。生協の人に教えてあげて！";
        }

        statusLine.setStatusText = msg ? msg : defaultStatusMessage;
    }

    @property auto controller()
    {
        return controller_;
    }

    auto enableMigemo()
    {
        binderTab.enableMigemoBox;
        skillTab.enableMigemoBox;
    }

    auto disableMigemo()
    {
        binderTab.disableMigemoBox;
        skillTab.disableMigemoBox;
    }

    auto setStatusText(dstring msg, ulong timeout = 0)
    {
        if (timerID > 0)
        {
            cancelTimer(timerID);
        }
        if (window)
        {
            statusLine.setStatusText = msg;
            if (timeout > 0)
            {
                timerID = setTimer(timeout);
            }
        }
    }

    auto defaultStatusMessage()
    {
        debug
        {
            return "デバッグ凡例: 赤 = レシピ情報なし、青 = アイテム情報なし、下線 = アイテム個別情報なし、"d;
        }
        else
        {
            import std.conv;
            import std.range;
            import coop.util;
            auto info = controller_.model.getInformation;
            string msg;
            if (Version.versionLT(info.oldestSupportedRelease))
            {
                msg = "知恵袋サーバーがサポートしてるのより古いバージョンだよ！このまま使うと鼻から LoC が出てくるかも！バージョン情報から最新版を入手してね！";
            }
            else if (Version.versionLT(info.latestRelease))
            {
                import std.format;
                msg = format("生協の知恵袋 %s が公開中です！ダウンロードはバージョン情報からどうぞ！", info.latestRelease);
            }
            else if (info.message.empty)
            {
                msg = "ダイアロス生活協同組合は P 鯖と E 鯖で活動中！晩御飯からピッキングの相談までお気軽にどうぞ！";
            }
            else
            {
                msg = info.message;
            }
            return "生協からのお知らせ: "~msg.to!dstring;
        }
    }
protected:

    override bool onTimer(ulong id)
    {
        statusLine.setStatusText = defaultStatusMessage;
        return false;
    }

    override protected void initialize()
    {
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
        super.initialize();
    }

    override MainMenu createMainMenu()
    {
        MenuItem mainMenuItems = new MenuItem;
        auto optionItem = new MenuItem(new Action(MENU_ACTION.OPTION, "オプション..."d));
        auto versionItem = new MenuItem(new Action(MENU_ACTION.VERSION, "バージョン情報..."d));
        auto exitItem = new MenuItem(new Action(MENU_ACTION.EXIT, "終了"d));
        mainMenuItems.add(optionItem);
        mainMenuItems.add(versionItem);
        mainMenuItems.add(exitItem);
        auto mainMenu = new MainMenu(mainMenuItems);

        return mainMenu;
    }

    override Widget createBody()
    {
        auto tabs = new TabWidget("tabs");
        tabs.layoutWidth(FILL_PARENT)
            .layoutHeight(FILL_PARENT);

        binderTab = new RecipeTabFrame("binderFrame");
        tabs.addTab(binderTab, "バインダー"d);
        binderTab.categoryName = "バインダー"d;

        skillTab = new RecipeTabFrame("skillFrame");
        tabs.addTab(skillTab, "スキル"d);
        skillTab.categoryName = "スキル"d;

        materialTab = new RecipeMaterialTabFrame("materialFrame");
        tabs.addTab(materialTab, "レシピ材料"d);

        tabs.tabChanged = (string next, string prev) {
            import std.algorithm;

            import coop.mui.view.tab_frame_base;

            auto prev_tab = childById!TabFrameBase(prev);
            auto useMetaSearch = prev_tab.useMetaSearch;
            auto useMigemo = prev_tab.useMigemo;
            auto query = prev_tab.queryBox.text == prev_tab.defaultMessage ? "" : prev_tab.queryBox.text;
            auto idx = prev_tab.charactersBox.selectedItemIndex;

            foreach(tab; [binderTab, skillTab, materialTab])
            {
                tab.useMetaSearch = useMetaSearch;
                tab.useMigemo = useMigemo;
                if (query == "")
                {
                    tab.queryBox.text = tab.defaultMessage;
                    tab.queryBox.textColor = "gray";
                }
                else
                {
                    tab.queryBox.text = query;
                    tab.queryBox.textColor = "black";
                }
                tab.charactersBox.selectedItemIndex = idx;
            }
        };
        return tabs;
    }

    override bool handleAction(const Action a)
    {
        if (a)
        {
            switch(a.id) with(MENU_ACTION)
            {
            case EXIT:
                window.close;
                return true;
            case OPTION:
                import coop.mui.view.config_window;
                showConfigWindow(window, controller.characters);
                return true;
            case VERSION:
                import coop.mui.view.version_window;
                showVersionWindow(window);
                return true;
            default:
            }
        }
        return false;
    }
private:

    import coop.mui.controller.main_frame_controller;
    import coop.mui.view.recipe_tab_frame;
    import coop.mui.view.recipe_material_tab_frame;

    MainFrameController controller_;
    RecipeTabFrame binderTab, skillTab;
    RecipeMaterialTabFrame materialTab;
    ulong timerID;
}

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
module coop.view.main_frame;

import dlangui;

import std.algorithm;

import coop.model.character;
import coop.model.wisdom;
import coop.model.config;
import coop.view.recipe_tab_frame;
import coop.controller.main_frame_controller;
import coop.controller.binder_tab_frame_controller;
import coop.controller.skill_tab_frame_controller;

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

enum MENU_ACTION{
    EXIT,
    OPTION,
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
    this(Wisdom wisdom, Character[dstring] chars, Config config)
    {
        super();
        controller_ = new MainFrameController(this, wisdom, chars, config);
        binderTab.controller = new BinderTabFrameController(binderTab, controller.wisdom.binders);
        skillTab.controller = new SkillTabFrameController(skillTab, controller.wisdom.recipeCategories);

        binderTab.controller.showBinderRecipes;

        statusLine.setStatusText(" "d);
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
protected:
    override protected void initialize()
    {
        _appName = "生協の知恵袋";
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
        super.initialize();
    }

    override MainMenu createMainMenu()
    {
        MenuItem mainMenuItems = new MenuItem;
        auto optionItem = new MenuItem(new Action(MENU_ACTION.OPTION, "オプション..."d));
        auto exitItem = new MenuItem(new Action(MENU_ACTION.EXIT, "終了"d));
        mainMenuItems.add(optionItem);
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

        tabs.tabChanged = (string next, string prev) {
            if (auto recipeTab = cast(RecipeTabFrame)childById(prev))
            {
                auto useMetaSearch = recipeTab.useMetaSearch;
                auto useMigemo = recipeTab.useMigemo;
                auto queryText = recipeTab.queryText;

                [binderTab, skillTab].each!((tab) {
                        tab.useMetaSearch = useMetaSearch;
                        tab.useMigemo = useMigemo;
                        tab.queryText = queryText;
                    });
            }

            if (auto nextTab = cast(RecipeTabFrame)childById(next))
            {
                nextTab.controller.showBinderRecipes;
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
                import coop.view.config_window;
                showConfigWindow(window, controller.characters, controller.config);
                return true;
            default:
            }
        }
        return false;
    }
private:
    MainFrameController controller_;
    RecipeTabFrame binderTab, skillTab;
}

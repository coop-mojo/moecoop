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
import dlangui.widgets.metadata;

import std.algorithm;

import coop.model.character;
import coop.model.wisdom;
import coop.model.config;
import coop.view.recipe_tab_frame;
import coop.controller.binder_tab_frame_controller;
import coop.controller.main_frame_controller;
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

    auto root()
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

class MainFrame : VerticalLayout
{
    this(string id)
    {
        super(id);
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
    }

    auto enableMigemo() {
        if (auto fr = childById!RecipeTabFrame("binderFrame"))
        {
            fr.enableMigemoBox;
        }
    }

    auto disableMigemo() {
        if (auto fr = childById!RecipeTabFrame("binderFrame"))
        {
            fr.disableMigemoBox;
        }
    }

    static auto create(Window parent, Wisdom wisdom, Character[dstring] chars, Config config)
    {
        auto root = new MainFrame("root");
        root.controller = new MainFrameController(root, wisdom, chars, config);

        auto mainMenuItems = new MenuItem;
        auto optionItem = new MenuItem(new Action(MENU_ACTION.OPTION, "オプション..."d));
        auto exitItem = new MenuItem(new Action(MENU_ACTION.EXIT, "終了"d));
        mainMenuItems.add(optionItem);
        mainMenuItems.add(exitItem);
        auto mainMenu = new MainMenu(mainMenuItems);

        mainMenu.menuItemClick = (MenuItem item) {
            auto a = item.action;
            if (a) {
                switch(a.id) with(MENU_ACTION)
                {
                case EXIT:
                    parent.close;
                    break;
                case OPTION:
                    import coop.view.config_window;
                    showConfigWindow(parent, chars, config);
                    break;
                default:
                }
            }
            return true;
        };
        root.addChild(mainMenu);

        auto tabs = new TabWidget("tabs");
        tabs.layoutWidth(FILL_PARENT)
            .layoutHeight(FILL_PARENT);
        root.addChild(tabs);

        // TODO: 下にスペースが残る
        auto status = new StatusLine;
        status.id = "status";
        status.setStatusText(" "d);
        root.addChild(status);

        auto binderTab = new RecipeTabFrame("binderFrame");
        tabs.addTab(binderTab, "バインダー"d);
        binderTab.setCategoryName("バインダー"d);
        binderTab.controller = new BinderTabFrameController(binderTab, wisdom.binders);

        auto skillTab = new RecipeTabFrame("skillFrame");
        tabs.addTab(skillTab, "スキル"d);
        skillTab.setCategoryName("スキル"d);
        skillTab.controller = new SkillTabFrameController(skillTab, wisdom.recipeCategories);

        tabs.tabChanged = (string next, string prev) {
            if (auto recipeTab = cast(RecipeTabFrame)root.childById(prev))
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

            (cast(RecipeTabFrame)root.childById(next)).controller.showBinderRecipes;
        };

        (cast(RecipeTabFrame)tabs.selectedTabBody).controller.showBinderRecipes;

        return root;
    }

    MainFrameController controller;
}

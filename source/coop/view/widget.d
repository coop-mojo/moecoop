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
module coop.view.widget;

import dlangui;
import dlangui.widgets.metadata;

import coop.model.character;
import coop.model.wisdom;
import coop.model.config;
import coop.view.recipe_base_frame;
import coop.controller.recipe_frame_controller;

immutable fontName = defaultFontName;

version(Windows) {
    immutable defaultFontName = "Meiryo UI";
}
else version(linux) {
    immutable defaultFontName = "源ノ角ゴシック JP";
}
else version(OSX) {
    immutable defaultFontName = "游ゴシック体";
}

enum MENU_ACTION{
    EXIT,
    OPTION,
}

class MainLayout : VerticalLayout
{
    this() {
        super();
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
    }

    this(string id)
    {
        super(id);
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
    }
    RecipeFrameController binderFrameController;
}

auto createBinderListLayout(Window parent, Wisdom wisdom, Character[] chars, Config config)
{
    auto root = new MainLayout("root");

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
                showConfigWindow(parent, config);
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

    auto binderFrame = new RecipeBaseFrame("binderFrame");
    binderFrame.setCategoryName("バインダー"d);

    root.binderFrameController =
        new RecipeFrameController(binderFrame, wisdom, chars, config);
    root.binderFrameController.categories = wisdom.binders;

    tabs.addTab(binderFrame, "バインダー"d);

    return root;
}

mixin(registerWidgets!(MainLayout)());

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
module coop.widget;
import dlangui;
import dlangui.widgets.metadata;

import std.algorithm;
import std.stdio;
import std.range;

import coop.union_binder;
import coop.wisdom;

immutable MaxNumberOfBinderPages = 128;
immutable MaxColumns = 4;

immutable fontName = defaultFontName;

version(Windows) {
    immutable defaultFontName = "Meiryo UI";
}
else version(linux) {
    immutable defaultFontName = "源ノ角ゴシック JP";
}

class MainLayout : HorizontalLayout
{
    this()
    {
        super();
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
    }
}

auto createBinderListLayout(Window parent, ref Wisdom wisdom)
{
    auto layout = cast(MainLayout)parseML(q{
    MainLayout {
        margins: 20; padding: 10
        VerticalLayout {
            ComboBox {
                id: cbOptions
            }

            HorizontalLayout {
                EditLine { id: searchQuery; text: "Search for something" }
                Button { id: searchButton; text: "レシピを検索" }
            }

            TextWidget { text: "レシピ" }
            FrameLayout {
                id: recipes
            }
        }
        VerticalLayout {
            Button { text: "レシピ情報"}
            Button { text: "アイテム情報"}
            HorizontalLayout {
                Button { id: btnExit; text: "終了" }
            }
        }
    }
        });

    enum exitFun = (Widget src) { parent.close; return true; };
    layout.childById("btnExit").click = exitFun;

    import std.algorithm.sorting;
    auto keys = ["バインダー"d, "-----"] ~ wisdom.binders;
    layout.childById!ComboBox("cbOptions").items = keys;
    layout.childById!ComboBox("cbOptions").itemClick = (Widget src, int idx) {
        auto key = keys[idx];
        if (auto lst = wisdom.binderElements(key))
        {
            auto binderElems = layout.childById!FrameLayout("recipes");
            binderElems.updateElememnts(*lst);
        }
        return true;
    };

    layout.childById("searchButton").click = (Widget src) {
        auto query = layout.childById("searchQuery").text;
        auto binder = layout.childById!ComboBox("cbOptions").selectedItem;
        auto binderElems = layout.childById!FrameLayout("recipes");
        binderElems.updateElememnts(wisdom.searchBinderElements(binder, query));
        return true;
    };
    return layout;
}

void updateElememnts(Recipes)(FrameLayout layout, Recipes rs)
    if (isInputRange!Recipes && is(ElementType!Recipes == BinderElement))
{
    layout.removeAllChildren();
    auto scroll = new ScrollWidget;
    auto horizontal = new HorizontalLayout;

    rs.toBinderTableWidget.each!(column => horizontal.addChild(column));
    scroll.contentWidget = horizontal;
    layout.addChild(scroll);
}

auto toBinderTableWidget(Recipes)(Recipes rs)
    if (isInputRange!Recipes && is(ElementType!Recipes == BinderElement))
{
    return rs
        .map!((ref r) {
                auto box = new CheckBox("recipe", r.recipe.to!dstring);
                box.checked = r.isFiled;
                box.checkChange = (Widget src, bool checked) {
                    r.isFiled = checked;
                    return true;
                };
                return box;
            })
        .chunks(MaxNumberOfBinderPages/MaxColumns)
        .map!((rs) {
                auto l = new VerticalLayout();
                rs.each!(r => l.addChild(r));
                return l;
            });
}

mixin(registerWidgets!(MainLayout)());

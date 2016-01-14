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
import std.container.util;
import std.stdio;
import std.range;

import coop.recipe;
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
            HorizontalLayout {
                TextWidget { text: "バインダー" }
                ComboBox {
                    id: binders
                }
            }

            HorizontalLayout {
                EditLine {
                    id: searchQuery
                    minWidth: 200
                    text: "見たいレシピ"
                }
                CheckBox { id: metaSearch; text: "バインダー全部から検索する" }
            }

            TextWidget { text: "レシピ一覧" }
            HorizontalLayout {
                FrameLayout {
                    id: recipes
                    padding: 1
                }
            }
        }
        VerticalLayout {
            padding: 10
            minWidth: 400
            TextWidget { text: "レシピ情報" }
            FrameLayout {
                id: recipeDetail
                padding: 1
                backgroundColor: "black"
            }
            Button { text: "アイテム情報"}
            HorizontalLayout {
                Button { id: exit; text: "終了" }
            }
        }
    }
        });

    auto detail = layout.childById("recipeDetail");
    Recipe dummy;
    dummy.techniques = make!(typeof(dummy.techniques))(cast(dstring)[]);
    detail.addChild(dummy.toRecipeWidget(wisdom));

    auto editLine = layout.childById!EditLine("searchQuery");
    editLine.focusChange = (Widget src, bool _) {
        static bool isFirstInput = true;
        if (isFirstInput)
        {
            src.text = "";
            isFirstInput = false;
        }
        return true;
    };
    editLine.keyEvent = (Widget src, KeyEvent e) {
        showRecipes(layout, wisdom);
        return false;
    };

    auto metaSearchBox = layout.childById!CheckBox("metaSearch");
    metaSearchBox.checkChange = (Widget src, bool checked) {
        showRecipes(layout, wisdom);
        return true;
    };

    enum exitFun = (Widget src) { parent.close; return true; };
    layout.childById("exit").click = exitFun;

    import std.exception;
    auto keys = wisdom.binders;
    layout.childById!ComboBox("binders").items = keys;
    layout.childById!ComboBox("binders").itemClick = (Widget src, int idx) {
        auto binderElems = layout.childById!FrameLayout("recipes");
        binderElems.updateElememnts(wisdom.recipesIn(Binder(keys[idx])), wisdom);
        return true;
    };
    return layout;
}

void showRecipes(MainLayout layout, ref Wisdom wisdom)
{
    auto query = layout.childById!EditLine("searchQuery").text;
    auto isMetaSearch = layout.childById!CheckBox("metaSearch").checked;

    if (isMetaSearch && query.empty)
        return;

    InputRange!BinderElement recipes;
    if (isMetaSearch)
    {
        recipes = inputRangeObject(wisdom.binders.map!(b => wisdom.recipesIn(Binder(b))).cache.joiner);
    }
    else
    {
        auto binder = layout.childById!ComboBox("binders").selectedItem;
        recipes = inputRangeObject(wisdom.recipesIn(Binder(binder)));
    }
    auto binderElems = layout.childById!FrameLayout("recipes");
    binderElems.updateElememnts(
        recipes.filter!(s => !find(s.recipe, boyerMooreFinder(query)).empty).array, wisdom);
}

void updateElememnts(Recipes)(FrameLayout layout, Recipes rs, ref Wisdom wisdom)
    if (isInputRange!Recipes && is(ElementType!Recipes == BinderElement))
{
    layout.removeAllChildren();
    auto scroll = new ScrollWidget;
    auto horizontal = new HorizontalLayout;

    layout.backgroundColor = rs.empty ? "white" : "black";
    rs.toBinderTableWidget(cast(MainLayout)layout.parent.parent.parent, wisdom)
      .each!(column => horizontal.addChild(column));
    scroll.contentWidget = horizontal;
    scroll.backgroundColor = "white";
    layout.addChild(scroll);
}

auto toBinderTableWidget(Recipes)(Recipes rs, MainLayout rootLayout, ref Wisdom wisdom)
    if (isInputRange!Recipes && is(ElementType!Recipes == BinderElement))
{
    return rs
        .map!((ref r) {
                auto layout = new HorizontalLayout;
                auto box = new CheckBox("recipe", r.recipe);
                box.checked = r.isFiled;
                box.checkChange = (Widget src, bool checked) {
                    r.isFiled = checked;
                    return true;
                };
                auto btn = new Button("detail", "詳細"d);
                btn.click = (Widget src) {
                    auto pane = rootLayout.childById("recipeDetail");
                    pane.removeAllChildren;
                    auto detail = wisdom.recipeFor(r.recipe);
                    if (detail.name.empty)
                    {
                        detail.name = r.recipe;
                        detail.remarks = "作り方がわかりません（´・ω・｀）";
                    }
                    pane.addChild(detail.toRecipeWidget(wisdom));
                    return true;
                };
                return [box, btn];
            })
        .chunks(MaxNumberOfBinderPages/MaxColumns)
        .map!((rs) {
                auto l = new TableLayout;
                l.colCount = 2;
                rs.each!(rr => rr.each!(r => l.addChild(r)));
                return l;
            });
}

auto toRecipeWidget(Recipe r, ref Wisdom wisdom)
{
    auto layout = parseML(q{
            VerticalLayout {
                padding: 5
                TableLayout {
                    colCount: 2

                    TextWidget { text: "レシピ名: " }
                    TextWidget { id: recipe }

                    TextWidget { text: "テクニック: " }
                    TextWidget { id: tech }

                    TextWidget { text: "必要スキル: " }
                    TextWidget { id: skills }

                    TextWidget { text: "材料: " }
                    VerticalLayout { id: ingredients }

                    TextWidget { text: "生成物: " }
                    VerticalLayout { id: products }

                    TextWidget { text: "収録バインダー: " }
                    TextWidget { id: binders }

                    TextWidget { text: "レシピ必須: " }
                    TextWidget { id: requireRecipe }

                    TextWidget { text: "ルーレット: " }
                    TextWidget { id: roulette }
                }
                HorizontalLayout {
                    id: remarksInfo
                    TextWidget { text: "備考:" }
                    TextWidget { id: remarks }
                }
            }
        });

    import std.format;
    layout.childById("recipe").text = r.name;
    layout.childById("tech").text = r.techniques[].join(" or ");
    layout.childById("skills").text = r.requiredSkills
                                       .byKeyValue
                                       .map!(kv => format("%s (%s)"d, kv.key, kv.value))
                                       .join(", ");
    auto productsList = r.products
                         .byKeyValue
                         .map!(kv => format("%s x %s"d, kv.key, kv.value))
                         .map!(s => new TextWidget("product", s));
    auto productsLayout = layout.childById!VerticalLayout("products");
    productsList.each!(w => productsLayout.addChild(w));

    auto ingredientsList = r.ingredients
                            .byKeyValue
                            .map!(kv => format("%s x %s"d, kv.key, kv.value))
                            .map!(s => new TextWidget("ingredients", s));
    auto ingredientsLayout = layout.childById!VerticalLayout("ingredients");
    ingredientsList.each!(w => ingredientsLayout.addChild(w));

    auto filedBinders = wisdom.bindersFor(r.name);
    layout.childById("binders").text = filedBinders.empty ? "なし": filedBinders.join(", ");
    layout.childById("requireRecipe").text = r.requiresRecipe ? "はい": "いいえ";

    dstring rouletteText;
    if (!r.isGambledRoulette && !r.isPenaltyRoulette)
    {
        rouletteText = "通常"d;
    }
    else
    {
        dstring[] attrs;
        if (r.isGambledRoulette) attrs ~= "ギャンブル";
        if (r.isPenaltyRoulette) attrs ~= "ペナルティ";
        rouletteText = attrs.join(", ");
    }
    layout.childById("roulette").text = rouletteText;

    auto l = layout.childById("remarksInfo");
    if (r.remarks.empty)
    {
        l.visibility = Visibility.Gone;
    }
    else
    {
        l.visibility = Visibility.Visible;
        auto remarksText = layout.childById("remarks");
        remarksText.text = r.remarks;
    }

    auto ret = new ScrollWidget;
    ret.contentWidget = layout;
    ret.backgroundColor = "white";
    return ret;
}

mixin(registerWidgets!(MainLayout)());

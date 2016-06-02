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
module coop.view.recipe_material_tab_frame;

import dlangui;

import std.algorithm;
import std.exception;
import std.format;
import std.range;
import std.regex;

import coop.util;
import coop.model.item;
import coop.model.recipe;
import coop.view.controls;
import coop.view.editors;
import coop.view.main_frame;
import coop.view.recipe_tab_frame;
import coop.view.item_detail_frame;
import coop.view.recipe_detail_frame;
import coop.controller.recipe_material_tab_frame_controller;

class RecipeMaterialTabFrame: HorizontalLayout
{
    mixin TabFrame;

    this() { super(); }

    this(string id)
    {
        super(id);
        auto layout = new HorizontalLayout;
        addChild(layout);
        layout.margins = 20;
        layout.padding = 10;

        layout.addChild(recipeMaterialLayout);
        layout.addChild(recipeDetailsLayout);
        layout.layoutHeight(FILL_PARENT);
        layout.layoutWidth(FILL_PARENT);
    }

    @property auto characters(dstring[] chars)
    {
        auto charBox = childById!ComboBox("characters");
        auto selected = charBox.items.empty ? "存在しないユーザー" : charBox.selectedItem;
        charBox.items = chars;
        auto newIdx = chars.countUntil(selected).to!int;
        charBox.selectedItemIndex = newIdx == -1 ? 0 : newIdx;
    }

    @property auto selectedCharacter()
    {
        return childById!ComboBox("characters").selectedItem;
    }

    auto hideItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Gone;
    }

    auto showItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Visible;
    }

    @property auto recipeDetail()
    {
        return cast(RecipeDetailFrame)childById!FrameLayout("recipeDetail").child(0);
    }

    @property auto recipeDetail(Widget recipe)
    {
        auto frame = childById("recipeDetail");
        frame.removeAllChildren;
        frame.addChild(recipe);
    }

    @property auto useMigemo()
    {
        return childById!CheckBox("migemo").checked;
    }

    @property auto useMigemo(bool use)
    {
        childById!CheckBox("migemo").checked = use;
    }

    @property auto disableMigemoBox()
    {
        with(childById!CheckBox("migemo"))
        {
            checked = false;
            enabled = false;
        }
    }

    @property auto enableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = true;
    }

    auto setItemDetail(Widget item, int idx)
    {
        auto frame = childById("detailFrame"~(idx+1).to!string);
        frame.removeAllChildren;
        frame.addChild(item);
    }

    auto showCandidates(dstring[] candidates)
    {
        auto lst = new StringListWidget("candidates", candidates);
        lst.itemClick = (Widget _, int idx) {
            childById("itemQuery").text = lst.selectedItem;
            return true;
        };

        auto candidateFrame = new VerticalLayout;
        candidateFrame.addChild(new TextWidget(null, "作成候補"d));
        candidateFrame.addChild(lst);

        auto helperFrame = childById("helper");
        helperFrame.removeAllChildren;
        helperFrame.addChild(candidateFrame);
    }

    auto showRecipeMaterials(OrderedMap!(int[Recipe]) recipes, int[dstring] materials, int[dstring] leftovers)
    {
        auto resultFrame = childById("result");
        scope(exit) showResult;
        resultFrame.removeAllChildren;

        auto lhs = new VerticalLayout;
        lhs.addChild(new TextWidget(null, "必要レシピ"d));
        auto rList = new ScrollWidget;
        auto rContents = new VerticalLayout;
        recipes.byKeyValue.map!((kv) {
                auto r = kv.key;
                auto layout = new HorizontalLayout;
                auto w = new CheckableEntryWidget(r.name);
                if (r.requiresRecipe && !controller.characters[selectedCharacter].hasRecipe(r.name))
                {
                    w.textColor = "gray";
                }
                w.detailClicked = {
                    recipeDetail = RecipeDetailFrame.create(r, controller.wisdom, controller.characters);
                };
                layout.addChild(w);
                auto times = new TextWidget(null, format(": %s 回"d, kv.value));
                layout.addChild(times);
                return layout;
            }).each!(w => rContents.addChild(w));
        rList.contentWidget = rContents;
        rList.backgroundColor = "white";
        lhs.addChild(rList);

        lhs.addChild(new TextWidget(null, ""d));
        lhs.addChild(new TextWidget(null, "余り物"d));
        auto lList = new ScrollWidget;
        auto lContents = new VerticalLayout;
        auto lefts = leftovers.keys.empty
                     ? [cast(Widget)new TextWidget(null, "なし"d)]
                     : leftovers.byKeyValue.map!((kv) {
                             auto layout = new HorizontalLayout;
                             auto w = new LinkWidget(null, kv.key);
                             w.click = (Widget _) {
                                 Item item;
                                 if (auto i = kv.key in controller.wisdom.itemList)
                                 {
                                     item = *i;
                                 }
                                 else
                                 {
                                     item.name = kv.key;
                                     item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                                 }
                                 showItemDetail(0);
                                 setItemDetail(ItemDetailFrame.create(item, 1, controller.wisdom, controller.cWisdom), 0);
                                 return true;
                             };
                             layout.addChild(w);
                             auto times = new TextWidget(null, format(": %s 個"d, kv.value));
                             layout.addChild(times);
                             return cast(Widget)layout;
                         }).array;
        lefts.each!(w => lContents.addChild(w));
        lList.contentWidget = lContents;
        lList.backgroundColor = "white";
        lhs.addChild(lList);
        resultFrame.addChild(lhs);

        auto rhs = new VerticalLayout;
        rhs.addChild(new TextWidget(null, "必要素材"d));
        auto mList = new ScrollWidget;
        auto mContents = new VerticalLayout;
        materials.byKeyValue.map!((kv) {
                auto layout = new HorizontalLayout;
                auto w = new CheckableEntryWidget(kv.key);
                w.detailClicked = {
                    Item item;
                    if (auto i = kv.key in controller.wisdom.itemList)
                    {
                        item = *i;
                    }
                    else
                    {
                        item.name = kv.key;
                        item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                    }
                    showItemDetail(0);
                    setItemDetail(ItemDetailFrame.create(item, 1, controller.wisdom, controller.cWisdom), 0);
                };
                layout.addChild(w);
                auto times = new TextWidget(null, format(": %s 個"d, kv.value));
                layout.addChild(times);
                return layout;
            }).each!(w => mContents.addChild(w));
        mList.contentWidget = mContents;
        mList.backgroundColor = "white";

        rhs.addChild(mList);
        resultFrame.addChild(rhs);
    }

    auto hideResult()
    {
        childById("resultBase").visibility = Visibility.Gone;
    }

    auto showResult()
    {
        childById("resultBase").visibility = Visibility.Visible;
    }
}

auto recipeMaterialLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                HorizontalLayout {
                    TextWidget { text: "キャラクター" }
                    ComboBox {
                        id: characters
                    }
                }

                HorizontalLayout {
                    EditLine {
                        id: itemQuery
                        minWidth: 300
                        minHeight: 10
                    }
                    EditIntLine {
                        id: numQuery
                        minWidth: 80
                        minHeight: 10
                    }
                    CheckBox { id: migemo; text: "Migemo 検索" }
                }

                TableLayout {
                    id: helper
                    padding: 1
                    colCount: 2
                }

                VerticalLayout {
                    id: resultBase
                    TextWidget { text: "必要レシピ情報" }
                    HorizontalLayout {
                        id: result
                        padding: 1
                    }
                }
            }
        });
    return layout;
}

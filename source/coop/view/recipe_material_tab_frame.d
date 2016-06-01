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

import coop.model.item;
import coop.model.recipe;
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

    auto showRecipeMaterials(int[Recipe] recipes, int[dstring] materials, int[dstring] leftovers)
    {
        auto resultFrame = childById("result");
        resultFrame.removeAllChildren;

        resultFrame.addChild(new TextWidget(null, "必要レシピ"d));
        auto rList = new StringListWidget("recipes");
        rList.items = recipes.byKeyValue.map!(kv => format("%s: コンバイン %s 回"d, kv.key.name, kv.value)).array;
        rList.itemClick = (Widget _, int idx) {
            auto txt = rList.selectedItem;
            auto rName = txt.matchFirst(ctRegex!r"^([^:]+): "d)[1];
            auto rDetail = controller.wisdom.recipeFor(rName);
            recipeDetail = RecipeDetailFrame.create(rDetail, controller.wisdom, controller.characters);
            auto itemNames = rDetail.products.keys;
            enforce(itemNames.length <= 2);

            hideItemDetail(1);

            itemNames.enumerate(0).each!((idx_name) {
                    auto idx = idx_name[0];
                    dstring name = idx_name[1];
                    Item item;
                    if (auto i = name in controller.wisdom.itemList)
                    {
                        item = *i;
                    }
                    else
                    {
                        item.name = name;
                        item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                    }

                    showItemDetail(idx);
                    setItemDetail(ItemDetailFrame.create(item, idx+1, controller.wisdom, controller.cWisdom), idx);
                });
            return true;
        };
        resultFrame.addChild(rList);

        resultFrame.addChild(new TextWidget(null, ""d));
        resultFrame.addChild(new TextWidget(null, "必要素材"d));
        auto mList = new StringListWidget("materials",
                                          materials.byKeyValue.map!(kv => format("%s: %s 個"d, kv.key, kv.value)).array);
        resultFrame.addChild(mList);

        resultFrame.addChild(new TextWidget(null, ""d));
        resultFrame.addChild(new TextWidget(null, "余り物"d));
        auto lList = new StringListWidget("leftovers",
                                          leftovers.keys.empty
                                          ? ["なし"d]
                                          : leftovers.byKeyValue.map!(kv => format("%s: %s 個"d, kv.key, kv.value)).array);
        resultFrame.addChild(lList);
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
                        minWidth: 200
                        text: "作りたいアイテム"
                    }
                    EditLine {
                        id: numQuery
                        minWidth: 60
                        text: "個数"
                    }
                    CheckBox { id: migemo; text: "Migemo 検索" }
                }

                TableLayout {
                    id: helper
                    padding: 1
                    colCount: 2
                }

                TextWidget { text: "必要レシピ情報" }
                VerticalLayout {
                    id: result
                    padding: 1
                }
            }
        });
    return layout;
}

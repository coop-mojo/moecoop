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
import std.typecons;

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

    auto showRequiredElements(OrderedMap!(int[Recipe]) recipes, OrderedMap!(MaterialTuple[dstring]) materials, int[dstring] leftovers)
    {
        scope(exit) showResult;

        showRequiredRecipes(recipes, leftovers);
        showRequiredMaterials(materials);
    }

    auto hideResult()
    {
        childById("result").visibility = Visibility.Gone;
    }

    auto showResult()
    {
        childById("result").visibility = Visibility.Visible;
    }

    auto requiredMaterialsAreAlreadyShown()
    {
        return childById("reqMatsBase").childCount > 0;
    }

    auto ownedMaterials()
    in{
        assert(requiredMaterialsAreAlreadyShown);
    } body {
        auto tbl = childById!TableLayout("reqMats");
        return iota(0, tbl.childCount, tbl.colCount).filter!((idx) {
                auto txt = tbl.child(idx+1).text;
                return !txt.empty && txt.to!int > 0;
            }).map!((idx) {
                return tuple(tbl.child(idx).text[0..$-2],
                             tbl.child(idx+1).text.to!int);
            }).assocArray;
    }

    auto showRequiredRecipes(OrderedMap!(int[Recipe]) recipes, int[dstring] leftovers)
    {
        auto reqFrame = childById("reqRecipesBase");
        reqFrame.removeAllChildren;

        reqFrame.addChild(new TextWidget(null, "必要レシピ"d));
        auto rList = new ScrollWidget;
        auto rContents = new TableLayout;
        rContents.colCount = 2;
        recipes.byKeyValue.map!((kv) {
                auto r = kv.key;
                auto w = new CheckableEntryWidget(r.name~": ");
                if (r.requiresRecipe && !controller.characters[selectedCharacter].hasRecipe(r.name))
                {
                    w.textColor = "gray";
                }
                w.detailClicked = {
                    recipeDetail = RecipeDetailFrame.create(r, controller.wisdom, controller.characters);
                };
                auto times = new TextWidget(null, format("%s 回"d, kv.value));
                return [w, times];
            }).each!(ws => rContents.addChildren(ws));
        rList.contentWidget = rContents;
        rList.backgroundColor = "white";
        reqFrame.addChild(rList);

        reqFrame.addChild(new TextWidget(null, "余り物"d));
        auto lList = new ScrollWidget;
        auto lContents = new TableLayout;
        lContents.colCount = 2;
        auto lefts = leftovers.keys.empty
                     ? [[new TextWidget(null, "なし"d)]]
                     : leftovers.byKeyValue.map!((kv) {
                             auto w = new LinkWidget(null, kv.key~": ");
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
                             auto num = new TextWidget(null, format("%s 個"d, kv.value));
                             return [w, num];
                         }).array;
        lefts.to!(Widget[][]).each!(ws => lContents.addChildren(ws));
        lList.contentWidget = lContents;
        lList.backgroundColor = "white";
        reqFrame.addChild(lList);
    }

    void showRequiredMaterials(OrderedMap!(MaterialTuple[dstring]) materials)
    {
        auto reqFrame = childById("reqMatsBase");
        reqFrame.removeAllChildren;

        auto matCap = new HorizontalLayout;
        matCap.addChild(new TextWidget(null, "必要素材 (所持数/必要数)"d));
        auto clearButton = new Button(null, "全部しまう"d);
        matCap.addChild(clearButton);
        reqFrame.addChild(matCap);

        auto mList = new ScrollWidget;
        auto mContents = new TableLayout("reqMats");
        mContents.colCount = 3;
        materials.byKeyValue.map!((kv) {
                auto w = new CheckableEntryWidget(kv.key~": ");
                if (kv.value.intermediate)
                {
                    w.textColor = "blue";
                }
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
                auto own = new EditIntLine("own");
                // own.contentChange = (EditableContent content) {
                //     auto product = childById("itemQuery").text;
                //     assert(product in controller.wisdom.rrecipeList);
                //     auto txt = childById("numQuery").text;
                //     if (!txt.empty)
                //     {
                //         auto owned = ownedMaterials;
                //         controller.showRecipeMaterials(product, txt.to!int, owned);
                //     }
                // };
                auto num = new TextWidget(null, format("/%s 個"d, kv.value.num));
                return [w, own, num];
            }).each!(ws => mContents.addChildren(ws));

        mList.contentWidget = mContents;
        mList.backgroundColor = "white";

        reqFrame.addChild(mList);

        clearButton.click = (Widget _) {
            iota(1, mContents.childCount, mContents.colCount).each!(idx => mContents.child(idx).text = "0");
            return true;
        };
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
                    id: result
                    TextWidget { text: "必要レシピ情報" }
                    HorizontalLayout {
                        padding: 1
                        VerticalLayout {
                            id: reqRecipesBase
                        }
                        VerticalLayout {
                            id: reqMatsBase
                        }
                    }
                }
            }
        });
    return layout;
}

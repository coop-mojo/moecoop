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
module coop.controller.skill_tab_frame_controller;

import dlangui;

import std.algorithm;
import std.exception;
import std.range;
import std.traits;
import std.typecons;

import coop.model.item;
import coop.model.wisdom;
import coop.view.item_detail_frame;
import coop.view.recipe_tab_frame;
import coop.view.recipe_detail_frame;
import coop.controller.recipe_tab_frame_controller;

class SkillTabFrameController: RecipeTabFrameController
{
    this(RecipeTabFrame frame, dstring[] categories)
    {
        super(frame, categories);
        with(frame.childById!ComboBox("sortBy"))
        {
            items = [EnumMembers!SortOrder][0..$-1];
            selectedItemIndex = 0;
        }
    }

protected:
    override dstring[][dstring] recipeChunks(Wisdom wisdom)
    {
        return wisdom.recipeCategories.map!(c => tuple(c, wisdom.recipesIn(Category(c)).keys)).assocArray;
    }

    override dstring[][dstring] recipeChunksFor(Wisdom wisdom, dstring cat)
    {
        return [tuple(cat, wisdom.recipesIn(Category(cat)).keys)].assocArray;
    }

    override bool useHeader(RecipeTabFrame frame)
    {
        return frame.sortKey == SortOrder.BySkill;
    }

    override Widget[] toRecipeWidgets(dstring[] recipes, dstring category)
    {
        return recipes.map!((r) {
                import std.stdio;
                auto ret = new RecipeEntryWidget(r);
                auto binders = wisdom.bindersFor(r);

                ret.filedStateChanged = (bool marked) {
                    auto c = frame_.selectedCharacter;
                    if (marked)
                    {
                        binders.each!(b => characters[c].markFiledRecipe(r, b));
                    }
                    else
                    {
                        binders.each!(b => characters[c].unmarkFiledRecipe(r, b));
                    }
                };
                ret.checked = binders.canFind!(b => characters[frame_.selectedCharacter].hasRecipe(r, b));
                ret.enabled = binders.length == 1;

                ret.detailClicked = {
                    frame_.unhighlightDetailRecipe;
                    scope(exit) frame_.highlightDetailRecipe;


                    auto rDetail = wisdom.recipeFor(r);
                    if (rDetail.name.empty)
                    {
                        rDetail.name = r;
                        rDetail.remarks = "作り方がわかりません（´・ω・｀）";
                    }
                    frame_.recipeDetail = RecipeDetailFrame.create(rDetail, wisdom, characters);

                    auto itemNames = rDetail.products.keys;
                    enforce(itemNames.length <= 2);
                    if (itemNames.empty)
                    {
                        // レシピ情報が完成するまでの間に合わせ
                        itemNames = [ r~"のレシピで作れる何か" ];
                    }

                    frame_.hideItemDetail(1);

                    itemNames.enumerate(0).each!((idx_name) {
                            auto idx = idx_name[0];
                            dstring name = idx_name[1];
                            Item item;
                            if (auto i = name in wisdom.itemList)
                            {
                                item = *i;
                            }
                            else
                            {
                                item.name = name;
                                item.remarks = "細かいことはわかりません（´・ω・｀）";
                            }

                            frame_.showItemDetail(idx);
                            frame_.setItemDetail(ItemDetailFrame.create(item, wisdom), idx);
                        });
                };
                return cast(Widget)ret;
            }).array;
    }

    override Widget[][] toRecipeTable(Widget[] recipes, int nColumns)
    {
        import std.math;
        return recipes.empty ? [] : recipes.chunks((recipes.length.to!real/nColumns).ceil.to!int).array;
    }
}

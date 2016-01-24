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
module coop.controller.recipe_frame_controller;

import dlangui;

import std.algorithm;
import std.container.util;
import std.exception;
import std.file;
import std.range;
import std.regex;
import std.typecons;

import coop.migemo;
import coop.model.character;
import coop.model.config;
import coop.model.item;
import coop.model.recipe;
import coop.model.wisdom;
import coop.view.item_detail_frame;
import coop.view.recipe_base_frame;
import coop.view.recipe_detail_frame;

class RecipeFrameController
{
    this(RecipeBaseFrame frame, Wisdom wisdom, Character[] chars, Config config)
    {
        frame_ = frame;
        wisdom_ = wisdom;
        chars_ = chars;
        config_ = config;
        frame_.queryFocused = {
            if (frame_.queryText == defaultTxtMsg)
            {
                frame_.queryText = ""d;
            }
        };

        frame_.queryChanged =
            frame_.metaSearchOptionChanged =
            frame_.migemoOptionChanged =
            frame_.categoryChanged =
            frame_.nColumnChanged = {
            showBinderRecipes;
        };

        // モーダル窓が作れないから設定を即時反映できない
        if (config_.migemoDLL.exists && config_.migemoDict.exists)
        {
            version(Windows) {
                frame_.disableMigemoBox;
            } else {
                import std.path;
                migemo_ = new Migemo(config_.migemoDLL, config_.migemoDict);
                migemo_.load(buildPath("resource", "dict", "moe-dict"));
                enforce(migemo_.isEnable);
            }
        }
        else
        {
            frame_.disableMigemoBox;
        }

        Recipe dummy;
        dummy.techniques = make!(typeof(dummy.techniques))(cast(dstring)[]);
        frame_.recipeDetail = RecipeDetailFrame.create(dummy, wisdom_);

        frame_.hideItemDetail(0);
        frame_.hideItemDetail(1);
    }

    auto showBinderRecipes()
    {
        import std.string;

        if (frame_.queryText == defaultTxtMsg)
        {
            frame_.queryText = ""d;
        }

        auto query = frame_.queryText.removechars(r"/[ 　]/");
        if (frame_.useMetaSearch && query.empty)
            return;

        dstring[][dstring] recipes;
        if (frame_.useMetaSearch)
        {
            recipes = wisdom_.binders.map!(b => tuple(b, wisdom_.recipesIn(Binder(b)))).assocArray;
        }
        else
        {
            auto binder = frame_.selectedCategory;
            recipes = [tuple(binder, wisdom_.recipesIn(Binder(binder)))].assocArray;
        }

        if (!query.empty)
        {
            bool delegate(dstring) matchFun =
                s => !find(s.removechars(r"/[ 　]/"), boyerMooreFinder(query)).empty;
            if (frame_.useMigemo)
            {
                try{
                    auto q = migemo_.query(query).regex;
                    matchFun = s => !s.removechars(r"/[ 　]/").matchFirst(q).empty;
                } catch(RegexException e) {
                    // use default matchFun
                }
            }
            recipes = recipes
                      .byKeyValue
                      .map!(kv =>
                            tuple(kv.key,
                                  kv.value.filter!matchFun.array))
                      .assocArray;
        }

        Widget[] tableElems;
        if (frame_.useMetaSearch)
        {
            tableElems = recipes.byKeyValue.map!((kv) {
                    auto binder = kv.key;
                    auto recipes = kv.value;
                    if (recipes.empty)
                        return cast(Widget[])[];
                    Widget header = new TextWidget("", binder);
                    header.backgroundColor = 0xCCCCCC;
                    return header~toBinderRecipeWidgets(binder, kv.value);
                }).join;
        }
        else
        {
            auto binder = frame_.selectedCategory;
            tableElems = toBinderRecipeWidgets(binder, recipes[binder]);
        }
        frame_.showRecipeList(tableElems, frame_.numberOfColumns);
    }

    auto categories(dstring[] cats)
    {
        frame_.categories = cats;
    }
private:

    auto toBinderRecipeWidgets(dstring binder, dstring[] recipes)
    {
        return recipes.map!((r) {
                import std.stdio;
                auto ret = new RecipeEntryWidget(r);

                ret.filedStateChanged = (bool marked) {
                    if (marked)
                    {
                        chars_.front.markFiledRecipe(r, binder);
                    }
                    else
                    {
                        chars_.front.unmarkFiledRecipe(r, binder);
                    }
                };
                ret.checked = chars_.front.hasRecipe(r, binder);
                ret.detailClicked = {
                    auto rDetail = wisdom_.recipeFor(r);
                    if (rDetail.name.empty)
                    {
                        rDetail.name = r;
                        rDetail.remarks = "作り方がわかりません（´・ω・｀）";
                    }
                    frame_.recipeDetail = RecipeDetailFrame.create(rDetail, wisdom_);

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
                            if (auto i = name in wisdom_.itemList)
                            {
                                item = *i;
                            }
                            else
                            {
                                item.name = name;
                                item.remarks = "細かいことはわかりません（´・ω・｀）";
                            }

                            frame_.showItemDetail(idx);
                            frame_.setItemDetail(ItemDetailFrame.create(item, wisdom_), idx);
                        });
                };
                return cast(Widget)ret;
            }).array;
    }

    enum defaultTxtMsg = "見たいレシピ";
    RecipeBaseFrame frame_;
    Config config_;
    Migemo migemo_;
    Character[] chars_;
    Wisdom wisdom_;
}

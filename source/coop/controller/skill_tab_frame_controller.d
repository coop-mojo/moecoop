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
import coop.view.skill_tab_frame;
import coop.view.recipe_detail_frame;
import coop.controller.main_frame_controller;

class SkillTabFrameController
{
    mixin TabController;

    this(SkillTabFrame frame)
    {
        frame_ = frame;
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
            frame_.characterChanged =
            frame_.nColumnChanged =
            frame_.sortKeyChanged = {
            showBinderRecipes;
        };

        Recipe dummy;
        dummy.techniques = make!(typeof(dummy.techniques))(cast(dstring)[]);
        frame_.recipeDetail = RecipeDetailFrame.create(dummy, wisdom, characters);

        frame_.characters = characters.keys.sort().array;

        frame_.hideItemDetail(0);
        frame_.hideItemDetail(1);

        if (migemo)
        {
            frame_.enableMigemoBox;
        }
        else
        {
            frame_.disableMigemoBox;
        }
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
            recipes = wisdom.recipeCategories.map!(c => tuple(c, wisdom.recipesIn(Category(c)).keys)).assocArray;
        }
        else
        {
            auto c = frame_.selectedCategory;
            recipes = [tuple(c, wisdom.recipesIn(Category(c)).keys)].assocArray;
        }

        if (!query.empty)
        {
            bool delegate(dstring) matchFun =
                s => !find(s.removechars(r"/[ 　]/"), boyerMooreFinder(query)).empty;
            if (frame_.useMigemo)
            {
                try{
                    auto q = migemo.query(query).regex;
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
        auto chunks = recipes.byKeyValue.map!((kv) {
                auto category = kv.key;
                auto rs = kv.value;
                if (rs.empty)
                    return [tuple(category, rs.array)];
                switch(frame_.sortKey)
                {
                case "スキル値順"d:
                    auto levels(dstring s) {
                        auto arr = wisdom.recipeFor(s).requiredSkills.byKeyValue.map!(a => tuple(a.key, a.value)).array;
                        arr.multiSort!("a[0] < b[0]", "a[1] < b[1]");
                        return arr;
                    }
                    auto lvToStr(Tuple!(dstring, real)[] tpls)
                    {
                        return tpls.map!(t => format("%s (%s)"d, t.tupleof)).join(", ");
                    }
                    auto arr = rs.map!(a => tuple(a, levels(a))).array;
                    arr.multiSort!("a[1] < b[1]", "a[0] < b[0]");
                    return arr.chunkBy!"a[1]"
                        .map!(a => tuple(lvToStr(a[0]), a[1].map!"a[0]".array))
                        .array;
                case "名前順"d:
                    return [tuple(category, rs.sort().array)];
                default:
                    assert(false);
                }
            }).joiner;
        tableElems = chunks.filter!"!a[1].empty".map!((tpl) {
                Widget[] header = [];
                if (frame_.useMetaSearch || frame_.sortKey == "スキル値順")
                {
                    Widget hd = new TextWidget("", tpl[0]);
                    hd.backgroundColor = 0xCCCCCC;
                    header = [hd];
                }
                return header~toBinderRecipeWidgets(tpl[0], tpl[1]);
            }).join;
        frame_.showRecipeList(tableElems, frame_.numberOfColumns);
    }

    @property auto categories(dstring[] cats)
    {
        frame_.categories = cats;
    }
private:
    auto toBinderRecipeWidgets(dstring category, dstring[] recipes)
    {
        return recipes.map!((r) {
                import std.stdio;
                auto ret = new RecipeEntryWidget(r);
                auto binders = wisdom.bindersFor(r);

                if (binders.empty)
                {
                    ret.enabled = false;
                }
                else
                {
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
                }
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

    enum defaultTxtMsg = "見たいレシピ";
}

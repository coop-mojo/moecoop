/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.recipe_tab_frame_controller;

import dlangui;

import std.algorithm;
import std.container.util;
import std.range;
import std.string;
import std.typecons;

import coop.model.recipe;
import coop.model.wisdom;
import coop.view.recipe_tab_frame;
import coop.view.recipe_detail_frame;
import coop.controller.main_frame_controller;

enum SortOrder {
    BySkill       = "スキル値順"d,
    ByName        = "名前順",
    ByBinderOrder = "バインダー順",
}

alias RecipePair = Tuple!(dstring, "category", dstring[], "recipes");

abstract class RecipeTabFrameController
{
    mixin TabController;

    this(RecipeTabFrame frame, dstring[] cats)
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
            assert(frame_);
            if (frame_.controller)
            {
                showRecipeNames;
            }
        };

        Recipe dummy;
        dummy.techniques = make!(typeof(dummy.techniques))(null);
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
        frame_.categories = cats;
    }

    auto showRecipeNames()
    {
        if (frame_.queryText == defaultTxtMsg)
        {
            frame_.queryText = ""d;
        }

        auto query = frame_.queryText.removechars(r"/[ 　]/");

        // メタ検索 + 検索欄が空 -> 全部の候補がでてくる
        // 意味がないのでこの場合には何もせず処理を終了する
        if (frame_.useMetaSearch && query.empty)
            return;

        dstring[][dstring] recipes;
        if (frame_.useMetaSearch)
        {
            recipes = recipeChunks(wisdom);
        }
        else
        {
            auto c = frame_.selectedCategory;
            recipes = recipeChunksFor(wisdom, c);
        }

        if (!query.empty)
        {
            auto queryFun = matchFunFor(query);
            recipes = recipes
                      .byKeyValue
                      .map!(kv =>
                            tuple(kv.key,
                                  kv.value.filter!queryFun.array))
                      .filter!"!a[1].empty"
                      .assocArray;
        }

        auto elems = recipes.byKeyValue.map!((kv) {
                auto category = kv.key;
                auto rs = kv.value;

                if (rs.empty)
                    return [RecipePair(category, rs.array)];

                final switch(frame_.sortKey) with(SortOrder)
                {
                case BySkill:
                    auto levels(dstring s) {
                        auto arr = wisdom.recipeFor(s).requiredSkills.byKeyValue.map!(a => tuple(a.key, a.value)).array;
                        arr.multiSort!("a[0] < b[0]", "a[1] < b[1]");
                        return arr;
                    }
                    auto lvToStr(Tuple!(dstring, real)[] tpls)
                    {
                        return tpls.map!(t => format("%s (%.1f)"d, t.tupleof)).join(", ");
                    }
                    auto arr = rs.map!(a => tuple(a, levels(a))).array;
                    arr.multiSort!("a[1] < b[1]", "a[0] < b[0]");
                    return arr.chunkBy!"a[1]"
                        .map!(a => RecipePair(lvToStr(a[0]), a[1].map!"a[0]".array))
                        .array;
                case ByName:
                    return [RecipePair(category, rs.sort().array)];
                case ByBinderOrder:
                    return [RecipePair(category, rs.array)];
                }
            }).joiner;

        frame_.showRecipeList(elems);
    }

protected:
    enum defaultTxtMsg = "見たいレシピ";

    abstract dstring[][dstring] recipeChunks(Wisdom);
    abstract dstring[][dstring] recipeChunksFor(Wisdom, dstring);

private:
    auto matchFunFor(dstring query)
    {
        import std.regex;
        if (frame_.useMigemo)
        {
            try{
                auto q = migemo.query(query).regex;
                return (dstring s) => !s.removechars(r"/[ 　]/").matchFirst(q).empty;
            } catch(RegexException e) {
                // use default matchFun
            }
        }
        else
        {
            return (dstring s) => !find(s.removechars(r"/[ 　]/"), boyerMooreFinder(query)).empty;
        }
        assert(false);
    }
}

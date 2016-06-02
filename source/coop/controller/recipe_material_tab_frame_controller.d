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
module coop.controller.recipe_material_tab_frame_controller;

import dlangui;

import std.algorithm;
import std.container;
import std.math;
import std.range;
import std.regex;
import std.string;
import std.typecons;

import coop.model.item;
import coop.model.recipe;
import coop.view.recipe_material_tab_frame;
import coop.view.recipe_detail_frame;
import coop.controller.main_frame_controller;

class RecipeMaterialTabFrameController
{
    mixin TabController;

    this(RecipeMaterialTabFrame frame)
    {
        frame_ = frame;
        frame_.characters = characters.keys.sort().array;

        Recipe dummy;
        dummy.techniques = make!(typeof(dummy.techniques))(cast(dstring)[]);
        frame_.recipeDetail = RecipeDetailFrame.create(dummy, wisdom, characters);

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

        with(frame_.childById!EditLine("numQuery"))
        {
            contentChange = (EditableContent content) {
                auto txt = content.text;
                auto product = frame_.childById("itemQuery").text;
                if (!txt.empty && txt.to!int > 0 && product in wisdom.rrecipeList)
                {
                    showRecipeMaterials(product, txt.to!int);
                }
                else
                {
                    frame_.hideResult;
                }
            };
        }

        with(frame_.childById!EditLine("itemQuery"))
        {
            contentChange = (EditableContent content) {
                showProductCandidate(content.text);
            };
        }
    }

    auto showProductCandidate(dstring queryText)
    {
        enum regex = r"^\d+$"d;
        auto query = queryText.removechars(r"/[ 　]/");
        if (query.empty)
        {
            return;
        }
        auto queryFun = matchFunFor(query);
        auto candidates = wisdom.rrecipeList.keys.filter!queryFun.array;

        frame_.showCandidates(candidates);
        auto nq = frame_.childById("numQuery").text;
        if (queryText in wisdom.rrecipeList && nq.matchFirst(ctRegex!regex) && nq.to!int > 0)
        {
            showRecipeMaterials(queryText, nq.to!int);
        }
        else
        {
            frame_.hideResult;
        }
    }

    auto showRecipeMaterials(dstring item, int num, int[dstring] leftovers = (int[dstring]).init)
    {
        alias TargetTuple = Tuple!(dstring, "target", int, "num");
        auto rList = wisdom.rrecipeList;
        int[Recipe] requiredRecipes;
        int[dstring] requiredMaterials;

        auto useLeftovers(dstring it, int n)
        {
            if (auto left = it in leftovers)
            {
                if (n < *left)
                {
                    leftovers[item] -= n;
                    n = 0;
                }
                else
                {
                    n -= *left;
                    leftovers.remove(it);
                }
            }
            return TargetTuple(it, n);
        }

        TargetTuple[] queue = [useLeftovers(item, num)];
        while(!queue.empty)
        {
            auto it = queue.front;
            queue.popFront;
            if (it.target !in rList)
            {
                requiredMaterials[it.target] += it.num;
                continue;
            }
            auto rNames = rList[it.target];
            auto recipe = wisdom.recipeFor(rNames[0]);

            auto numApplied = (it.num.to!real/recipe.products[it.target]).ceil.to!int;
            requiredRecipes[recipe] += numApplied;

            // コンバイン時の余り物を追加
            foreach(mat, n; recipe.products)
            {
                if (mat == it.target)
                {
                    if (n*numApplied > it.num)
                    {
                        leftovers[mat] += n*numApplied-it.num;
                    }
                }
                else
                {
                    leftovers[mat] += n*numApplied;
                }
            }

            queue ~= recipe.ingredients
                           .byKeyValue
                           .map!(kv => tuple(kv.key, kv.value*numApplied))
                           .map!(kv => useLeftovers(kv[0], kv[1])) // leftovers に対して破壊的なので注意！
                           .array;
        }

        // DAG を構成
        // トポロジカルソートで表示順を決定
        return frame_.showRecipeMaterials(requiredRecipes, requiredMaterials, leftovers);
    }
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

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

import coop.util;
import coop.model.item;
import coop.model.recipe;
import coop.view.recipe_material_tab_frame;
import coop.view.recipe_detail_frame;
import coop.controller.main_frame_controller;

alias MaterialTuple = Tuple!(int, "num", bool, "intermediate");

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
                if (txt.empty || txt.to!int == 0)
                {
                    return;
                }
                else if (product in wisdom.rrecipeList)
                {
                    auto owned = frame_.requiredMaterialsAreAlreadyShown
                                 ? frame_.ownedMaterials : (int[dstring]).init;
                    showRecipeMaterials(product, txt.to!int, owned);
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
        auto query = queryText.removechars(r"/[ 　]/");
        if (query.empty)
        {
            return;
        }
        auto queryFun = matchFunFor(query);
        auto candidates = wisdom.rrecipeList.keys.filter!queryFun.array;

        frame_.showCandidates(candidates);
        auto nq = frame_.childById("numQuery").text;
        if (queryText in wisdom.rrecipeList && nq.to!int > 0)
        {
            showRecipeMaterials(queryText, nq.to!int);
        }
        else
        {
            frame_.hideResult;
        }
    }

    auto showRecipeMaterials(dstring item, int num, int[dstring] owned = (int[dstring]).init, bool forRecipeOnly = false)
    {
        alias TargetTuple = Tuple!(dstring, "target", int, "num");

        auto leftovers = owned.dup;
        auto rList = wisdom.rrecipeList;
        OrderedMap!(int[Recipe]) requiredRecipes;
        OrderedMap!(MaterialTuple[dstring]) requiredMaterials;

        assert(false, "この関数はまるごと書き換える可能性あり");
        auto consumeLeftOvers(dstring it, int n, int usedForRecipe = 0) {
            if (auto left = it in leftovers)
            {
                if (n+usedForRecipe < *left)
                {
                    leftovers[it] -= n;
                    n = 0;
                    assert(leftovers[it] > 0);
                }
                else
                {
                    n -= *left;
                    leftovers.remove(it);
                }
                assert(n >= 0);
            }
            else
            {
            }
            return n;
        }
        auto useLeftovers(dstring it, int n)
        {
            if (auto left = it in leftovers)
            {
                if (n < *left)
                {
                    leftovers[it] -= n;
                    n = 0;
                    assert(leftovers[it] > 0);
                }
                else
                {
                    n -= *left;
                    leftovers.remove(it);
                }
                assert(n >= 0);
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
                if (it.target !in requiredMaterials)
                {
                    requiredMaterials[it.target] = MaterialTuple.init;
                }
                requiredMaterials[it.target].num += it.num;
                continue;
            }
            else if (it.target != item)
            {
                if (it.target !in requiredMaterials)
                {
                    requiredMaterials[it.target] = MaterialTuple.init;
                }
                requiredMaterials[it.target].num += it.num;
                requiredMaterials[it.target].intermediate = true;
            }
            auto rNames = rList[it.target];
            auto recipe = wisdom.recipeFor(rNames[0]);

            auto req = it.target in leftovers ? max(it.num-leftovers[it.target], 0) : it.num;
            auto nGen = recipe.products[it.target];
            auto numApplied = (req.to!real/nGen).ceil.to!int;
            assert(it.num-leftovers.get(it.target, 0) <= nGen*numApplied);
            it.num = consumeLeftOvers(it.target, it.num, nGen*numApplied);
            assert(true);
            if (numApplied == 0)
            {
                continue;
            }

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
                           .map!(kv => TargetTuple(kv.key, kv.value*numApplied))
                           .array;
        }

        // DAG を構成
        // トポロジカルソートで表示順を決定
        if (forRecipeOnly)
        {
            frame_.showRequiredRecipes(requiredRecipes, leftovers);
        }
        else
        {
            frame_.showRequiredElements(requiredRecipes, requiredMaterials, leftovers);
        }
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

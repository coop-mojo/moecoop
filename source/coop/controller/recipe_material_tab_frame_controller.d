/**
 * Authors: Mojo
 * License: MIT License
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
        dummy.techniques = make!(typeof(dummy.techniques))(null);
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
        frame_.migemoOptionChanged = {
            auto txtBox = frame_.childById("itemQuery");
            showProductCandidate(txtBox.text);
        };

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

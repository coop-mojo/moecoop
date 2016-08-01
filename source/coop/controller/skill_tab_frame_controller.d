/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.skill_tab_frame_controller;

import dlangui;

import std.algorithm;
import std.range;
import std.traits;
import std.typecons;

import coop.model.wisdom;
import coop.view.recipe_tab_frame;
import coop.controller.recipe_tab_frame_controller;

class SkillTabFrameController: RecipeTabFrameController
{
    this(RecipeTabFrame frame, dstring[] categories)
    {
        import std.math: ceil;

        super(frame, categories);
        frame.relatedBindersFor = (recipe, _) => wisdom.bindersFor(recipe);
        frame.tableColumnLength = (nRecipes, nColumns) => (nRecipes.to!real/nColumns).ceil.to!int;
        with(frame.childById!ComboBox("sortBy"))
        {
            items = [EnumMembers!SortOrder][0..$-1];
            selectedItemIndex = 0;
        }
        auto revSearch = new CheckBox("revSearch", "逆引き検索"d);
        frame.childById("searchOptions").addChild(revSearch);
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
}

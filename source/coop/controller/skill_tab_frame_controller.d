/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.skill_tab_frame_controller;

import coop.controller.recipe_tab_frame_controller;

class SkillTabFrameController: RecipeTabFrameController
{
    import coop.view.recipe_tab_frame;

    this(RecipeTabFrame frame, dstring[] categories)
    {
        import dlangui;
        import std.conv;
        import std.math: ceil;
        import std.traits;

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
    import coop.core.wisdom;

    override dstring[][dstring] recipeChunks(Wisdom wisdom)
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        return wisdom.recipeCategories.map!(c => tuple(c, wisdom.recipesIn(Category(c)).keys)).assocArray;
    }

    override dstring[][dstring] recipeChunksFor(Wisdom wisdom, dstring cat)
    {
        import std.range;
        import std.typecons;

        return [tuple(cat, wisdom.recipesIn(Category(cat)).keys)].assocArray;
    }
}

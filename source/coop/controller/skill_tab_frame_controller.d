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

    override void showRecipeNames()
    {
        import std.regex;
        import std.typecons;
        import coop.core.wisdom: Category;

        auto query = frame_.queryBox.text == frame_.defaultMessage ? ""d : frame_.queryBox.text;
        if (frame_.useMetaSearch && query.matchFirst(r"/^\s*$/"d))
        {
            return;
        }

        auto recipes = model.getRecipeList(query, Category(frame_.selectedCategory),
                                           cast(Flag!"useMetaSearch")frame_.useMetaSearch, cast(Flag!"useMigemo")frame_.useMigemo,
                                           cast(Flag!"useReverseSearch")frame_.useReverseSearch,
                                           cast(SortOrder)frame_.sortKey);
        frame_.showRecipeList(recipes);
    }
}

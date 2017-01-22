/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.binder_tab_frame_controller;

import coop.controller.recipe_tab_frame_controller;

class BinderTabFrameController: RecipeTabFrameController
{
    import coop.view.recipe_tab_frame;

    this(RecipeTabFrame frame, dstring[] categories)
    {
        import dlangui;
        import std.traits;

        import coop.core;

        super(frame, categories);
        frame.relatedBindersFor = (recipe, binder) => [binder];
        frame.tableColumnLength = (_, nColumns) => MaxNumberOfBinderPages/nColumns;

        frame.childById!ComboBox("sortBy").selectedItemIndex = [EnumMembers!SortOrder].length-1;
        frame.childById("sortBox").visibility = Visibility.Gone;
    }

    override void showRecipeNames()
    {
        import std.algorithm;
        import std.conv;
        import std.regex;
        import std.typecons;
        import coop.core.wisdom: Binder;

        auto query = frame_.queryBox.text == frame_.defaultMessage ? ""d : frame_.queryBox.text;
        if (frame_.useMetaSearch && query.matchFirst(ctRegex!r"^\s*$"d))
        {
            return;
        }

        auto recipes = model.getRecipeList(query, Binder(frame_.selectedCategory.to!string),
                                           cast(Flag!"useMetaSearch")frame_.useMetaSearch, cast(Flag!"useMigemo")frame_.useMigemo);
        frame_.showRecipeList(recipes.map!(r => Tuple!(dstring, "category",
                                                       dstring[], "recipes")(r.category.to!dstring,
                                                                             r.recipes.to!(dstring[]))));
    }
private:
    enum MaxNumberOfBinderPages = 128;
}

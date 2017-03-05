/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.controller.binder_tab_frame_controller;

import coop.mui.controller.recipe_tab_frame_controller;

class BinderTabFrameController: RecipeTabFrameController
{
    import coop.mui.view.recipe_tab_frame;

    this(RecipeTabFrame frame, dstring[] categories)
    {
        import dlangui;
        import std.traits;

        import coop.core: SortOrder;

        super(frame, categories);
        frame.relatedBindersFor = (recipe, binder) => [binder];
        frame.tableColumnLength = (_, nColumns) => MaxNumberOfBinderPages/nColumns;

        frame.childById!ComboBox("sortBy").selectedItemIndex = [EnumMembers!SortOrder].length-1;
        frame.childById("sortBox").visibility = Visibility.Gone;
    }

    override void showRecipeNames()
    {
        import std.algorithm;
        import std.array;
        import std.conv;
        import std.regex;
        import std.typecons;

        auto query = frame_.queryBox.text == frame_.defaultMessage ? ""d : frame_.queryBox.text;
        if (frame_.useMetaSearch && query.matchFirst(ctRegex!r"^\s*$"d))
        {
            return;
        }

        auto binders = frame_.useMetaSearch ? model.getBinderCategories.バインダー一覧.map!"a.バインダー名.to!dstring".array
                       : [frame_.selectedCategory];

        alias RecipePair = Tuple!(dstring, "category", dstring[], "recipes");

        auto recipes = binders.map!(b => RecipePair(b, model.getBinderRecipes(b.to!string, query.to!string,
                                                                              cast(Flag!"useMigemo")frame_.useMigemo,
                                                                              No.useReverseSearch, "default")
                                                            .レシピ一覧
                                                            .map!"a.レシピ名.to!dstring"
                                                            .array)).array;
        frame_.showRecipeList(recipes);
    }
private:
    enum MaxNumberOfBinderPages = 128;
}

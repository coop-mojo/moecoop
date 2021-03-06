/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.controller.recipe_tab_frame_controller;

import std.typecons;
import coop.mui.model.wisdom_adapter;

alias RecipePair = Tuple!(dstring, "category", RecipeLink[], "recipes");

abstract class RecipeTabFrameController
{
    import coop.mui.view.recipe_tab_frame;
    import coop.mui.controller.main_frame_controller;

    mixin TabController;

    this(RecipeTabFrame frame, dstring[] cats)
    {
        import std.algorithm;
        import std.container.util;
        import std.range;

        import coop.mui.model.wisdom_adapter;
        import coop.mui.view.recipe_detail_frame;

        frame_ = frame;

        frame_.queryChanged =
            frame_.metaSearchOptionChanged =
            frame_.migemoOptionChanged =
            frame_.categoryChanged =
            frame_.revOptionChanged =
            frame_.characterChanged =
            frame_.nColumnChanged =
            frame_.sortKeyChanged = {
            assert(frame_);
            if (frame_.controller)
            {
                showRecipeNames;
            }
        };

        frame_.recipeDetail = RecipeDetailFrame.create(""d, model, characters);

        frame_.charactersBox.items = characters.keys.sort().array;
        frame_.charactersBox.selectedItemIndex = 0;

        frame_.hideItemDetail(0);
        frame_.hideItemDetail(1);

        frame_.enableMigemoBox;
        frame_.categories = cats;
    }

    abstract void showRecipeNames();
}

/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.recipe_tab_frame_controller;

import std.typecons;

enum SortOrder {
    BySkill       = "スキル値順"d,
    ByName        = "名前順",
    ByBinderOrder = "バインダー順",
}

alias RecipePair = Tuple!(dstring, "category", dstring[], "recipes");

abstract class RecipeTabFrameController
{
    import coop.view.recipe_tab_frame;
    import coop.controller.main_frame_controller;

    mixin TabController;

    this(RecipeTabFrame frame, dstring[] cats)
    {
        import std.algorithm;
        import std.container.util;
        import std.range;

        import coop.core.recipe;
        import coop.view.recipe_detail_frame;

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

        if (model.migemoAvailable)
        {
            frame_.enableMigemoBox;
        }
        else
        {
            frame_.disableMigemoBox;
        }
        frame_.categories = cats;
    }

    abstract void showRecipeNames();
}

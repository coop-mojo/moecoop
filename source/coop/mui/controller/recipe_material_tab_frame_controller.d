/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.controller.recipe_material_tab_frame_controller;

import std.typecons;

alias MaterialTuple = Tuple!(int, "num", bool, "intermediate");

class RecipeMaterialTabFrameController
{
    import coop.mui.controller.main_frame_controller;
    import coop.mui.view.recipe_material_tab_frame;

    mixin TabController;

    this(RecipeMaterialTabFrame frame)
    {
        import std.algorithm;
        import std.container;
        import std.range;

        import coop.mui.model.wisdom_adapter;
        import coop.mui.view.recipe_detail_frame;

        frame_ = frame;
        frame_.charactersBox.items = characters.keys.sort().array;
        frame_.charactersBox.selectedItemIndex = 0;

        frame_.recipeDetail = RecipeDetailFrame.create(""d, model, characters);

        frame_.hideItemDetail(0);
        frame_.hideItemDetail(1);

        frame_.enableMigemoBox;
        frame_.migemoOptionChanged =
            frame_.fromIngredientsChanged =
            frame_.queryChanged = {
            auto txt = frame_.childById("itemQuery").text;
            showProductCandidate(txt);
        };
    }

    auto showProductCandidate(dstring query)
    {
        import std.algorithm;
        import std.array;
        import std.conv;
        import std.regex;

        if (query.matchFirst(ctRegex!r"^\s*$"d))
        {
            return;
        }
        auto candidates = model.getItems(query.to!string, frame_.useMigemo, true, frame_.searchFromIngredients)
                               .アイテム一覧
                               .map!"a.アイテム名.to!dstring"
                               .array;
        frame_.showCandidates(candidates.to!(dstring[]));
    }
}

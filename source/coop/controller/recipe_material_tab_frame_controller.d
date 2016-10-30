/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.recipe_material_tab_frame_controller;

import std.typecons;

alias MaterialTuple = Tuple!(int, "num", bool, "intermediate");

class RecipeMaterialTabFrameController
{
    import coop.controller.main_frame_controller;
    import coop.view.recipe_material_tab_frame;

    mixin TabController;

    this(RecipeMaterialTabFrame frame)
    {
        import std.algorithm;
        import std.container;
        import std.range;

        import coop.core.recipe;
        import coop.view.recipe_detail_frame;

        frame_ = frame;
        frame_.charactersBox.items = characters.keys.sort().array;
        frame_.charactersBox.selectedItemIndex = 0;

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
        frame_.migemoOptionChanged =
            frame_.queryChanged = {
            auto txt = frame_.childById("itemQuery").text;
            showProductCandidate(txt);
        };
    }

    auto showProductCandidate(dstring queryText)
    {
        import std.algorithm;
        import std.range;
        import std.string;

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
        import std.string;

        if (frame_.useMigemo)
        {
            import std.regex;
            try{
                auto q = migemo.query(query).regex;
                return (dstring s) => !s.removechars(r"/[ 　]/").matchFirst(q).empty;
            } catch(RegexException e) {
                // use default matchFun
            }
        }
        else
        {
            import std.algorithm;
            import std.range;

            return (dstring s) => !find(s.removechars(r"/[ 　]/"), boyerMooreFinder(query)).empty;
        }
        assert(false);
    }
}

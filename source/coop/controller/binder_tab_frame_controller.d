/**
 * Copyright: Copyright (c) 2016 Mojo
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

        super(frame, categories);
        frame.relatedBindersFor = (recipe, binder) => [binder];
        frame.tableColumnLength = (_, nColumns) => MaxNumberOfBinderPages/nColumns;

        frame.childById!ComboBox("sortBy").selectedItemIndex = [EnumMembers!SortOrder].length-1;
        frame.childById("sortBox").visibility = Visibility.Gone;
    }

protected:
    import coop.model.wisdom;

    override dstring[][dstring] recipeChunks(Wisdom wisdom)
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        return wisdom.binders.map!(b => tuple(b, wisdom.recipesIn(Binder(b)))).assocArray;
    }

    override dstring[][dstring] recipeChunksFor(Wisdom wisdom, dstring cat)
    {
        import std.range;
        import std.typecons;

        return [tuple(cat, wisdom.recipesIn(Binder(cat)))].assocArray;
    }

private:
    enum MaxNumberOfBinderPages = 128;
}

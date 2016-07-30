/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.binder_tab_frame_controller;

import dlangui;

import std.algorithm;
import std.range;
import std.traits;
import std.typecons;

import coop.model.wisdom;
import coop.view.recipe_tab_frame;
import coop.controller.recipe_tab_frame_controller;

class BinderTabFrameController: RecipeTabFrameController
{
    this(RecipeTabFrame frame, dstring[] categories)
    {
        super(frame, categories);
        frame.relatedBindersFor = (recipe, binder) => [binder];
        frame.tableColumnLength = (_, nColumns) => MaxNumberOfBinderPages/nColumns;

        frame.childById!ComboBox("sortBy").selectedItemIndex = [EnumMembers!SortOrder].length-1;
        frame.childById("sortBox").visibility = Visibility.Gone;
    }

protected:
    override dstring[][dstring] recipeChunks(Wisdom wisdom)
    {
        return wisdom.binders.map!(b => tuple(b, wisdom.recipesIn(Binder(b)))).assocArray;
    }

    override dstring[][dstring] recipeChunksFor(Wisdom wisdom, dstring cat)
    {
        return [tuple(cat, wisdom.recipesIn(Binder(cat)))].assocArray;
    }

private:
    enum MaxNumberOfBinderPages = 128;
}

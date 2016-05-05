/**
   MoeCoop
   Copyright (C) 2016  Mojo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

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
module coop.control.recipe_frame_controller;


import coop.view.recipe_base_frame;
import coop.model.config;
import coop.migemo;
import coop.model.wisdom;

class RecipeFrameController
{
    this(RecipeBaseFrame frame, Wisdom wisdom, Config config)
    {
        frame_ = frame;
        wisdom_ = wisdom;
        config_ = config;
        frame_.queryFocused = {
            if (frame_.queryText == defaultTxtMsg)
            {
                frame_.queryText = ""d;
            }
        };
    }

    auto showRecipeList()
    {
        import std.string;
        auto query = frame_.queryText.removechars(r"/[ 　]/");
        if (frame_.useMetaSearch && query.empty)
            return;

        // InputRange!BinderElement recipes; // BinderElement[] である必要はない
    }

    auto categories(dstring[] cats)
    {
        frame_.categories = cats;
    }
private:
    enum defaultTxtMsg = "見たいレシピ";
    RecipeBaseFrame frame_;
    Config config_;
    Migemo migemo_;
    Wisdom wisdom_;
}

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
module coop.view.recipe_material_tab_frame;

import dlangui;

import std.algorithm;

import coop.view.main_frame;
import coop.view.recipe_tab_frame;
import coop.view.recipe_detail_frame;
import coop.controller.recipe_material_tab_frame_controller;

class RecipeMaterialTabFrame: HorizontalLayout
{
    mixin TabFrame;

    this() { super(); }

    this(string id)
    {
        super(id);
        auto layout = new HorizontalLayout;
        addChild(layout);
        layout.margins = 20;
        layout.padding = 10;

        layout.addChild(recipeMaterialLayout);
        layout.addChild(recipeDetailsLayout);
        layout.layoutHeight(FILL_PARENT);
        layout.layoutWidth(FILL_PARENT);
    }

    @property auto characters(dstring[] chars)
    {
        auto charBox = childById!ComboBox("characters");
        auto selected = charBox.items.empty ? "存在しないユーザー" : charBox.selectedItem;
        charBox.items = chars;
        auto newIdx = chars.countUntil(selected).to!int;
        charBox.selectedItemIndex = newIdx == -1 ? 0 : newIdx;
    }

    @property auto selectedCharacter()
    {
        return childById!ComboBox("characters").selectedItem;
    }

    auto hideItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Gone;
    }

    auto showItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Visible;
    }

    @property auto recipeDetail()
    {
        return cast(RecipeDetailFrame)childById!FrameLayout("recipeDetail").child(0);
    }

    @property auto recipeDetail(Widget recipe)
    {
        auto frame = childById("recipeDetail");
        frame.removeAllChildren;
        frame.addChild(recipe);
    }

    @property auto disableMigemoBox()
    {
        with(childById!CheckBox("migemo"))
        {
            checked = false;
            enabled = false;
        }
    }

    @property auto enableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = true;
    }
}

auto recipeMaterialLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                HorizontalLayout {
                    TextWidget { text: "キャラクター" }
                    ComboBox {
                        id: characters
                    }
                }

                HorizontalLayout {
                    EditLine {
                        id: itemQuery
                        minWidth: 200
                        text: "作りたいアイテム"
                        /// 候補を出したい
                    }
                    EditLine {
                        id: numQuery
                        minWidth: 60
                        text: "個数"
                    }
                    CheckBox { id: migemo; text: "Migemo 検索" }
                }

                HorizontalLayout {
                    EditLine {
                        id: ownMaterial
                        minWidth: 200
                        text: "既に持っている素材"
                    }
                    EditLine {
                        id: ownMaterial
                        minWidth: 60
                        text: "個数"
                    }
                }

                VerticalLayout {
                    TextWidget { text: "検索結果" }
                    TableLayout {
                        padding: 5
                        colCount: 2
                        // 必要素材一覧を表示
                    }
                }
                FrameLayout {
                    id: recipeGraph
                    padding: 1
                }
            }
        });
    return layout;
}

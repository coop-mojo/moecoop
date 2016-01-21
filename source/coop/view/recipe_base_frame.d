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
module coop.view.recipe_base_frame;

import dlangui;

import coop.model.item;
import coop.model.recipe;

abstract class RecipeBaseFrame: HorizontalLayout
{
    this() { super(); }

    this(string id) {
        super(id);
        margins = 20;
        padding = 10;

        addChild(recipeListLayout);
        addChild(recipeDetailsLayout);
        layoutHeight(FILL_PARENT);
        layoutWidth(FILL_PARENT);
        with(childById!ComboBox("nColumns"))
        {
            items = [ "1列表示", "2列表示", "4列表示" ];
            selectedItemIndex = 2;
            itemClick = (Widget src, int idx) {
                nColumnChanged();
                return true;
            };
        }

        with(childById!EditLine("searchQuery"))
        {
            focusChange = (Widget src, bool checked) {
                queryFocused();
                return true;
            };
            keyEvent = (Widget src, KeyEvent e) {
                queryChanged();
                return false;
            };
        }
        childById!CheckBox("metaSearch").checkChange = (Widget src, bool checked) {
            metaSearchOptionChanged();
            return true;
        };

        childById!CheckBox("migemo").checkChange = (Widget src, bool checked) {
            migemoOptionChanged();
            return true;
        };

        childById!ComboBox("categories").itemClick = (Widget src, int idx) {
            categoryChanged();
            return true;
        };
    }

    @property auto categories(dstring[] cats)
    {
        childById!ComboBox("categories").items = cats;
    }

    @property auto selectedCategory()
    {
        return childById!ComboBox("categories").selectedItem;
    }

    @property auto recipeList(dstring[] recipes)
    {
    }

    @property auto recipeDetail(Recipe recipe)
    {
    }

    @property auto itemDedail(Item item, int idx)
    {
    }

    @property auto queryText()
    {
        return childById!EditLine("searchQuery").text;
    }

    @property auto queryText(dstring str)
    {
        childById!EditLine("searchQuery").text = str;
    }

    auto hideItemDetail(int idx)
    {
        childById("item"~idx.to!string).visibility = Visibility.Gone;
    }

    auto showItemDetail(int idx)
    {
        childById("item"~idx.to!string).visibility = Visibility.Visible;
    }

    @property auto numberOfColumns()
    {
        return childById!ComboBox("nColumns").selectedItem[0..1].to!int;
    }

    @property auto useMetaSearch()
    {
        return childById!CheckBox("metaSearch").checked;
    }

    @property auto useMigemo()
    {
        return childById!CheckBox("metaSearch").checked;
    }

    @property auto disableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = false;
    }

    @property auto enableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = true;
    }

    auto setCategoryName(dstring cat)
    {
        import std.format;
        childById("categoryCaption").text = cat;
        childById("metaSearch").text = format("全ての%sから検索"d, cat);
    }

    alias EventHandler = void delegate();
    EventHandler queryFocused;
    EventHandler queryChanged;
    EventHandler metaSearchOptionChanged;
    EventHandler migemoOptionChanged;
    EventHandler categoryChanged;
    EventHandler nColumnChanged;
}

auto recipeListLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                HorizontalLayout {
                    TextWidget { id: categoryCaption }
                    ComboBox {
                        id: categories
                    }
                }

                HorizontalLayout {
                    EditLine {
                        id: searchQuery
                        minWidth: 200
                        text: "見たいレシピ"
                    }
                    CheckBox {
                        id: metaSearch;
                    }
                    CheckBox { id: migemo; text: "Migemo 検索" }
                }

                HorizontalLayout {
                    TextWidget { text: "レシピ一覧" }
                    ComboBox { id: nColumns }
                }
                FrameLayout {
                    id: recipeList
                    padding: 1
                }
            }
        });
    return layout;
}

auto recipeDetailsLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                padding: 10
                minWidth: 400
                TextWidget { text: "レシピ情報" }
                FrameLayout {
                    id: recipeDetail
                    padding: 1
                    backgroundColor: "black"
                }

                VerticalLayout {
                    id: item1
                    TextWidget { text: "アイテム情報1" }
                    FrameLayout {
                        id: detail1
                        padding: 1
                        backgroundColor: "black"
                    }
                }

                VerticalLayout {
                    id: item2
                    TextWidget { text: "アイテム情報2" }
                    FrameLayout {
                        id: detail2
                        padding: 1
                        backgroundColor: "black"
                    }
                }
            }
        });
    return layout;
}

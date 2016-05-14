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
module coop.view.recipe_tab_frame;

import dlangui;
import dlangui.widgets.metadata;

import std.algorithm;
import std.exception;
import std.range;
import std.traits;

import coop.model.item;
import coop.util;

import coop.view.main_frame;
import coop.view.item_detail_frame;
import coop.view.recipe_detail_frame;
import coop.controller.recipe_tab_frame_controller;

class RecipeTabFrame: HorizontalLayout
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

        layout.addChild(recipeListLayout);
        layout.addChild(recipeDetailsLayout);
        layout.layoutHeight(FILL_PARENT);
        layout.layoutWidth(FILL_PARENT);
        with(childById!ComboBox("nColumns"))
        {
            items = ["1列表示"d, "2列表示", "4列表示"];
            selectedItemIndex = 2;
            itemClick = (Widget src, int idx) {
                nColumnChanged();
                return true;
            };
        }

        with(childById!ComboBox("sortBy"))
        {
            items = [EnumMembers!SortOrder];
            selectedItemIndex = 0;
            itemClick = (Widget src, int idx) {
                sortKeyChanged();
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

        childById!ComboBox("characters").itemClick = (Widget src, int idx) {
            characterChanged();
            return true;
        };

        childById!Button("editItem1").click = (Widget _) {
            import coop.view.item_edit_dialog;
            showItemEditDialog(root.window, childById!ItemDetailFrame("detail1"));
            return true;
        };

        childById!Button("editItem2").click = (Widget _) {
            import coop.view.item_edit_dialog;
            showItemEditDialog(root.window, childById!ItemDetailFrame("detail2"));
            return true;
        };
    }

    @property auto categories(dstring[] cats)
    {
        with(childById!ComboBox("categories"))
        {
            items = cats;
            selectedItemIndex = 0;
        }
    }

    @property auto selectedCategory()
    {
        return childById!ComboBox("categories").selectedItem;
    }

    @property auto characters(dstring[] chars)
    {
        auto charBox = childById!ComboBox("characters");
        auto selected = charBox.items.empty ? "存在しないユーザー" : charBox.selectedItem;
        charBox.items = chars;
        auto newIdx = chars.countUntil(selected).to!int;
        charBox.selectedItemIndex = newIdx == -1 ? 0 : newIdx;
    }

    auto updateCharacters(dstring[] chars)
    {
        characters = chars;
        characterChanged();
    }

    @property auto selectedCharacter()
    {
        return childById!ComboBox("characters").selectedItem;
    }

    auto showRecipeList(Pairs)(Pairs pairs)
        if (isInputRange!Pairs && is(ElementType!Pairs == RecipePair))
    {
        auto entries = toRecipeEntries(pairs);

        unhighlightDetailRecipe;
        scope(exit) highlightDetailRecipe;
        auto recipeList = childById("recipeList");
        recipeList.removeAllChildren;
        recipeList.backgroundColor = entries.empty ? "white" : "black";

        auto scroll = new ScrollWidget;
        auto horizontal = new HorizontalLayout;

        auto chs = entries.empty ? []
                                 : entries.chunks(tableColumnLength(entries.length,
                                                                    numberOfColumns)).array;
        chs.map!((rs) {
                auto col = new VerticalLayout;
                rs.each!(r => col.addChild(r));
                return col;
            })
            .each!(col => horizontal.addChild(col));
        scroll.contentWidget = horizontal;
        scroll.backgroundColor = "white";
        recipeList.addChild(scroll);
    }

    auto toRecipeEntries(Pairs)(Pairs pairs)
        if (isInputRange!Pairs && is(ElementType!Pairs == RecipePair))
    {
        return pairs.map!((pair) {
                auto category = pair.category;
                auto recipes = pair.recipes;

                Widget[] header = [];
                if (useMetaSearch || sortKey == SortOrder.BySkill)
                {
                    Widget hd = new TextWidget("", category);
                    hd.backgroundColor = 0xCCCCCC;
                    header = [hd];
                }
                return chain(header, recipes.map!(r => toRecipeWidget(r, category)).array);
            }).join.array;
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

    auto highlightDetailRecipe()
    {
        if (auto detailFrame = recipeDetail)
        {
            auto shownRecipe = detailFrame.name;
            if (auto item = childById("recipeList").childById!RecipeEntryWidget(shownRecipe.to!string))
            {
                item.highlight;
            }
        }
    }

    auto unhighlightDetailRecipe()
    {
        if (auto detailFrame = recipeDetail)
        {
            auto shownRecipe = detailFrame.name;
            if (auto item = childById("recipeList").childById!RecipeEntryWidget(shownRecipe.to!string))
            {
                item.unhighlight;
            }
        }
    }

    auto setItemDetail(Widget item, int idx)
    {
        auto frame = childById("detailFrame"~(idx+1).to!string);
        frame.removeAllChildren;
        frame.addChild(item);
    }

    @property auto sortKey()
    {
        return childById!ComboBox("sortBy").selectedItem;
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
        childById("item"~(idx+1).to!string).visibility = Visibility.Gone;
    }

    auto showItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Visible;
    }

    @property auto numberOfColumns()
    {
        return childById!ComboBox("nColumns").selectedItem[0..1].to!int;
    }

    @property auto useMetaSearch()
    {
        return childById!CheckBox("metaSearch").checked;
    }

    @property auto useMetaSearch(bool use)
    {
        childById!CheckBox("metaSearch").checked = use;
    }

    @property auto useMigemo()
    {
        return childById!CheckBox("migemo").checked;
    }

    @property auto useMigemo(bool use)
    {
        childById!CheckBox("migemo").checked = use;
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

    @property auto categoryName(dstring cat)
    {
        import std.format;
        childById("categoryCaption").text = cat;
        childById("metaSearch").text = format("全ての%sから検索"d, cat);
    }

    EventHandler!() queryFocused;
    EventHandler!() queryChanged;
    EventHandler!() metaSearchOptionChanged;
    EventHandler!() migemoOptionChanged;
    EventHandler!() categoryChanged;
    EventHandler!() characterChanged;
    EventHandler!() nColumnChanged;
    EventHandler!() sortKeyChanged;
    int delegate(size_t, int) tableColumnLength;
    dstring[] delegate(dstring, dstring) relatedBindersFor;

private:
    Widget toRecipeWidget(dstring recipe, dstring category)
    {
        auto ret = new RecipeEntryWidget(recipe);
        auto wisdom = controller.wisdom;
        auto characters = controller.characters;
        auto binders = relatedBindersFor(recipe, category);

        ret.filedStateChanged = (bool marked) {
            auto c = selectedCharacter;
            if (marked)
            {
                binders.each!(b => characters[c].markFiledRecipe(recipe, b));
            }
            else
            {
                binders.each!(b => characters[c].unmarkFiledRecipe(recipe, b));
            }
        };
        ret.checked = binders.canFind!(b => characters[selectedCharacter].hasRecipe(recipe, b));
        ret.enabled = binders.length == 1;

        ret.detailClicked = {
            unhighlightDetailRecipe;
            scope(exit) highlightDetailRecipe;


            auto rDetail = wisdom.recipeFor(recipe);
            if (rDetail.name.empty)
            {
                rDetail.name = recipe;
                rDetail.remarks = "作り方がわかりません（´・ω・｀）";
            }
            recipeDetail = RecipeDetailFrame.create(rDetail, wisdom, characters);

            auto itemNames = rDetail.products.keys;
            enforce(itemNames.length <= 2);
            if (itemNames.empty)
            {
                // レシピ情報が完成するまでの間に合わせ
                itemNames = [ recipe~"のレシピで作れる何か" ];
            }

            hideItemDetail(1);

            itemNames.enumerate(0).each!((idx_name) {
                    auto idx = idx_name[0];
                    dstring name = idx_name[1];
                    Item item;
                    if (auto i = name in wisdom.itemList)
                    {
                        item = *i;
                    }
                    else
                    {
                        item.name = name;
                        item.remarks = "細かいことはわかりません（´・ω・｀）";
                        item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                    }

                    showItemDetail(idx);
                    setItemDetail(ItemDetailFrame.create(item, idx+1, wisdom), idx);
                });
        };
        return ret;
    }
}

auto recipeListLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                HorizontalLayout {
                    TextWidget { text: "キャラクター" }
                    ComboBox {
                        id: characters
                    }

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

                    TextWidget { text: " " }

                    HorizontalLayout {
                        id: sortBox
                        TextWidget { text: "ソート" }
                        ComboBox { id: sortBy }
                    }
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
                    HorizontalLayout {
                        TextWidget { text: "アイテム情報1" }
                        Button { id: editItem1; text: "編集" }
                    }
                    FrameLayout {
                        id: detailFrame1
                        padding: 1
                        backgroundColor: "black"
                    }
                }

                VerticalLayout {
                    id: item2
                    HorizontalLayout {
                        TextWidget { text: "アイテム情報2" }
                        Button { id: editItem2; text: "編集" }
                    }
                    FrameLayout {
                        id: detailFrame2
                        padding: 1
                        backgroundColor: "black"
                    }
                }
            }
        });
    return layout;
}

class RecipeEntryWidget: HorizontalLayout
{
    this()
    {
        super();
    }

    this(dstring recipe)
    {
        super(recipe.to!string);
        box = new CheckBox(null, ""d);
        link = new LinkWidget(null, recipe);
        addChild(box);
        addChild(link);
        box.checkChange = (Widget src, bool checked) {
            filedStateChanged(checked);
            if (checked)
            {
                this.backgroundColor = 0xdcdcdc;
            }
            else
            {
                this.backgroundColor = "white";
            }
            return true;
        };
        link.click = (Widget src) {
            detailClicked();
            return true;
        };
    }

    override @property bool checked() { return box.checked; }
    override @property Widget checked(bool c) {
        box.checked = c;
        return this;
    }

    override @property Widget enabled(bool c) {
        box.enabled = c;
        return this;
    }

    auto highlight()
    {
        link.backgroundColor = 0xfffacd;
    }
    auto unhighlight()
    {
        link.backgroundColor = backgroundColor;
    }

    EventHandler!(bool) filedStateChanged;
    EventHandler!() detailClicked;
private:
    CheckBox box;
    LinkWidget link;
}

class LinkWidget: TextWidget
{
    this()
    {
        super();
        clickable = true;
        styleId = STYLE_CHECKBOX_LABEL;
        enabled = true;
        trackHover = true;
    }

    this(string id, dstring txt)
    {
        super(id, txt);
        clickable = true;
        styleId = STYLE_CHECKBOX_LABEL;
        enabled = true;
        trackHover = true;
    }
}

mixin(registerWidgets!(RecipeTabFrame, RecipeEntryWidget));

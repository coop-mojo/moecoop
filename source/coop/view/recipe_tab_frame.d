/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.recipe_tab_frame;

import dlangui;

import coop.view.tab_frame_base;

class RecipeTabFrame: TabFrameBase
{
    import std.range;

    import coop.controller.recipe_tab_frame_controller;
    import coop.util;
    import coop.view.main_frame;

    mixin TabFrame;

    this() { super(); }

    this(string id)
    {
        super(id);
        defaultMessage = "レシピ名";
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
            import std.traits;

            items = [EnumMembers!SortOrder];
            selectedItemIndex = 0;
            itemClick = (Widget src, int idx) {
                sortKeyChanged();
                return true;
            };
        }

        import coop.view.editors;
        childById!EditLine("searchQuery").contentChange = (EditableContent content) {
            if (timerID > 0)
            {
                cancelTimer(timerID);
            }
            if (window)
            {
                timerID = setTimer(300);
            }
        };
        childById!EditLine("searchQuery").popupMenu = editorPopupMenu;

        childById!EditLine("searchQuery").focusChange = (Widget src, bool focused) {
            if (focused)
            {
                if (src.text == defaultMessage)
                {
                    src.text = "";
                    src.textColor = "black";
                }
            }
            else
            {
                if (src.text == "")
                {
                    src.text = defaultMessage;
                    src.textColor = "gray";
                }
            }
            return true;
        };
        childById("searchQuery").text = defaultMessage;
        childById("searchQuery").textColor = "gray";

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
            import coop.view.item_detail_frame;

            showItemEditDialog(root.window, this, childById!ItemDetailFrame("detail1").item, 0, controller.cWisdom);
            return true;
        };

        childById!Button("editItem2").click = (Widget _) {
            import coop.view.item_edit_dialog;
            import coop.view.item_detail_frame;

            showItemEditDialog(root.window, this, childById!ItemDetailFrame("detail2").item, 1, controller.cWisdom);
            return true;
        };
    }

    override @property EditLine queryBox()
    {
        return childById!EditLine("searchQuery");
    }

    override bool onTimer(ulong id)
    {
        queryChanged();
        return false;
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

    override @property ComboBox charactersBox()
    {
        return childById!ComboBox("characters");
    }

    auto showRecipeList(Pairs)(Pairs pairs)
        if (isInputRange!Pairs && is(ElementType!Pairs == RecipePair))
    {
        import std.algorithm;

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
        auto cols = chs.map!((rs) {
                import coop.view.controls;

                Widget col = new VerticalLayout;
                auto box = new CheckableEntryWidget("markall", "全部所持"d);
                box.backgroundColor = "gray";
                box.textColor = "white";
                box.checkStateChanged = (bool checked) {
                    rs.filter!(r => r.id != box.id && r.enabled)
                      .each!(r => r.checked = checked);
                };
                box.detailClicked = {
                    box.checked = !box.checked;
                };
                col.addChild(box);
                col.addChildren(rs);
                return col;
            }).array;
        horizontal.addChildren(cols);
        scroll.contentWidget = horizontal;
        scroll.backgroundColor = "white";
        recipeList.addChild(scroll);
    }

    auto toRecipeEntries(Pairs)(Pairs pairs)
        if (isInputRange!Pairs && is(ElementType!Pairs == RecipePair))
    {
        import std.algorithm;

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
        import coop.view.recipe_detail_frame;

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
            import coop.view.controls;

            auto shownRecipe = detailFrame.name;
            if (auto item = childById("recipeList").childById!CheckableEntryWidget(shownRecipe.to!string))
            {
                item.highlight;
            }
        }
    }

    auto unhighlightDetailRecipe()
    {
        if (auto detailFrame = recipeDetail)
        {
            import coop.view.controls;

            auto shownRecipe = detailFrame.name;
            if (auto item = childById("recipeList").childById!CheckableEntryWidget(shownRecipe.to!string))
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

    override @property bool useMetaSearch()
    {
        return childById!CheckBox("metaSearch").checked;
    }

    override @property void useMetaSearch(bool use)
    {
        childById!CheckBox("metaSearch").checked = use;
    }

    @property auto useReverseSearch()
    {
        if (auto box = childById!CheckBox("revSearch"))
        {
            return box.checked;
        }
        else
        {
            return false;
        }
    }

    override @property bool useMigemo()
    {
        return childById!CheckBox("migemo").checked;
    }

    override @property void useMigemo(bool use)
    {
        childById!CheckBox("migemo").checked = use;
    }

    override @property void disableMigemoBox()
    {
        with(childById!CheckBox("migemo"))
        {
            checked = false;
            enabled = false;
        }
    }

    override @property void enableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = true;
    }

    @property auto categoryName(dstring cat)
    {
        import std.format;
        childById("categoryCaption").text = cat;
        childById("metaSearch").text = format("全ての%sから検索"d, cat);
    }

    EventHandler!() queryChanged;
    EventHandler!() metaSearchOptionChanged;
    EventHandler!() migemoOptionChanged;
    EventHandler!() categoryChanged;
    EventHandler!() characterChanged;
    EventHandler!() revOptionChanged;
    EventHandler!() nColumnChanged;
    EventHandler!() sortKeyChanged;
    int delegate(size_t, int) tableColumnLength;
    dstring[] delegate(dstring, dstring) relatedBindersFor;

private:
    Widget toRecipeWidget(dstring recipe, dstring category)
    {
        import std.algorithm;

        import coop.view.controls;

        auto ret = new CheckableEntryWidget(recipe.to!string, recipe);
        auto wisdom = controller.wisdom;
        auto cWisdom = controller.cWisdom;
        auto characters = controller.characters;
        auto binders = relatedBindersFor(recipe, category);

        auto r = wisdom.recipeFor(recipe);

        ret.checkStateChanged = (bool marked) {
            auto c = characters[charactersBox.selectedItem];
            if (marked)
            {
                binders.each!(b => c.markFiledRecipe(recipe, b));
                if (c.hasSkillFor(r))
                {
                    ret.textColor = "black";
                }
            }
            else
            {
                binders.each!(b => c.unmarkFiledRecipe(recipe, b));
                if (!c.hasSkillFor(r) || r.requiresRecipe)
                {
                    ret.textColor = "gray";
                }
            }
        };
        ret.checked = binders.canFind!(b => characters[charactersBox.selectedItem].hasRecipe(recipe, b));
        ret.enabled = binders.length == 1;
        if (r.requiresRecipe)
        {
            ret.textColor = (ret.checked && characters[charactersBox.selectedItem].hasSkillFor(r)) ? "black" : "gray";
        }
        else
        {
            ret.textColor = characters[charactersBox.selectedItem].hasSkillFor(r) ? "black" : "gray";
        }
        debug
        {
            import std.range;

            if (r.name.empty)
            {
                ret.textColor = "red";
            }
            else
            {
                import std.algorithm;

                auto prods = r.products.keys;
                if (!prods.all!(p => p in wisdom.itemList))
                {
                    ret.textColor = "blue";
                }
                else
                {
                    if (!prods.map!(p => wisdom.itemList[p]).all!((it) {
                                return it.type !in wisdom.extraInfoList ||
                                       it.name in wisdom.extraInfoList[it.type];
                            }))
                    {
                        ret.textFlags = TextFlag.Underline;
                    }
                }
            }
        }

        ret.detailClicked = {
            import std.exception;

            import coop.view.recipe_detail_frame;

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
                    import coop.core.item;
                    import coop.view.item_detail_frame;

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
                        item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                    }

                    showItemDetail(idx);
                    setItemDetail(ItemDetailFrame.create(item, idx+1, wisdom, cWisdom), idx);
                });
        };

        import std.typecons;
        ret.popupMenu = [tuple("このレシピをコピー"d, () {
                    platform.setClipboardText(r.toShortString.to!dstring);
                })];
        return ret;
    }
    ulong timerID;
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

                EditLine {
                    id: searchQuery
                    minWidth: 300
                    text: "見たいレシピ"
                }
                HorizontalLayout {
                    id: searchOptions
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

import dlangui.widgets.metadata;
mixin(registerWidgets!RecipeTabFrame);

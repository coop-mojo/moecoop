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
import std.container;
import std.exception;
import std.format;
import std.range;
import std.regex;
import std.string;
import std.typecons;

import coop.util;
import coop.model.item;
import coop.model.recipe;
import coop.model.recipe_graph;
import coop.view.controls;
import coop.view.editors;
import coop.view.layouts;
import coop.view.main_frame;
import coop.view.recipe_tab_frame;
import coop.view.item_detail_frame;
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
        leafMaterials = new RedBlackTree!dstring;

        hideResult;
        childById!CheckBox("migemo").checkChange = (Widget src, bool checked) {
            migemoOptionChanged();
            return true;
        };
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

    auto setItemDetail(Widget item, int idx)
    {
        auto frame = childById("detailFrame"~(idx+1).to!string);
        frame.removeAllChildren;
        frame.addChild(item);
    }

    auto showCandidates(dstring[] candidates)
    {
        auto lst = new StringListWidget("candidates", candidates);
        lst.itemClick = (Widget _, int idx) {
            childById("itemQuery").text = lst.selectedItem;
            return true;
        };

        auto candidateFrame = new VerticalLayout;
        candidateFrame.addChild(new TextWidget(null, "作成候補"d));
        candidateFrame.addChild(lst);

        auto helperFrame = childById("helper");
        helperFrame.removeAllChildren;
        helperFrame.addChild(candidateFrame);
    }

    auto hideResult()
    {
        childById("result").visibility = Visibility.Gone;
    }

    auto showResult()
    {
        childById("result").visibility = Visibility.Visible;
    }

    auto hasShownResult()
    {
        return childById("result").visibility == Visibility.Visible;
    }

    auto ownedMaterials()
    {
        if (!hasShownResult)
        {
            return null;
        }
        auto tbl = childById!TableLayout("materials");
        return tbl.rows.map!((r) {
                auto mat = r[0].text.chomp(": ");
                if (r[1].text.empty)
                {
                    return tuple(mat, 0);
                }
                else
                {
                    return tuple(mat, r[1].text.to!int);
                }
            }).filter!(a => a[1] > 0).assocArray;
    }

    auto initRecipeTable(dstring[] recipes)
    {
        auto fr = childById("recipeBase");
        fr.removeAllChildren;

        fr.addChild(new TextWidget(null, "必要レシピ"d));
        auto scr = new ScrollWidget;
        auto tbl = new TableLayout("recipes");
        tbl.colCount = 2;

        recipes.map!((r) {
                auto w = new LinkWidget("recipe", r~": ");
                auto t = new TextWidget("times", format("%s 回"d, 0));
                auto detail = controller.wisdom.recipeFor(r);
                w.click = (Widget _) {
                    recipeDetail = RecipeDetailFrame.create(detail, controller.wisdom, controller.characters);
                    return true;
                };
                return cast(Widget[])[w, t];
            }).each!(c => tbl.addChildren(c));

        scr.contentWidget = tbl;
        scr.backgroundColor = "white";
        fr.addChild(scr);
    }

    auto initLeftoverTable(dstring[] leftovers)
    {
        auto fr = childById("leftoverBase");
        fr.removeAllChildren;

        fr.addChild(new TextWidget(null, "余り物"d));
        auto scr = new ScrollWidget;
        auto tbl = new TableLayout("leftovers");
        tbl.colCount = 2;

        leftovers.map!((lo) {
                auto w = new LinkWidget(null, lo~": ");
                auto n = new TextWidget("num", format("%s 個"d, 0));
                w.click = (Widget _) {
                    Item item;
                    if (auto i = lo in controller.wisdom.itemList)
                    {
                        item = *i;
                    }
                    else
                    {
                        item.name = lo;
                        item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                    }
                    showItemDetail(0);
                    setItemDetail(ItemDetailFrame.create(item, 1, controller.wisdom, controller.cWisdom), 0);
                    return true;
                };
                return cast(Widget[])[w, n];
            }).each!(c => tbl.addChildren(c));
        tbl.addChild(new TextWidget("なし", "なし"d));

        scr.contentWidget = tbl;
        scr.backgroundColor = "white";
        fr.addChild(scr);
    }

    auto initMaterialTable(dstring[] materials)
    {
        auto fr = childById("materialBase");
        fr.removeAllChildren;

        auto matCap = new HorizontalLayout;
        matCap.addChild(new TextWidget(null, "必要素材 (所持数/必要数)"d));
        auto clearButton = new Button(null, "全部しまう"d);
        matCap.addChild(clearButton);
        fr.addChild(matCap);

        auto scr = new ScrollWidget;
        auto tbl = new TableLayout("materials");
        tbl.colCount = 3;

        materials.map!((lo) {
                auto w = new CheckableEntryWidget(lo~": ");
                auto o = new EditIntLine("own");
                auto t = new TextWidget("times", format("/%s 個"d, 0));

                w.checkStateChanged = (bool checked) {
                    if (checked)
                    {
                        o.text = t.text.matchFirst(r"/(\d+) 個"d)[1];
                    }
                    else
                    {
                        o.text = "0";
                    }
                };
                w.detailClicked = {
                    Item item;
                    if (auto i = lo in controller.wisdom.itemList)
                    {
                        item = *i;
                    }
                    else
                    {
                        item.name = lo;
                        item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
                    }
                    showItemDetail(0);
                    setItemDetail(ItemDetailFrame.create(item, 1, controller.wisdom, controller.cWisdom), 0);
                };
                o.contentChange = (EditableContent content) {
                    auto product = childById("itemQuery").text;
                    auto txt = childById("numQuery").text;
                    if (txt.empty || txt.to!int == 0)
                    {
                        return;
                    }
                    assert(product in controller.wisdom.rrecipeList);
                    updateTables(product, txt.to!int, ownedMaterials);
                    if (txt == t.text.matchFirst(r"/(\d+) 個"d)[1])
                    {
                        w.checked = true;
                    }
                };
                return [w, o, t];
            }).each!(c => tbl.addChildren(c));

        scr.contentWidget = tbl;
        scr.backgroundColor = "white";
        fr.addChild(scr);
        clearButton.click = (Widget _) {
            tbl.rows.map!"a[1]".each!(w => w.text = "0");
            return true;
        };
    }

    auto updateRecipeTable(int[dstring] recipes)
    {
        auto tbl = enforce(childById!TableLayout("recipes"));
        tbl.rows.each!((rs) {
                auto r = rs[0].text.chomp(": ");
                if (auto n  = r in recipes)
                {
                    rs.each!(w => w.visibility = Visibility.Visible);
                    rs[1].text = format("%s 回"d, *n);
                    auto detail = controller.wisdom.recipeFor(r);
                    if (detail.requiresRecipe && !controller.characters[selectedCharacter].hasRecipe(r))
                    {
                        rs[0].textColor = "gray";
                    }
                    else if (detail.ingredients.keys.all!(ing => childById!TableLayout("materials").row(format("%s: ", ing))[0].checked))
                    {
                        rs[0].textColor = "red";
                    }
                    else
                    {
                        rs[0].textColor = "black";
                    }

                    auto rNode = fullGraph.recipeNodes[r];
                    if (!rNode.parents.empty)
                    {
                        auto bros = rNode.parents[]
                                         .map!(p => fullGraph.materialNodes[p].children)
                                         .join
                                         .map!"a.name"
                                         .array
                                         .sort()
                                         .uniq
                                         .array;
                        if (bros.length > 1)
                        {
                            auto menu = bros.filter!(b => b != r)
                                            .map!(b => tuple(format("%s を使う"d, b), () {
                                                        preference[rNode.parents[].front] = b;
                                                        reload;
                                                    }))
                                            .array;
                            (cast(LinkWidget)rs[0]).popupMenu = menu;
                        }
                    }
                }
                else
                {
                    rs.each!(w => w.visibility = Visibility.Gone);
                }
            });
    }

    auto updateLeftoverTable(int[dstring] leftovers)
    {
        auto tbl = enforce(childById!TableLayout("leftovers"));
        tbl.rows.each!((rs) {
                if (auto n = rs[0].text.chomp(": ") in leftovers)
                {
                    rs.each!(w => w.visibility = Visibility.Visible);
                    rs[1].text = format("%s 個"d, *n);
                }
                else
                {
                    rs.each!(w => w.visibility = Visibility.Gone);
                }
            });
        if (leftovers.keys.empty)
        {
            tbl.childById("なし").visibility = Visibility.Visible;
        }
    }

    auto updateMaterialTable(MatTuple[dstring] materials)
    {
        auto tbl = enforce(childById!TableLayout("materials"));
        tbl.rows.each!((rs) {
                auto m = rs[0].text.chomp(": ");
                if (auto n = m in materials)
                {
                    rs.each!(w => w.visibility = Visibility.Visible);
                    rs[2].text = format("/%s 個"d, (*n).num);
                    rs[0].textColor = (*n).isIntermediate ? "blue" : "black";
                    if (!rs[1].text.empty && rs[1].text.to!int >= (*n).num)
                    {
                        rs[0].checked = true;
                    }
                    else
                    {
                        rs[0].checked = false;
                    }

                    auto mNode = fullGraph.materialNodes[m];
                    if (!mNode.isLeaf)
                    {
                        Tuple!(dstring, void delegate()) menuItem;
                        if (mNode.name in leafMaterials)
                        {
                            menuItem = tuple("材料から用意する"d, () {
                                    leafMaterials.removeKey(mNode.name);
                                    reload;
                                });
                        }
                        else
                        {
                            menuItem = tuple("直接用意する"d, () {
                                    leafMaterials.insert(mNode.name);
                                    reload;
                                });
                        }
                        (cast(CheckableEntryWidget)rs[0]).popupMenu = [menuItem];
                    }
                }
                else
                {
                    rs.each!(w => w.visibility = Visibility.Gone);
                }
            });
    }

    auto initializeTables(dstring item)
    {
        fullGraph = new RecipeGraph(item, controller.wisdom, null);
        preference = RecipeGraph.preference;

        auto elems = fullGraph.elements;
        initRecipeTable(elems.recipes);
        initLeftoverTable(elems.materials);
        initMaterialTable(elems.materials);
    }

    auto updateTables(dstring item, int num, int[dstring] owned = null)
    {
        if (subGraph is null || fullGraph.target != subGraph.target)
        {
            subGraph = new RecipeGraph(item, controller.wisdom, preference);
        }
        auto elems = subGraph.elements(num, owned, controller.wisdom, leafMaterials);
        updateMaterialTable(elems.materials); // 最初にすること！
        updateRecipeTable(elems.recipes);
        updateLeftoverTable(elems.leftovers);
        showResult;
    }

    void reload()
    in{
        assert(hasShownResult);
    } body {
        auto numText = childById("numQuery").text;
        if (numText.empty || numText.to!int == 0)
        {
            return;
        }
        auto product = childById("itemQuery").text;
        subGraph = null;
        updateTables(product, numText.to!int, ownedMaterials);
     }

    EventHandler!() migemoOptionChanged;
    RecipeGraph fullGraph;
    RecipeGraph subGraph;
    dstring[dstring] preference;
    RedBlackTree!dstring leafMaterials;
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
                        minWidth: 300
                    }
                    EditIntLine {
                        id: numQuery
                        minWidth: 80
                    }
                    CheckBox { id: migemo; text: "Migemo 検索" }
                }

                TableLayout {
                    id: helper
                    padding: 1
                    colCount: 2
                }

                VerticalLayout {
                    id: result
                    TextWidget { text: "必要レシピ情報" }
                    HorizontalLayout {
                        padding: 1
                        VerticalLayout {
                            VerticalLayout {
                                id: recipeBase
                            }
                            VerticalLayout {
                                id: leftoverBase
                            }
                        }
                        VerticalLayout {
                            id: materialBase
                        }
                    }
                }
            }
        });
    return layout;
}

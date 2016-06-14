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
module coop.model.recipe_graph;

import coop.model.wisdom;

import std.algorithm;
import std.container;
import std.conv;
import std.format;
import std.math;
import std.range;
import std.typecons;

alias MatTuple = Tuple!(int, "num", bool, "isIntermediate");

class RecipeGraph
{
    this(dstring name, Wisdom w, dstring[dstring] pref = defaultPreference)
    {
        preferences_ = pref;
        root = init(name, cast(RecipeContainer)null, w);
    }

    auto elements()
    {
        if (orderedRecipes_.empty)
        {
            visit;
        }
        alias Ret = Tuple!(dstring[], "recipes", dstring[], "materials");
        return Ret(orderedRecipes_, orderedMaterials_);
    }

    /++
     + root を n 個作るのに必要なレシピ，素材，作成時のあまり素材を返す
     + TODO: コンバインしない素材列が引数に必要
     +/
    auto elements(int targetNum, int[dstring] owned, Wisdom w, RedBlackTree!dstring mats = new RedBlackTree!dstring)
    {
        int[dstring] rs, leftover;
        MatTuple[dstring] ms;
        ms[root.name] = MatTuple(targetNum, false);
        foreach(r; elements.recipes)
        {
            auto re = w.recipeFor(r);
            auto tar = setIntersection(recipes_[r].parents[].array.sort(), re.products.keys.sort()).front;
            if (tar in mats)
            {
                continue;
            }
            auto nPerComb = re.products[tar];
            if (auto o = tar in ms)
            {
                auto req = (*o).num;
                auto ow = owned.get(tar, 0);
                int nApply;
                if (req > ow)
                {
                    nApply = ((req-ow)/nPerComb.to!real).ceil.to!int;
                    leftover[tar] = nApply*nPerComb - (req-ow);
                    rs[r] = nApply;
                    assert(rs[r] > 0);
                    recipes_[r].parents[].each!(m => ms[m].isIntermediate = true);
                }
                else
                {
                    nApply = 0;
                    leftover[tar] = ow-req;
                }

                if (leftover[tar] == 0)
                {
                    leftover.remove(tar);
                }
                if (nApply > 0)
                {
                    foreach(kv; re.products.byKeyValue.filter!(kv => kv.key != tar))
                    {
                        leftover[kv.key] += kv.value*nApply;
                    }

                    foreach(mat, n; re.ingredients)
                    {
                        if (mat !in ms)
                        {
                            ms[mat] = MatTuple.init;
                        }
                        ms[mat].num += n*nApply;
                    }
                }
            }
            else
            {
                // 上流はもうこのアイテムを必要としていない
                continue;
            }
        }
        alias Ret = Tuple!(int[dstring], "recipes", MatTuple[dstring], "materials", int[dstring], "leftovers");
        return Ret(rs, ms, leftover);
    }

    @property auto target()
    {
        return root.name;
    }

    override string toString()
    {
        auto rs = new RedBlackTree!string;
        auto ms = new RedBlackTree!string;
        return root.toGraphString(ms, rs);
    }

    @property static auto preference()
    {
        return defaultPreference;
    }

    // material -> recipe
    enum defaultPreference = [
        "魚の餌"d: "魚の餌(ヘビの肉)"d,
        "砂糖": "砂糖(臼)",
        "塩": "塩(岩塩)",
        "パン粉": "パン粉",
        "パン生地": "パン生地",
        "パイ生地": "パイ生地(ミニ ウォーター ボトル)",
        "ゼラチン": "ゼラチン(オークの骨)",
        "切り身魚のチーズ焼き": "切り身魚のチーズ焼き",
        "お雑煮": "お雑煮",
        "味噌汁": "味噌汁",
        "ざるそば": "ざるそば",
        "ベーコン": "ベーコン",
        "ショート ケーキ": "ショート ケーキ",
        "揚げ玉": "かき揚げ",
        "焼き鳥": "焼き鳥",
        "かけそば": "かけそば",
        "そば湯": "ざるそば",
        "モチ": "モチ(ミニ ウォーター ボトル)",
        "パルプ": "パルプ(木の板材)",
        "小さな紙": "小さな紙(調合)",
        "髪染め液": "髪染め液",
        "染色液": "染色液",
        "染色液(大)": "染色液(大)",
        "クロノスの涙": "クロノスの涙",
        "クロノスの光": "クロノスの光",
        "骨": "骨(タイガー ボーン)",
        "ボーン チップ": "ボーン チップ(タイガー ボーン)",
        "鉄の棒": "鉄の棒(アイアンインゴット)",
        "カッパーインゴット": "カッパーインゴット(鉱石)",
        "ブロンズインゴット": "ブロンズインゴット(鉱石)",
        "アイアンインゴット": "アイアンインゴット(鉱石)",
        "スチールインゴット": "スチールインゴット(鉱石)",
        "ブラスインゴット": "ブラスインゴット(鉱石)",
        "シルバーインゴット": "シルバーインゴット(鉱石)",
        "ゴールドインゴット": "ゴールドインゴット(鉱石)",
        "ミスリルインゴット": "ミスリルインゴット(鉱石)",
        "オリハルコンインゴット": "オリハルコンインゴット(鉱石)",
        ];

    @property auto recipeNodes()
    {
        return recipes_;
    }

    @property auto materialNodes()
    {
        return materials_;
    }
private:

    /++
     + Init tree from a given material name
     +/
    auto init(dstring name, RecipeContainer parent, Wisdom w)
    {
        auto mat = materials_.get(name, new MaterialContainer(name));
        if (parent !is null && parent.name !in mat.parents)
        {
            mat.parents.insert(parent.name);
        }

        if (name in materials_)
        {
            return mat;
        }
        materials_[name] = mat;

        if (auto rs = name in w.rrecipeList)
        {
            dstring[] arr;
            if (auto elem = name in preferences_)
            {
                arr = [*elem];
            }
            else
            {
                arr = (*rs)[].array;
            }
            mat.children = arr.map!(r => this.init(r, mat, w)).array;
        }
        else
        {
            materials_[name].isProduct = false;
        }
        return mat;
    }

    /++
     + Init tree from agiven recipe name
     +/
    auto init(dstring name, MaterialContainer parent, Wisdom w)
    {
        auto recipe = recipes_.get(name, new RecipeContainer(name));
        if (parent.name !in recipe.parents)
        {
            recipe.parents.insert(parent.name);
        }
        if (name in recipes_)
        {
            return recipe;
        }
        recipes_[name] = recipe;

        assert(w.recipeFor(name).name == name);
        recipe.children = w.recipeFor(name)
                           .ingredients.keys
                           .map!(m => this.init(m, recipe, w))
                           .array;
        return recipe;
    }

    auto visit()
    {
        orderedRecipes_ = [];
        orderedMaterials_ = [];
        auto visitedRecipes = new RedBlackTree!dstring;
        auto visitedMaterials = new RedBlackTree!dstring;
        visit(root, visitedRecipes, visitedMaterials);
        orderedRecipes_.reverse();
        orderedMaterials_.reverse();
        assert(orderedMaterials_.front == root.name);
        orderedMaterials_ = orderedMaterials_[1..$];
    }

    void visit(MaterialContainer material, ref RedBlackTree!dstring rs, ref RedBlackTree!dstring ms)
    {
        if (material.name in ms)
        {
            return;
        }
        ms.insert(material.name);
        material.children.filter!(c => !orderedRecipes_.canFind(c.name)).each!(c => this.visit(c, rs, ms));
        orderedMaterials_ ~= material.name;
    }

    void visit(RecipeContainer recipe, ref RedBlackTree!dstring rs, ref RedBlackTree!dstring ms)
    {
        if (recipe.name in rs)
        {
            return;
        }
        rs.insert(recipe.name);
        recipe.children.filter!(c => !orderedMaterials_.canFind(c.name)).each!(c => this.visit(c, rs, ms));
        orderedRecipes_ ~= recipe.name;
    }

    MaterialContainer root;

    MaterialContainer[dstring] materials_;
    RecipeContainer[dstring] recipes_;
    dstring[dstring] preferences_;
    dstring[] orderedRecipes_;
    dstring[] orderedMaterials_;
}


class RecipeContainer
{
    this(dstring name_)
    {
        name = name_;
        parents = new RedBlackTree!dstring;
    }

    override string toString()
    {
        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0)
    {
        if (name.to!string in rs)
        {
            return format("%sR: %s (already occured)", ' '.repeat.take(lv*2), name);
        }
        rs.insert(name.to!string);
        auto nextLv = lv+1;
        return format("%sR: %s\n%s", ' '.repeat.take(lv*2), name, children.map!(c => c.toGraphString(ms, rs, nextLv)).join("\n"));
    }

    dstring name;
    RedBlackTree!dstring parents;
    MaterialContainer[] children;
}

class MaterialContainer
{
    this(dstring name_)
    {
        name = name_;
        parents = new RedBlackTree!dstring;
    }

    auto isLeaf()
    {
        return !isProduct;
    }

    override string toString()
    {
        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0)
    {
        if (!isProduct)
        {
            return format("%sM: %s (Leaf)", ' '.repeat.take(lv*2), name);
        }
        else if (name.to!string in ms)
        {
            return format("%sM: %s (already occured)", ' '.repeat.take(lv*2), name);
        }
        ms.insert(name.to!string);
        auto nextLv = lv+1;
        return format("%sM: %s\n%s", ' '.repeat.take(lv*2), name, children.map!(c => c.toGraphString(ms, rs, nextLv)).join("\n"));
    }

    dstring name;
    bool isProduct = true;
    RedBlackTree!dstring parents;
    RecipeContainer[] children;
}

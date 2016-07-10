/**
 * Authors: Mojo
 * License: MIT License
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
    this(dstring[] names, Wisdom w, dstring[dstring] pref = defaultPreference) pure
    {
        preferences_ = pref;
        roots = names.sort().map!(n => init(n, cast(RecipeContainer)null, w)).array;
    }

    auto elements() pure
    {
        if (orderedRecipes_.empty)
        {
            visit;
        }
        alias Ret = Tuple!(dstring[], "recipes", dstring[], "materials");
        return Ret(orderedRecipes_, orderedMaterials_);
    }

    /++
     + targets を作るのに必要なレシピ，素材，作成時の余り素材を返す
     +/
    auto elements(int[dstring] targets, int[dstring] owned, Wisdom w, RedBlackTree!dstring mats = new RedBlackTree!dstring) pure
    in {
        import std.format;
        assert(targets.keys.all!(t => roots.map!"a.name".canFind(t)), format("Invalid input: %s but roots are %s", targets, roots.map!"a.name".array));
    } body {
        int[dstring] rs, leftover;
        MatTuple[dstring] ms = targets.byKeyValue.map!(kv => tuple(kv.key, MatTuple(kv.value, false))).assocArray;
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

    @property auto targets() const @safe pure nothrow
    out(result) {
        assert(result.isSorted);
    } body {
        return roots.map!"a.name".array;
    }

    // override string toString()
    // {
    //     auto rs = new RedBlackTree!string;
    //     auto ms = new RedBlackTree!string;
    //     return root.toGraphString(ms, rs);
    // }

    @property static auto preference() @safe pure nothrow
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

    @property auto recipeNodes() @safe pure nothrow
    {
        return recipes_;
    }

    @property auto materialNodes() @safe pure nothrow
    {
        return materials_;
    }
private:

    /++
     + Init tree from a given material name
     +/
    auto init(dstring name, RecipeContainer parent, Wisdom w) pure
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
    auto init(dstring name, MaterialContainer parent, Wisdom w) pure
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

    auto visit() pure
    out {
        assert(targets.all!(t => orderedMaterials_.canFind(t)));
    } body {
        orderedRecipes_ = [];
        orderedMaterials_ = [];
        auto visitedRecipes = new RedBlackTree!dstring;
        auto visitedMaterials = new RedBlackTree!dstring;
        roots.each!(r => visit(r, visitedRecipes, visitedMaterials));
        orderedRecipes_.reverse();
        orderedMaterials_.reverse();
    }

    void visit(MaterialContainer material, ref RedBlackTree!dstring rs, ref RedBlackTree!dstring ms) pure
    {
        if (material.name in ms)
        {
            return;
        }
        ms.insert(material.name);
        material.children.filter!(c => !orderedRecipes_.canFind(c.name)).each!(c => this.visit(c, rs, ms));
        orderedMaterials_ ~= material.name;
    }

    void visit(RecipeContainer recipe, ref RedBlackTree!dstring rs, ref RedBlackTree!dstring ms) pure
    {
        if (recipe.name in rs)
        {
            return;
        }
        rs.insert(recipe.name);
        recipe.children.filter!(c => !orderedMaterials_.canFind(c.name)).each!(c => this.visit(c, rs, ms));
        orderedRecipes_ ~= recipe.name;
    }

    MaterialContainer[] roots;

    MaterialContainer[dstring] materials_;
    RecipeContainer[dstring] recipes_;
    dstring[dstring] preferences_;
    dstring[] orderedRecipes_;
    dstring[] orderedMaterials_;
}


class RecipeContainer
{
    this(dstring name_) @safe pure nothrow
    {
        name = name_;
        parents = new RedBlackTree!dstring;
    }

    override string toString() const @safe pure
    {
        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0) const pure
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
    this(dstring name_) @safe pure nothrow
    {
        name = name_;
        parents = new RedBlackTree!dstring;
    }

    auto isLeaf() const @safe pure nothrow
    {
        return !isProduct;
    }

    override string toString() const @safe pure
    {
        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0) const pure
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

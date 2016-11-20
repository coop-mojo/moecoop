/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.recipe_graph;

import std.typecons;

/// for elements/0
alias RecipeInfo = Tuple!(dstring, "name", dstring, "parentGroup");
alias MaterialInfo = Tuple!(dstring, "name", bool, "isLeaf");

/// for elements/4
alias MatTuple = Tuple!(int, "num", bool, "isIntermediate");

class RecipeGraph
{
    import std.container;

    import coop.core.wisdom;
    import coop.core.recipe;

    this(dstring[] names, Wisdom w, dstring[dstring] pref = defaultPreference) pure
    {
        import std.algorithm;
        import std.array;

        preferences_ = pref;
        recipeFor = r => w.recipeFor(r);
        rrecipeFor = i => i in w.rrecipeList;
        roots = names.sort().map!(n => init(n, cast(RecipeContainer)null)).array;
    }

    this(dstring[] names, Recipe[dstring] recipeMap, RedBlackTree!dstring[dstring] rrecipeMap, dstring[dstring] pref = defaultPreference)
    {
        import std.algorithm;
        import std.array;

        preferences_ = pref;
        recipeFor = r => recipeMap[r];
        rrecipeFor = i => i in rrecipeMap;
        roots = names.sort().map!(n => init(n, cast(RecipeContainer)null)).array;
    }

    auto elements() pure
    {
        import std.algorithm;
        import std.range;

        if (orderedRecipes_.empty)
        {
            visit;
        }
        RecipeInfo[] rinfo = orderedRecipes_.map!((r) {
                auto bros = recipes_[r].parents[].map!(p => materials_[p].children).join.map!"a.name".array.sort().uniq.array;
                assert(bros.length <= 1 || recipes_[r].parents[].walkLength == 1);
                return RecipeInfo(r, bros.length > 1 ? recipes_[r].parents[].front : "");
            }).array;

        MaterialInfo[] minfo = orderedMaterials_.map!(m => MaterialInfo(m, materials_[m].isLeaf)).array;

        return tuple!("recipes", "materials")(rinfo, minfo);
    }

    /++
     + targets を作るのに必要なレシピ，素材，作成時の余り素材を返す
     +/
    auto elements(int[dstring] targets, int[dstring] owned, RedBlackTree!dstring mats = new RedBlackTree!dstring) pure
    in {
        import std.algorithm;
        import std.array;
        import std.format;

        assert(targets.keys.all!(t => roots.map!"a.name".canFind(t)), format("Invalid input: %s but roots are %s", targets, roots.map!"a.name".array));
    } body {
        import std.algorithm;
        import std.array;

        int[dstring] rs, leftover;
        MatTuple[dstring] ms = targets.byKeyValue.map!(kv => tuple(kv.key, MatTuple(kv.value, false))).assocArray;
        foreach(r; elements.recipes.map!"a.name")
        {
            auto re = recipeFor(r);
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
                    import std.conv;
                    import std.math;

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
        import std.algorithm;

        assert(result.isSorted);
    } body {
        import std.algorithm;
        import std.array;

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
    auto init(dstring name, RecipeContainer parent) pure
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

        if (auto rs = rrecipeFor(name))
        {
            import std.algorithm;
            import std.array;

            dstring[] arr;
            if (auto elem = name in preferences_)
            {
                arr = [*elem];
            }
            else
            {

                arr = (*rs)[].array;
            }
            mat.children = arr.map!(r => this.init(r, mat)).array;
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
    auto init(dstring name, MaterialContainer parent) pure
    {
        import std.algorithm;
        import std.array;

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

        recipe.children = recipeFor(name)
                           .ingredients.keys
                           .map!(m => this.init(m, recipe))
                           .array;
        return recipe;
    }

    void visit(MaterialContainer material, ref RedBlackTree!dstring rs, ref RedBlackTree!dstring ms) pure
    {
        import std.algorithm;

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
        import std.algorithm;

        if (recipe.name in rs)
        {
            return;
        }
        rs.insert(recipe.name);
        recipe.children.filter!(c => !orderedMaterials_.canFind(c.name)).each!(c => this.visit(c, rs, ms));
        orderedRecipes_ ~= recipe.name;
    }

    auto visit() pure
    out {
        import std.algorithm;

        assert(targets.all!(t => orderedMaterials_.canFind(t)));
    } body {
        import std.algorithm;

        orderedRecipes_ = [];
        orderedMaterials_ = [];
        auto visitedRecipes = new RedBlackTree!dstring;
        auto visitedMaterials = new RedBlackTree!dstring;
        foreach(r; roots)
        {
            visit(r, visitedRecipes, visitedMaterials);
        }
        orderedRecipes_.reverse();
        orderedMaterials_.reverse();
    }

    MaterialContainer[] roots;

    MaterialContainer[dstring] materials_;
    RecipeContainer[dstring] recipes_;
    dstring[dstring] preferences_;
    dstring[] orderedRecipes_;
    dstring[] orderedMaterials_;
    Recipe delegate(dstring) pure recipeFor;
    RedBlackTree!dstring* delegate(dstring) pure rrecipeFor;
}


class RecipeContainer
{
    import std.container;

    this(dstring name_) @safe pure nothrow
    {
        name = name_;
        parents = new RedBlackTree!dstring;
    }

    override string toString() const @safe pure
    {
        import std.conv;

        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0) const pure
    {
        import std.algorithm;
        import std.conv;
        import std.format;
        import std.range;

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
    import std.container;

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
        import std.conv;

        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0) const pure
    {
        import std.algorithm;
        import std.conv;
        import std.format;
        import std.range;

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

unittest
{
    import std.container;

    import coop.core.recipe;

    Recipe roastSnake = {
        name: "ロースト スネーク ミート"d,
        ingredients: ["ヘビの肉"d: 1],
    };
    auto graph = new RecipeGraph(["ロースト スネーク ミート"d],
                                 ["ロースト スネーク ミート"d: roastSnake],
                                 ["ロースト スネーク ミート"d: make!(RedBlackTree!dstring)("ロースト スネーク ミート"d)]);
    auto tpl = graph.elements;
    assert(tpl.recipes == [RecipeInfo("ロースト スネーク ミート"d, "")]);import std.conv;
    assert(tpl.materials == [MaterialInfo("ロースト スネーク ミート"d, false),
                             MaterialInfo("ヘビの肉"d, true)]);
}

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

    this(dstring[] names, Recipe[dstring] recipeMap, RedBlackTree!dstring[dstring] rrecipeMap, dstring[dstring] pref = defaultPreference) pure
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
     + Init tree from a given recipe name
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
        assert(name !in recipes_);
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

        assert(recipe.name !in rs);
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

    dstring name;
    bool isProduct = true;
    RedBlackTree!dstring parents;
    RecipeContainer[] children;
}

///
unittest
{
    import std.container;

    import coop.core.recipe;

    Recipe roastSnake = {
        name: "ロースト スネーク ミート",
        ingredients: ["ヘビの肉": 1],
        products: ["ロースト スネーク ミート": 1],
    };
    auto graph = new RecipeGraph(["ロースト スネーク ミート"],
                                 ["ロースト スネーク ミート": roastSnake],
                                 ["ロースト スネーク ミート": make!(RedBlackTree!dstring)("ロースト スネーク ミート"d)]);
    auto tpl = graph.elements;
    assert(tpl.recipes == [RecipeInfo("ロースト スネーク ミート", "")]);import std.conv;
    assert(tpl.materials == [MaterialInfo("ロースト スネーク ミート", false),
                             MaterialInfo("ヘビの肉", true)]);
}

version(unittest)
{
    import coop.util: indexOf;
}

// 作成対象が1種類の場合
unittest
{
    import std.container;

    import coop.core.recipe;

    Recipe roastTiger = {
        name: "ロースト タイガー ミート",
        ingredients: ["トラの肉": 1, "塩": 1],
        products: ["ロースト タイガー ミート": 1],
    };
    Recipe salt1 = {
        name: "塩(岩塩)",
        ingredients: ["岩塩": 1],
        products: ["塩": 7],
    };
    Recipe salt2 = {
        name: "塩(木炭＋海水)"d,
        ingredients: ["木炭": 1, "海水": 1],
        products: ["塩": 18],
    };

    {
        // 必要なレシピ・素材を全て列挙
        typeof(RecipeGraph.defaultPreference) pref = null;
        auto graph = new RecipeGraph(["ロースト タイガー ミート"],
                                     [
                                         "ロースト タイガー ミート": roastTiger,
                                         "塩(岩塩)": salt1,
                                         "塩(木炭＋海水)": salt2,
                                     ],
                                     [
                                         "ロースト タイガー ミート"d: make!(RedBlackTree!dstring)("ロースト タイガー ミート"d),
                                         "塩": make!(RedBlackTree!dstring)("塩(岩塩)"d, "塩(木炭＋海水)"d),
                                     ],
                                     pref);

        auto tpl = graph.elements;

        import std.algorithm;
        import std.array;
        assert(tpl.recipes.dup.sort().equal(
                   [
                       RecipeInfo("ロースト タイガー ミート", ""),
                       RecipeInfo("塩(岩塩)", "塩"),
                       RecipeInfo("塩(木炭＋海水)", "塩"),
                   ]));
        assert(tpl.recipes.front == RecipeInfo("ロースト タイガー ミート", ""));

        assert(tpl.materials.dup.sort().equal(
                   [
                       MaterialInfo("トラの肉", true),
                       MaterialInfo("ロースト タイガー ミート", false),
                       MaterialInfo("塩", false),
                       MaterialInfo("岩塩", true),
                       MaterialInfo("木炭", true),
                       MaterialInfo("海水", true),
                   ]));
        auto mats = tpl.materials.map!"a.name".array;
        assert(mats.front == "ロースト タイガー ミート");
        assert(mats.indexOf("塩"d) < mats.indexOf("木炭"d));
        assert(mats.indexOf("塩"d) < mats.indexOf("海水"d));
        assert(mats.indexOf("塩"d) < mats.indexOf("岩塩"d));
    }

    {
        // 塩(岩塩)のレシピを使う場合のレシピ・素材を列挙
        auto pref = ["塩"d: "塩(岩塩)"d];
        auto graph = new RecipeGraph(["ロースト タイガー ミート"],
                                     [
                                         "ロースト タイガー ミート": roastTiger,
                                         "塩(岩塩)": salt1,
                                         "塩(木炭＋海水)": salt2,
                                     ],
                                     [
                                         "ロースト タイガー ミート"d: make!(RedBlackTree!dstring)("ロースト タイガー ミート"d),
                                         "塩": make!(RedBlackTree!dstring)("塩(岩塩)"d, "塩(木炭＋海水)"d),
                                     ],
                                     pref);
        auto tpl = graph.elements;

        import std.algorithm;
        import std.array;
        assert(tpl.recipes == [
                   RecipeInfo("ロースト タイガー ミート", ""),
                   RecipeInfo("塩(岩塩)", ""),
                   ]);
        assert(tpl.materials.dup.sort().equal(
                   [
                       MaterialInfo("トラの肉", true),
                       MaterialInfo("ロースト タイガー ミート", false),
                       MaterialInfo("塩", false),
                       MaterialInfo("岩塩", true),
                   ]));
        auto mats = tpl.materials.map!"a.name".array;
        assert(mats.front == "ロースト タイガー ミート");
        assert(mats.indexOf("塩"d) < mats.indexOf("岩塩"d));
    }
}

// 作成対象が複数種類の場合
unittest
{
    import std.container;

    import coop.core.recipe;

    Recipe roastTiger = {
        name: "ロースト タイガー ミート",
        ingredients: [
            "トラの肉": 1,
            "塩": 1,
            ],
        products: ["ロースト タイガー ミート": 1],
    };
    Recipe roastLion = {
        name: "ロースト ライオン ミート",
        ingredients: ["ライオンの肉": 1, "塩": 1],
        products: ["ロースト ライオン ミート": 1],
    };
    Recipe salt1 = {
        name: "塩(岩塩)",
        ingredients: ["岩塩": 1],
        products: ["塩": 7],
    };
    Recipe salt2 = {
        name: "塩(木炭＋海水)"d,
        ingredients: ["木炭": 1, "海水": 1],
        products: ["塩": 18],
    };

    {
        // 必要なレシピ・素材を全て列挙
        typeof(RecipeGraph.defaultPreference) pref = null;
        auto graph = new RecipeGraph(["ロースト タイガー ミート", "ロースト ライオン ミート"],
                                     [
                                         "ロースト タイガー ミート": roastTiger,
                                         "ロースト ライオン ミート": roastLion,
                                         "塩(岩塩)": salt1,
                                         "塩(木炭＋海水)": salt2,
                                     ],
                                     [
                                         "ロースト タイガー ミート"d: make!(RedBlackTree!dstring)("ロースト タイガー ミート"d),
                                         "ロースト ライオン ミート"d: make!(RedBlackTree!dstring)("ロースト ライオン ミート"d),
                                         "塩": make!(RedBlackTree!dstring)("塩(岩塩)"d, "塩(木炭＋海水)"d),
                                     ],
                                     pref);
        auto tpl = graph.elements;

        import std.algorithm;
        import std.array;
        assert(tpl.recipes.dup.sort().equal(
                   [
                       RecipeInfo("ロースト タイガー ミート", ""),
                       RecipeInfo("ロースト ライオン ミート", ""),
                       RecipeInfo("塩(岩塩)", "塩"),
                       RecipeInfo("塩(木炭＋海水)", "塩"),
                   ]));
        auto rs = tpl.recipes.map!"a.name".array;
        assert(rs.indexOf("ロースト タイガー ミート"d) < rs.indexOf("塩(岩塩)"d));
        assert(rs.indexOf("ロースト タイガー ミート"d) < rs.indexOf("塩(木炭＋海水)"d));
        assert(rs.indexOf("ロースト ライオン ミート"d) < rs.indexOf("塩(岩塩)"d));
        assert(rs.indexOf("ロースト ライオン ミート"d) < rs.indexOf("塩(木炭＋海水)"d));

        assert(tpl.materials.dup.sort().equal(
                   [
                       MaterialInfo("トラの肉", true),
                       MaterialInfo("ライオンの肉", true),
                       MaterialInfo("ロースト タイガー ミート", false),
                       MaterialInfo("ロースト ライオン ミート", false),
                       MaterialInfo("塩", false),
                       MaterialInfo("岩塩", true),
                       MaterialInfo("木炭", true),
                       MaterialInfo("海水", true),
                   ]));
        auto mats = tpl.materials.map!"a.name".array;
        assert(mats.indexOf("ロースト ライオン ミート"d) < mats.indexOf("ライオンの肉"d));
        assert(mats.indexOf("ロースト ライオン ミート"d) < mats.indexOf("塩"d));
        assert(mats.indexOf("ロースト タイガー ミート"d) < mats.indexOf("トラの肉"d));
        assert(mats.indexOf("ロースト タイガー ミート"d) < mats.indexOf("塩"d));
        assert(mats.indexOf("塩"d) < mats.indexOf("岩塩"d));
        assert(mats.indexOf("塩"d) < mats.indexOf("木炭"d));
        assert(mats.indexOf("塩"d) < mats.indexOf("海水"d));
    }

    {
        // 塩(岩塩)のレシピを使う場合のレシピ・素材を列挙
        auto pref = ["塩"d: "塩(岩塩)"d];
        auto graph = new RecipeGraph(["ロースト タイガー ミート", "ロースト ライオン ミート"],
                                     [
                                         "ロースト タイガー ミート": roastTiger,
                                         "ロースト ライオン ミート": roastLion,
                                         "塩(岩塩)": salt1,
                                         "塩(木炭＋海水)": salt2,
                                     ],
                                     [
                                         "ロースト タイガー ミート"d: make!(RedBlackTree!dstring)("ロースト タイガー ミート"d),
                                         "ロースト ライオン ミート"d: make!(RedBlackTree!dstring)("ロースト ライオン ミート"d),
                                         "塩": make!(RedBlackTree!dstring)("塩(岩塩)"d, "塩(木炭＋海水)"d),
                                     ],
                                     pref);
        auto tpl = graph.elements;

        import std.algorithm;
        import std.array;
        assert(tpl.recipes.dup.sort().equal(
                   [
                       RecipeInfo("ロースト タイガー ミート", ""),
                       RecipeInfo("ロースト ライオン ミート", ""),
                       RecipeInfo("塩(岩塩)", ""),
                   ]));
        auto rs = tpl.recipes.map!"a.name".array;
        assert(rs.back == "塩(岩塩)");

        assert(tpl.materials.dup.sort().equal(
                   [
                       MaterialInfo("トラの肉", true),
                       MaterialInfo("ライオンの肉", true),
                       MaterialInfo("ロースト タイガー ミート", false),
                       MaterialInfo("ロースト ライオン ミート", false),
                       MaterialInfo("塩", false),
                       MaterialInfo("岩塩", true),
                   ]));
        auto mats = tpl.materials.map!"a.name".array;
        assert(mats.indexOf("ロースト ライオン ミート"d) < mats.indexOf("ライオンの肉"d));
        assert(mats.indexOf("ロースト ライオン ミート"d) < mats.indexOf("塩"d));
        assert(mats.indexOf("ロースト タイガー ミート"d) < mats.indexOf("トラの肉"d));
        assert(mats.indexOf("ロースト タイガー ミート"d) < mats.indexOf("塩"d));
        assert(mats.indexOf("塩"d) < mats.indexOf("岩塩"d));
    }
}

unittest
{
    import std.container;

    import coop.core.recipe;

    Recipe cheesePie = {
        name: "チーズ パイ",
        ingredients: [
            "チーズ": 1,
            "パイ生地": 1,
            ],
        products: ["チーズ パイ": 2],
    };
    Recipe piePaste = {
        name: "パイ生地(ミニ ウォーター ボトル)",
        ingredients: ["小麦粉": 1, "バター": 1, "ミニ ウォーター ボトル": 1],
        products: ["パイ生地": 1],
    };
    Recipe butter = {
        name: "バター",
        ingredients: ["塩": 1, "ミルク": 1],
        products: ["バター": 1],
    };
    Recipe flour = {
        name: "小麦粉",
        ingredients: ["小麦": 1, "臼": 1],
        products: ["小麦粉": 5],
    };
    Recipe cheese = {
        name: "チーズ",
        ingredients: ["酢": 1, "塩": 1, "ミルク": 1],
        products: ["チーズ": 1],
    };
    Recipe salt = {
        name: "塩(岩塩)",
        ingredients: ["岩塩": 1],
        products: ["塩": 7],
    };

    auto graph = new RecipeGraph(["チーズ パイ"],
                                 [
                                     "チーズ パイ": cheesePie,
                                     "パイ生地(ミニ ウォーター ボトル)": piePaste,
                                     "バター": butter,
                                     "小麦粉": flour,
                                     "チーズ": cheese,
                                     "塩(岩塩)": salt,
                                 ],
                                 [
                                     "チーズ パイ"d: make!(RedBlackTree!dstring)("チーズ パイ"d),
                                     "パイ生地"d: make!(RedBlackTree!dstring)("パイ生地(ミニ ウォーター ボトル)"d),
                                     "バター"d: make!(RedBlackTree!dstring)("バター"d),
                                     "小麦粉"d: make!(RedBlackTree!dstring)("小麦粉"d),
                                     "チーズ"d: make!(RedBlackTree!dstring)("チーズ"d),
                                     "塩": make!(RedBlackTree!dstring)("塩(岩塩)"d),
                                 ]);
    auto tpl = graph.elements(["チーズ パイ": 1], ["塩": 1]);
    assert(tpl.recipes == [
               "チーズ パイ"d: 1,
               "パイ生地(ミニ ウォーター ボトル)": 1,
               "バター": 1,
               "小麦粉": 1,
               "チーズ": 1,
               "塩(岩塩)": 1,
               ]);
    assert(tpl.materials == [
               "小麦粉": MatTuple(1, true),
               "ミルク": MatTuple(2, false),
               "チーズ": MatTuple(1, true),
               "パイ生地": MatTuple(1, true),
               "小麦": MatTuple(1, false),
               "岩塩": MatTuple(1, false),
               "バター": MatTuple(1, true),
               "ミニ ウォーター ボトル": MatTuple(1, false),
               "臼": MatTuple(1, false),
               "酢": MatTuple(1, false),
               "チーズ パイ"d: MatTuple(1, true),
               "塩": MatTuple(2, true),
               ]);
    assert(tpl.leftovers == ["小麦粉": 4, "チーズ パイ"d: 1, "塩": 6]);
}

/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.recipe;

import std.json;

struct Recipe
{
    import std.container;

    /// レシピ名
    dstring name;

    /// 材料
    int[dstring] ingredients;

    /// 生成物
    int[dstring] products;

    /// 必要テクニック
    RedBlackTree!dstring techniques;

    /// 必要スキル
    real[dstring] requiredSkills;

    bool requiresRecipe;
    bool isGambledRoulette;
    bool isPenaltyRoulette;

    dstring remarks;

    auto opCmp(ref const typeof(this) other) const
    {
        if (name == other.name) return 0;
        else if (name < other.name) return -1;
        else return 1;
    }

    bool opEquals(ref const typeof(this) other) const @safe pure nothrow
    {
        return name == other.name;
    }

    size_t toHash() const @safe pure nothrow
    {
        return name.hashOf;
    }

    /**
     * MoE 内に貼り付けるための短めの文字列を返す
     */
    auto toShortString() const
    {
        import std.algorithm;
        import std.format;
        import std.string;

        import coop.util;

        return format("%s (%s%s) = %s",
                      products.byKeyValue.map!(kv => format("%sx%s", kv.key.toHankaku.removechars(" "), kv.value)).join(","),
                      requiredSkills.byKeyValue.map!(kv => format("%s%.1f", kv.key.toHankaku.removechars(" "), kv.value)).join(","),
                      requiresRecipe ? ": ﾚｼﾋﾟ必須" : "",
                      ingredients.byKeyValue.map!(kv => format("%sx%s", kv.key.toHankaku.removechars(" "), kv.value)).join(" "));
    }
}

auto readRecipes(string file)
in{
    import std.file;

    assert(file.exists);
} body {
    import std.algorithm;
    import std.conv;
    import std.exception;
    import std.file;
    import std.path;
    import std.range;
    import std.typecons;

    auto category = file.baseName(".json");
    auto res = file.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);

    auto recipes = res.object;
    return tuple(category.to!dstring,
                 recipes.keys
                        .map!(key =>
                              tuple(key.to!dstring,
                                    key.toRecipe(recipes[key].object)))
                        .assocArray);
}

auto toRecipe(string s, JSONValue[string] json)
{
    Recipe ret;
    with(ret) {
        import std.conv;
        import std.container;

        import coop.util;

        name = s.to!dstring;
        ingredients = json["材料"].jto!(int[dstring]);
        products = json["生成物"].jto!(int[dstring]);
        techniques = make!(typeof(techniques))(json["テクニック"].jto!(dstring[]));
        requiredSkills = json["スキル"].jto!(real[dstring]);
        requiresRecipe = json["レシピが必要"].jto!bool;
        isGambledRoulette = json["ギャンブル型"].jto!bool;
        isPenaltyRoulette = json["ペナルティ型"].jto!bool;
        if (auto rem = ("備考" in json))
        {
            remarks = (*rem).jto!dstring;
        }
    }
    return ret;
}

@safe pure nothrow unittest
{
    Recipe r1;
    r1.name = "ロースト スネーク ミート"d;
    assert(r1 == r1);
    assert(r1.toHash == r1.toHash);
}

@safe pure nothrow unittest
{
    Recipe r1;
    r1.name = "ロースト スネーク ミート"d;

    Recipe r2;
    r2.name = "ライス";
    assert(r1 > r2);
    assert(r1.toHash != r2.toHash);

    Recipe r3;
    r3.name = "ワイン"d;
    assert(r1 < r3);
    assert(r1.toHash != r3.toHash);
}

unittest
{
    import std.algorithm;
    import std.range;

    auto name = "ロースト スネーク ミート";
    auto json = ["材料": JSONValue([ "ヘビの肉": 1 ]),
                 "生成物": JSONValue([ "ロースト スネーク ミート": 1 ]),
                 "テクニック": JSONValue([ "料理(焼く)" ]),
                 "スキル": JSONValue([ "料理": 0.0 ]),
                 "レシピが必要": JSONValue(false),
                 "ギャンブル型": JSONValue(false),
                 "ペナルティ型": JSONValue(false)];
    auto recipe = name.toRecipe(json);
    assert(recipe.name == "ロースト スネーク ミート");
    assert(recipe.ingredients == ["ヘビの肉"d: 1]);
    assert(recipe.products == ["ロースト スネーク ミート"d: 1]);
    assert(recipe.techniques[].equal(["料理(焼く)"d]));
    assert(!recipe.requiresRecipe);
    assert(!recipe.isGambledRoulette);
    assert(!recipe.isPenaltyRoulette);
    assert(recipe.remarks.empty);
    assert(recipe.toShortString == "ﾛｰｽﾄｽﾈｰｸﾐｰﾄx1 (料理0.0) = ﾍﾋﾞの肉x1");
}

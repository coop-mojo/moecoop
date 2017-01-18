/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.recipe;

import std.json;

struct Recipe
{
    import vibe.data.json: name_ = name, optional;

    @name_("名前") string name;
    @name_("材料") int[string] ingredients;
    @name_("生成物") int[string] products;
    @name_("テクニック") string[] techniques;
    @name_("スキル") double[string] requiredSkills;
    @name_("レシピが必要") bool requiresRecipe;
    @name_("ギャンブル型") bool isGambledRoulette;
    @name_("ペナルティ型") bool isPenaltyRoulette;
    @name_("備考") @optional string remarks;

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

    size_t toHash() const @trusted pure nothrow
    {
        return name.hashOf;
    }

    auto opCast(T: bool)()
    {
        import std.range;
        return !name.empty;
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
    import vibe.data.json;

    import std.algorithm;
    import std.file;
    import std.path;
    import std.range;
    import std.typecons;

    auto category = file.baseName(".json");
    return tuple(category,
                 file.readText
                     .parseJsonString
                     .deserialize!(JsonSerializer, Recipe[])
                     .map!"tuple(a.name, a)"
                     .assocArray);
}

@safe pure nothrow unittest
{
    Recipe r1;
    r1.name = "ロースト スネーク ミート";
    assert(r1 == r1);
    assert(r1.toHash == r1.toHash);
}

@safe pure nothrow unittest
{
    Recipe r1;
    r1.name = "ロースト スネーク ミート";

    Recipe r2;
    r2.name = "ライス";
    assert(r1 > r2);
    assert(r1.toHash != r2.toHash);

    Recipe r3;
    r3.name = "ワイン";
    assert(r1 < r3);
    assert(r1.toHash != r3.toHash);
}

unittest
{
    import vibe.data.json;
    auto str = q"EOS
{
    "名前": "ロースト スネーク ミート",
    "材料": {
        "ヘビの肉": 1
    },
    "生成物": {
        "ロースト スネーク ミート": 1
    },
    "テクニック": [
        "料理(焼く)"
    ],
    "スキル": {
        "料理": 0.0
    },
    "レシピが必要": false,
    "ギャンブル型": false,
    "ペナルティ型": false
}
EOS";
    auto recipe = str.parseJsonString.deserialize!(JsonSerializer, Recipe);
    assert(recipe.toShortString == "ﾛｰｽﾄｽﾈｰｸﾐｰﾄx1 (料理0.0) = ﾍﾋﾞの肉x1");
}

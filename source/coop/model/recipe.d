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
module coop.model.recipe;

import std.algorithm;
import std.array;
import std.container.rbtree;
import std.container.util;
import std.conv;
import std.exception;
import std.file;
import std.json;
import std.typecons;

import coop.util;

struct Recipe
{
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
}

auto readRecipes(string file)
in{
    assert(file.exists);
} body {
    import std.path;
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

unittest
{
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
}

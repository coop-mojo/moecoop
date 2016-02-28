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
module coop.model.wisdom;

import std.algorithm;
import std.array;
import std.exception;
import std.file;
import std.path;
import std.typecons;

import coop.model.item;
import coop.model.recipe;

alias Binder = Typedef!(dstring, "binder");
alias Category = Typedef!(dstring, "category");

class Wisdom {
    /// バインダーごとのレシピ名一覧
    dstring[][dstring] binderList;

    /// カテゴリごとのレシピ一覧
    Recipe[dstring][dstring] recipeList;

    /// アイテム一覧
    Item[dstring] itemList;

    /// 料理一覧
    Food[dstring] foodList;

    /// 飲食バフ一覧
    AdditionalEffect[dstring] foodEffectList;

    /// システムデータが保存してあるパス
    immutable string baseDir_;

    this(string baseDir)
    {
        baseDir_ = baseDir;
        binderList = readBinderList(baseDir_);
        recipeList = readRecipeList(baseDir_);
        itemList = readItemList(baseDir_);
        foodList = readFoodList(baseDir_);
        foodEffectList = readFoodEffectList(baseDir_);
    }

    auto readBinderList(string basedir)
    {
        enforce(basedir.exists);
        enforce(basedir.isDir);

        return dirEntries(buildPath(basedir, "バインダー"), "*.json", SpanMode.breadth)
            .map!(s => s.readBinders)
            .array
            .joiner
            .assocArray;
    }

    auto readRecipeList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        return dirEntries(buildPath(sysBase, "レシピ"), "*.json", SpanMode.breadth)
            .map!(s => s.readRecipes)
            .assocArray;
    }

    auto readItemList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        return dirEntries(buildPath(sysBase, "アイテム"), "*.json", SpanMode.breadth)
            .map!(s => s.readItems)
            .array
            .joiner
            .assocArray;
    }

    auto readFoodList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        return dirEntries(buildPath(sysBase, "食べ物"), "*.json", SpanMode.breadth)
            .map!(s => s.readFoods)
            .joiner
            .assocArray;
    }

    auto readFoodEffectList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        return dirEntries(buildPath(sysBase, "飲食バフ"), "*.json", SpanMode.breadth)
            .map!(s => s.readFoodEffects)
            .joiner
            .assocArray;
    }

    @property auto recipeCategories()
    {
        return recipeList.keys.sort().array;
    }

    auto recipesIn(Category name)
    {
        enforce(name in recipeList);
        return recipeList[cast(dstring)name];
    }

    @property auto binders()
    {
        return binderList.keys.sort().array;
    }

    auto recipesIn(Binder name)
    {
        enforce(name in binderList);
        return binderList[cast(dstring)name];
    }

    auto recipeFor(dstring recipeName)
    {
        auto ret = recipeCategories.find!(c => recipeName in recipesIn(Category(c)));
        if (ret.empty)
        {
            import std.container.util;
            Recipe dummy;
            dummy.techniques = make!(typeof(dummy.techniques))(cast(dstring)[]);
            return dummy;
        }
        else
        {
            return recipesIn(Category(ret.front))[recipeName];
        }
    }

    auto bindersFor(dstring recipeName)
    {
        return binders.filter!(b => recipesIn(Binder(b)).canFind(recipeName)).array;
    }
}

auto readBinders(string file)
{
    import std.json;
    import std.conv;

    enforce(file.exists);
    auto res = file
               .readText
               .parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    return res
        .object
        .byKeyValue
        .map!((kv) {
                auto binder = kv.key.to!dstring;
                enforce(kv.value.type == JSON_TYPE.ARRAY);
                auto recipes = kv.value.array.map!(e => e.str).array.to!(dstring[]);
                return tuple(binder, recipes);
            });
}

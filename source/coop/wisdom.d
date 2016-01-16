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
module coop.wisdom;

import std.algorithm;
import std.array;
import std.exception;
import std.file;
import std.path;
import std.typecons;

import coop.item;
import coop.union_binder;
import coop.recipe;

alias Binder = Typedef!(dstring, "binder");
alias Category = Typedef!(dstring, "category");

struct Wisdom{
    /// バインダーごとのレシピ名一覧
    BinderElement[][dstring] binderList;

    /// カテゴリごとのレシピ一覧
    Recipe[dstring][dstring] recipeList;

    /// アイテム一覧
    Item[dstring] itemList;

    /// 料理一覧
    Food[dstring] foodList;

    /// 飲食バフ一覧
    AdditionalEffect[dstring] foodEffectList;

    /// システムデータが保存してあるパス
    immutable string sysBase_;

    /// ユーザーデータを保存するパス
    immutable string userBase_;

    this(string sysBase, string userBase)
    {
        sysBase_ = sysBase;
        userBase_ = userBase;
        binderList = readBinderList(sysBase, userBase);
        recipeList = readRecipeList(sysBase, userBase);
        itemList = readItemList(sysBase, userBase);
        foodList = readFoodList(sysBase);
        foodEffectList = readFoodEffectList(sysBase);
    }

    auto readBinderList(string sysBase, string userBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        return dirEntries(buildPath(sysBase, "バインダー"), "*.json", SpanMode.breadth)
            .map!(s => s.readBinders(sysBase, userBase))
            .joiner
            .assocArray;
    }

    auto readRecipeList(string sysBase, string userBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        return dirEntries(buildPath(sysBase, "レシピ"), "*.json", SpanMode.breadth)
            .map!(s => s.readRecipes(sysBase, userBase))
            .assocArray;
    }

    auto readItemList(string sysBase, string userBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        return dirEntries(buildPath(sysBase, "素材"), "*.json", SpanMode.breadth)
            .map!(s => s.readItems(sysBase, userBase))
            .array
            .joiner
            .assocArray;
    }

    auto readFoodList(string sysBase) {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        return dirEntries(buildPath(sysBase, "食べ物"), "*.json", SpanMode.breadth)
            .map!(s => s.readFoods(sysBase))
            .joiner
            .assocArray;
    }

    auto readFoodEffectList(string sysBase) {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        return dirEntries(buildPath(sysBase, "飲食バフ"), "*.json", SpanMode.breadth)
            .map!(s => s.readFoodEffects(sysBase))
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
        return binders.filter!(b => recipesIn(Binder(b)).canFind!(elem => elem.recipe == recipeName)).array;
    }

    ~this()
    {
        writeBinderList;
    }

    auto writeBinderList()
    {
        import std.json;
        import std.container.rbtree;

        auto userBinderDir = buildPath(userBase_, "バインダー");
        if (!userBinderDir.exists)
        {
            mkdirRecurse(userBinderDir);
        }

        JSONValue[string] binderFiles;
        foreach(kv; binderList.byKeyValue)
        {
            import std.conv;
            import std.regex;
            auto binder = kv.key.to!string;
            auto elems = kv.value.filter!(e => e.isFiled);
            if (elems.empty) continue;
            auto fileName = binder
                            .replaceFirst(ctRegex!r" No\.(\d)+$", "")
                            .replaceFirst(ctRegex!r"/", "_")
                            .to!string;
            bool[string] jsonElems;
            elems.each!(r => jsonElems[r.recipe.to!string] = r.isFiled);
            if (fileName !in binderFiles)
            {
                binderFiles[fileName] = JSONValue([binder: jsonElems]);
            }
            else
            {
                enforce(binderFiles[fileName].type == JSON_TYPE.OBJECT);
                binderFiles[fileName][binder] = jsonElems;
            }
        }

        auto existingBinders = make!(RedBlackTree!string)(dirEntries(buildPath(userBase_, "バインダー"), "*.json", SpanMode.breadth));
        foreach(kv; binderFiles.byKeyValue)
        {
            import std.stdio;
            auto path = buildPath(userBinderDir, kv.key~".json");
            auto f = File(path, "w");
            f.write(kv.value.toPrettyString);
            existingBinders.removeKey(path);
        }

        existingBinders[].each!((string file) {
                file.remove;
            });
    }
}

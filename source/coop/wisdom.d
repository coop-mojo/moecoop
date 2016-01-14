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

import coop.union_binder;
import coop.recipe;

alias Binder = Typedef!(dstring, "binder");
alias Category = Typedef!(dstring, "category");

struct Wisdom{
    /// バインダーごとのレシピ名一覧
    BinderElement[][dstring] binderList;

    /// カテゴリごとのレシピ一覧
    Recipe[dstring][dstring] recipeList;

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

    auto relatedBinders(Category cat)
    {
        immutable binderMap = [
            "料理"d: [ "食べ物"d, "カオス", "材料/道具", "家具", "QoAクエスト", ], // "チュートリアル用"
            "醸造": [ "飲み物"d, "カオス", ],
            "鍛冶": [ "鍛冶"d, "材料/道具", "QoAクエスト", "カオス", "家具", "楽器"],
            "木工": [ "木工"d, "材料/道具", "鍛冶", "QoAクエスト", "カオス", "家具", "家", "楽器", ],
            "裁縫": [ "裁縫"d, "材料/道具", "QoAクエスト", "カオス", "家具", ],
            "装飾": [ "材料/道具"d, "アクセサリー", "カオス", "QoAクエスト", "楽器", "家具", ],
            "複製": [ "材料/道具"d, "複製", ],
            "調合": [ "材料/道具"d, "飲み物", "カオス", "QoAクエスト", ],
            "合成": [ "罠"d, ],
            // "美容": [], // 含めるかどうかは後で考える
            // "栽培": [],
            "複合": [ "材料/道具"d, "鍛冶", "木工", "裁縫", "アクセサリー", "QoAクエスト", "家具", ],
            ];
        return binderMap[cast(dstring)cat];
    }

    auto relatedCategories(Binder binder)
    {
        immutable categoryMap = [
            "QoAクエスト"d: [ "鍛冶"d, "木工", "裁縫", "料理", "複合", "装飾", "調合", ],
            "アクセサリー": [],
            "カオス": [],
            "飲み物": [],
            "家": [],
            "家具": ["罠"d, ],
            "楽器": [],
            "裁縫": [],
            "材料/道具": [], // "材料\/道具" の可能性あり
            "食べ物": [ "料理"d,  ],
            "鍛冶": [ "鍛冶"d, "複合", ],
            "複製": [],
            "木工": [],
            "罠": [ "合成"d, ],
            "アセット": [], /// 上には含まれていないものがあったはず
            ];
        return categoryMap[cast(dstring)binder];
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

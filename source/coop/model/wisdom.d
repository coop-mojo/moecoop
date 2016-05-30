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
import std.conv;
import std.exception;
import std.file;
import std.json;
import std.path;
import std.typecons;

import coop.model.item;
import coop.model.recipe;
import coop.util;

alias Binder = Typedef!(dstring, "binder");
alias Category = Typedef!(dstring, "category");

class Wisdom {
    /// バインダーごとのレシピ名一覧
    dstring[][dstring] binderList;

    /// カテゴリごとのレシピ一覧
    Recipe[dstring][dstring] recipeList;

    /// アイテム一覧
    Item[dstring] itemList;

    /// 飲食バフ一覧
    AdditionalEffect[dstring] foodEffectList;

    /// アイテム種別ごとの固有情報一覧
    ExtraInfo[dstring][ItemType] extraInfoList;

    /// システムデータが保存してあるパス
    immutable string baseDir_;

    this(string baseDir)
    {
        baseDir_ = baseDir;
        reload;
    }

    auto reload()
    {
        binderList = readBinderList(baseDir_);
        recipeList = readRecipeList(baseDir_);
        foodEffectList = readFoodEffectList(baseDir_);

        with(ItemType)
        {
            extraInfoList[Food.to!ItemType] = readFoodList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Drink.to!ItemType] = readDrinkList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Liquor.to!ItemType] = readLiquorList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Weapon.to!ItemType] = readWeaponList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Bullet.to!ItemType] = readBulletList(baseDir_).to!(ExtraInfo[dstring]);
        }
        itemList = readItemList(baseDir_);
    }

    auto readBinderList(string basedir)
    {
        enforce(basedir.exists);
        enforce(basedir.isDir);

        auto dir = buildPath(basedir, "バインダー");
        if (!dir.exists)
        {
            return typeof(binderList).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
            .map!(s => s.readBinders)
            .array
            .joiner
            .assocArray;
    }

    auto readRecipeList(string basedir)
    {
        enforce(basedir.exists);
        enforce(basedir.isDir);

        auto dir = buildPath(basedir, "レシピ");
        if (!dir.exists)
        {
            return typeof(recipeList).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
            .map!(s => s.readRecipes)
            .assocArray;
    }

    auto readItemList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto dir = buildPath(sysBase, "アイテム");
        if (!dir.exists)
        {
            return typeof(itemList).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
            .map!(s => s.readItems)
            .array
            .joiner
            .assocArray;
    }

    auto readFoodList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto dir = buildPath(sysBase, "食べ物");
        if (!dir.exists)
        {
            return (FoodInfo[dstring]).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
            .map!(s => s.readFoods)
            .joiner
            .assocArray;
    }

    auto readDrinkList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto file = buildPath(sysBase, "飲み物", "飲み物.json");
        if (!file.exists)
        {
            return (FoodInfo[dstring]).init;
        }
        return file.readFoods.assocArray;
    }

    auto readLiquorList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto file = buildPath(sysBase, "飲み物", "酒.json");
        if (!file.exists)
        {
            return (FoodInfo[dstring]).init;
        }
        return buildPath(sysBase, "飲み物", "酒.json").readFoods.assocArray;
    }

    auto readWeaponList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto file = buildPath(sysBase, "武器", "武器.json");
        if (!file.exists)
        {
            return (WeaponInfo[dstring]).init;
        }
        return buildPath(sysBase, "武器", "武器.json").readWeapons.assocArray;
    }

    auto readBulletList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto file = buildPath(sysBase, "武器", "弾.json");
        if (!file.exists)
        {
            return (BulletInfo[dstring]).init;
        }
        return buildPath(sysBase, "武器", "弾.json").readBullets.assocArray;
    }

    auto readFoodEffectList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto dir = buildPath(sysBase, "飲食バフ");
        if (!dir.exists)
        {
            return typeof(foodEffectList).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
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

    auto save()
    {
        import std.stdio;
        import std.conv;

        foreach(dir; ["アイテム", "バインダー", "レシピ", "飲み物", "飲食バフ",
                      "食べ物", "武器", "防具"])
        {
            mkdirRecurse(buildPath(baseDir_, dir));
        }

        auto f = File(buildPath(baseDir_, "アイテム", "アイテム.json"), "w");
        f.write(JSONValue(itemList.values
                          .map!(item => tuple(item.name.to!string, item.toJSON))
                          .assocArray).toPrettyString);
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
                auto recipes = kv.value.jto!(dstring[]);
                return tuple(binder, recipes);
            });
}

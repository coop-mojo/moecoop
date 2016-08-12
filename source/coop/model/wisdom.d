/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.model.wisdom;

import std.algorithm;
import std.array;
import std.conv;
import std.container;
import std.exception;
import std.file;
import std.json;
import std.path;
import std.range;
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

    /// 素材を作成するレシピ名一覧
    RedBlackTree!dstring[dstring] rrecipeList;

    /// アイテム一覧
    Item[dstring] itemList;

    /// 飲食バフ一覧
    AdditionalEffect[dstring] foodEffectList;

    /// アイテム種別ごとの固有情報一覧
    ExtraInfo[dstring][ItemType] extraInfoList;

    this(string baseDir)
    {
        baseDir_ = baseDir;
        reload;
    }

    auto reload()
    {
        binderList = readBinderList(baseDir_);
        recipeList = readRecipeList(baseDir_);
        rrecipeList = genRRecipeList(recipeList.values.map!(a => a.values).join);
        foodEffectList = readFoodEffectList(baseDir_);

        with(ItemType)
        {
            extraInfoList[Food.to!ItemType] = readFoodList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Drink.to!ItemType] = readDrinkList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Liquor.to!ItemType] = readLiquorList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Weapon.to!ItemType] = readWeaponList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Armor.to!ItemType] = (ExtraInfo[dstring]).init;
            extraInfoList[Bullet.to!ItemType] = readBulletList(baseDir_).to!(ExtraInfo[dstring]);
        }
        itemList = readItemList(baseDir_);
    }

    @property auto recipeCategories() const pure nothrow
    {
        return recipeList.keys.sort().array;
    }

    auto recipesIn(Category name) @safe pure nothrow
    in {
        assert(name in recipeList);
    } body {
        return recipeList[cast(dstring)name];
    }

    @property auto binders() const pure nothrow
    {
        return binderList.keys.sort().array;
    }

    auto recipesIn(Binder name) @safe pure nothrow
    in {
        assert(name in binderList);
    } body {
        return binderList[cast(dstring)name];
    }

    auto recipeFor(dstring recipeName) pure
    {
        auto ret = recipeCategories.find!(c => recipeName in recipesIn(Category(c)));
        if (ret.empty)
        {
            import std.container.util;
            Recipe dummy;
            dummy.techniques = make!(typeof(dummy.techniques))(null);
            return dummy;
        }
        else
        {
            return recipesIn(Category(ret.front))[recipeName];
        }
    }

    auto bindersFor(dstring recipeName) pure nothrow
    {
        return binders.filter!(b => recipesIn(Binder(b)).canFind(recipeName)).array;
    }

    auto save() const
    {
        import std.stdio;
        import std.conv;

        foreach(dir; ["アイテム", "バインダー", "レシピ", "飲み物", "飲食バフ",
                      "食べ物", "武器", "弾", "防具", "盾"])
        {
            mkdirRecurse(buildPath(baseDir_, dir));
        }

        auto f = File(buildPath(baseDir_, "アイテム", "アイテム.json"), "w");
        f.write(JSONValue(itemList.values
                          .map!(item => tuple(item.name.to!string, item.toJSON))
                          .assocArray).toPrettyString);
    }
private:
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
            .map!readBinders
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
            .map!readRecipes
            .checkedAssocArray;
    }

    auto genRRecipeList(Recipe[] recipes) const pure
    {
        RedBlackTree!dstring[dstring] ret;
        recipes.each!((r) {
                r.products.keys.each!((p) {
                        if (p !in ret)
                        {
                            ret[p] = make!(RedBlackTree!dstring)(r.name);
                        }
                        else
                        {
                            ret[p].insert(r.name);
                        }
                    });
            });
        return ret;
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
            .map!readItems
            .array
            .joiner
            .checkedAssocArray;
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
            .map!readFoods
            .joiner
            .checkedAssocArray;
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
        return file.readFoods.checkedAssocArray;
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
        return buildPath(sysBase, "飲み物", "酒.json").readFoods.checkedAssocArray;
    }

    auto readWeaponList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto dir = buildPath(sysBase, "武器");
        if (!dir.exists)
        {
            return (WeaponInfo[dstring]).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
            .map!readWeapons
            .joiner
            .checkedAssocArray;
    }

    auto readBulletList(string sysBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        auto dir = buildPath(sysBase, "弾");
        if (!dir.exists)
        {
            return (BulletInfo[dstring]).init;
        }
        return dirEntries(dir, "*.json", SpanMode.breadth)
            .map!readBullets
            .joiner
            .checkedAssocArray;
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
            .map!readFoodEffects
            .joiner
            .checkedAssocArray;
    }

    /// データが保存してあるパス
    immutable string baseDir_;
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

unittest
{
    auto w = assertNotThrown(new Wisdom(SystemResourceBase));
    assert(w.recipeCategories.equal(["合成"d, "料理", "木工", "特殊", "薬調合", "裁縫", "装飾細工", "複合", "醸造", "鍛冶"]));
    assert(w.binders.equal(["QoAクエスト"d, "アクセサリー", "アクセサリー No.2", "カオス", "家", "家具", "木工", "木工 No.2",
                            "材料/道具", "材料/道具 No.2", "楽器", "罠", "裁縫", "裁縫 No.2", "複製",
                            "鍛冶 No.1", "鍛冶 No.2", "鍛冶 No.3", "鍛冶 No.4", "鍛冶 No.5", "鍛冶 No.6", "鍛冶 No.7",
                            "食べ物", "食べ物 No.2", "食べ物 No.3", "飲み物"]));

    assert(w.recipesIn(Binder("食べ物")).length == 128);
    assert("ロースト スネーク ミート"d in w.recipesIn(Category("料理")));

    assert(w.recipeFor("とても美味しい食べ物").name.empty);
    assert(w.recipeFor("ロースト スネーク ミート").ingredients == ["ヘビの肉"d: 1]);

    assert(w.bindersFor("ロースト スネーク ミート").equal(["食べ物"d]));
}

unittest
{
    auto w = assertNotThrown(new Wisdom("."));
    assert(w.binders.empty);
    assert(w.recipeCategories.empty);
}

unittest
{
    enum invalidDir = "__invalid__";
    mkdir(invalidDir);
    scope(exit) rmdirRecurse(invalidDir);

    auto w = assertNotThrown(new Wisdom(invalidDir));
    w.save;

    foreach(dir; ["アイテム", "バインダー", "レシピ", "飲み物", "飲食バフ",
                  "食べ物", "武器", "防具"])
    {
        auto d = buildPath(invalidDir, dir);
        assert(d.exists);
        assert(d.isDir);
    }
    auto itemFile = buildPath(invalidDir, "アイテム", "アイテム.json");
    assert(itemFile.exists);
    assert(itemFile.readText == "{}");
}

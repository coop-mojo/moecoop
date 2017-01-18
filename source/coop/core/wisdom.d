/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.wisdom;

import std.typecons;

alias Binder = Typedef!(string, string.init, "binder");
alias Category = Typedef!(string, string.init, "category");

class Wisdom {
    import std.container;

    import coop.core.item;
    import coop.core.recipe;
    import coop.core.vendor;

    /// バインダーごとのレシピ名一覧
    string[][string] binderList;

    /// スキルカテゴリごとのレシピ名一覧
    RedBlackTree!string[string] skillList;

    /// レシピ一覧
    Recipe[string] recipeList;

    /// 素材を作成するレシピ名一覧
    RedBlackTree!string[string] rrecipeList;

    /// アイテム一覧
    Item[string] itemList;

    /// 飲食バフ一覧
    AdditionalEffect[string] foodEffectList;

    /// アイテム種別ごとの固有情報一覧
    ExtraInfo[string][ItemType] extraInfoList;

    /// 販売員情報
    Vendor[string] vendorList;

    /// アイテムごとの売店での販売価格一覧
    int[string] vendorPriceList;

    this(string baseDir)
    {
        baseDir_ = baseDir;
        reload;
    }

    auto reload()
    {
        import std.algorithm;
        import std.array;

        binderList = readBinderList(baseDir_);
        auto tmp = readRecipeList(baseDir_);
        recipeList = tmp.recipes;
        skillList = tmp.skillList;

        rrecipeList = genRRecipeList(recipeList.values);
        foodEffectList = readFoodEffectList(baseDir_);

        with(ItemType)
        {
            import std.conv;

            extraInfoList[Food.to!ItemType] = readFoodList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Drink.to!ItemType] = readDrinkList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Liquor.to!ItemType] = readLiquorList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Weapon.to!ItemType] = readWeaponList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Armor.to!ItemType] = readArmorList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Bullet.to!ItemType] = readBulletList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Shield.to!ItemType] = readShieldList(baseDir_).to!(ExtraInfo[string]);
        }
        itemList = readItemList(baseDir_);

        vendorList = readVendorList(baseDir_);
        vendorPriceList = genVendorPriceList(vendorList.values);
    }

    @property auto recipeCategories() const pure nothrow
    {
        import std.algorithm;
        import std.array;

        return skillList.keys.sort().array;
    }

    auto recipesIn(Category name) @safe pure nothrow
    in {
        assert(name in skillList);
    } body {
        return skillList[cast(string)name];
    }

    @property auto binders() const pure nothrow
    {
        import std.algorithm;
        import std.array;

        return binderList.keys.sort().array;
    }

    auto recipesIn(Binder name) @safe pure nothrow
    in {
        assert(name in binderList);
    } body {
        return binderList[cast(string)name];
    }

    auto recipeFor(string recipeName) pure
    {
        return recipeList.get(recipeName, Recipe.init);
    }

    auto bindersFor(string recipeName) pure nothrow
    {
        import std.algorithm;
        import std.range;

        return binders.filter!(b => recipesIn(Binder(b)).canFind(recipeName)).array;
    }

private:
    auto readBinderList(string basedir)
    {
        import std.algorithm;
        import std.exception;
        import std.file;
        import std.path;
        import std.range;

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
        import std.algorithm;
        import std.exception;
        import std.file;
        import std.path;
        import std.range;

        import coop.util;

        enforce(basedir.exists);
        enforce(basedir.isDir);

        alias RetType = Tuple!(typeof(skillList), "skillList",
                               typeof(recipeList), "recipes");
        auto dir = buildPath(basedir, "レシピ");
        if (!dir.exists)
        {
            return RetType.init;
        }

        auto lst = dirEntries(dir, "*.json", SpanMode.breadth)
                   .map!readRecipes
                   .checkedAssocArray;
        auto slist = lst.byKeyValue
                        .map!(kv => tuple(kv.key,
                                          make!(RedBlackTree!string)(kv.value.keys)))
                        .assocArray;
        auto rlist = lst.values
                        .map!"a.byPair"
                        .joiner
                        .assocArray;
        return RetType(slist, rlist);
    }

    auto genRRecipeList(Recipe[] recipes) const pure
    {
        import std.algorithm;

        RedBlackTree!string[string] ret;
        foreach(r; recipes)
        {
            foreach(p; r.products.keys)
            {
                if (p !in ret)
                {
                    ret[p] = make!(RedBlackTree!string)(r.name);
                }
                else
                {
                    ret[p].insert(r.name);
                }
            }
        }
        return ret;
    }

    auto readFoodEffectList(string sysBase)
    {
        import std.algorithm;
        import std.exception;
        import std.file;
        import std.path;

        import coop.util;

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

    auto readVendorList(string sysBase)
    {
        import std.algorithm;
        import std.exception;
        import std.file;
        import std.path;

        import coop.util;

        enforce(sysBase.exists);
        enforce(sysBase.isDir);
        auto dir = buildPath(sysBase, "売店");
        if (!dir.exists)
        {
            return typeof(vendorList).init;
        }
        return ["present", "ancient"].map!(d => buildPath(dir, d))
            .filter!(d => d.exists && d.isDir)
            .map!(d => dirEntries(d, "*.json", SpanMode.breadth))
            .joiner
            .map!readVendors
            .joiner
            .checkedAssocArray;
    }

    auto genVendorPriceList(Vendor[] vendors)
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        return vendors.map!(v => v.products.byKeyValue)
            .joiner
            .map!(kv => tuple(kv.key, kv.value.price))
            .assocArray;
    }

    /// データが保存してあるパス
    immutable string baseDir_;
}

auto readBinders(string file)
{
    import std.algorithm;
    import std.conv;
    import std.exception;
    import std.file;
    import std.json;

    enforce(file.exists);
    auto res = file
               .readText
               .parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    return res
        .object
        .byKeyValue
        .map!((kv) {
                import coop.util;

                auto binder = kv.key.to!string;
                enforce(kv.value.type == JSON_TYPE.ARRAY);
                auto recipes = kv.value.jto!(string[]);
                return tuple(binder, recipes);
            });
}

unittest
{
    import std.algorithm;
    import std.exception;
    import std.range;

    import coop.util;

    auto w = assertNotThrown(new Wisdom(SystemResourceBase));
    assert(w.recipeCategories.equal(["合成", "料理", "木工", "特殊", "薬調合", "裁縫", "装飾細工", "複合", "醸造", "鍛冶"]));
    assert(w.binders.equal(["QoAクエスト", "アクセサリー", "アクセサリー No.2", "カオス", "家", "家具", "木工", "木工 No.2",
                            "材料/道具", "材料/道具 No.2", "楽器", "罠", "裁縫", "裁縫 No.2", "複製",
                            "鍛冶 No.1", "鍛冶 No.2", "鍛冶 No.3", "鍛冶 No.4", "鍛冶 No.5", "鍛冶 No.6", "鍛冶 No.7",
                            "食べ物", "食べ物 No.2", "食べ物 No.3", "飲み物"]));

    assert(w.recipesIn(Binder("食べ物")).length == 128);
    assert("ロースト スネーク ミート" in w.recipesIn(Category("料理")));

    assert(w.recipeFor("とても美味しい食べ物").name.empty);
    assert(w.recipeFor("ロースト スネーク ミート").ingredients == ["ヘビの肉": 1]);

    assert(w.bindersFor("ロースト スネーク ミート").equal(["食べ物"]));
}

unittest
{
    import std.exception;
    import std.range;

    auto w = assertNotThrown(new Wisdom("."));
    assert(w.binders.empty);
    assert(w.recipeCategories.empty);
}

/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.model;

enum SortOrder {
    BySkill       = "スキル値順"d,
    ByName        = "名前順",
    ByBinderOrder = "バインダー順",
}

class WisdomModel
{
    /// コンストラクタ
    this(Wisdom w) @safe
    {
        wisdom = w;
        migemo = initMigemo;
    }

    /// Migemo 検索が利用可能かどうかを返す
    @property auto migemoAvailable() const @safe pure nothrow @nogc
    {
        return migemo !is null;
    }

    /// バインダー一覧を返す
    @property auto getBinderCategories() const pure nothrow
    {
        return wisdom.binders;
    }

    /// スキル一覧を返す
    @property auto getSkillCategories() const pure nothrow
    {
        return wisdom.recipeCategories;
    }

    /// レシピ情報を返す
    auto getRecipe(Str)(Str name) if (isSomeString!Str)
    {
        import std.conv;
        return wisdom.recipeFor(name.to!dstring);
    }

    /// アイテム情報を返す
    auto getItem(Str)(Str name) if (isSomeString!Str)
    {
        import std.conv;
        import coop.core.item;

        if (auto i = name.to!dstring in wisdom.itemList)
        {
            return *i;
        }
        else
        {
            Item item;
            item.petFoodInfo = [PetFoodType.UNKNOWN.to!PetFoodType: 0];
            return item;
        }
        assert(false);
    }

    /// レシピが収録されているバインダーを返す
    auto getBindersFor(Str)(Str name) if (isSomeString!Str)
    {
        import std.conv;
        return wisdom.bindersFor(name.to!dstring);
    }

    /// アイテムの固有情報を返す
    auto getExtraInfo(Str)(Str name) if (isSomeString!Str)
    {
        import std.conv;
        import std.typecons;
        import coop.core.item;

        alias RetType = Tuple!(ItemType, "type", ExtraInfo, "extra");

        if (auto i = name.to!dstring in wisdom.itemList)
        {
            if ((*i).type == ItemType.Others)
            {
                RetType ret;
                ret.type = ItemType.Others;
                return ret;
            }
            else if ((*i).type !in wisdom.extraInfoList ||
                     (*i).name !in wisdom.extraInfoList[(*i).type])
            {
                return RetType.init;
            }
            return RetType((*i).type, wisdom.extraInfoList[(*i).type][(*i).name]);
        }
        else
        {
            return RetType.init;
        }
        assert(false);
    }

    /// 飲食物のバフ効果を返す
    auto getFoodEffect(Str)(Str name) if (isSomeString!Str)
    {
        import std.conv;
        if (auto einfo = name.to!dstring in wisdom.foodEffectList)
        {
            return *einfo;
        }
        else
        {
            import coop.core.item;
            return AdditionalEffect.init;
        }
        assert(false);
    }

    /// binder に収録されているレシピ一覧を返す
    auto getRecipeList(Str)(Str query, Binder binder,
                            Flag!"useMetaSearch" useMetaSearch, Flag!"useMigemo" useMigemo)
        if (isSomeString!Str)
    {
        import std.algorithm;
        import std.array;
        import std.typecons;

        alias RecipePair = Tuple!(dstring, "category", dstring[], "recipes");

        auto allRecipes = useMetaSearch ?
                          wisdom.binders.map!(b => tuple(b, wisdom.recipesIn(Binder(b)))).assocArray :
                          [tuple(cast(dstring)binder, wisdom.recipesIn(binder))].assocArray;
        auto queryResult = getQueryResultBase(query, allRecipes, useMetaSearch, useMigemo);
        return queryResult.byKeyValue.map!((kv) {
                return [RecipePair(kv.key, kv.value.array)];
            }).joiner;
    }

    /// スキルカテゴリ category に分類されているレシピ一覧を返す
    auto getRecipeList(Str)(Str query, Category category,
                            Flag!"useMetaSearch" useMetaSearch, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch,
                            SortOrder order)
        if (isSomeString!Str)
    {
        import std.algorithm;
        import std.array;
        import std.typecons;

        alias RecipePair = Tuple!(dstring, "category", dstring[], "recipes");

        auto allRecipes = useMetaSearch ?
                          wisdom.recipeCategories.map!(c => tuple(c, wisdom.recipesIn(Category(c)).keys)).assocArray :
                          [tuple(cast(dstring)category, wisdom.recipesIn(category).keys)].assocArray;
        auto queryResult = getQueryResultBase(query, allRecipes, useMetaSearch, useMigemo, useReverseSearch);
        return queryResult.byKeyValue.map!((kv) {
                import std.range;
                auto category = kv.key;
                auto rs = kv.value;

                if (rs.empty)
                {
                    return [RecipePair(category, rs.array)];
                }

                final switch(order) with(SortOrder)
                {
                case BySkill:
                    auto levels(dstring s) {
                        auto arr = wisdom.recipeFor(s).requiredSkills.byKeyValue.map!(a => tuple(a.key, a.value)).array;
                        arr.multiSort!("a[0] < b[0]", "a[1] < b[1]");
                        return arr;
                    }
                    auto lvToStr(Tuple!(dstring, real)[] tpls)
                    {
                        import std.format;
                        return tpls.map!(t => format("%s (%.1f)"d, t.tupleof)).join(", ");
                    }
                    auto arr = rs.map!(a => tuple(a, levels(a))).array;
                    arr.multiSort!("a[1] < b[1]", "a[0] < b[0]");
                    return arr.chunkBy!"a[1]"
                              .map!(a => RecipePair(lvToStr(a[0]), a[1].map!"a[0]".array))
                              .array;
                case ByName:
                    return [RecipePair(category, rs.sort().array)];
                case ByBinderOrder:
                    assert(false);
                }
            }).joiner;
    }

    /// query にヒットするアイテム一覧を返す
    auto getItemList(Str)(Str query, Flag!"useMigemo" useMigemo, Flag!"canBeProduced" canBeProduced)
        if (isSomeString!Str)
    {
        import std.algorithm;
        import std.array;

        auto items = canBeProduced ?
                     wisdom.rrecipeList.keys :
                     wisdom.itemList.keys;
        auto queryFun = matchFunFor(query, useMigemo);
        return items.filter!queryFun.array;
    }

    /// 
    @property auto getDefaultPreference() const @safe pure nothrow
    {
        import coop.core.recipe_graph;
        return RecipeGraph.preference;
    }

    /// 
    auto getMenuRecipeResult(Str)(Str[] targets)
        if (isSomeString!Str)
    {
        import coop.core.recipe_graph;
        auto graph = new RecipeGraph(targets, wisdom, null);
        return graph.elements;
    }

    /// 
    auto getMenuRecipeResult(Str)(int[Str] targets, int[Str] owned, Str[Str] preference, RedBlackTree!Str terminals)
        if (isSomeString!Str)
    {
        import coop.core.recipe_graph;
        auto graph = new RecipeGraph(targets.keys, wisdom, preference);
        return graph.elements(targets, owned, wisdom, terminals);
    }

private:
    import std.container;
    import std.traits;
    import std.typecons;
    import coop.core.wisdom;
    import coop.migemo;

    auto getQueryResultBase(dstring query, dstring[][dstring] allRecipes,
                            Flag!"useMetaSearch" useMetaSearch, Flag!"useMigemo" useMigemo,
                            Flag!"useReverseSearch" useReverseSearch = No.useReverseSearch)
    {
        import std.algorithm;
        import std.range;
        import std.string;

        auto input = query.removechars(r"/[ 　]/");
        auto queryFun = matchFunFor(query, useMigemo, useReverseSearch);

        return input.empty ?
            allRecipes :
            allRecipes.byKeyValue
                      .map!(kv =>
                            tuple(kv.key,
                                  kv.value.filter!queryFun.array))
                      .filter!"!a[1].empty"
                      .assocArray;
    }

    auto matchFunFor(dstring query, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch = No.useReverseSearch)
    {
        import std.regex;
        import std.string;
        bool delegate(dstring) fun;
        if (useMigemo)
        {
            assert(migemo);
            try{
                auto q = migemo.query(query).regex;
                fun = (dstring s) => !s.removechars(r"/[ 　]/").matchFirst(q).empty;
            } catch(RegexException e) {
                // use default matchFun
            }
        }
        else
        {
            import std.algorithm;
            import std.range;

            fun = (dstring s) => !find(s.removechars(r"/[ 　]/"), boyerMooreFinder(query)).empty;
        }

        if (useReverseSearch)
        {
            import std.algorithm;
            return (dstring s) => wisdom.recipeFor(s).ingredients.keys.any!(ing => fun(ing));
        }
        else
        {
            return (dstring s) => fun(s);
        }
        assert(false);
    }

    static auto initMigemo() @safe
    {
        import std.file;

        auto info = migemoInfo;

        if (info.lib.exists)
        {
            Migemo m;
            try{
                import std.exception;
                import std.path;

                m = new Migemo(info.lib, info.dict);
                m.load(buildPath("resource", "dict", "moe-dict"));
                enforce(m.isEnable);
            } catch(MigemoException e) {
                m = null;
            }
            return m;
        }
        else
        {
            return null;
        }
        assert(false);
    }

    static auto migemoInfo() @safe nothrow
    {
        import std.algorithm;
        import std.file;
        import std.range;
        import std.typecons;

        alias LibInfo = Tuple!(string, "lib", string, "dict");
        version(Windows)
        {
            version(X86)
            {
                enum candidates = [LibInfo.init];
            }
            else version(X86_64)
            {
                enum candidates = [LibInfo(`migemo.dll`, `resource\dict\dict`)];
            }
        }
        else version(linux)
        {
            import std.format;

            version(X86)
            {
                enum arch = "i386-linux-gnu";
            }
            else
            {
                enum arch = "x86_64-linux-gnu";
            }
            enum candidates = [
                // Arch
                LibInfo("/usr/lib/libmigemo.so", "/usr/share/migemo/utf-8"),
                // Debian/Ubuntu
                LibInfo(format("/usr/lib/%s/libmigemo.so.1", arch), "/usr/share/cmigemo/utf-8"),
                // Fedora
                LibInfo("/usr/lib/libmigemo.so.1", "/usr/share/cmigemo/utf-8"),
                ];
        }
        else version(OSX)
        {
            enum candidates = [LibInfo("/usr/local/opt/cmigemo/lib/libmigemo.dylib",
                                       "/usr/local/opt/cmigemo/share/migemo/utf-8")];
        }
        auto ret = candidates.find!(a => a.lib.exists);
        return ret.empty ? LibInfo.init : ret.front;
    }

    public Wisdom wisdom;
    Migemo migemo;
}

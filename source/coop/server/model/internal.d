/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model.internal;

import coop.common;

class WebModel: ModelAPI
{
    import vibe.data.json;

    import coop.core: WisdomModel;

    this(string path, string msg = "")
    {
        import coop.core.wisdom;
        this.wm = new WisdomModel(new Wisdom(path));
        this.message = msg;
    }

    override @property GetVersionResult getVersion() const
    {
        import coop.util;
        return GetVersionResult(Version);
    }

    override @property GetInformationResult getInformation() const pure nothrow
    {
        return GetInformationResult(message, "v1.2.1", "v1.2.1");
    }

    override @property GetBinderCategoriesResult getBinderCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return typeof(return)(wm.getBinderCategories.map!(b => BinderLink(b)).array);
    }

    override GetRecipesResult getBinderRecipes(string binder, string query, bool migemo, bool rev, string key, string fs)
    {
        import std.algorithm;
        import std.array;
        import std.typecons;

        import vibe.http.common;

        import coop.core;

        auto fields = fs.split(",");

        binder = binder.replace("_", "/");
        enforceHTTP(getBinderCategories.バインダー一覧.map!"a.バインダー名".canFind(binder),
                    HTTPStatus.notFound, "No such binder '"~binder~"'");

        auto lst = recipeSort(wm.getRecipeList(query, Binder(binder), No.useMetaSearch,
                                               cast(Flag!"useMigemo")migemo, cast(Flag!"useReverseSearch")rev), key);

        auto toRecipeLink(string r)
        {
            import std.exception;
            auto ret = RecipeLink(r);
            auto detail = getRecipe(r).ifThrown!HTTPStatusException(RecipeInfo.init).toAssocArray;
            ret.追加情報 = getDetails(detail, fields);
            return ret;
        }
        return typeof(return)(lst.map!toRecipeLink.array);
    }

    override @property GetSkillCategoriesResult getSkillCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return typeof(return)(wm.getSkillCategories.map!(s => SkillLink(s)).array);
    }

    override GetRecipesResult getSkillRecipes(string skill, string query, bool migemo, bool rev, string key, string fs)
    {
        import std.algorithm;
        import std.array;
        import std.typecons;

        import vibe.http.common;

        import coop.core;

        auto fields = fs.split(",");

        enforceHTTP(getSkillCategories.スキル一覧.map!"a.スキル名".canFind(skill), HTTPStatus.notFound, "No such skill category '"~skill~"'");

        auto lst = recipeSort(wm.getRecipeList(query, Category(skill), No.useMetaSearch, cast(Flag!"useMigemo")migemo,
                                               cast(Flag!"useReverseSearch")rev, SortOrder.ByName), key);
        auto toRecipeLink(string r)
        {
            import std.exception;
            auto ret = RecipeLink(r);
            auto detail = getRecipe(r).ifThrown!HTTPStatusException(RecipeInfo.init).toAssocArray;
            ret.追加情報 = getDetails(detail, fields);
            return ret;
        }
        return typeof(return)(lst.map!toRecipeLink.array);
    }

    override BufferLink[][string] getBuffers()
    {
        import std.algorithm;
        import std.range;

        return ["バフ一覧": wm.wisdom.foodEffectList.keys.map!(k => BufferLink(k)).array];
    }

    override GetRecipesResult getRecipes(string query, bool useMigemo, bool useReverseSearch, string key, string fs)
    {
        import std.algorithm;
        import std.range;

        import vibe.http.common;
        auto fields = fs.split(",");

        auto lst = recipeSort(wm.getRecipeList(query, cast(Flag!"useMigemo")useMigemo, cast(Flag!"useReverseSearch")useReverseSearch), key);

        auto toRecipeLink(string r)
        {
            import std.exception;
            auto ret = RecipeLink(r);
            auto detail = getRecipe(r).ifThrown!HTTPStatusException(RecipeInfo.init).toAssocArray;
            ret.追加情報 = getDetails(detail, fields);
            return ret;
        }
        return typeof(return)(lst.map!toRecipeLink.array);
    }

    override GetItemsResult getItems(string query, bool useMigemo, bool onlyProducts)
    {
        import std.algorithm;
        import std.range;

        return typeof(return)(wm.getItemList(query, cast(Flag!"useMigemo")useMigemo, cast(Flag!"canBeProduced")onlyProducts)
                                .map!(i => ItemLink(i)).array);
    }

    override RecipeInfo getRecipe(string _recipe)
    {
        import std.array;
        import vibe.http.common;

        _recipe = _recipe.replace("_", "/");
        return RecipeInfo(enforceHTTP(wm.getRecipe(_recipe), HTTPStatus.notFound, "No such recipe '"~_recipe~"'"), wm);
    }

    override ItemInfo getItem(string _item)
    {
        return postItem(_item, (int[string]).init);
    }

    override ItemInfo postItem(string _item, int[string] 調達価格)
    {
        import vibe.http.common;
        auto info = ItemInfo(enforceHTTP(wm.getItem(_item), HTTPStatus.notFound, "No such item '"~_item~"'"), wm);
        info.参考価格 = wm.costFor(_item, 調達価格);
        return info;
    }

    /*
     * 2種類以上レシピがあるアイテムに関して、レシピ候補の一覧を返す
     */
    override GetMenuRecipeOptionsResult getMenuRecipeOptions()
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        import vibe.data.json;

        with(typeof(return))
        {
            return typeof(return)(wm.getDefaultPreference
                                    .keys
                                    .map!(k => RetElem(ItemLink(k),
                                                       wm.wisdom
                                                         .rrecipeList[k][]
                                                         .map!(r => RecipeLink(r))
                                                         .array))
                                    .array);
        }
    }

    override PostMenuRecipePreparationResult postMenuRecipePreparation(string[] 作成アイテム)
    {
        import std.algorithm;
        import std.range;
        import coop.core.recipe_graph: RI = RecipeInfo;

        import vibe.http.common;

        auto toMenuRecipeInfo(RI ri)
        {
            import std.exception;
            import vibe.data.json;

            auto ret = RecipeLink(ri.name);
            auto detail = getRecipe(ri.name).ifThrown!HTTPStatusException(RecipeInfo.init);
            ret.追加情報["必要スキル"] = detail.必要スキル.serialize!JsonSerializer;
            ret.追加情報["レシピ必須"] = detail.レシピ必須.serialize!JsonSerializer;
            ret.追加情報["選択レシピグループ"] = ri.parentGroup.serialize!JsonSerializer;
            return ret;
        }

        作成アイテム.each!(i => enforceHTTP(wm.getItem(i), HTTPStatus.badRequest, "No such item '"~i~"'"));

        auto ret = wm.getMenuRecipeResult(作成アイテム);

        return typeof(return)(
            ret.recipes.map!toMenuRecipeInfo.array,
            ret.materials.map!((m) {
                    auto it = ItemLink(m.name);
                    it.追加情報["中間素材"] = (!m.isLeaf).serialize!JsonSerializer;
                    return it;
                }).array);
    }

    override PostMenuRecipeResult postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.container.rbtree;

        import vibe.http.common;

        chain(作成アイテム.keys, 所持アイテム.keys,
              使用レシピ.keys, 直接調達アイテム).each!(i => enforceHTTP(wm.getItem(i),
                                                                        HTTPStatus.badRequest,
                                                                        "No such item '"~i~"'"));
        使用レシピ.values.each!(r => enforceHTTP(wm.getRecipe(r), HTTPStatus.badRequest, "No such recipe '"~r~"'"));

        auto ret = wm.getMenuRecipeResult(作成アイテム, 所持アイテム, 使用レシピ, new RedBlackTree!string(直接調達アイテム));
        return typeof(return)(
            ret.recipes.byKeyValue.map!(kv => RecipeNumberLink(kv.key, kv.value)).array,
            ret.materials.byKeyValue.map!((kv) {
                    auto it = ItemNumberLink(kv.key, kv.value.num);
                    it.追加情報["中間素材"] = kv.value.isIntermediate.serialize!JsonSerializer;
                    return it;
                }).array,
            ret.leftovers.byKeyValue.map!(kv => ItemNumberLink(kv.key, kv.value)).array);
    }
private:
    auto getDetails(Json[string] info, string[] fields)
    {
        typeof(info) ret;

        foreach(f; fields)
        {
            if (auto val = f in info)
            {
                ret[f] = *val;
            }
            else
            {
                import vibe.http.common;
                enforceHTTP(false, HTTPStatus.notFound, "No such field '"~f~"'");
            }
        }
        return ret;
    }

    auto recipeSort(string[] rs, string key)
    {
        import std.algorithm;
        import std.array;

        import vibe.http.common;

        switch(key)
        {
        case "skill":{
            import std.typecons;
            auto levels(string s) {
                auto arr = wm.getRecipe(s).requiredSkills.byKeyValue.map!(a => tuple(a.key, a.value)).array;
                arr.multiSort!("a[0] < b[0]", "a[1] < b[1]");
                return arr;
            }
            auto arr = rs.map!(a => tuple(a, levels(a))).array;
            arr.multiSort!("a[1] < b[1]", "a[0] < b[0]");
            return arr.map!"a[0]".array;
        }
        case "name":
            return rs.sort().array;
        case "default":
            return rs;
        default:
            enforceHTTP(false, HTTPStatus.BadRequest, "No such key for 'sort'");
        }
        assert(false);
    }
    WisdomModel wm;
    string message;
}

private:

auto toAssocArray(T)(T info) if (is(T == struct))
{
    import std.traits;
    import vibe.data.json;
    Json[string] ret;

    foreach(fname; FieldNameTuple!T)
    {
        ret[fname] = mixin("info."~fname).serialize!JsonSerializer;
    }
    return ret;
}

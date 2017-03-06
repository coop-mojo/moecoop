/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model.internal;

import coop.server.model;

class WebModel: ModelAPI
{
    import std.typecons;
    import vibe.data.json;

    import coop.core;

    this(WisdomModel wm, string msg = "") @safe pure nothrow
    {
        this.wm = wm;
        this.message = msg;
    }

    override @property GetVersionResult getVersion() const
    {
        import coop.util;
        return GetVersionResult(Version);
    }

    override @property GetInformationResult getInformation() const pure nothrow
    {
        return GetInformationResult(message);
    }

    override @property GetBinderCategoriesResult getBinderCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return typeof(return)(wm.getBinderCategories.map!(b => BinderLink(b)).array);
    }

    override GetRecipesResult getBinderRecipes(string binder, string query, Flag!"useMigemo" migemo,
                                               Flag!"useReverseSearch" rev, string key)
    {
        import std.algorithm;
        import std.array;
        import std.typecons;

        import vibe.http.common;

        binder = binder.replace("_", "/");
        enforceHTTP(getBinderCategories.バインダー一覧.map!"a.バインダー名".canFind(binder),
                    HTTPStatus.notFound, "No such binder");

        auto lst = recipeSort(wm.getRecipeList(query, Binder(binder), No.useMetaSearch, migemo, rev), key);

        return typeof(return)(lst.map!(r => RecipeLink(r)).array);
    }

    override @property GetSkillCategoriesResult getSkillCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return typeof(return)(wm.getSkillCategories.map!(s => SkillLink(s)).array);
    }

    override GetRecipesResult getSkillRecipes(string skill, string query, Flag!"useMigemo" migemo,
                                              Flag!"useReverseSearch" rev, string key)
    {
        import std.algorithm;
        import std.array;
        import std.typecons;

        import vibe.http.common;

        enforceHTTP(getSkillCategories.スキル一覧.map!"a.スキル名".canFind(skill), HTTPStatus.notFound, "No such skill category");

        auto lst = recipeSort(wm.getRecipeList(query, Category(skill), No.useMetaSearch, migemo, rev, SortOrder.ByName), key);
        return typeof(return)(lst.map!(r => RecipeLink(r)).array);
    }

    override BufferLink[][string] getBuffers()
    {
        import std.algorithm;
        import std.range;

        return ["バフ一覧": wm.wisdom.foodEffectList.keys.map!(k => BufferLink(k)).array];
    }

    override GetRecipesResult getRecipes(string query, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch,
                                         string key)
    {
        import std.algorithm;
        import std.range;

        import vibe.http.common;

        auto lst = recipeSort(wm.getRecipeList(query, useMigemo, useReverseSearch), key);
        return typeof(return)(lst.map!(r => RecipeLink(r)).array);
    }

    override GetItemsResult getItems(string query, Flag!"useMigemo" useMigemo, Flag!"onlyProducts" onlyProducts)
    {
        import std.algorithm;
        import std.range;

        return typeof(return)(wm.getItemList(query, useMigemo, cast(Flag!"canBeProduced")onlyProducts).map!(i => ItemLink(i)).array);
    }

    override RecipeInfo getRecipe(string _recipe)
    {
        import vibe.http.common;

        return RecipeInfo(enforceHTTP(wm.getRecipe(_recipe), HTTPStatus.notFound, "No such recipe"), wm);
    }

    override ItemInfo getItem(string _item)
    {
        return postItem(_item, (int[string]).init);
    }

    override ItemInfo postItem(string _item, int[string] 調達価格)
    {
        import vibe.http.common;
        auto info = ItemInfo(enforceHTTP(wm.getItem(_item), HTTPStatus.notFound, "No such item"), wm);
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

        auto ret = wm.getMenuRecipeResult(作成アイテム);
        with(typeof(return))
        {
            return typeof(return)(ret.recipes.map!(r => RecipeLink(r.name)).array,
                                  ret.materials
                                     .map!(m => MatElem(ItemLink(m.name),
                                                        !m.isLeaf)).array);
        }
    }

    override PostMenuRecipeResult postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.container.rbtree;

        auto ret = wm.getMenuRecipeResult(作成アイテム, 所持アイテム, 使用レシピ, new RedBlackTree!string(直接調達アイテム));
        with(typeof(return))
        {
            return typeof(return)(ret.recipes.byKeyValue.map!(kv => RecipeElem(RecipeLink(kv.key), kv.value)).array,
                                  ret.materials.byKeyValue.map!(kv => MatElem(ItemLink(kv.key), kv.value.num, kv.value.isIntermediate)).array,
                                  ret.leftovers.byKeyValue.map!(kv => LOElem(ItemLink(kv.key), kv.value)).array);
        }
    }
private:
    auto recipeSort(string[] rs, string key)
    {
        import std.algorithm;
        import std.array;

        import vibe.http.common;

        switch(key)
        {
        case "skill":{
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

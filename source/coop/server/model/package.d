/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model;

import coop.server.model.data;

interface ModelAPI
{
    import std.typecons;

    import vibe.d;
    import coop.core.item;
    import coop.core.recipe;

    @path("/version") @property Json[string] getVersion();

    @path("/binders") @property BinderLink[][string] getBinderCategories();
    @path("/binders/:binder/recipes")
    @queryParam("query", "query") @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort")
    RecipeLink[][string] getBinderRecipes(string _binder, string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                          Flag!"useReverseSearch" rev=No.useReverseSearch, string key = "skill");

    @path("/skills") @property SkillLink[][string] getSkillCategories();
    @path("/skills/:skill/recipes")
    @queryParam("query", "query") @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort")
    RecipeLink[][string] getSkillRecipes(string _skill, string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                         Flag!"useReverseSearch" rev=No.useReverseSearch, string key = "skill");

    @path("/buffers") @property BufferLink[][string] getBuffers();

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort")
    RecipeLink[][string] getRecipes(string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                    Flag!"useReverseSearch" rev=No.useReverseSearch, string key = "skill");

    @path("/items") @queryParam("migemo", "migemo")
    ItemLink[][string] getItems(string query="", Flag!"useMigemo" migemo=No.useMigemo);

    @path("/recipes/:recipe") RecipeInfo getRecipe(string _recipe);

    // 調達価格なしの場合
    @path("/items/:item") ItemInfo getItem(string _item);
    // 調達価格ありの場合
    @path("/items/:item") ItemInfo postItem(string _item, int[string] 調達価格 = null);

    @path("/menu-recipes/options") Json getMenuRecipeOptions();

    @path("/menu-recipes/preparation") Json postMenuRecipePreparation(string[] 作成アイテム);
    @path("/menu-recipes")
    Json postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム);
}

class WebModel: ModelAPI
{
    import std.typecons;
    import vibe.data.json;

    import coop.core;

    this(WisdomModel wm) @safe pure nothrow
    {
        this.wm = wm;
    }

    @property Json[string] getVersion() const
    {
        import coop.util;
        return ["version": Version.serializeToJson, "migemo": wm.migemoAvailable.serializeToJson];
    }

    override @property BinderLink[][string] getBinderCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return ["バインダー一覧": wm.getBinderCategories.map!(b => BinderLink(b)).array];
    }

    override RecipeLink[][string] getBinderRecipes(string binder, string query, Flag!"useMigemo" migemo,
                                                   Flag!"useReverseSearch" rev, string key)
    {
        import std.algorithm;
        import std.array;
        import std.range;
        import std.typecons;

        import vibe.http.common;

        binder = binder.replace("_", "/");
        enforceHTTP(getBinderCategories["バインダー一覧"].map!"a.バインダー名".canFind(binder),
                    HTTPStatus.notFound, "No such binder");

        auto lst = recipeSort(wm.getRecipeList(query, Binder(binder), No.useMetaSearch, migemo, rev)
                                .front
                                .recipes,
                              key);

        return ["レシピ一覧": lst.map!(r => RecipeLink(r)).array];
    }

    override @property SkillLink[][string] getSkillCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return ["スキル一覧": wm.getSkillCategories.map!(s => SkillLink(s)).array];
    }

    override RecipeLink[][string] getSkillRecipes(string skill, string query, Flag!"useMigemo" migemo,
                                                  Flag!"useReverseSearch" rev, string key)
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        import vibe.http.common;

        enforceHTTP(getSkillCategories["スキル一覧"].map!"a.スキル名".canFind(skill), HTTPStatus.notFound, "No such skill category");

        auto lst = recipeSort(wm.getRecipeList(query, Category(skill), No.useMetaSearch, migemo, rev, SortOrder.ByName)
                                 .front
                                 .recipes,
                              key);
        return ["レシピ一覧": lst.map!(r => RecipeLink(r)).array];
    }

    override BufferLink[][string] getBuffers()
    {
        import std.algorithm;
        import std.range;

        return ["バフ一覧": wm.wisdom.foodEffectList.keys.map!(k => BufferLink(k)).array];
    }

    override RecipeLink[][string] getRecipes(string query, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch,
                                             string key)
    {
        import std.algorithm;
        import std.range;

        import vibe.http.common;

        auto lst = recipeSort(wm.getRecipeList(query, useMigemo, useReverseSearch), key);
        return ["レシピ一覧": lst.map!(r => RecipeLink(r)).array];
    }

    override ItemLink[][string] getItems(string query, Flag!"useMigemo" useMigemo)
    {
        import std.algorithm;
        import std.range;

        return ["アイテム一覧": wm.getItemList(query, useMigemo, No.canBeProduced).map!(i => ItemLink(i)).array];
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
    override Json getMenuRecipeOptions()
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        import vibe.data.json;

        struct RetElem{
            ItemLink 生産アイテム;
            RecipeLink[] レシピ候補;
        }

        return ["選択可能レシピ":
                wm.getDefaultPreference
                  .keys
                  .map!(k => RetElem(ItemLink(k),
                                     wm.wisdom
                                       .rrecipeList[k][]
                                       .map!(r => RecipeLink(r))
                                       .array))
                  .array].serializeToJson;
    }

    override Json postMenuRecipePreparation(string[] 作成アイテム)
    {
        import std.algorithm;
        import std.range;

        struct MatElem{
            ItemLink 素材名;
            bool 中間素材;
        }

        auto ret = wm.getMenuRecipeResult(作成アイテム);
        return ["必要レシピ": ret.recipes.map!(r => RecipeLink(r.name)).array.serializeToJson,
                "必要素材": ret.materials.map!(m => MatElem(ItemLink(m.name),
                                                            !m.isLeaf)).array.serializeToJson].serializeToJson;
    }

    override Json postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.container.rbtree;

        struct RecipeElem{
            RecipeLink レシピ名;
            int コンバイン数;
        }
        struct MatElem{
            ItemLink 素材名;
            int 素材数;
            bool 中間素材;
        }
        struct LOElem{
            ItemLink 素材名;
            int 余剰数;
        }

        auto ret = wm.getMenuRecipeResult(作成アイテム.to!(int[dstring]), 所持アイテム.to!(int[dstring]), 使用レシピ.to!(dstring[dstring]), new RedBlackTree!string(直接調達アイテム));
        return ["必要レシピ": ret.recipes.byKeyValue.map!(kv => RecipeElem(RecipeLink(kv.key), kv.value)).array.serializeToJson,
                "必要素材": ret.materials.byKeyValue.map!(kv => MatElem(ItemLink(kv.key), kv.value.num, kv.value.isIntermediate)).array.serializeToJson,
                "余り物": ret.leftovers.byKeyValue.map!(kv => LOElem(ItemLink(kv.key), kv.value)).array.serializeToJson].serializeToJson;
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
        default:
            enforceHTTP(false, HTTPStatus.BadRequest, "No such key for 'sort'");
        }
        assert(false);
    }
    WisdomModel wm;
}

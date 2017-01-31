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

    @path("/version") @property string[string] getVersion();

    @path("/binders") @property BinderLink[][string] getBinderCategories();
    @path("/binders/:binder/recipes") RecipeLink[][string] getBinderRecipes(string _binder);
    @path("/binders/:binder/recipes/:recipe") RecipeInfo getBinderRecipe(string _binder, string _recipe);

    @path("/skills") @property SkillLink[][string] getSkillCategories();
    @path("/skills/:skill/recipes") RecipeLink[][string] getSkillRecipes(string _skill);
    @path("/skills/:skill/recipes/:recipe") RecipeInfo getSkillRecipe(string _skill, string _recipe);

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev")
    RecipeLink[][string] getRecipes(string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                    Flag!"useReverseSearch" rev=No.useReverseSearch);

    @path("/items") @queryParam("migemo", "migemo")
    ItemLink[][string] getItems(string query="", Flag!"useMigemo" migemo=No.useMigemo);

    @path("/recipes/:recipe") RecipeInfo getRecipe(string _recipe);

    // 調達価格なしの場合
    @path("/items/:item") ItemInfo getItem(string _item);
    // 調達価格ありの場合
    @path("/items/:item") ItemInfo postItem(string _item, int[string] prices = null);
}

class WebModel: ModelAPI
{
    import std.typecons;

    import coop.core;

    this(WisdomModel wm, string url) @safe pure nothrow
    {
        this.wm = wm;
        this.baseURL = url;
    }

    @property string[string] getVersion() @safe const pure nothrow
    {
        import coop.util;
        return ["version": Version];
    }

    override @property BinderLink[][string] getBinderCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return ["バインダー一覧": wm.getBinderCategories.map!(b => BinderLink(b, baseURL)).array];
    }

    override RecipeLink[][string] getBinderRecipes(string binder)
    {
        import std.algorithm;
        import std.array;
        import std.range;
        import std.typecons;

        import vibe.http.common;

        binder = binder.replace("_", "/");
        enforceHTTP(getBinderCategories["バインダー一覧"].map!"a.バインダー名".canFind(binder),
                    HTTPStatus.notFound, "No such binder");

        return ["レシピ一覧": wm.getRecipeList("", Binder(binder), No.useMetaSearch, No.useMigemo)
                                .front
                                .recipes
                                .map!(r => RecipeLink(r, baseURL))
                                .array];
    }

    RecipeInfo getBinderRecipe(string _binder, string _recipe)
    {
        import std.algorithm;
        import std.array;
        import std.format;

        import vibe.http.common;

        enforceHTTP(getBinderRecipes(_binder)["レシピ一覧"].map!"a.レシピ名".canFind(_recipe),
                    HTTPStatus.notFound, format("No such recipe in binder '%s'", _binder.replace("_", "/")));
        return getRecipe(_recipe);
    }

    override @property SkillLink[][string] getSkillCategories() const pure nothrow
    {
        import std.algorithm;
        import std.range;

        return ["スキル一覧": wm.getSkillCategories.map!(s => SkillLink(s, baseURL)).array];
    }

    override RecipeLink[][string] getSkillRecipes(string skill)
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        import vibe.http.common;

        enforceHTTP(getSkillCategories["スキル一覧"].map!"a.スキル名".canFind(skill), HTTPStatus.notFound, "No such skill category");
        return ["レシピ一覧": wm.getRecipeList("", Category(skill), No.useMetaSearch, No.useMigemo, No.useReverseSearch, SortOrder.ByName)
                                .front
                                .recipes
                                .map!(r => RecipeLink(r, baseURL))
                                .array];
    }

    RecipeInfo getSkillRecipe(string _skill, string _recipe)
    {
        import std.algorithm;
        import std.format;

        import vibe.http.common;

        enforceHTTP(getSkillRecipes(_skill)["レシピ一覧"].map!"a.レシピ名".canFind(_recipe),
                    HTTPStatus.notFound, format("No such recipe in skill '%s'", _skill));
        return getRecipe(_recipe);
    }

    override RecipeLink[][string] getRecipes(string query, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch)
    {
        import std.algorithm;
        import std.range;

        return ["レシピ一覧": wm.getRecipeList(query, useMigemo, useReverseSearch).map!(r => RecipeLink(r, baseURL)).array];
    }

    override ItemLink[][string] getItems(string query, Flag!"useMigemo" useMigemo)
    {
        import std.algorithm;
        import std.range;

        return ["アイテム一覧": wm.getItemList(query, useMigemo, No.canBeProduced).map!(i => ItemLink(i, baseURL)).array];
    }

    override RecipeInfo getRecipe(string _recipe)
    {
        import vibe.http.common;

        return RecipeInfo(enforceHTTP(wm.getRecipe(_recipe), HTTPStatus.notFound, "No such recipe"),
                          wm, baseURL);
    }

    override ItemInfo getItem(string _item)
    {
        return postItem(_item, (int[string]).init);
    }

    override ItemInfo postItem(string _item, int[string] prices)
    {
        import vibe.http.common;
        auto info = ItemInfo(enforceHTTP(wm.getItem(_item), HTTPStatus.notFound, "No such item"),
                             wm, baseURL);
        info.参考価格 = wm.costFor(_item, prices);
        return info;
    }
private:
    WisdomModel wm;
    string baseURL;
}

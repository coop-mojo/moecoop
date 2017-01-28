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

    @path("/version") @property string getVersion();

    @path("/binders") @property BinderLink[][string] getBinderCategories();
    @path("/binders/:binder/recipes") RecipeLink[][string] getBinderRecipes(string _binder);
    @path("/binders/:binder/recipes/:recipe") RecipeInfoLink getBinderRecipe(string _binder, string _recipe);

    @path("/skills") @property SkillLink[][string] getSkillCategories();
    @path("/skills/:skill/recipes") RecipeLink[][string] getSkillRecipes(string _skill);
    @path("/skills/:skill/recipes/:recipe") RecipeInfoLink getSkillRecipe(string _skill, string _recipe);

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev")
    RecipeLink[][string] getRecipes(string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                    Flag!"useReverseSearch" rev=No.useReverseSearch);

    @path("/items") @queryParam("migemo", "migemo")
    ItemLink[][string] getItems(string query="", Flag!"useMigemo" migemo=No.useMigemo);

    @path("/recipes/:recipe") RecipeInfoLink getRecipe(string _recipe);
    @path("/items/:item") Item getItem(string _item);
}

class WebModel: ModelAPI
{
    import std.typecons;

    import coop.core;
    import coop.core.item;
    import coop.core.recipe;

    import vibe.d;

    this(WisdomModel wm, string url)
    {
        this.wm = wm;
        this.baseURL = url;
    }

    @property string getVersion()
    {
        import coop.util;
        return Version;
    }

    override @property BinderLink[][string] getBinderCategories() const
    {
        import std.algorithm;
        import std.range;

        return ["バインダー一覧": wm.getBinderCategories.map!(b => BinderLink(b, baseURL)).array];
    }

    override RecipeLink[][string] getBinderRecipes(string binder)
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        import vibe.http.common;

        enforceHTTP(getBinderCategories["バインダー一覧"].map!"a.バインダー名".canFind(binder),
                    HTTPStatus.notFound, "No such binder");

        return ["レシピ一覧": wm.getRecipeList("", Binder(binder), No.useMetaSearch, No.useMigemo)
                                .front
                                .recipes
                                .map!(r => RecipeLink(r, baseURL))
                                .array];
    }

    RecipeInfoLink getBinderRecipe(string _binder, string _recipe)
    {
        import std.algorithm;
        import std.format;

        import vibe.http.common;

        enforceHTTP(getBinderRecipes(_binder)["レシピ一覧"].map!"a.レシピ名".canFind(_recipe),
                    HTTPStatus.notFound, format("No such recipe in binder '%s'", _binder));
        return getRecipe(_recipe);
    }

    override @property SkillLink[][string] getSkillCategories() const
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

    RecipeInfoLink getSkillRecipe(string _skill, string _recipe)
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

    override RecipeInfoLink getRecipe(string _recipe)
    {
        import vibe.http.common;

        return RecipeInfoLink(enforceHTTP(wm.getRecipe(_recipe), HTTPStatus.notFound, "No such recipe"),
                              wm, baseURL);
    }

    override Item getItem(string _item)
    {
        import vibe.http.common;

        return enforceHTTP(wm.getItem(_item), HTTPStatus.notFound, "No such item");
    }
private:
    WisdomModel wm;
    string baseURL;
}

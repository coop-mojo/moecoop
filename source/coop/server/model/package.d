/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model;

interface ModelAPI
{
    import std.typecons;

    import vibe.d;
    import coop.core.item;
    import coop.core.recipe;

    @path("/version") @property string getVersion();

    @path("/binders") @property string[] getBinderCategories();
    @path("/binders/:binder/recipes") string[] getBinderRecipes(string _binder);
    @path("/binders/:binder/recipes/:recipe") Recipe getBinderRecipe(string _binder, string _recipe);

    @path("/skills") @property string[] getSkillCategories();
    @path("/skills/:skill/recipes") string[] getSkillRecipes(string _skill);
    @path("/skills/:skill/recipes/:recipe") Recipe getSkillRecipe(string _skill, string _recipe);

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev")
    string[] getRecipes(string query="", Flag!"useMigemo" migemo=No.useMigemo,
                        Flag!"useReverseSearch" rev=No.useReverseSearch);

    @path("/items") @queryParam("migemo", "migemo")
    string[] getItems(string query="", Flag!"useMigemo" migemo=No.useMigemo);

    @path("/recipes/:recipe") Recipe getRecipe(string _recipe);
    @path("/items/:item") Item getItem(string _item);
}

class WebModel: ModelAPI
{
    import std.typecons;

    import coop.core;
    import coop.core.item;
    import coop.core.recipe;

    this(WisdomModel wm)
    {
        this.wm = wm;
    }

    @property string getVersion()
    {
        import coop.util;
        return Version;
    }

    override @property string[] getBinderCategories() const pure
    {
        return wm.getBinderCategories;
    }

    override string[] getBinderRecipes(string binder)
    {
        import std.algorithm;
        import std.typecons;

        import vibe.http.common;

        enforceHTTP(getBinderCategories.canFind(binder),
                    HTTPStatus.notFound, "No such binder");

        return wm.getRecipeList("", Binder(binder), No.useMetaSearch, No.useMigemo).front.recipes;
    }

    Recipe getBinderRecipe(string _binder, string _recipe)
    {
        import std.algorithm;
        import std.format;

        import vibe.http.common;

        enforceHTTP(getBinderRecipes(_binder).canFind(_recipe),
                    HTTPStatus.notFound, format("No such recipe in binder '%s'", _binder));
        return getRecipe(_recipe);
    }

    override @property string[] getSkillCategories() const pure
    {
        return wm.getSkillCategories;
    }

    override string[] getSkillRecipes(string skill)
    {
        import std.algorithm;
        import std.typecons;

        import vibe.http.common;

        enforceHTTP(getSkillCategories.canFind(skill), HTTPStatus.notFound, "No such skill category");
        return wm.getRecipeList("", Category(skill), No.useMetaSearch, No.useMigemo, No.useReverseSearch, SortOrder.ByName).front.recipes;
    }

    Recipe getSkillRecipe(string _skill, string _recipe)
    {
        import std.algorithm;
        import std.format;

        import vibe.http.common;

        enforceHTTP(getSkillRecipes(_skill).canFind(_recipe), HTTPStatus.notFound, format("No such recipe in skill '%s'", _skill));
        return getRecipe(_recipe);
    }

    override string[] getRecipes(string query, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch)
    {
        return wm.getRecipeList(query, useMigemo, useReverseSearch);
    }

    override string[] getItems(string query, Flag!"useMigemo" useMigemo)
    {
        return wm.getItemList(query, useMigemo, No.canBeProduced);
    }

    override Recipe getRecipe(string _recipe)
    {
        import vibe.http.common;

        return enforceHTTP(wm.getRecipe(_recipe), HTTPStatus.notFound, "No such recipe");
    }

    override Item getItem(string _item)
    {
        import vibe.http.common;

        return enforceHTTP(wm.getItem(_item), HTTPStatus.notFound, "No such item");
    }
private:
    WisdomModel wm;
}

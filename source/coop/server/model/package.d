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
    @path("/skills") @property string[] getSkillCategories();
    @path("/skills/:skill/recipes") string[] getSkillRecipes(string _skill);

    @path("/recipes") string[] getRecipes(string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                          Flag!"useReverseSearch" rev=No.useReverseSearch);
    @path("/items") string[] getItems(string query="", Flag!"useMigemo" migemo=No.useMigemo);

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

        if (getBinderCategories.canFind(binder))
        {
            import std.typecons;
            return wm.getRecipeList("", Binder(binder), No.useMetaSearch, No.useMigemo).front.recipes;
        }
        else
        {
            return []; // not found
        }
        assert(false);
    }

    override @property string[] getSkillCategories() const pure
    {
        return wm.getSkillCategories;
    }

    override string[] getSkillRecipes(string skill)
    {
        import std.algorithm;

        if (getSkillCategories.canFind(skill))
        {
            import std.typecons;
            return wm.getRecipeList("", Category(skill), No.useMetaSearch, No.useMigemo, No.useReverseSearch, SortOrder.ByName).front.recipes;
        }
        else
        {
            return []; // not found
        }
        assert(false);
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
        return wm.getRecipe(_recipe);
    }

    override Item getItem(string _item)
    {
        return wm.getItem(_item);
    }
private:
    WisdomModel wm;
}

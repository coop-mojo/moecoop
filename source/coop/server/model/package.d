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

    @path("/buffers") @property BufferLink[][string] getBuffers();

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev")
    RecipeLink[][string] getRecipes(string query="", Flag!"useMigemo" migemo=No.useMigemo,
                                    Flag!"useReverseSearch" rev=No.useReverseSearch);

    @path("/items") @queryParam("migemo", "migemo")
    ItemLink[][string] getItems(string query="", Flag!"useMigemo" migemo=No.useMigemo);

    @path("/recipes/:recipe") RecipeInfo getRecipe(string _recipe);

    // 調達価格なしの場合
    @path("/items/:item") ItemInfo getItem(string _item);
    // 調達価格ありの場合
    @path("/items/:item") ItemInfo postItem(string _item, int[string] 調達価格 = null);

    @path("/menu-recipes/options") Tuple!(ItemLink, "生産アイテム", RecipeLink[], "レシピ候補")[][string] getMenuRecipeOptions();
    @path("/menu-recipes/preparation")
    Tuple!(RecipeLink[], "必要レシピ",
           Tuple!(ItemLink, "素材名",
                  bool, "中間素材")[], "必要素材") postMenuRecipePreparation(string[] targets);
    @path("/menu-recipes")
    Tuple!(Tuple!(RecipeLink, "レシピ名", int, "コンバイン数")[], "必要レシピ",
           Tuple!(ItemLink, "素材名", int, "素材数", bool, "中間素材")[], "必要素材",
           Tuple!(ItemLink, "素材名", int, "余剰数")[], "余り物")
    postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム);
}

class WebModel: ModelAPI
{
    import std.typecons;

    import coop.core;

    this(WisdomModel wm) @safe pure nothrow
    {
        this.wm = wm;
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

        return ["バインダー一覧": wm.getBinderCategories.map!(b => BinderLink(b)).array];
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
                                .map!(r => RecipeLink(r))
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

        return ["スキル一覧": wm.getSkillCategories.map!(s => SkillLink(s)).array];
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
                                .map!(r => RecipeLink(r))
                                .array];
    }

    override RecipeInfo getSkillRecipe(string _skill, string _recipe)
    {
        import std.algorithm;
        import std.format;

        import vibe.http.common;

        enforceHTTP(getSkillRecipes(_skill)["レシピ一覧"].map!"a.レシピ名".canFind(_recipe),
                    HTTPStatus.notFound, format("No such recipe in skill '%s'", _skill));
        return getRecipe(_recipe);
    }

    override BufferLink[][string] getBuffers()
    {
        import std.algorithm;
        import std.range;

        return ["バフ一覧": wm.wisdom.foodEffectList.keys.map!(k => BufferLink(k)).array];
    }

    override RecipeLink[][string] getRecipes(string query, Flag!"useMigemo" useMigemo, Flag!"useReverseSearch" useReverseSearch)
    {
        import std.algorithm;
        import std.range;

        return ["レシピ一覧": wm.getRecipeList(query, useMigemo, useReverseSearch).map!(r => RecipeLink(r)).array];
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
    override Tuple!(ItemLink, "生産アイテム", RecipeLink[], "レシピ候補")[][string] getMenuRecipeOptions()
    {
        import std.algorithm;
        import std.range;
        import std.typecons;

        alias RetElem = Tuple!(ItemLink, "生産アイテム", RecipeLink[], "レシピ候補");

        return ["選択可能レシピ":
                wm.getDefaultPreference
                  .keys
                  .map!(k => RetElem(ItemLink(k),
                                     wm.wisdom
                                       .rrecipeList[k][]
                                       .map!(r => RecipeLink(r))
                                       .array))
                  .array];
    }

    override Tuple!(RecipeLink[], "必要レシピ",
                    Tuple!(ItemLink, "素材名",
                           bool, "中間素材")[], "必要素材") postMenuRecipePreparation(string[] targets)
    {
        import std.algorithm;
        import std.range;

        alias MatElem = Tuple!(ItemLink, "素材名", bool, "中間素材");

        auto ret = wm.getMenuRecipeResult(targets);
        return typeof(return)(ret.recipes.map!(r => RecipeLink(r.name)).array,
                              ret.materials.map!(m => MatElem(ItemLink(m.name),
                                                              !m.isLeaf)).array);
    }

    override Tuple!(Tuple!(RecipeLink, "レシピ名", int, "コンバイン数")[], "必要レシピ",
                    Tuple!(ItemLink, "素材名", int, "素材数", bool, "中間素材")[], "必要素材",
                    Tuple!(ItemLink, "素材名", int, "余剰数")[], "余り物")
        postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.container.rbtree;

        alias RecipeElem = Tuple!(RecipeLink, "レシピ名", int, "コンバイン数");
        alias MatElem = Tuple!(ItemLink, "素材名", int, "素材数", bool, "中間素材");
        alias LOElem = Tuple!(ItemLink, "素材名", int, "余剰数");

        auto ret = wm.getMenuRecipeResult(作成アイテム.to!(int[dstring]), 所持アイテム.to!(int[dstring]), 使用レシピ.to!(dstring[dstring]), new RedBlackTree!string(直接調達アイテム));
        return typeof(return)(ret.recipes.byKeyValue.map!(kv => RecipeElem(RecipeLink(kv.key), kv.value)).array,
                              ret.materials.byKeyValue.map!(kv => MatElem(ItemLink(kv.key), kv.value.num, kv.value.isIntermediate)).array,
                              ret.leftovers.byKeyValue.map!(kv => LOElem(ItemLink(kv.key), kv.value)).array);
    }
private:
    WisdomModel wm;
}

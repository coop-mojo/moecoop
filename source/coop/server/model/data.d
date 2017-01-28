/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model.data;

import vibe.data.json;

struct BinderLink
{
    this(string binder, string host)
    {
        import std.path;
        バインダー名 = binder;
        レシピ一覧 = buildPath(host, "binders", binder, "recipes");
    }
    string バインダー名;
    string レシピ一覧;
}

struct SkillLink
{
    this(string skill, string host)
    {
        import std.path;
        スキル名 = skill;
        レシピ一覧 = buildPath(host, "skills", skill, "recipes");
    }
    string スキル名;
    string レシピ一覧;
}

struct ItemLink
{
    this(string item, string host)
    {
        import std.path;
        アイテム名 = item;
        詳細 = buildPath(host, "items", item);
    }
    string アイテム名;
    string 詳細;
}

struct RecipeLink
{
    this(string recipe, string host)
    {
        import std.path;
        レシピ名 = recipe;
        詳細 = buildPath(host, "recipes", recipe);
    }
    string レシピ名;
    string 詳細;
}

struct ItemNumberLink
{
    this(string item, int num, string host)
    {
        import std.path;
        アイテム名 = item;
        詳細 = buildPath(host, "items", item);
        個数 = num;
    }
    string アイテム名;
    string 詳細;
    int 個数;
}

struct RecipeInfoLink
{
    import coop.core;
    import coop.core.recipe;

    this(Recipe r, WisdomModel wm, string host)
    {
        import std.algorithm;
        import std.range;

        レシピ名 = r.name;
        材料 = r.ingredients
                .byKeyValue
                .map!(kv => ItemNumberLink(kv.key, kv.value, host))
                .array;
        生成物 = r.products
                  .byKeyValue
                  .map!(kv => ItemNumberLink(kv.key, kv.value, host))
                  .array;
        テクニック = r.techniques;
        必要スキル = r.requiredSkills;
        レシピ必須 = r.requiresRecipe;
        ギャンブル型 = r.isGambledRoulette;
        ペナルティ型 = r.isPenaltyRoulette;
        収録バインダー = wm.getBindersFor(レシピ名).map!(b => BinderLink(b, host)).array;
        備考 = r.remarks;
    }
    string レシピ名;
    ItemNumberLink[] 材料;
    ItemNumberLink[] 生成物;
    string[] テクニック;
    double[string] 必要スキル;
    bool レシピ必須;
    bool ギャンブル型;
    bool ペナルティ型;
    BinderLink[] 収録バインダー;
    string 備考;
}

/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model;

import vibe.data.json;

interface ModelAPI
{
    import std.typecons;

    import vibe.web.common;
    import coop.core.item;
    import coop.core.recipe;

    @path("/version") @property GetVersionResult getVersion();
    @path("/information") @property GetInformationResult getInformation();

    @path("/binders") @property GetBinderCategoriesResult getBinderCategories();
    @path("/binders/:binder/recipes") @queryParam("query", "query")
    @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort") @queryParam("fields", "fields")
    GetRecipesResult getBinderRecipes(string _binder, string query="",
                                      bool migemo=false, bool rev=false, string key = "defalut", string fields = "");

    @path("/skills") @property GetSkillCategoriesResult getSkillCategories();
    @path("/skills/:skill/recipes") @queryParam("query", "query")
    @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort") @queryParam("fields", "fields")
    GetRecipesResult getSkillRecipes(string _skill, string query="",
                                     bool migemo=false, bool rev=false, string key = "default", string fields = "");

    @path("/buffers") @property BufferLink[][string] getBuffers();

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort") @queryParam("fields", "fields")
    GetRecipesResult getRecipes(string query="", bool migemo=false, bool rev=false, string key = "default", string fields = "");

    @path("/items") @queryParam("migemo", "migemo") @queryParam("onlyProducts", "only-products")
    GetItemsResult getItems(string query="", bool migemo=false, bool onlyProducts=false);

    @path("/recipes/:recipe") RecipeInfo getRecipe(string _recipe);

    // 調達価格なしの場合
    @path("/items/:item") ItemInfo getItem(string _item);
    // 調達価格ありの場合
    @path("/items/:item") ItemInfo postItem(string _item, int[string] 調達価格 = null);

    @path("/menu-recipes/options") GetMenuRecipeOptionsResult getMenuRecipeOptions();

    @path("/menu-recipes/preparation") PostMenuRecipePreparationResult postMenuRecipePreparation(string[] 作成アイテム);
    @path("/menu-recipes")
    PostMenuRecipeResult postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム);
}

struct GetVersionResult
{
    @name("version") string version_;
}

struct GetInformationResult
{
    string message;
}

struct GetBinderCategoriesResult
{
    BinderLink[] バインダー一覧;
}

struct GetRecipesResult
{
    RecipeLink[] レシピ一覧;
}

struct GetSkillCategoriesResult
{
    SkillLink[] スキル一覧;
}

struct GetItemsResult
{
    ItemLink[] アイテム一覧;
}

struct GetMenuRecipeOptionsResult
{
    static struct RetElem{
        ItemLink 生産アイテム;
        RecipeLink[] レシピ候補;
    }
    RetElem[] 選択可能レシピ;
}

struct PostMenuRecipePreparationResult
{
    static struct MatElem{
        ItemLink 素材情報;
        bool 中間素材;
    }
    RecipeLink[] 必要レシピ;
    MatElem[] 必要素材;
}

struct PostMenuRecipeResult
{
    static struct RecipeElem{
        RecipeLink レシピ情報;
        int コンバイン数;
    }
    static struct MatElem{
        ItemLink 素材情報;
        int 素材数;
        bool 中間素材;
    }
    static struct LOElem{
        ItemLink 素材情報;
        int 余剰数;
    }
    RecipeElem[] 必要レシピ;
    MatElem[] 必要素材;
    LOElem[] 余り物;
}

struct BinderLink
{
    this(string binder) @safe pure nothrow
    {
        import std.array;
        バインダー名 = binder;
        レシピ一覧 = "/binders/"~binder.replace("/", "_")~"/recipes";
    }
    string バインダー名;
    string レシピ一覧;
}

struct SkillLink
{
    this(string skill) @safe pure nothrow
    {
        スキル名 = skill;
        レシピ一覧 = "/skills/"~skill~"/recipes";
    }
    string スキル名;
    string レシピ一覧;
}

struct SkillNumberLink
{
    this(string skill, double val) @safe pure nothrow
    {
        スキル名 = skill;
        レシピ一覧 = "/skills/"~skill~"/recipes";
        スキル値 = val;
    }
    string スキル名;
    string レシピ一覧;
    double スキル値;
}

struct ItemLink
{
    import vibe.data.json;
    this(string item) @safe pure nothrow
    {
        アイテム名 = item;
        詳細 = "/items/"~item;
    }
    string アイテム名;
    string 詳細;
}

struct RecipeLink
{
    import vibe.data.json;
    this(string recipe) @safe pure nothrow
    {
        import std.array;
        レシピ名 = recipe;
        詳細 = "/recipes/"~recipe.replace("/", "_");
    }
    string レシピ名;
    string 詳細;
    Json[string] 追加情報;
}

struct BufferLink
{
    this(string buff) @safe pure nothrow
    {
        バフ名 = buff;
        詳細 = "/buffers/"~buff;
    }
    string バフ名;
    string 詳細;
}

struct ItemNumberLink
{
    import vibe.data.json;
    this(string item, int num) @safe pure nothrow
    {
        アイテム名 = item;
        詳細 = "/items/"~item;
        個数 = num;
    }
    string アイテム名;
    string 詳細;
    int 個数;
}

struct RecipeInfo
{
    import coop.core;
    import coop.core.recipe;

    this(Recipe r, WisdomModel wm) pure nothrow
    {
        import std.algorithm;
        import std.range;

        レシピ名 = r.name;
        材料 = r.ingredients
                .byKeyValue
                .map!(kv => ItemNumberLink(kv.key, kv.value))
                .array;
        生成物 = r.products
                  .byKeyValue
                  .map!(kv => ItemNumberLink(kv.key, kv.value))
                  .array;
        テクニック = r.techniques;
        必要スキル = r.requiredSkills;
        レシピ必須 = r.requiresRecipe;
        ギャンブル型 = r.isGambledRoulette;
        ペナルティ型 = r.isPenaltyRoulette;
        収録バインダー = wm.getBindersFor(レシピ名).map!(b => BinderLink(b)).array;
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

struct SpecialPropertyInfo
{
    string 略称;
    string 詳細;
}

struct PetFoodInfo
{
    string 種別 = "不明";
    double 効果;
}

struct ItemInfo
{
    import std.typecons;

    import coop.core;
    import coop.core.item;

    this(Item item, WisdomModel wm)
    {
        import std.algorithm;
        import std.range;

        アイテム名 = item.name;
        英名 = item.ename;
        重さ = item.weight;
        NPC売却価格 = item.price;
        参考価格 = wm.costFor(item.name, (int[string]).init);
        info = item.info;
        特殊条件 = item.properties.map!(p => SpecialPropertyInfo(p.to!string, cast(string)p)).array;
        転送可 = item.transferable;
        スタック可 = item.stackable;
        ペットアイテム = item.petFoodInfo.byKeyValue.map!(kv => PetFoodInfo(cast(string)kv.key, kv.value)).front;
        備考 = item.remarks;
        アイテム種別 = cast(string)item.type;
        auto ex = wm.getExtraInfo(アイテム名);
        if (ex.extra == ExtraInfo.init)
        {
            return;
        }

        final switch(item.type) with(typeof(item.type))
        {
        case UNKNOWN, Others:
            break;
        case Food, Drink, Liquor: {
            import coop.core.item: FInfo = FoodInfo;
            飲食物情報 = FoodInfo(*ex.extra.peek!FInfo, wm);
            break;
        }
        case Weapon: {
            import coop.core.item: WInfo = WeaponInfo;
            武器情報 = WeaponInfo(*ex.extra.peek!WInfo, wm);
            break;
        }
        case Armor: {
            import coop.core.item: AInfo = ArmorInfo;
            防具情報 = ArmorInfo(*ex.extra.peek!AInfo, wm);
            break;
        }
        case Bullet: {
            import coop.core.item: BInfo = BulletInfo;
            弾情報 = BulletInfo(*ex.extra.peek!BInfo, wm);
            break;
        }
        case Shield: {
            import coop.core.item: SInfo = ShieldInfo;
            盾情報 = ShieldInfo(*ex.extra.peek!SInfo, wm);
            break;
        }
        case Expendable:
            break;
        case Asset:
            break;
        }
    }

    string アイテム名;
    string 英名;
    double 重さ;
    uint NPC売却価格;
    uint 参考価格;
    string info;
    SpecialPropertyInfo[] 特殊条件;
    bool 転送可;
    bool スタック可;
    PetFoodInfo ペットアイテム;
    string 備考;
    string アイテム種別 = "不明";

    Nullable!FoodInfo 飲食物情報;
    Nullable!WeaponInfo 武器情報;
    Nullable!ArmorInfo 防具情報;
    Nullable!BulletInfo 弾情報;
    Nullable!ShieldInfo 盾情報;
    // Nullable!ExpendableInfo 消耗品情報;
}

struct FoodInfo
{
    import std.typecons;

    import coop.core;
    import coop.core.item: FInfo = FoodInfo, AdditionalEffect;

    this(FInfo info, WisdomModel wm) @safe pure
    {
        効果 = info.effect;
        if (auto eff = info.additionalEffect)
        {
            付加効果 = FoodBufferInfo(eff, wm);
        }
    }

    double 効果;
    Nullable!FoodBufferInfo 付加効果;
}

struct FoodBufferInfo
{
    import coop.core;

    this(string eff, WisdomModel wm) @safe pure
    {
        バフ名 = eff;
        if (auto einfo = wm.getFoodEffect(eff))
        {
            import std.conv;
            バフグループ = einfo.group.to!string;
            効果 = einfo.effects;
            その他効果 = einfo.otherEffects;
            効果時間 = einfo.duration;
            備考 = einfo.remarks;
        }
    }

    string バフ名;
    string バフグループ;
    int[string] 効果;
    string その他効果;
    uint 効果時間;
    string 備考;
}

struct DamageInfo
{
    string 状態;
    double 効果;
}

struct ShipLink
{
    this(string ship) @safe pure nothrow
    {
        シップ名 = ship;
    }

    string シップ名;
    string 詳細;
}

struct WeaponInfo
{
    import coop.core;
    import coop.core.item: WInfo = WeaponInfo, Grade;

    this(WInfo info, WisdomModel wm)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.traits;

        攻撃力 = [EnumMembers!Grade]
                      .filter!(g => info.damage.keys.canFind(g))
                      .map!(g => DamageInfo(cast(string)g, info.damage[g]))
                      .array;
        攻撃間隔 = info.duration;
        有効レンジ = info.range;
        必要スキル = info.skills
                         .byKeyValue
                         .map!(kv => SkillNumberLink(kv.key, kv.value))
                         .array;
        両手装備 = info.isDoubleHands;
        装備スロット = cast(string)info.slot;
        装備可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s))
                             .array;
        素材 = cast(string)info.material;
        消耗タイプ = cast(string)info.type;
        耐久 = info.exhaustion;
        追加効果 = info.effects;
        付加効果 = info.additionalEffect; //
        効果アップ = info.specials; //
        魔法チャージ = info.canMagicCharged;
        属性チャージ = info.canElementCharged;
    }

    DamageInfo[] 攻撃力;
    int 攻撃間隔;
    double 有効レンジ;
    SkillNumberLink[] 必要スキル;
    bool 両手装備;
    string 装備スロット;
    ShipLink[] 装備可能シップ;
    string 素材;
    string 消耗タイプ;
    int 耐久;
    double[string] 追加効果;
    int[string] 付加効果;
    string[] 効果アップ;
    bool 魔法チャージ;
    bool 属性チャージ;
}

struct ArmorInfo
{
    import coop.core;
    import coop.core.item: AInfo = ArmorInfo, Grade;

    this(AInfo info, WisdomModel wm)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.traits;

        アーマークラス = [EnumMembers!Grade]
                              .filter!(g => info.AC.keys.canFind(g))
                              .map!(g => DamageInfo(cast(string)g, info.AC[g]))
                              .array;
        必要スキル = info.skills
                         .byKeyValue
                         .map!(kv => SkillNumberLink(kv.key, kv.value))
                         .array;
        装備スロット = cast(string)info.slot;
        装備可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s))
                             .array;
        素材 = cast(string)info.material;
        消耗タイプ = cast(string)info.type;
        耐久 = info.exhaustion;
        追加効果 = info.effects;
        付加効果 = info.additionalEffect;
        効果アップ = info.specials;
        魔法チャージ = info.canMagicCharged;
        属性チャージ = info.canElementCharged;

    }

    DamageInfo[] アーマークラス;
    SkillNumberLink[] 必要スキル;
    string 装備スロット;
    ShipLink[] 装備可能シップ;
    string 素材;
    string 消耗タイプ;
    int 耐久;
    double[string] 追加効果;
    string 付加効果; //
    string[] 効果アップ; //
    bool 魔法チャージ;
    bool 属性チャージ;
}

struct BulletInfo
{
    import coop.core;
    import coop.core.item: BInfo = BulletInfo;

    this(BInfo info, WisdomModel wm) pure nothrow
    {
        import std.algorithm;
        import std.range;

        ダメージ = info.damage;
        有効レンジ = info.range;
        角度補正角 = info.angle;
        使用可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s))
                             .array;
        必要スキル = info.skills
                         .byKeyValue
                         .map!(kv => SkillNumberLink(kv.key, kv.value))
                         .array;
        追加効果 = info.effects;
        付与効果 = info.additionalEffect; //
    }

    double ダメージ;
    double 有効レンジ;
    int 角度補正角;
    ShipLink[] 使用可能シップ;
    SkillNumberLink[] 必要スキル;
    double[string] 追加効果;
    string 付与効果;
}

struct ShieldInfo
{
    import coop.core;
    import coop.core.item: SInfo = ShieldInfo, Grade;

    this(SInfo info, WisdomModel wm)
    {
        import std.algorithm;
        import std.conv;
        import std.range;
        import std.traits;

        アーマークラス = [EnumMembers!Grade]
                              .filter!(g => info.AC.keys.canFind(g))
                              .map!(g => DamageInfo(cast(string)g, info.AC[g]))
                              .array;
        必要スキル = info.skills
                         .byKeyValue
                         .map!(kv => SkillNumberLink(kv.key, kv.value))
                         .array;
        回避 = info.avoidRatio;
        使用可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s))
                             .array;
        素材 = cast(string)info.material;
        消耗タイプ = cast(string)info.type;
        耐久 = info.exhaustion;
        追加効果 = info.effects;
        付加効果 = info.additionalEffect;
        効果アップ = info.specials;
        魔法チャージ = info.canMagicCharged;
        属性チャージ = info.canElementCharged;
    }

    DamageInfo[] アーマークラス;
    SkillNumberLink[] 必要スキル;
    int 回避;
    ShipLink[] 使用可能シップ;
    string 素材;
    string 消耗タイプ;
    int 耐久;
    double[string] 追加効果;
    string 付加効果;
    string[] 効果アップ;
    bool 魔法チャージ;
    bool 属性チャージ;
}

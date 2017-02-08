/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model.data;

import vibe.data.json;

struct BinderLink
{
    this(string binder, string host) @safe pure nothrow
    {
        import std.array;
        import std.path;
        バインダー名 = binder;
        レシピ一覧 = buildPath(host, "binders", binder.replace("/", "_"), "recipes");
    }
    string バインダー名;
    string レシピ一覧;
}

struct SkillLink
{
    this(string skill, string host) @safe pure nothrow
    {
        import std.path;
        スキル名 = skill;
        レシピ一覧 = buildPath(host, "skills", skill, "recipes");
    }
    string スキル名;
    string レシピ一覧;
}

struct SkillNumberLink
{
    this(string skill, double val, string host) @safe pure nothrow
    {
        import std.path;
        スキル名 = skill;
        レシピ一覧 = buildPath(host, "skills", skill, "recipes");
        スキル値 = val;
    }
    string スキル名;
    string レシピ一覧;
    double スキル値;
}

struct ItemLink
{
    this(string item, string host) @safe pure nothrow
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
    this(string recipe, string host) @safe pure nothrow
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
    this(string item, int num, string host) @safe pure nothrow
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

struct RecipeNumberLink
{
    this(string recipe, int num, string host) @safe pure nothrow
    {
        import std.path;
        レシピ名 = recipe;
        詳細 = buildPath(host, "recipes", recipe);
        コンバイン回数 = num;
    }
    string レシピ名;
    string 詳細;
    int コンバイン回数;
}

struct RecipeInfo
{
    import coop.core;
    import coop.core.recipe;

    this(Recipe r, WisdomModel wm, string host) pure nothrow
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

struct SpecialPropertyInfo
{
    string 略称;
    string 詳細;
}

struct PetFoodInfo
{
    string 種別;
    double 効果;
}

struct ItemInfo
{
    import std.typecons;

    import coop.core;
    import coop.core.item;

    this(Item item, WisdomModel wm, string host)
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
        ペットアイテム = item.petFoodInfo.byKeyValue.map!(kv => PetFoodInfo(kv.key.to!PetFoodType.to!string, kv.value)).front;
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
            飲食物情報 = FoodInfo(*ex.extra.peek!FInfo, wm, host);
            break;
        }
        case Weapon: {
            import coop.core.item: WInfo = WeaponInfo;
            武器情報 = WeaponInfo(*ex.extra.peek!WInfo, wm, host);
            break;
        }
        case Armor: {
            import coop.core.item: AInfo = ArmorInfo;
            防具情報 = ArmorInfo(*ex.extra.peek!AInfo, wm, host);
            break;
        }
        case Bullet: {
            import coop.core.item: BInfo = BulletInfo;
            弾情報 = BulletInfo(*ex.extra.peek!BInfo, wm, host);
            break;
        }
        case Shield: {
            import coop.core.item: SInfo = ShieldInfo;
            盾情報 = ShieldInfo(*ex.extra.peek!SInfo, wm, host);
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
    string アイテム種別;

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

    this(FInfo info, WisdomModel wm, string host) @safe pure
    {
        効果 = info.effect;
        if (auto eff = info.additionalEffect)
        {
            付加効果 = FoodBufferInfo(eff, wm, host);
        }
    }

    double 効果;
    Nullable!FoodBufferInfo 付加効果;
}

struct FoodBufferInfo
{
    import coop.core;

    this(string eff, WisdomModel wm, string host) @safe pure
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
    this(string ship, string host) @safe pure nothrow
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

    this(WInfo info, WisdomModel wm, string host)
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
                         .map!(kv => SkillNumberLink(kv.key, kv.value, host))
                         .array;
        両手装備 = info.isDoubleHands;
        装備箇所 = cast(string)info.slot;
        装備可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s, host))
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
    string 装備箇所;
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

    this(AInfo info, WisdomModel wm, string host)
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
                         .map!(kv => SkillNumberLink(kv.key, kv.value, host))
                         .array;
        装備箇所 = cast(string)info.slot;
        装備可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s, host))
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
    string 装備箇所;
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

    this(BInfo info, WisdomModel wm, string host) pure nothrow
    {
        import std.algorithm;
        import std.range;

        ダメージ = info.damage;
        有効レンジ = info.range;
        角度補正角 = info.angle;
        使用可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s, host))
                             .array;
        必要スキル = info.skills
                         .byKeyValue
                         .map!(kv => SkillNumberLink(kv.key, kv.value, host))
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

    this(SInfo info, WisdomModel wm, string host)
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
                         .map!(kv => SkillNumberLink(kv.key, kv.value, host))
                         .array;
        回避 = info.avoidRatio;
        使用可能シップ = info.restriction
                             .map!(s => ShipLink(cast(string)s, host))
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

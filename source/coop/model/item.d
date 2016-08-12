/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.model.item;

import std.algorithm;
import std.conv;
import std.container;
import std.exception;
import std.file;
import std.json;
import std.math;
import std.range;
import std.traits;
import std.typecons;
import std.variant;

import coop.util;

/// アイテムの追加情報
alias ExtraInfo = Algebraic!(FoodInfo, WeaponInfo, ArmorInfo, BulletInfo, ExpendableInfo);

/// アイテム一般の情報
struct Item
{
    this(this) @safe pure nothrow
    {
        petFoodInfo = assumeWontThrow(petFoodInfo.dup);
    }

    /// アイテム名
    dstring name;
    /// 英語名
    dstring ename;
    /// 重さ
    real weight;
    /// NPC 売却価格
    uint price;
    /// info
    dstring info;
    /// 特殊条件
    ushort properties;
    /// 転送可能かどうか
    bool transferable;
    /// スタックできるかどうか
    bool stackable;
    /// ペットアイテム
    real[PetFoodType] petFoodInfo;
    /// 備考
    dstring remarks;
    /// アイテム種別
    ItemType type;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;

    auto toJSON() const
    {
        auto hash = [
            "英名": JSONValue(ename.to!string),
            "NPC売却価格": JSONValue(price),
            "重さ": JSONValue(weight.isNaN ? 0 : weight),
            "info": JSONValue(info.to!string),
            "転送できる": JSONValue(transferable),
            "スタックできる": JSONValue(stackable),
            "種類": JSONValue(type.to!string),
            ];

        assert(petFoodInfo.keys.length == 1);
        if (petFoodInfo.keys[0] != PetFoodType.NoEatable)
        {
            hash["ペットアイテム"] = JSONValue(petFoodInfo.to!(real[string]));
        }

        if (properties)
        {
            hash["特殊条件"] = JSONValue(properties.toStrings(false));
        }
        if (!remarks.empty)
        {
            hash["備考"] = JSONValue(remarks.to!string);
        }
        return JSONValue(hash);
    }
}

unittest
{
    Item item;
    with(item)
    {
        name = "マイナーズ ワイフ";
        price = 0;
        weight = 0.03;
        petFoodInfo = [ PetFoodType.UNKNOWN.to!PetFoodType: 0.0 ];
        stackable = true;
        properties = SpecialProperty.OP;
        type = ItemType.Others;
        remarks = "クエストで使う";
    }
    auto json = item.toJSON;
    with(json)
    {
        assert(json["英名"].str == item.ename.to!string);
        assert(json["info"].str == item.info.to!string);
        assert(json["NPC売却価格"].uinteger == item.price);
        assert(json["重さ"].floating.approxEqual(item.weight));
        assert(json["転送できる"].type == JSON_TYPE.FALSE);
        assert(json["スタックできる"].type == JSON_TYPE.TRUE);
        assert(json["ペットアイテム"].object == ["不明": JSONValue(0.0)]);
        assert(json["種類"].str == item.type.to!string);
        assert(json["備考"].str == item.remarks.to!string);
    }
}

auto readItems(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto items = res.object;
    return items.keys.map!(key =>
                           tuple(key.to!dstring,
                                 key.toItem(items[key].object,
                                            fname)));
}

/**
 * アイテム s の情報を、ファイル fname に書かれている json から読み込む
 */
auto toItem(string s, JSONValue[string] json, string fname)
{
    Item item;
    with(item)
    {
        name = s.to!dstring;
        ename = json["英名"].jto!dstring;
        price = json["NPC売却価格"].jto!uint;
        weight = json["重さ"].jto!real;
        info = json["info"].jto!dstring;
        transferable = json["転送できる"].jto!bool;
        stackable = json["スタックできる"].jto!bool;

        if (auto petFood = "ペットアイテム" in json)
        {
            petFoodInfo = (*petFood).jto!(real[PetFoodType]);
        }
        else
        {
            petFoodInfo = [PetFoodType.NoEatable.to!PetFoodType: 0];
        }

        if (auto props = "特殊条件" in json)
        {
            properties = (*props).array.toSpecialProperties;
        }
        type = json["種類"].jto!ItemType;
        file = fname;
    }
    return item;
}

alias PetFoodType = ExtendedEnum!(
    UNKNOWN => "不明", Food => "食べ物", Meat => "肉食物", Weed => "草食物",
    Drink => "飲み物", Liquor => "酒", Medicine => "薬", Metal => "金属",
    Stone => "石", Bone => "骨", Crystal => "クリスタル", Wood => "木",
    Leather => "皮", Paper => "紙", Cloth => "布", Others => "その他",
    NoEatable => "犬も喰わない",);

enum SpecialProperty: ushort
{
    NT = 0b00000000000001,
    OP = 0b00000000000010,
    CS = 0b00000000000100,
    CR = 0b00000000001000,
    PM = 0b00000000010000,
    NC = 0b00000000100000,
    NB = 0b00000001000000,
    ND = 0b00000010000000,
    CA = 0b00000100000000,
    DL = 0b00001000000000,
    TC = 0b00010000000000,
    LO = 0b00100000000000,
    AL = 0b01000000000000,
    WA = 0b10000000000000,
}

auto toStrings(ushort sps, bool detailed = true) pure
{
    with(SpecialProperty)
    {
        auto propMap = [
            NT: "他のプレイヤーにトレードで渡せない",
            OP: "一人一個のみ",
            CS: "売ることができない",
            CR: "修理できない",
            PM: "消耗度による威力計算を行わない",
            NC: "修理による最大耐久度低下を行わない",
            NB: "耐久度による武器の破壊が行われない",
            ND: "死亡時ドロップしない",
            CA: "カオスエイジで死亡しても消えない",
            DL: "死亡すると消える",
            TC: "タイムカプセルボックスに入れることが出来ない",
            LO: "ログアウトすると消える",
            AL: "現在のエリア限定",
            WA: "WarAgeでは性能が低下する",
            ];
        auto str(SpecialProperty p)
        {
            return detailed ? propMap[p] : p.to!string;
        }
        return propMap.keys.filter!(p => sps&p).map!(p => str(p)).array;
    }
}

pure unittest
{
    assert(SpecialProperty.OP.toStrings.equal(["一人一個のみ"]));
    assert((SpecialProperty.CS | SpecialProperty.CR).toStrings.sort().equal(["修理できない", "売ることができない"]));

    assert(SpecialProperty.OP.toStrings(false).equal(["OP"]));
}

auto toSpecialProperties(JSONValue[] vals) pure
{
    auto props = vals.map!"a.str".map!(s => s.to!SpecialProperty).array;
    return props.reduce!((a, b) => a|b).to!ushort;
}

alias ItemType = ExtendedEnum!(
    UNKNOWN => "不明", Others => "その他", Food => "食べ物", Drink => "飲み物",
    Liquor => "酒", Expendable => "消耗品", Weapon => "武器", Armor => "防具",
    Bullet => "弾", Asset => "アセット",);

/// 料理固有の情報
struct FoodInfo
{
    dstring name;
    real effect;
    dstring additionalEffect;
}

auto readFoods(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto foods = res.object;
    return foods.keys.map!(key =>
                           tuple(key.to!dstring,
                                 key.toFoodInfo(foods[key].object)));
}

auto toFoodInfo(string s, JSONValue[string] json) @safe pure
{
    FoodInfo info;
    with(info)
    {
        name = s.to!dstring;
        effect = json["効果"].jto!real;
        if (auto addition = "付加効果" in json)
        {
            additionalEffect = (*addition).jto!dstring;
        }
    }
    return info;
}

/// 飲食バフのグループ
enum AdditionalEffectGroup
{
    A, B1, B2, C1, C2, D1, D2, D3, D4, E, F, Others,
}

/// 飲食バフの効果情報
struct AdditionalEffect
{
    dstring name;
    AdditionalEffectGroup group;
    int[dstring] effects;
    dstring otherEffects;
    uint duration;
    dstring remarks;
}

auto readFoodEffects(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto effects = res.object;
    return effects.keys.map!(key =>
                             tuple(key.to!dstring,
                                   key.toFoodEffect(effects[key].object)));
}

auto toFoodEffect(string s, JSONValue[string] json) pure
{
    AdditionalEffect effect;
    with(effect)
    {
        name = s.to!dstring;
        effects = json["効果"].jto!(int[dstring]);
        if (auto others = "その他効果" in json)
        {
            otherEffects = (*others).jto!dstring;
        }
        duration = json["効果時間"].jto!uint;
        group = json["グループ"].jto!AdditionalEffectGroup;
        if (auto rem = "備考" in json)
        {
            remarks = (*rem).jto!dstring;
        }
    }
    return effect;
}

struct WeaponInfo
{
    /// ダメージ
    real[Grade] damage;
    /// 攻撃間隔
    int duration;
    /// 有効レンジ
    real range;
    /// 必要スキル
    real[dstring] skills;
    /// 両手持ちかどうか
    bool isDoubleHands;
    /// 装備スロット
    WeaponSlot slot;
    /// 使用可能シップ
    ShipRestriction[] restriction;
    /// 素材
    Material material;
    /// 消耗タイプ
    ExhaustionType type;
    /// 消耗度
    int exhaustion;
    /// 追加効果
    real[dstring] effects;
    /// 付与効果
    int[dstring] additionalEffect;
    /// 効果アップ
    RedBlackTree!dstring specials;
    /// 魔法チャージ可能かどうか
    bool canMagicCharged;
    /// 属性チャージ可能かどうか
    bool canElementCharged;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;
}

auto readWeapons(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto weapons = res.object;
    return weapons.keys.map!(key =>
                             tuple(key.to!dstring,
                                   weapons[key].object.toWeaponInfo(fname)));
}

auto toWeaponInfo(JSONValue[string] json, string fname)
{
    WeaponInfo info;
    with(info)
    {
        damage = json["攻撃力"].jto!(real[Grade]);
        duration = json["攻撃間隔"].jto!int;
        range = json["射程"].jto!real;
        skills = json["必要スキル"].jto!(real[dstring]);
        slot = json["装備箇所"].jto!WeaponSlot;
        isDoubleHands = json["両手装備"].jto!bool;
        material = json["素材"].jto!Material;
        if (auto t = "消耗タイプ" in json)
        {
            type = (*t).jto!ExhaustionType;
        }
        exhaustion = json["耐久"].jto!int;
        if (auto f = "追加効果" in json)
        {
            effects = (*f).jto!(real[dstring]);
        }
        if (auto af = "付与効果" in json)
        {
            additionalEffect = (*af).jto!(int[dstring]);
        }

        specials = new RedBlackTree!dstring;
        if (auto sp = "効果アップ" in json)
        {
            specials.insert((*sp).jto!(dstring[]));
        }

        if (auto rest = "使用可能シップ" in json)
        {
            restriction = (*rest).jto!(ShipRestriction[]);
        }
        else
        {
            restriction = [ShipRestriction.Any.to!ShipRestriction];
        }
        canMagicCharged = json["魔法チャージ"].jto!bool;
        canElementCharged = json["属性チャージ"].jto!bool;

        file = fname;
    }
    return info;
}

struct ArmorInfo
{
    /// アーマークラス
    real[Grade] AC;
    /// 必要スキル
    real[dstring] skills;
    /// 装備スロット
    ArmorSlot slot;
    /// 使用可能シップ
    ShipRestriction[] restriction;
    /// 素材
    Material material;
    /// 消耗タイプ
    ExhaustionType type;
    /// 消耗度
    int exhaustion;
    /// 追加効果
    real[dstring] effects;
    /// 付加効果
    dstring additionalEffect;
    /// 効果アップ
    RedBlackTree!dstring specials;
    /// 魔法チャージ可能かどうか
    bool canMagicCharged;
    /// 属性チャージ可能かどうか
    bool canElementCharged;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;
}

auto readArmors(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto armors = res.object;
    return armors.keys.map!(key =>
                             tuple(key.to!dstring,
                                   armors[key].object.toArmorInfo(fname)));
}

auto toArmorInfo(JSONValue[string] json, string fname)
{
    ArmorInfo info;
    with(info)
    {
        AC = json["アーマークラス"].jto!(real[Grade]);
        skills = json["必要スキル"].jto!(real[dstring]);
        slot = json["装備箇所"].jto!ArmorSlot;
        material = json["素材"].jto!Material;
        if (auto t = "消耗タイプ" in json)
        {
            type = (*t).jto!ExhaustionType;
        }
        exhaustion = json["耐久"].jto!int;
        if (auto f = "追加効果" in json)
        {
            effects = (*f).jto!(real[dstring]);
        }
        if (auto af = "付加効果" in json)
        {
            additionalEffect = (*af).jto!dstring;
        }

        specials = new RedBlackTree!dstring;
        if (auto sp = "効果アップ" in json)
        {
            specials.insert((*sp).jto!(dstring[]));
        }

        if (auto rest = "使用可能シップ" in json)
        {
            restriction = (*rest).jto!(ShipRestriction[]);
        }
        else
        {
            restriction = [ShipRestriction.Any.to!ShipRestriction];
        }
        canMagicCharged = json["魔法チャージ"].jto!bool;
        canElementCharged = json["属性チャージ"].jto!bool;

        file = fname;
    }
    return info;
}

struct BulletInfo
{
    real damage;
    real range;
    int angle;
    ShipRestriction[] restriction;
    real[dstring] skills;
    real[dstring] effects;
    dstring additionalEffect;
}

auto readBullets(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto bullets = res.object;
    return bullets.keys.map!(key =>
                             tuple(key.to!dstring,
                                   bullets[key].object.toBulletInfo));
}

auto toBulletInfo(JSONValue[string] json)
{
    BulletInfo info;
    with(info)
    {
        damage = json["ダメージ"].jto!real;
        range = json["有効レンジ"].jto!real;
        angle = json["角度補正角"].jto!int;
        skills = json["必要スキル"].jto!(real[dstring]);
        if (auto f = "追加効果" in json)
        {
            effects = (*f).jto!(real[dstring]);
        }
        if (auto af = "付与効果" in json)
        {
            additionalEffect = (*af).jto!dstring;
        }

        if (auto rest = "使用可能シップ" in json)
        {
            restriction = (*rest).jto!(ShipRestriction[]);
        }
        else
        {
            restriction = [ShipRestriction.Any.to!ShipRestriction];
        }
    }
    return info;
}

struct AssetInfo
{
    uint width, depth, height;
    Material material;
    int exhaustion;
}

alias ShipRestriction = ExtendedEnum!(
    UNKNOWN => "不明", Any => "なし",
    // 基本シップ
    // 熟練
    Puncher => "パンチャー", Swordsman => "剣士",
    Macer => "メイサー",
    Lancer => "ランサー", Gunner => "ガンナー", Archer => "アーチャー",
    Guardsman => "ガーズマン",
    //"投げ士",
    Ranger => "レンジャー", BloodSucker => "ブラッド サッカー",
    Kicker => "キッカー", Wildman => "ワイルドマン", Drinker => "ドリンカー", Copycat => "物まね師",
    Tamer => "テイマー", Wizard => "ウィザード", Priest => "プリースト", Shaman => "シャーマン",
    Enchanter => "エンチャンター", Summoner => "サモナー", Shadow => "シャドウ", Magician => "魔術師",
    WildBoy => "野生児", Gremlin => "小悪魔", Vendor =>"ベンダー", RockSinger => "ロックシンガー",
    Songsinger => "ソングシンガー", //"スリ",
    Showboat => "目立ちたがり", StreetDancer => "ストリートダンサー",

    // 基本
    Fallman => "フォールマン",
    Swimmer => "スイマー", // DeadMan => "デッドマン",
    Helper => "ヘルパー",
    Recoverer => "休憩人",
    Miner => "マイナー",
    Woodsman => "木こり", Plower => "耕作師",
    Angler => "釣り人", // "解読者",

    // 生産
    Cook => "料理師",
    //"鍛冶師",
    Bartender => "バーテンダー", WoodWorker => "木工師", Tailor => "仕立て屋",
    Drugmaker => "調合師", Decorator => "細工師", Scribe => "筆記師",
    Barber => "調髪師", Cultivator => "栽培師",

    // 複合
    Warrior => "ウォーリアー",  Alchemist => "アルケミスト", Forester => "フォレスター",
    Necromancer => "ネクロマンサー", Creator => "クリエイター", Bomberman => "爆弾男",
    Breeder => "ブリーダー", TempleKnight => "テンプルナイト", Druid => "ドルイド",
    SageOfCerulean => "紺碧の賢者", GreatCreator => "グレート クリエイター",
    Mercenary => "傭兵", Samurai => "サムライ", MineBishop => "マイン ビショップ",
    KitchenMaster => "厨房師", Assassin => "アサシン", SeaFighter => "海戦士",
    BraveKnight => "ブレイブナイト", EvilKnight => "イビルナイト",
    CosPlayer => "コスプレイヤー", Dabster => "物好き", Athlete => "アスリート",
    DrunkenFighter => "酔拳士", Rowdy => "荒くれ者", NewIdol => "新人アイドル",
    HouseKeeper => "ハウスキーパー", Adventurer => "アドベンチャラー",
    Spy => "スパイ", Punk => "チンピラ", Academian => "アカデミアン",
    BloodBard => "ブラッドバード", Duelist => "デュエリスト", Collector => "コレクター",

    // 二次シップ
    Sniper => "スナイパー", Hawkeye => "ホークアイ",
    );

alias WeaponSlot = ExtendedEnum!(
    UNKNOWN => "不明", Right => "右手", Left => "左手", Both => "左右",
    );

alias ArmorSlot = ExtendedEnum!(
    UNKNOWN => "不明",
    HeadProtector => "頭(防)", BodyProtector => "胴(防)", HandProtector => "手(防)",
    PantsProtector => "パンツ(防)", ShoesProtector => "靴(防)", ShoulderProtector => "肩(防)",
    WaistProtector => "腰(防)",
    HeadOrnament => "頭(装)", FaceOrnament => "顔(装)", EarOrnament => "耳(装)",
    FingerOrnament => "手(装)", BreastOrnament => "胸(装)", BackOrnament => "背中(装)",
    WaistOrnament => "腰(装)",
    );

alias Material = ExtendedEnum!(
    UNKNOWN => "不明", Copper => "銅", Bronze => "青銅", Iron => "鉄", Steel => "鋼鉄",
    Silver => "銀", Gold => "金", Mithril => "ミスリル", Orichalcum => "オリハルコン",
    Cotton => "綿", Silk => "絹", AnimalSkin => "動物の皮", DragonSkin => "竜の皮",
    Plant => "プラント", Wood => "木", Treant => "トレント", Paper => "紙",
    Bamboo => "竹筒", BlackBamboo => "黒い竹", Bone => "骨", Stone => "石",
    Glass => "ガラス", Crystal => "クリスタル", Cobalt => "コバルト", Chaos => "カオス",);

alias Grade = ExtendedEnum!(
    UNKNOWN => "不明", Degraded => "劣化", Cursed => "呪い", NG => "NG", HG => "HG", MG => "MG", NG_War => "NG(War)"
    );

alias ExhaustionType = ExtendedEnum!(
    UNKNOWN => "不明", Points => "耐久値", Times => "使用可能回数",
    );

/// 消耗品固有の情報
struct ExpendableInfo
{
    real[dstring] skill;
    dstring effect;
}

auto readExpendables(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto expendables = res.object;
    return expendables.keys.map!(key =>
                             tuple(key.to!dstring,
                                   expendables[key].object.toExpendableInfo));
}

auto toExpendableInfo(JSONValue[string] json) pure
{
    ExpendableInfo info;
    with(info)
    {
        effect = json["効果"].jto!dstring;
        if (auto f = "必要スキル" in json)
        {
            skill = (*f).jto!(real[dstring]);
        }
    }
    return info;
}

struct Overlaid(T)
{
    this(T orig, T* ol)
    {
        original = orig;
        overlaid = ol;
    }

    @property auto ref opDispatch(string field)()
        if (hasMember!(T, field))
    {
        if (isOverlaid!field)
        {
            return mixin("overlaid."~field);
        }
        else
        {
            return mixin("original."~field);
        }
    }

    @property auto isOverlaid(string field)() const pure nothrow
        if (hasMember!(T, field))
    {
        return overlaid !is null && !isValidValue(mixin("original."~field));
    }
private:
    static auto isValidValue(T)(T val) pure nothrow
    {
        static if (isFloatingPoint!T)
            return !val.isNaN;
        else static if (isSomeString!T)
            return !val.empty;
        else static if (isIntegral!T)
            return val > 0;
        else static if (is(T == bool))
            return val;
        else static if (is(T == real[PetFoodType]))
        {
            return val.keys[0] != PetFoodType.UNKNOWN;
        }
        else
            return val != T.init;
    }

    T original;
    T* overlaid;
}

@safe nothrow unittest
{
    Item orig;
    with(orig)
    {
        name = "テスト";
        ename = "test";
        weight = 0.3;
        price = 100;
        info = "Info";
        petFoodInfo[PetFoodType.UNKNOWN.to!PetFoodType] = 0;
    }

    auto overlaid = Overlaid!Item(orig, null);
    foreach(field; FieldNameTuple!Item)
    {
        assert(!overlaid.isOverlaid!field);
    }
    assert(overlaid.name == "テスト");
}

pure nothrow unittest
{
    Item orig;
    orig.name = "テスト";

    Item item;
    item.name = "テスト";
    item.ename = "test";
    item.weight = 1.4;

    auto overlaid = Overlaid!Item(orig, &item);
    assert(!overlaid.isOverlaid!"name");
    assert(overlaid.name == "テスト");

    assert(overlaid.isOverlaid!"ename");
    assert(overlaid.ename == "test");

    assert(overlaid.isOverlaid!"weight");
    assert(overlaid.weight == 1.4);

    assert(overlaid.isOverlaid!"price");
    assert(overlaid.price == 0);
}

/**
 * Authors: Mojo
 * License: MIT License
 */
module coop.model.item;

import std.algorithm;
import std.conv;
import std.exception;
import std.file;
import std.json;
import std.math;
import std.range;
import std.traits;
import std.typecons;
import std.variant;

import coop.util;

alias ExtraInfo = Algebraic!(FoodInfo, WeaponInfo, BulletInfo, ExpendableInfo);

/// アイテム一般の情報
struct Item
{
    this(this) @safe pure nothrow
    {
        petFoodInfo = assumeWontThrow(petFoodInfo.dup);
    }

    dstring name;
    dstring ename;
    real weight;
    uint price;
    dstring info;
    ushort properties;
    bool transferable;
    bool stackable;
    real[PetFoodType] petFoodInfo;
    dstring remarks;
    ItemType type;

    auto toJSON()
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
        return JSONValue(hash);
    }

    bool opEquals(ref const typeof(this) other) const @safe pure nothrow
    {
        auto prop(string p)(in typeof(this) item)
        {
            return mixin("item."~p);
        }
        foreach(field; FieldNameTuple!(typeof(this)))
        {
            static if (field == "weight")
            {
                import std.math;
                if (!prop!field(this).isNaN && !prop!field(other).isNaN &&
                    !prop!field(this).approxEqual(prop!field(other)))
                {
                    return false;
                }
                else if (prop!field(this).isNaN ^ prop!field(other).isNaN)
                {
                    return false;
                }
            }
            else
            {
                if (prop!field(this) != prop!field(other))
                {
                    return false;
                }
            }
        }
        return true;
    }

    size_t toHash() const @safe pure nothrow
    {
        return name.hashOf;
    }
}

auto readItems(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto items = res.object;
    return items.keys.map!(key =>
                           tuple(key.to!dstring,
                                 key.toItem(items[key].object)));
}

auto toItem(string s, JSONValue[string] json)
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

auto toStrings(ushort sps, bool detailed = true)
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

auto toSpecialProperties(JSONValue[] vals)
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

auto toFoodInfo(string s, JSONValue[string] json)
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

auto toFoodEffect(string s, JSONValue[string] json)
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
    real[Grade] damage;
    int duration;
    real range;
    real[dstring] skills;
    bool isDoubleHands;
    WeaponSlot slot;
    ShipRestriction[] restriction;
    Material material;
    ExhaustionType type;
    int exhaustion;
    real[dstring] effects;
    int[dstring] additionalEffect;
}

auto readWeapons(string fname)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto weapons = res.object;
    return weapons.keys.map!(key =>
                             tuple(key.to!dstring,
                                   weapons[key].object.toWeaponInfo));
}

auto toWeaponInfo(JSONValue[string] json)
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

struct ArmorInfo
{
    real[Grade] AC;
    real[dstring] skills;
    ArmorSlot slot;
    ShipRestriction[] restriction;
    Material material;
    ExhaustionType type;
    int exhaustion;
    real[dstring] effects;
    dstring additionalEffect;
}

struct BulletInfo
{
    real damage;
    real range;
    int angle;
    ShipRestriction[] restriction;
    real[dstring] skills; // ステータス上の効果
    real[dstring] effects;
    dstring additionalEffect; // 攻撃に用いた時の付加効果
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
        // if (auto af = "付与効果" in json)
        // {
        //     additionalEffect = (*af).jto!(int[dstring]);
        // }

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
    Puncher => "パンチャー", //"剣士", "メイサー",
    Lancer => "ランサー", //"ガンナー", "アーチャー",
    Guardsman => "ガーズマン",
    //"投げ士", "レンジャー", "ブラッド サッカー",
    Kicker => "キッカー", Wildman => "ワイルドマン", Drinker => "ドリンカー",
    //"物まね師",
    Tamer => "テイマー", //"ウィザード", "プリースト", "シャーマン", //ウィッチは？
    Enchanter => "エンチャンター",
    //"サモナー", "シャドウ", "魔術師", "野生児", "小悪魔",
    Vendor =>"ベンダー", //"ロックシンガー",
    Songsinger => "ソングシンガー", //"スリ",
    Showboat => "目立ちたがり", StreetDancer => "ストリートダンサー",

    // 基本
    // "フォールマン",
    Swimmer => "スイマー", //"デッドマン",
    Helper => "ヘルパー",
    //"休憩人",
    Miner => "マイナー",
    // "木こり", "耕作師", "釣り人", "解読者",

    // 生産
    Cook => "料理師",
    //"鍛冶師", "バーテンダー", "木工師",
    Tailor => "仕立て屋",
    // "調合師",
    Decorator => "細工師",
    //"筆記師", "調髪師", "栽培師",

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
    Sniper => "スナイパー",
    );

alias WeaponSlot = ExtendedEnum!(
    UNKNOWN => "不明", Right => "右手", Left => "左手", Both => "左右",
    );

alias ArmorSlot = ExtendedEnum!(
    UNKNOWN => "不明", HeadProtector => "頭(防)", BodyProtector => "胴(防)",
    HandProtector => "手(防)", PantsProtector => "パンツ(防)", ShoesProtector => "靴(防)",
    ShoulderProtector => "肩(防)", WaistProtector => "腰(防)",
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
    UNKNOWN => "不明", Degraded => "劣化", NG => "NG", HG => "HG", MG => "MG",
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

auto toExpendableInfo(JSONValue[string] json)
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

    @property auto isOverlaid(string field)()
        if (hasMember!(T, field))
    {
        return overlaid !is null && !isValidValue(mixin("original."~field));
    }
private:
    static auto isValidValue(T)(T val)
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

unittest
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

unittest
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

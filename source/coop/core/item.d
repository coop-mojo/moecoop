/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.item;

import std.json: JSONValue;
import std.variant: Algebraic;

import coop.util: ExtendedEnum;

/// アイテムの追加情報
alias ExtraInfo = Algebraic!(FoodInfo, WeaponInfo, ArmorInfo, BulletInfo, ShieldInfo, ExpendableInfo);

/// アイテム一般の情報
struct Item
{
    this(this) @safe pure nothrow
    {
        import std.exception: assumeWontThrow;
        petFoodInfo = assumeWontThrow(petFoodInfo.dup);
    }

    /// アイテム名
    string name;
    /// 英語名
    string ename;
    /// 重さ
    real weight;
    /// NPC 売却価格
    uint price;
    /// info
    string info;
    /// 特殊条件
    ushort properties;
    /// 転送可能かどうか
    bool transferable;
    /// スタックできるかどうか
    bool stackable;
    /// ペットアイテム
    real[PetFoodType] petFoodInfo;
    /// 備考
    string remarks;
    /// アイテム種別
    ItemType type;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;

    auto toJSON() const
    {
        import std.conv: to;
        import std.math: isNaN;
        import std.range: empty;

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

    auto opCast(T: bool)()
    {
        import std.range;
        return !name.empty;
    }
}

unittest
{
    import std.conv: to;

    Item item;
    assert(cast(bool)item == false);
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
    assert(cast(bool)item == true);

    auto json = item.toJSON;
    with(json)
    {
        import std.json: JSON_TYPE;
        import std.math: approxEqual;

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
    import std.algorithm: map;
    import std.conv: to;
    import std.exception: enforce;
    import std.file: readText;
    import std.json: JSON_TYPE, parseJSON;
    import std.typecons: tuple;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto items = res.object;
    return items.keys.map!(key =>
                           tuple(key.to!string,
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
        import std.conv: to;
        import coop.util: jto;

        name = s.to!string;
        ename = json["英名"].jto!string;
        price = json["NPC売却価格"].jto!uint;
        weight = json["重さ"].jto!real;
        info = json["info"].jto!string;
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
        import std.algorithm: filter, map;
        import std.range: array;

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
            import std.conv: to;
            return detailed ? propMap[p] : p.to!string;
        }
        return propMap.keys.filter!(p => sps&p).map!(p => str(p)).array;
    }
}

pure unittest
{
    import std.algorithm: equal, sort;
    assert(SpecialProperty.OP.toStrings.equal(["一人一個のみ"]));
    assert((SpecialProperty.CS | SpecialProperty.CR).toStrings.sort().equal(["修理できない", "売ることができない"]));

    assert(SpecialProperty.OP.toStrings(false).equal(["OP"]));
}

auto toSpecialProperties(JSONValue[] vals) pure
{
    import std.algorithm: map, reduce;
    import std.conv: to;
    import std.range: array;
    auto props = vals.map!"a.str".map!(s => s.to!SpecialProperty).array;
    return props.reduce!((a, b) => a|b).to!ushort;
}

alias ItemType = ExtendedEnum!(
    UNKNOWN => "不明", Others => "その他", Food => "食べ物", Drink => "飲み物",
    Liquor => "酒", Expendable => "消耗品", Weapon => "武器", Armor => "防具",
    Bullet => "弾", Shield => "盾", Asset => "アセット",);

/// 料理固有の情報
struct FoodInfo
{
    import vibe.data.json: name_ = name, optional;
    @name_("名前") string name;
    @name_("効果") double effect;
    @name_("付加効果") @optional string additionalEffect;
}

auto readFoods(string fname)
{
    import vibe.data.json;

    import std.algorithm;
    import std.file;
    import std.typecons;

    return fname.readText
                .parseJsonString
                .deserialize!(JsonSerializer, FoodInfo[])
                .map!"tuple(a.name, a)";
}

/// 飲食バフのグループ
enum AdditionalEffectGroup
{
    A, B1, B2, C1, C2, D1, D2, D3, D4, E, F, Others,
}

/// 飲食バフの効果情報
struct AdditionalEffect
{
    import vibe.data.json: name_ = name, optional, byName;
    @name_("名前") string name;
    @name_("グループ") @byName AdditionalEffectGroup group;
    @name_("効果") int[string] effects;
    @name_("その他効果") @optional string otherEffects;
    @name_("効果時間") uint duration;
    @name_("備考") @optional string remarks;

    auto opCast(T: bool)()
    {
        import std.range;
        return !name.empty;
    }
}

auto readFoodEffects(string fname)
{
    import vibe.data.json;

    import std.algorithm;
    import std.file;
    import std.typecons;

    return fname.readText
                .parseJsonString
                .deserialize!(JsonSerializer, AdditionalEffect[])
                .map!"tuple(a.name, a)";
}

struct WeaponInfo
{
    import std.container.rbtree: RedBlackTree;

    /// ダメージ
    real[Grade] damage;
    /// 攻撃間隔
    int duration;
    /// 有効レンジ
    real range;
    /// 必要スキル
    real[string] skills;
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
    real[string] effects;
    /// 付与効果
    int[string] additionalEffect;
    /// 効果アップ
    RedBlackTree!string specials;
    /// 魔法チャージ可能かどうか
    bool canMagicCharged;
    /// 属性チャージ可能かどうか
    bool canElementCharged;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;
}

auto readWeapons(string fname)
{
    import std.algorithm: map;
    import std.conv: to;
    import std.exception: enforce;
    import std.file: readText;
    import std.json: JSON_TYPE, parseJSON;
    import std.typecons: tuple;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto weapons = res.object;
    return weapons.keys.map!(key =>
                             tuple(key.to!string,
                                   weapons[key].object.toWeaponInfo(fname)));
}

auto toWeaponInfo(JSONValue[string] json, string fname)
{
    WeaponInfo info;
    with(info)
    {
        import std.conv: to;
        import coop.util: jto;

        damage = json["攻撃力"].jto!(real[Grade]);
        duration = json["攻撃間隔"].jto!int;
        range = json["射程"].jto!real;
        skills = json["必要スキル"].jto!(real[string]);
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
            effects = (*f).jto!(real[string]);
        }
        if (auto af = "付与効果" in json)
        {
            additionalEffect = (*af).jto!(int[string]);
        }

        specials = new RedBlackTree!string;
        if (auto sp = "効果アップ" in json)
        {
            specials.insert((*sp).jto!(string[]));
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
    import std.container.rbtree: RedBlackTree;

    /// アーマークラス
    real[Grade] AC;
    /// 必要スキル
    real[string] skills;
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
    real[string] effects;
    /// 付加効果
    string additionalEffect;
    /// 効果アップ
    RedBlackTree!string specials;
    /// 魔法チャージ可能かどうか
    bool canMagicCharged;
    /// 属性チャージ可能かどうか
    bool canElementCharged;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;
}

auto readArmors(string fname)
{
    import std.algorithm: map;
    import std.conv: to;
    import std.exception: enforce;
    import std.file: readText;
    import std.json: JSON_TYPE, parseJSON;
    import std.typecons: tuple;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto armors = res.object;
    return armors.keys.map!(key =>
                             tuple(key.to!string,
                                   armors[key].object.toArmorInfo(fname)));
}

auto toArmorInfo(JSONValue[string] json, string fname)
{
    ArmorInfo info;
    with(info)
    {
        import std.conv: to;
        import coop.util: jto;

        AC = json["アーマークラス"].jto!(real[Grade]);
        skills = json["必要スキル"].jto!(real[string]);
        slot = json["装備箇所"].jto!ArmorSlot;
        material = json["素材"].jto!Material;
        if (auto t = "消耗タイプ" in json)
        {
            type = (*t).jto!ExhaustionType;
        }
        exhaustion = json["耐久"].jto!int;
        if (auto f = "追加効果" in json)
        {
            effects = (*f).jto!(real[string]);
        }
        if (auto af = "付加効果" in json)
        {
            additionalEffect = (*af).jto!string;
        }

        specials = new RedBlackTree!string;
        if (auto sp = "効果アップ" in json)
        {
            specials.insert((*sp).jto!(string[]));
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
    real[string] skills;
    real[string] effects;
    string additionalEffect;
}

auto readBullets(string fname)
{
    import std.algorithm: map;
    import std.conv: to;
    import std.exception: enforce;
    import std.file: readText;
    import std.json: JSON_TYPE, parseJSON;
    import std.typecons: tuple;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto bullets = res.object;
    return bullets.keys.map!(key =>
                             tuple(key.to!string,
                                   bullets[key].object.toBulletInfo));
}

auto toBulletInfo(JSONValue[string] json)
{
    BulletInfo info;
    with(info)
    {
        import std.conv: to;
        import coop.util: jto;

        damage = json["ダメージ"].jto!real;
        range = json["有効レンジ"].jto!real;
        angle = json["角度補正角"].jto!int;
        skills = json["必要スキル"].jto!(real[string]);
        if (auto f = "追加効果" in json)
        {
            effects = (*f).jto!(real[string]);
        }
        if (auto af = "付与効果" in json)
        {
            additionalEffect = (*af).jto!string;
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

struct ShieldInfo
{
    import std.container.rbtree: RedBlackTree;

    /// アーマークラス
    real[Grade] AC;
    /// 必要スキル
    real[string] skills;
    /// 回避率
    int avoidRatio;
    /// 使用可能シップ
    ShipRestriction[] restriction;
    /// 素材
    Material material;
    /// 消耗タイプ
    ExhaustionType type;
    /// 消耗度
    int exhaustion;
    /// 追加効果
    real[string] effects;
    /// 付加効果
    string additionalEffect;
    /// 効果アップ
    RedBlackTree!string specials;
    /// 魔法チャージ可能かどうか
    bool canMagicCharged;
    /// 属性チャージ可能かどうか
    bool canElementCharged;

    /// デバッグ用。このアイテム情報が収録されているファイル名
    string file;
}

auto readShields(string fname)
{
    import std.algorithm: map;
    import std.conv: to;
    import std.exception: enforce;
    import std.file: readText;
    import std.json: JSON_TYPE, parseJSON;
    import std.typecons: tuple;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto shields = res.object;
    return shields.keys.map!(key =>
                             tuple(key.to!string,
                                   shields[key].object.toShieldInfo(fname)));
}

auto toShieldInfo(JSONValue[string] json, string fname)
{
    ShieldInfo info;
    with(info)
    {
        import std.conv: to;
        import coop.util: jto;

        AC = json["アーマークラス"].jto!(real[Grade]);
        skills = json["必要スキル"].jto!(real[string]);
        avoidRatio = json["回避"].jto!int;
        material = json["素材"].jto!Material;
        if (auto t = "消耗タイプ" in json)
        {
            type = (*t).jto!ExhaustionType;
        }
        exhaustion = json["耐久"].jto!int;
        if (auto f = "追加効果" in json)
        {
            effects = (*f).jto!(real[string]);
        }
        if (auto af = "付加効果" in json)
        {
            additionalEffect = (*af).jto!string;
        }

        specials = new RedBlackTree!string;
        if (auto sp = "効果アップ" in json)
        {
            specials.insert((*sp).jto!(string[]));
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
    FingerOrnament => "指(装)", BreastOrnament => "胸(装)", BackOrnament => "背中(装)",
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
    real[string] skill;
    string effect;
}

auto readExpendables(string fname)
{
    import std.algorithm: map;
    import std.conv: to;
    import std.exception: enforce;
    import std.file: readText;
    import std.json: JSON_TYPE, parseJSON;
    import std.typecons: tuple;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto expendables = res.object;
    return expendables.keys.map!(key =>
                             tuple(key.to!string,
                                   expendables[key].object.toExpendableInfo));
}

auto toExpendableInfo(JSONValue[string] json) pure
{
    ExpendableInfo info;
    with(info)
    {
        import coop.util: jto;

        effect = json["効果"].jto!string;
        if (auto f = "必要スキル" in json)
        {
            skill = (*f).jto!(real[string]);
        }
    }
    return info;
}

struct Overlaid(T)
{
    import std.traits: hasMember;

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
    static auto isValidValue(T)(const T val) pure nothrow
    {
        import std.range: empty;
        import std.math: isNaN;
        import std.traits: isFloatingPoint, isSomeString, isIntegral;

        static if (isFloatingPoint!T)
            return !val.isNaN;
        else static if (isSomeString!T)
            return !val.empty;
        else static if (isIntegral!T)
            return val > 0;
        else static if (is(T == bool))
            return val;
        else static if (is(T == const(real)[PetFoodType]))
            return val.keys[0] != PetFoodType.UNKNOWN;
        else
            return val != T.init;
    }

    T original;
    T* overlaid;
}

nothrow unittest
{
    import std.traits: FieldNameTuple;

    Item orig;
    with(orig)
    {
        import std.conv: to;

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

nothrow unittest
{
    import std.conv;

    Item orig;
    orig.name = "テスト";
    orig.petFoodInfo[PetFoodType.UNKNOWN.to!PetFoodType] = 0;

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

    assert(overlaid.isOverlaid!"petFoodInfo");
    assert(overlaid.petFoodInfo == typeof(overlaid.petFoodInfo).init);
}

auto readItemList(string sysBase)
{
    import std.algorithm;
    import std.array;
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto dir = buildPath(sysBase, "アイテム");
    if (!dir.exists)
    {
        return (Item[string]).init;
    }
    return dirEntries(dir, "*.json", SpanMode.breadth)
        .map!readItems
        .array
        .joiner
        .checkedAssocArray;
}

auto readFoodList(string sysBase)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto dir = buildPath(sysBase, "食べ物");
    if (!dir.exists)
    {
        return (FoodInfo[string]).init;
    }
    return dirEntries(dir, "*.json", SpanMode.breadth)
        .map!readFoods
        .joiner
        .checkedAssocArray;
}

auto readDrinkList(string sysBase)
{
    import std.exception;
    import std.file;
    import std.path;

    import coop.util;
    import coop.core.item;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto file = buildPath(sysBase, "飲み物", "飲み物.json");
    if (!file.exists)
    {
        return (FoodInfo[string]).init;
    }
    return file.readFoods.checkedAssocArray;
}

auto readLiquorList(string sysBase)
{
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto file = buildPath(sysBase, "飲み物", "酒.json");
    if (!file.exists)
    {
        return (FoodInfo[string]).init;
    }
    return buildPath(sysBase, "飲み物", "酒.json").readFoods.checkedAssocArray;
}

auto readWeaponList(string sysBase)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto dir = buildPath(sysBase, "武器");
    if (!dir.exists)
    {
        return (WeaponInfo[string]).init;
    }
    return dirEntries(dir, "*.json", SpanMode.breadth)
        .map!readWeapons
        .joiner
        .checkedAssocArray;
}

auto readArmorList(string sysBase)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto dir = buildPath(sysBase, "防具");
    if (!dir.exists)
    {
        return (ArmorInfo[string]).init;
    }
    return dirEntries(dir, "*.json", SpanMode.breadth)
        .map!readArmors
        .joiner
        .checkedAssocArray;
}

auto readBulletList(string sysBase)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto dir = buildPath(sysBase, "弾");
    if (!dir.exists)
    {
        return (BulletInfo[string]).init;
    }
    return dirEntries(dir, "*.json", SpanMode.breadth)
        .map!readBullets
        .joiner
        .checkedAssocArray;
}

auto readShieldList(string sysBase)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.path;

    import coop.core.item;
    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);

    auto dir = buildPath(sysBase, "盾");
    if (!dir.exists)
    {
        return (ShieldInfo[string]).init;
    }
    return dirEntries(dir, "*.json", SpanMode.breadth)
        .map!readShields
        .joiner
        .checkedAssocArray;
}

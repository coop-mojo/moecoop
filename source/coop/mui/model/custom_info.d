/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.model.custom_info;

class CustomInfo
{
    /// バージョン情報
    @name("version") string ver = Version;

    /// アイテム一覧
    UserItemInfo[string] items;

    /// アイテムごとの調達価格
    int[string] prices;

    string[] leafMaterials;
    string[string] recipePreference;

    enum defaultPreference = [
        "魚の餌": "魚の餌(ヘビの肉)",
        "砂糖": "砂糖(臼)",
        "塩": "塩(岩塩)",
        "パン粉": "パン粉",
        "パン生地": "パン生地",
        "パイ生地": "パイ生地(ミニ ウォーター ボトル)",
        "ゼラチン": "ゼラチン(オークの骨)",
        "切り身魚のチーズ焼き": "切り身魚のチーズ焼き",
        "お雑煮": "お雑煮",
        "味噌汁": "味噌汁",
        "ざるそば": "ざるそば",
        "ベーコン": "ベーコン",
        "ショート ケーキ": "ショート ケーキ",
        "揚げ玉": "かき揚げ",
        "焼き鳥": "焼き鳥",
        "かけそば": "かけそば",
        "そば湯": "ざるそば",
        "モチ": "モチ(ミニ ウォーター ボトル)",
        "パルプ": "パルプ(木の板材)",
        "小さな紙": "小さな紙(調合)",
        "髪染め液": "髪染め液",
        "染色液": "染色液",
        "染色液(大)": "染色液(大)",
        "クロノスの涙": "クロノスの涙",
        "クロノスの光": "クロノスの光",
        "骨": "骨(タイガー ボーン)",
        "ボーン チップ": "ボーン チップ(タイガー ボーン)",
        "鉄の棒": "鉄の棒(アイアンインゴット)",
        "カッパーインゴット": "カッパーインゴット(鉱石)",
        "ブロンズインゴット": "ブロンズインゴット(鉱石)",
        "アイアンインゴット": "アイアンインゴット(鉱石)",
        "スチールインゴット": "スチールインゴット(鉱石)",
        "ブラスインゴット": "ブラスインゴット(鉱石)",
        "シルバーインゴット": "シルバーインゴット(鉱石)",
        "ゴールドインゴット": "ゴールドインゴット(鉱石)",
        "ミスリルインゴット": "ミスリルインゴット(鉱石)",
        "オリハルコンインゴット": "オリハルコンインゴット(鉱石)",
        ];


    this() @safe pure nothrow @nogc {}

    this(string baseDir) // 1.1.9 以下
    {
        import std.array;
        import std.algorithm;
        import std.typecons;

        import coop.core.item: readItemList;

        auto alist = readItemList(baseDir);
        items = alist.byKeyValue.map!(kv => tuple(kv.key, UserItemInfo(kv.value))).assocArray;
        prices = readProcPriceList(baseDir);

        recipePreference = defaultPreference;
    }
private:
    import vibe.data.json;

    import coop.util;
}

auto readProcPriceList(string sysBase)
{
    import std.exception;
    import std.file;
    import std.path;

    import vibe.data.json;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);
    auto file = buildPath(sysBase, "調達価格.json");
    if (!file.exists)
    {
        return (int[string]).init;
    }
    return file.readText
               .parseJsonString
               .deserialize!(JsonSerializer, int[string]);
}

struct UserItemInfo
{
    import coop.core.item: Item, PetFoodType;
    import coop.server.model;

    this(Item item)
    {
        import std.algorithm;
        import std.conv;
        import std.range;

        アイテム名 = item.name;
        英名 = item.ename;
        重さ = item.weight;
        NPC売却価格 = item.price;
        info = item.info;
        特殊条件 = item.properties.map!(p => SpecialPropertyInfo(p.to!string, cast(string)p)).array;
        転送可 = item.transferable;
        スタック可 = item.stackable;
        ペットアイテム = item.petFoodInfo.byKeyValue.map!(kv => PetFoodInfo(cast(string)kv.key, kv.value)).front;
        備考 = item.remarks;
        アイテム種別 = cast(string)item.type;
    }

    string アイテム名;
    string 英名;
    double 重さ;
    uint NPC売却価格;
    string info;
    SpecialPropertyInfo[] 特殊条件;
    bool 転送可;
    bool スタック可;
    PetFoodInfo ペットアイテム;
    string 備考;
    string アイテム種別;
}

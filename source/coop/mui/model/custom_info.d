/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.model.custom_info;

class CustomInfo
{
    /// バージョン情報
    @name("version") string ver;

    /// アイテム一覧
    UserItemInfo[string] items;

    /// アイテムごとの調達価格
    int[string] prices;

    this()
    {
        ver = Version;
    }

    this(string baseDir) // 1.1.9 以下
    {
        import std.array;
        import std.algorithm;
        import std.typecons;

        import coop.core.item: readItemList;

        auto alist = readItemList(baseDir);
        items = alist.byKeyValue.map!(kv => tuple(kv.key, UserItemInfo(kv.value))).assocArray;
        prices = readProcPriceList(baseDir);

        ver = Version;
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
        ペットアイテム = item.petFoodInfo.byKeyValue.map!(kv => PetFoodInfo(kv.key.to!PetFoodType.to!string, kv.value)).front;
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

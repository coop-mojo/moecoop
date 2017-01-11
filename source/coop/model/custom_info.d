/**
 * Copyright: Copyright (c) 2016-2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.model.custom_info;

class CustomInfo
{
    import coop.core.item;

    /// アイテム一覧
    Item[dstring] itemList;

    /// アイテム種別ごとの固有情報一覧
    ExtraInfo[dstring][ItemType] extraInfoList;

    /// アイテムごとの調達価格
    int[dstring] procurementPriceList;

    this(string baseDir)
    {
        baseDir_ = baseDir;
        with(ItemType)
        {
            import std.conv;

            extraInfoList[Food.to!ItemType] = readFoodList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Drink.to!ItemType] = readDrinkList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Liquor.to!ItemType] = readLiquorList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Weapon.to!ItemType] = readWeaponList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Armor.to!ItemType] = readArmorList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Bullet.to!ItemType] = readBulletList(baseDir_).to!(ExtraInfo[dstring]);
            extraInfoList[Shield.to!ItemType] = readShieldList(baseDir_).to!(ExtraInfo[dstring]);
        }
        itemList = readItemList(baseDir_);
        procurementPriceList = readProcPriceList(baseDir_);
    }

    auto save()
    {
        import std.algorithm;
        import std.conv;
        import std.file;
        import std.json;
        import std.path;
        import std.range;
        import std.stdio;
        import std.typecons;

        auto itemDir = buildPath(baseDir_, "アイテム");
        mkdirRecurse(itemDir);
        auto items = File(buildPath(itemDir, "アイテム.json"), "w");
        items.writeln(JSONValue(itemList.values
                              .map!(item => tuple(item.name.to!string, item.toJSON))
                              .assocArray).toPrettyString);

        auto prices = File(buildPath(baseDir_, "調達価格.json"), "w");
        prices.writeln(JSONValue(procurementPriceList.to!(int[string])).toPrettyString);
    }
private:
    string baseDir_;
}

auto readProcPriceList(string sysBase)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.json;
    import std.path;

    import coop.util;

    enforce(sysBase.exists);
    enforce(sysBase.isDir);
    auto file = buildPath(sysBase, "調達価格.json");
    if (!file.exists)
    {
        return (int[dstring]).init;
    }
    return file.readText.parseJSON.jto!(int[dstring]);
}

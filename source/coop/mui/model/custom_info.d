/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.model.custom_info;

class CustomInfo
{
    import coop.core.item;

    /// アイテム一覧
    Item[string] itemList;

    /// アイテム種別ごとの固有情報一覧
    ExtraInfo[string][ItemType] extraInfoList;

    /// アイテムごとの調達価格
    int[string] procurementPriceList;

    this(string baseDir)
    {
        baseDir_ = baseDir;
        with(ItemType)
        {
            import std.conv;

            extraInfoList[Food.to!ItemType] = readFoodList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Drink.to!ItemType] = readDrinkList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Liquor.to!ItemType] = readLiquorList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Weapon.to!ItemType] = readWeaponList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Armor.to!ItemType] = readArmorList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Bullet.to!ItemType] = readBulletList(baseDir_).to!(ExtraInfo[string]);
            extraInfoList[Shield.to!ItemType] = readShieldList(baseDir_).to!(ExtraInfo[string]);
        }
        itemList = readItemList(baseDir_);
        procurementPriceList = readProcPriceList(baseDir_);
    }

    auto save()
    {
        import std.file;
        import std.path;
        import std.stdio;
        import vibe.data.json;

        auto itemDir = buildPath(baseDir_, "アイテム");
        mkdirRecurse(itemDir);
        auto items = File(buildPath(itemDir, "アイテム.json"), "w");
        items.writeln(itemList.values.serializeToPrettyJson);

        auto prices = File(buildPath(baseDir_, "調達価格.json"), "w");
        prices.writeln(procurementPriceList.serializeToPrettyJson);
    }
private:
    string baseDir_;
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

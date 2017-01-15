/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.vendor;

struct ProductInfo
{
    import vibe.data.json;
    @name("価格") int price;
    @name("備考") @optional string remarks;
}

struct Vendor
{
    import vibe.data.json: name_ = name;
    @name_("名前") string name;
    @name_("販売情報") ProductInfo[string] products;
}

/**
 * ファイル fname に含まれる販売員の情報を返す
 */
auto readVendors(string fname)
{
    import vibe.data.json;

    import std.algorithm;
    import std.file;
    import std.typecons;

    return fname.readText
                .parseJsonString
                .deserialize!(JsonSerializer, Vendor[])
                .map!"tuple(a.name, a)";
}

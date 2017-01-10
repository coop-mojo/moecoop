/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.vendor;

import std.json;
import std.typecons;

alias ProductInfo = Tuple!(int, "price", dstring, "remarks");

struct Vendor{
    dstring name;
    ProductInfo[dstring] products;
}

auto readVendors(string fname)
{
    import std.algorithm;
    import std.conv;
    import std.exception;
    import std.file;
    import std.json;

    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto vendors = res.object;
    return vendors.keys.map!(key =>
                             tuple(key.to!dstring,
                                   key.toVendor(vendors[key].object, fname)));
}

/**
 * 販売員 s の情報を、ファイル fname に書かれている json から読み込む
 */
auto toVendor(string s, JSONValue[string] json, string fname)
{
    Vendor v;
    with(v)
    {
        import std.algorithm;
        import std.conv;
        import std.range;

        import coop.util;

        name = s.to!dstring;
        products = json.keys
                       .map!(key =>
                             tuple(key.to!dstring,
                                   ProductInfo(json[key]["価格"].jto!int,
                                               json[key].object.get("備考", JSONValue("")).jto!dstring)))
                       .assocArray;
    }
    return v;
}

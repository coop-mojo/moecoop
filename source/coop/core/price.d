/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.price;

import std.container;

import coop.core.item;
import coop.core.recipe;

/**
   参考価格 =
(or 調達価格
    (min NPC販売価格
         (max NPC売却価格
              クエスト価格
              参考計算価格)))
調達価格: ユーザーが指定した価格
NPC販売価格: そのまま
NPC売却価格: そのまま
クエスト価格: クエストなどで、交換するアイテムなどから計算できる計算
参考計算価格: レシピおよび素材の参考価格化を計算できる価格
 */
auto procurementCostFor(dstring item,
                        Item[dstring] itemMap, Recipe[dstring] recipeMap,
                        RedBlackTree!dstring[dstring] rrecipeMap,
                        int[dstring] vendingPriceMap, int[dstring] questPriceMap,
                        int[dstring] procurementMap,
                        RedBlackTree!dstring visited = new RedBlackTree!dstring)
{
    import std.algorithm;
    import coop.fallback;

    if (auto pr = item in procurementMap)
    {
        return *pr;
    }

    auto vendPrice = vendingPriceMap.get(item, int.max);
    auto sellingPrice = itemMap.get(item, Item.init).price;
    auto questPrice = questPriceMap.get(item, 0);

    int procRecipeCost;
    if (auto rs = item in rrecipeMap)
    {
        import std.conv;
        import std.functional;
        import std.math;

        visited.insert(item);

        procRecipeCost = (*rs)[].map!(r => recipeMap[r])
                                .filter!(r => r.ingredients.keys.all!(i => i !in visited))
                                .map!(r => r.ingredients
                                            .byKeyValue
                                            .fold!((a, b) =>
                                                   a + procurementCostFor(b.key, itemMap, recipeMap, rrecipeMap,
                                                                          vendingPriceMap, questPriceMap,
                                                                          procurementMap, visited.dup)*b.value)(0)
                                      / r.products[item].to!real)
                                .fold!min(real.max)
                                .ceil
                                .to!int;
    }
    else
    {
        procRecipeCost = 0;
    }
    return min(vendPrice, max(sellingPrice, questPrice, procRecipeCost));
}

// 単純な場合
unittest
{
    Item roastSnakeMeat = { name: "ロースト スネーク ミート"d, price: 8 };
    Item snakeMeat = { name: "ヘビの肉"d, price: 5 };
    Recipe r = {
        name: "ロースト スネーク ミート",
        ingredients: ["ヘビの肉": 1],
        products: ["ロースト スネーク ミート": 1]
    };

    // 単純なケース
    assert(procurementCostFor("ロースト スネーク ミート"d,
                              ["ロースト スネーク ミート"d: roastSnakeMeat,
                               "ヘビの肉": snakeMeat],
                              ["ロースト スネーク ミート"d: r],
                              ["ロースト スネーク ミート"d: make!(RedBlackTree!dstring)("ロースト スネーク ミート"d)],
                              (int[dstring]).init, (int[dstring]).init,
                              (int[dstring]).init) == 8);

    // 材料の価格がユーザー定義されているケース
    assert(procurementCostFor("ロースト スネーク ミート"d,
                              ["ロースト スネーク ミート"d: roastSnakeMeat,
                               "ヘビの肉": snakeMeat],
                              ["ロースト スネーク ミート"d: r],
                              ["ロースト スネーク ミート"d: make!(RedBlackTree!dstring)("ロースト スネーク ミート"d)],
                              (int[dstring]).init, (int[dstring]).init,
                              ["ヘビの肉"d: 10]) == 10);

    // 生成物の価格がユーザー定義されているケース
    assert(procurementCostFor("ロースト スネーク ミート"d,
                              ["ロースト スネーク ミート"d: roastSnakeMeat,
                               "ヘビの肉": snakeMeat],
                              ["ロースト スネーク ミート"d: r],
                              ["ロースト スネーク ミート"d: make!(RedBlackTree!dstring)("ロースト スネーク ミート"d)],
                              (int[dstring]).init, (int[dstring]).init,
                              ["ロースト スネーク ミート"d: 5]) == 5);
}

// 必要素材がループする場合
unittest
{
    Item ironBar = { name: "鉄の棒"d, price: 12 };
    Item ironIngot = { name: "アイアンインゴット"d, price: 10 };
    Item scrapIron = { name: "鉄屑"d, price: 25 };
    Item ironOre = { name: "鉄鉱石"d, price: 13 };
    Item ironOreFragment = { name: "鉄鉱石の破片"d, price: 4 };

    Recipe barFromIng = {
        name: "鉄の棒(アイアンインゴット)"d,
        ingredients: ["アイアンインゴット": 1],
        products: ["鉄の棒": 3]
    };
    Recipe barFromScrap = {
        name: "鉄の棒(鉄屑)"d,
        ingredients: ["鉄屑": 2],
        products: ["鉄の棒": 1]
    };
    Recipe ingFromOre = {
        name: "アイアンインゴット(鉱石)"d,
        ingredients: ["鉄鉱石": 1],
        products: ["アイアンインゴット": 1]
    };
    Recipe ingFromOreFrag = {
        name: "アイアンインゴット(破片)"d,
        ingredients: ["鉄鉱石の破片": 3],
        products: ["アイアンインゴット": 1]
    };
    Recipe ingFromBar = {
        name: "アイアンインゴット(鉄の棒)"d,
        ingredients: ["鉄の棒": 5],
        products: ["アイアンインゴット": 1]
    };

    assert(procurementCostFor("鉄の棒"d,
                              ["鉄の棒"d: ironBar,
                               "アイアンインゴット": ironIngot,
                               "鉄屑": scrapIron,
                               "鉄鉱石": ironOre,
                               "鉄鉱石の破片": ironOreFragment],
                              ["鉄の棒(アイアンインゴット)"d: barFromIng,
                               "鉄の棒(鉄屑)": barFromScrap,
                               "アイアンインゴット(鉱石)": ingFromOre,
                               "アイアンインゴット(破片)": ingFromOreFrag,
                               "アイアンインゴット(鉄の棒)": ingFromBar],
                              ["鉄の棒"d: make!(RedBlackTree!dstring)("鉄の棒(アイアンインゴット)"d,
                                                                      "鉄の棒(鉄屑)"d),
                               "アイアンインゴット": make!(RedBlackTree!dstring)("アイアンインゴット(鉱石)"d,
                                                                                 "アイアンインゴット(破片)"d,
                                                                                 "アイアンインゴット(鉄の棒)"d)],
                              (int[dstring]).init, (int[dstring]).init,
                              (int[dstring]).init) == 12);
}

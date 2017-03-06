/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.view.item_detail_frame;

import dlangui;

import std.traits;

import coop.mui.model.custom_info;
import coop.mui.model.wisdom_adapter;

class ItemDetailFrame: ScrollWidget
{
    this() { super(); }

    this(string id)
    {
        super(id);
        auto layout = parseML(q{
                VerticalLayout {
                    padding: 5
                    TableLayout {
                        id: table
                        colCount: 2
                    }
                }
            });
        contentWidget = layout;
        backgroundColor = "white";
    }

    static auto create(dstring name, int idx, WisdomAdapter model, CustomInfo customInfo)
    {
        import std.conv;
        import std.exception;

        import vibe.http.common;

        import coop.util;
        import coop.mui.model.wisdom_adapter;
        import coop.core.item: overlaid;

        auto orig = model.postItem(name.to!string, customInfo.prices).ifThrown!HTTPStatusException(ItemInfo.init);
        auto ret = new typeof(this)("detail"~idx.to!string);
        auto item = overlaid(orig, name.to!string in customInfo.items);
        ret.item_ = orig;

        auto table = ret.childById("table");
        with(table)
        {
            import std.format;
            import std.math;
            import std.range;

            table.addElem("名前", name);

            table.addElem("英名", item.英名.empty ? "わからん（´・ω・｀）" : item.英名, item.isOverlaid!"英名");
            table.addElem("重さ", item.重さ.isNaN ? "そこそこの重さ" : format("%.2f", item.重さ), item.isOverlaid!"重さ");

            string extraRemarks = table.addExtraElem(item);

            table.addElem("NPC売却価格", format("%s g", item.NPC売却価格), item.isOverlaid!"NPC売却価格");

            import coop.core.price;
            table.addChild(new TextWidget("", "参考価格: "d));
            auto lo = new HorizontalLayout;
            auto refPriceWidget = new TextWidget("", format("%s g"d, item.参考価格));
            lo.addChild(refPriceWidget);
            lo.addChild(new TextWidget("", "(調達価格: "d));
            import coop.mui.view.editors;
            auto procurementPriceWidget = new EditIntLine("", name.to!string in customInfo.prices ?
                                                                                    customInfo.prices[name.to!string].to!dstring : "");
            procurementPriceWidget.maxWidth = 100;
            procurementPriceWidget.contentChange = (EditableContent content) {
                int modifiedPrice;
                if (content.text.empty)
                {
                    customInfo.prices.remove(item.アイテム名);
                    modifiedPrice = item.アイテム名.empty ? 0 : model.postItem(name.to!string, customInfo.prices).参考価格;
                }
                else
                {
                    customInfo.prices[item.アイテム名] = modifiedPrice = content.text.to!int;
                }
                refPriceWidget.text = format("%s g"d, modifiedPrice);
            };
            lo.addChild(procurementPriceWidget);
            lo.addChild(new TextWidget("", " g)"d));
            table.addChild(lo);

            table.addElem("転送可", item.転送可 ? "はい" : "いいえ", item.isOverlaid!"転送可");
            table.addElem("スタック可", item.スタック可 ? "はい": "いいえ", item.isOverlaid!"スタック可");

            if (!item.特殊条件.empty)
            {
                import std.algorithm;
                import std.conv;
                table.addElem("特殊条件", item.特殊条件.map!"a.詳細".join(", ").to!dstring, item.isOverlaid!"特殊条件");
            }

            import coop.core.item: PetFoodType;
            if (item.ペットアイテム.種別 != cast(string)PetFoodType.NoEatable)
            {
                import std.algorithm;

                if (item.ペットアイテム.種別 == cast(string)PetFoodType.UNKNOWN)
                {
                    table.addElem("ペットアイテム", "不明", item.isOverlaid!"ペットアイテム");
                }
                else
                {
                    table.addElem("ペットアイテム",
                                  format("%s (%.1f)",
                                         item.ペットアイテム.種別,
                                         item.ペットアイテム.効果),
                                  item.isOverlaid!"ペットアイテム");
                }
            }

            if (!item.info.empty)
            {
                table.addElem("info", item.info, item.isOverlaid!"info");
            }

            auto rem = orig.アイテム名 ? item.備考 : "細かいことはわかりません（´・ω・｀）";
            if (!rem.empty || !extraRemarks.empty)
            {
                import std.algorithm;

                table.addElem("備考", [rem, extraRemarks].filter!"!a.empty".join(", "));
            }
        }

        return ret;
    }

    @property auto item()
    {
        return item_;
    }
private:
    import coop.mui.model.wisdom_adapter: ItemInfo;
    ItemInfo item_;
}


auto addElem(dstring delim = ": ", Str1, Str2)(Widget layout, Str1 caption, Str2 elem, bool overlaid = false)
    if (isSomeString!Str1 && isSomeString!Str2)
{
    layout.addChild(new TextWidget("", (caption~delim).to!dstring));
    auto text = new TextWidget("", elem.to!dstring);
    layout.addChild(text);
    if (overlaid)
    {
        text.textColor = "red";
    }
}

auto addExtraElem(Item)(Widget layout, Item item)
{
    import std.range;
    import coop.core.item: ItemType;

    if (item.アイテム種別.empty)
    {
        return "";
    }

    final switch(item.アイテム種別) with(ItemType)
    {
    case Food, Drink, Liquor:{
        import std.format;

        auto info = item.飲食物情報;
        layout.addElem("効果", format("%.1f", info.効果));

        if (!info.付加効果.isNull) with(info.付加効果)
        {
            import std.range;

            layout.addElem("付加効果", バフ名);
            if (!バフグループ.empty)
            {
                import std.algorithm;
                import std.array;

                auto effectStr = 効果
                                 .byKeyValue
                                 .map!(kv => format("%s: %s%s",
                                                    kv.key,
                                                    kv.value > 0 ? "+" : "",
                                                    kv.value))
                                 .join(", ");
                if (その他効果)
                {
                    if (effectStr)
                        effectStr ~= ", ";
                    effectStr ~= その他効果;
                }
                import coop.core.item: AdditionalEffectGroup;
                layout.addElem!""("", effectStr);
                layout.addElem("バフグループ",
                               バフグループ == AdditionalEffectGroup.Others.to!string ? "その他"
                               : バフグループ.to!string);
                layout.addElem("効果時間", format("%s 秒", 効果時間));

                return 備考;
            }
        }
        break;
    }
    case Expendable:{
        // import std.range;

        // auto info = ex.extra.peek!ExpendableInfo;
        // if (!info.skill.keys.empty)
        // {
        //     import std.algorithm;
        //     import std.format;

        //     layout.addElem("必要スキル",
        //                    info.skill
        //                        .byKeyValue
        //                        .map!(kv => format("%s (%.1f)", kv.key, kv.value))
        //                        .join(", "));
        // }
        // layout.addElem("効果", info.effect);
        // TODO: 具体的な効果を wisdom に問い合わせて表示
        break;
    }
    case Weapon:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = item.武器情報;

        auto damageStr = info.攻撃力
                             .map!(g => format("%s: %.1f", g.状態, g.効果))
                             .join(", ");
        layout.addElem("ダメージ", damageStr);
        layout.addElem("攻撃間隔", info.攻撃間隔.to!string);
        layout.addElem("有効レンジ", format("%.1f", info.有効レンジ));
        layout.addElem(info.消耗タイプ, info.耐久.to!dstring);
        layout.addElem("必要スキル",
                       info.必要スキル
                           .map!(sk => format("%s (%.1f)", sk.スキル名, sk.スキル値))
                           .join(", "));
        layout.addElem("装備スロット", format("%s (%s)", info.装備スロット, info.両手装備 ? "両手" : "片手"));
        layout.addElem("素材", info.素材);
        import coop.core.item: ShipRestriction;
        if (info.装備可能シップ.front.シップ名 != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.装備可能シップ.map!(a => a.シップ名.to!dstring~"系").join(", "));
        }

        if (!info.付加効果.keys.empty)
        {
            layout.addElem("付加効果",
                           info.付加効果
                               .byKeyValue
                               .map!(kv => format("%s: %s%%"d, kv.key, kv.value))
                               .join(", "));
        }

        if (!info.追加効果.keys.empty)
        {
            layout.addElem("追加効果",
                           info.追加効果
                               .byKeyValue
                               .map!(kv => format("%s: %s%.1f"d,
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "",
                                                  kv.value))
                               .join(", "));
        }

        if (!info.効果アップ.empty)
        {
            layout.addElem("効果アップ", info.効果アップ.join(", "));
        }

        if (info.魔法チャージ)
        {
            layout.addElem("魔法チャージ", "可能");
        }
        if (info.属性チャージ)
        {
            layout.addElem("属性チャージ", "可能");
        }
        break;
    }
    case Armor:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = item.防具情報;

        auto ACStr = info.アーマークラス
                         .map!(g => format("%s: %.1f"d, g.状態, g.効果))
                         .join(", ");
        layout.addElem("アーマークラス", ACStr);
        layout.addElem(info.消耗タイプ, info.耐久.to!string);
        layout.addElem("必要スキル",
                       info.必要スキル
                           .map!(sk => format("%s (%.1f)", sk.スキル名, sk.スキル値))
                           .join(", "));
        layout.addElem("装備スロット", info.装備スロット);
        layout.addElem("素材", info.素材);
        import coop.core.item: ShipRestriction;
        if (info.装備可能シップ.front.シップ名 != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.装備可能シップ.map!(a => a.シップ名.to!string~"系").join(", "));
        }

        if (!info.付加効果.empty)
        {
            layout.addElem("付加効果", info.付加効果);
        }

        if (!info.追加効果.keys.empty)
        {
            layout.addElem("追加効果",
                           info.追加効果
                               .byKeyValue
                               .map!(kv => format("%s: %s%.1f",
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "",
                                                  kv.value))
                               .join(", "));
        }

        if (!info.効果アップ.empty)
        {
            layout.addElem("効果アップ", info.効果アップ.join(", "));
        }

        if (info.魔法チャージ)
        {
            layout.addElem("魔法チャージ", "可能");
        }
        if (info.魔法チャージ)
        {
            layout.addElem("属性チャージ", "可能");
        }
        break;
    }
    case Bullet:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = item.弾情報;

        layout.addElem("ダメージ", format("%.1f", info.ダメージ));
        layout.addElem("有効レンジ", format("%.1f", info.有効レンジ));
        layout.addElem("角度補正角", info.角度補正角.to!string);
        layout.addElem("必要スキル",
                       info.必要スキル
                           .map!(sk => format("%s (%.1f)", sk.スキル名, sk.スキル値))
                           .join(", "));
        layout.addElem("装備スロット", "矢/弾");
        import coop.core.item: ShipRestriction;
        if (info.使用可能シップ.front.シップ名 != ShipRestriction.Any)
        {
            layout.addElem("使用可能シップ", info.使用可能シップ.map!(a => a.シップ名.to!string~"系").join(", "));
        }
        if (!info.追加効果.keys.empty)
        {
            layout.addElem("追加効果",
                           info.追加効果
                               .byKeyValue
                               .map!(kv => format("%s: %s%s",
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "-",
                                                  kv.value))
                               .join(", "));
        }
        if (!info.付与効果.empty)
        {
            layout.addElem("付与効果", info.付与効果);
        }
        break;
    }
    case Shield:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = item.盾情報;

        auto ACStr = info.アーマークラス
                         .map!(g => format("%s: %.1f", g.状態, g.効果))
                         .join(", ");
        layout.addElem("アーマークラス", ACStr);
        layout.addElem(info.消耗タイプ, info.耐久.to!string);
        layout.addElem("必要スキル",
                       info.必要スキル
                           .map!(sk => format("%s (%.1f)", sk.スキル名, sk.スキル値))
                           .join(", "));
        layout.addElem("回避", format("%s%%", info.回避));
        layout.addElem("素材", info.素材);
        import coop.core.item: ShipRestriction;
        if (info.使用可能シップ.front.シップ名 != ShipRestriction.Any)
        {
            layout.addElem("使用可能シップ", info.使用可能シップ.map!(a => a.シップ名.to!string~"系").join(", "));
        }

        if (!info.付加効果.empty)
        {
            layout.addElem("付加効果", info.付加効果);
        }

        if (!info.追加効果.keys.empty)
        {
            layout.addElem("追加効果",
                           info.追加効果
                               .byKeyValue
                               .map!(kv => format("%s: %s%.1f",
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "",
                                                  kv.value))
                               .join(", "));
        }

        if (!info.効果アップ.empty)
        {
            layout.addElem("効果アップ", info.効果アップ.join(", "));
        }

        if (info.魔法チャージ)
        {
            layout.addElem("魔法チャージ", "可能");
        }
        if (info.属性チャージ)
        {
            layout.addElem("属性チャージ", "可能");
        }
        break;
    }
    case Asset:{
        break;
    }
    case Others:{
        break;
    }
    case UNKNOWN:
        break;
    }
    return "";
}

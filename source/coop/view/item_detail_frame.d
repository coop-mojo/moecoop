/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.item_detail_frame;

import dlangui;

import std.traits;

import coop.core.item;
import coop.core.wisdom;
import coop.model;
import coop.model.custom_info;

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

    static auto create(dstring name, int idx, WisdomModel model, CustomInfo customInfo)
    {
        import std.conv;

        auto orig = model.getItem(name);
        auto ret = new typeof(this)("detail"~idx.to!string);
        auto item = Overlaid!Item(orig, name.to!string in customInfo.itemList);
        ret.item_ = orig;

        auto table = ret.childById("table");
        with(table)
        {
            import std.format;
            import std.math;
            import std.range;

            table.addElem("名前", name);

            table.addElem("英名", item.ename.empty ? "わからん（´・ω・｀）" : item.ename, item.isOverlaid!"ename");
            table.addElem("重さ", item.weight.isNaN ? "そこそこの重さ" : format("%.2f", item.weight), item.isOverlaid!"weight");

            string extraRemarks = table.addExtraElem(name, model);

            table.addElem("NPC売却価格", format("%s g", item.price), item.isOverlaid!"price");

            import coop.core.price;
            table.addChild(new TextWidget("", "参考価格: "d));
            auto lo = new HorizontalLayout;
            auto refPriceWidget = new TextWidget("", format("%s g"d, model.costFor(item.name, customInfo.procurementPriceList)));
            lo.addChild(refPriceWidget);
            lo.addChild(new TextWidget("", "(調達価格: "d));
            import coop.view.editors;
            auto procurementPriceWidget = new EditIntLine("", name.to!string in customInfo.procurementPriceList ?
                                                                                    customInfo.procurementPriceList[name.to!string].to!dstring : "");
            procurementPriceWidget.maxWidth = 100;
            procurementPriceWidget.contentChange = (EditableContent content) {
                if (content.text.empty)
                {
                    customInfo.procurementPriceList.remove(item.name);
                }
                else
                {
                    customInfo.procurementPriceList[item.name] = content.text.to!int;
                }
                refPriceWidget.text = format("%s g"d, model.costFor(item.name, customInfo.procurementPriceList));
            };
            lo.addChild(procurementPriceWidget);
            lo.addChild(new TextWidget("", " g)"d));
            table.addChild(lo);

            table.addElem("転送可", item.transferable ? "はい" : "いいえ", item.isOverlaid!"transferable");
            table.addElem("スタック可", item.stackable ? "はい": "いいえ", item.isOverlaid!"stackable");

            if (!item.properties.empty)
            {
                import std.algorithm;
                import std.conv;
                table.addElem("特殊条件", (cast(string[])item.properties).join(", ").to!dstring, item.isOverlaid!"properties");
            }

            if (item.petFoodInfo.keys[0] != PetFoodType.NoEatable)
            {
                import std.algorithm;

                table.addElem("ペットアイテム",
                              item.petFoodInfo
                                  .byKeyValue
                                  .map!(kv => format("%s (%.1f)",
                                                     kv.key,
                                                     kv.value)).join,
                              item.isOverlaid!"petFoodInfo");
            }

            if (!item.info.empty)
            {
                table.addElem("info", item.info, item.isOverlaid!"info");
            }

            auto rem = orig ? item.remarks : "細かいことはわかりません（´・ω・｀）";
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
    Item item_;
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

auto addExtraElem(Str)(Widget layout, Str name, WisdomModel model)
    if (isSomeString!Str)
{
    auto ex = model.getExtraInfo(name.to!string);
    if (ex.type == ItemType.UNKNOWN || ex.extra == ExtraInfo.init)
    {
        return "";
    }

    final switch(ex.type) with(ItemType)
    {
    case Food, Drink, Liquor:{
        import std.format;

        auto info = ex.extra.peek!FoodInfo;
        layout.addElem("効果", format("%.1f", info.effect));

        if (auto effectName = info.additionalEffect)
        {
            layout.addElem("付加効果", effectName);
            if (auto einfo = model.getFoodEffect(effectName))
            {
                import std.algorithm;
                import std.array;

                auto effectStr = einfo
                                 .effects
                                 .byKeyValue
                                 .map!(kv => format("%s: %s%s",
                                                    kv.key,
                                                    kv.value > 0 ? "+" : "",
                                                    kv.value))
                                 .join(", ");
                if (einfo.otherEffects)
                {
                    if (effectStr)
                        effectStr ~= ", ";
                    effectStr ~= einfo.otherEffects;
                }
                layout.addElem!""("", effectStr);
                layout.addElem("バフグループ",
                               einfo.group == AdditionalEffectGroup.Others ? "その他"
                                                                           : einfo.group.to!string);
                layout.addElem("効果時間", format("%s 秒", einfo.duration));

                return einfo.remarks;
            }
        }
        break;
    }
    case Expendable:{
        import std.range;

        auto info = ex.extra.peek!ExpendableInfo;
        if (!info.skill.keys.empty)
        {
            import std.algorithm;
            import std.format;

            layout.addElem("必要スキル",
                           info.skill
                               .byKeyValue
                               .map!(kv => format("%s (%.1f)", kv.key, kv.value))
                               .join(", "));
        }
        layout.addElem("効果", info.effect);
        // TODO: 具体的な効果を wisdom に問い合わせて表示
        break;
    }
    case Weapon:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = ex.extra.peek!WeaponInfo;

        auto damageStr = Grade.values
                              .filter!(g => info.damage.keys.canFind(g))
                              .map!(g => format("%s: %.1f", g.to!Grade, info.damage[g.to!Grade]))
                              .join(", ");
        layout.addElem("ダメージ", damageStr);
        layout.addElem("攻撃間隔", info.duration.to!string);
        layout.addElem("有効レンジ", format("%.1f", info.range));
        layout.addElem(cast(string)info.type, info.exhaustion.to!dstring);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)", kv.key, kv.value))
                           .join(", "));
        layout.addElem("装備スロット", format("%s (%s)", cast(string)info.slot, info.isDoubleHands ? "両手" : "片手"));
        layout.addElem("素材", cast(string)info.material);
        if (info.restriction.front != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.map!(a => a.to!dstring~"系").join(", "));
        }

        if (!info.additionalEffect.keys.empty)
        {
            layout.addElem("付与効果",
                           info.additionalEffect
                               .byKeyValue
                               .map!(kv => format("%s: %s%%"d, kv.key, kv.value))
                               .join(", "));
        }

        if (!info.effects.keys.empty)
        {
            layout.addElem("追加効果",
                           info.effects
                               .byKeyValue
                               .map!(kv => format("%s: %s%.1f"d,
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "",
                                                  kv.value))
                               .join(", "));
        }

        if (!info.specials.empty)
        {
            layout.addElem("効果アップ", info.specials[].join(", "));
        }

        if (info.canMagicCharged)
        {
            layout.addElem("魔法チャージ", "可能");
        }
        if (info.canElementCharged)
        {
            layout.addElem("属性チャージ", "可能");
        }
        break;
    }
    case Armor:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = ex.extra.peek!ArmorInfo;

        auto ACStr = Grade.values
                          .filter!(g => info.AC.keys.canFind(g))
                          .map!(g => format("%s: %.1f"d, g.to!Grade, info.AC[g.to!Grade]))
                          .join(", ");
        layout.addElem("アーマークラス", ACStr);
        layout.addElem(cast(string)info.type, info.exhaustion.to!string);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)", kv.key, kv.value))
                           .join(", "));
        layout.addElem("装備スロット", cast(string)info.slot);
        layout.addElem("素材", cast(string)info.material);
        if (info.restriction.front != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.map!(a => a.to!string~"系").join(", "));
        }

        if (!info.additionalEffect.empty)
        {
            layout.addElem("付加効果", info.additionalEffect);
        }

        if (!info.effects.keys.empty)
        {
            layout.addElem("追加効果",
                           info.effects
                               .byKeyValue
                               .map!(kv => format("%s: %s%.1f",
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "",
                                                  kv.value))
                               .join(", "));
        }

        if (!info.specials.empty)
        {
            layout.addElem("効果アップ", info.specials[].join(", "));
        }

        if (info.canMagicCharged)
        {
            layout.addElem("魔法チャージ", "可能");
        }
        if (info.canElementCharged)
        {
            layout.addElem("属性チャージ", "可能");
        }
        break;
    }
    case Bullet:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = ex.extra.peek!BulletInfo;

        layout.addElem("ダメージ", format("%.1f", info.damage));
        layout.addElem("有効レンジ", format("%.1f", info.range));
        layout.addElem("角度補正角", info.angle.to!string);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)", kv.key, kv.value))
                           .join(", "));
        layout.addElem("装備スロット", "矢/弾");
        if (info.restriction.front != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.map!(a => a.to!string~"系").join(", "));
        }
        if (!info.effects.keys.empty)
        {
            layout.addElem("追加効果",
                           info.effects
                               .byKeyValue
                               .map!(kv => format("%s: %s%s",
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "-",
                                                  kv.value))
                               .join(", "));
        }
        if (!info.additionalEffect.empty)
        {
            layout.addElem("付与効果", info.additionalEffect);
        }
        break;
    }
    case Shield:{
        import std.algorithm;
        import std.array;
        import std.format;

        auto info = ex.extra.peek!ShieldInfo;

        auto ACStr = Grade.values
                          .filter!(g => info.AC.keys.canFind(g))
                          .map!(g => format("%s: %.1f", g.to!Grade, info.AC[g.to!Grade]))
                          .join(", ");
        layout.addElem("アーマークラス", ACStr);
        layout.addElem(cast(string)info.type, info.exhaustion.to!string);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)", kv.key, kv.value))
                           .join(", "));
        layout.addElem("回避", format("%s%%", info.avoidRatio));
        layout.addElem("素材", cast(string)info.material);
        if (info.restriction.front != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.map!(a => a.to!string~"系").join(", "));
        }

        if (!info.additionalEffect.empty)
        {
            layout.addElem("付加効果", info.additionalEffect);
        }

        if (!info.effects.keys.empty)
        {
            layout.addElem("追加効果",
                           info.effects
                               .byKeyValue
                               .map!(kv => format("%s: %s%.1f",
                                                  kv.key,
                                                  kv.value > 0 ? "+" : "",
                                                  kv.value))
                               .join(", "));
        }

        if (!info.specials.empty)
        {
            layout.addElem("効果アップ", info.specials[].join(", "));
        }

        if (info.canMagicCharged)
        {
            layout.addElem("魔法チャージ", "可能");
        }
        if (info.canElementCharged)
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
        assert(false);
    }
    return "";
}

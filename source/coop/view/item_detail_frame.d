/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.item_detail_frame;

import dlangui;

import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.math;

import coop.model.item;
import coop.model.wisdom;

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

    static auto create(Item i, int idx, Wisdom wisdom, Wisdom cWisdom)
    {
        auto ret = new typeof(this)("detail"~idx.to!string);
        auto item = Overlaid!Item(i, i.name in cWisdom.itemList);
        ret.item_ = i;

        auto table = ret.childById("table");
        with(table)
        {
            table.addElem("名前", item.name);

            table.addElem("英名", item.ename.empty ? "わからん（´・ω・｀）" : item.ename, item.isOverlaid!"ename");
            table.addElem("重さ", item.weight.isNaN ? "そこそこの重さ" : format("%.2f"d, item.weight), item.isOverlaid!"weight");

            dstring extraRemarks = table.addExtraElem(i, wisdom);

            table.addElem("NPC売却価格", format("%s g"d, item.price), item.isOverlaid!"price");
            table.addElem("転送可", item.transferable ? "はい" : "いいえ", item.isOverlaid!"transferable");
            table.addElem("スタック可", item.stackable ? "はい": "いいえ", item.isOverlaid!"stackable");

            if (item.properties != 0)
            {
                table.addElem("特殊条件", item.properties.toStrings.join(", ").to!dstring, item.isOverlaid!"properties");
            }

            if (item.petFoodInfo.keys[0] != PetFoodType.NoEatable)
            {
                table.addElem("ペットアイテム",
                              item.petFoodInfo
                                  .byKeyValue
                                  .map!(kv => format("%s (%.1f)"d,
                                                     kv.key,
                                                     kv.value)).join,
                              item.isOverlaid!"petFoodInfo");
            }

            if (!item.info.empty)
            {
                table.addElem("info", item.info, item.isOverlaid!"info");
            }

            auto rem = item.name in wisdom.itemList ? item.remarks : "細かいことはわかりません（´・ω・｀）";
            if (!rem.empty || !extraRemarks.empty)
            {
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


auto addElem(dstring delim = ": ")(Widget layout, dstring caption, dstring elem, bool overlaid = false)
{
    layout.addChild(new TextWidget("", caption~delim));
    auto text = new TextWidget("", elem);
    layout.addChild(text);
    if (overlaid)
    {
        text.textColor = "red";
    }
}

auto addExtraElem(Widget layout, Item item, Wisdom wisdom)
{
    if (item.type !in wisdom.extraInfoList ||
        item.name !in wisdom.extraInfoList[item.type])
    {
        return ""d;
    }
    auto ei = wisdom.extraInfoList[item.type][item.name];

    final switch(item.type) with(ItemType)
    {
    case Food, Drink, Liquor:{
        auto info = ei.peek!FoodInfo;
        layout.addElem("効果", format("%.1f"d, info.effect));

        if (auto effectName = info.additionalEffect)
        {
            layout.addElem("付加効果", effectName);
            if (auto einfo = effectName in wisdom.foodEffectList)
            {
                auto effectStr = einfo
                                 .effects
                                 .byKeyValue
                                 .map!(kv => format("%s: %s%s"d,
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
                                                                           : einfo.group.to!dstring);
                layout.addElem("効果時間", format("%s 秒"d, einfo.duration));

                return einfo.remarks;
            }
        }
        break;
    }
    case Expendable:{
        auto info = ei.peek!ExpendableInfo;
        if (!info.skill.keys.empty)
        {
            layout.addElem("必要スキル",
                           info.skill
                               .byKeyValue
                               .map!(kv => format("%s (%.1f)"d, kv.key, kv.value))
                               .join(", "));
        }
        layout.addElem("効果", info.effect);
        // TODO: 具体的な効果を wisdom に問い合わせて表示
        break;
    }
    case Weapon:{
        auto info = ei.peek!WeaponInfo;

        auto damageStr = Grade.values
                              .filter!(g => info.damage.keys.canFind(g))
                              .map!(g => format("%s: %.1f"d, g.to!Grade, info.damage[g.to!Grade]))
                              .join(", ");
        layout.addElem("ダメージ", damageStr);
        layout.addElem("攻撃間隔", info.duration.to!dstring);
        layout.addElem("有効レンジ", format("%.1f"d, info.range));
        layout.addElem(info.type == ExhaustionType.Points ? "使用可能回数" : "消耗度",
                       info.exhaustion.to!dstring);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)"d, kv.key, kv.value))
                           .join(", "));
        layout.addElem("装備スロット", format("%s (%s)"d, info.slot, info.isDoubleHands ? "両手" : "片手"));
        layout.addElem("素材", info.material.to!dstring);
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
        break;
    }
    case Bullet:{
        auto info = ei.peek!BulletInfo;

        layout.addElem("ダメージ", format("%.1f"d, info.damage));
        layout.addElem("有効レンジ", format("%.1f"d, info.range));
        layout.addElem("角度補正角", info.angle.to!dstring);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)"d, kv.key, kv.value))
                           .join(", "));
        layout.addElem("装備スロット", "矢/弾");
        if (info.restriction.front != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.map!(a => a.to!dstring~"系").join(", "));
        }
        if (!info.effects.keys.empty)
        {
            layout.addElem("追加効果",
                           info.effects
                               .byKeyValue
                               .map!(kv => format("%s: %s%s"d,
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
    case Asset:{
        break;
    }
    case Others:{
        break;
    }
    case UNKNOWN:
        assert(false);
    }
    return ""d;
}

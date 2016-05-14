/**
   MoeCoop
   Copyright (C) 2016  Mojo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

    static auto create(Item i, int idx, Wisdom wisdom)
    {
        auto ret = new typeof(this)("detail"~idx.to!string);
        ret.item_ = i;

        auto table = ret.childById("table");
        with(table)
        {
            table.addElem("名前", i.name);
            table.addElem("英名", i.ename.empty ? "わからん（´・ω・｀）" : i.ename);
            table.addElem("重さ", i.weight.isNaN ? "そこそこの重さ" : format("%.2f"d, i.weight));

            dstring extraRemarks;
            if (i.hasExtraInfo)
            {
                extraRemarks = table.addExtraElem(i, wisdom);
            }

            // extrainfo
            table.addElem("NPC売却価格", format("%s g"d, i.price));
            table.addElem("転送可", i.transferable ? "はい" : "いいえ");
            table.addElem("スタック可", i.stackable ? "はい": "いいえ");

            if (i.properties != 0)
            {
                table.addElem("特殊条件", i.properties.toStrings.join(", ").to!dstring);
            }

            if (i.petFoodInfo.keys[0] != PetFoodType.NoEatable)
            {
                table.addElem("ペットアイテム",
                              i.petFoodInfo
                               .byKeyValue
                               .map!(kv => format("%s (%.1f)"d,
                                                  kv.key,
                                                  kv.value)).join);
            }

            if (!i.info.empty)
            {
                table.addElem("info", i.info);
            }

            if (!i.remarks.empty || !extraRemarks.empty)
            {
                table.addElem("備考", [i.remarks, extraRemarks].filter!"!a.empty".join(", "));
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


auto addElem(Widget layout, dstring caption, dstring elem, dstring delim = ": ")
{
    layout.addChild(new TextWidget("", caption~delim));
    layout.addChild(new TextWidget("", elem));
}

auto addExtraElem(Widget layout, Item item, Wisdom wisdom)
{
    final switch(item.type) with(ItemType)
    {
    case Food, Drink, Liquor:{
        auto info = item.extraInfo.peek!FoodInfo;
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
                layout.addElem("", effectStr, "");
                layout.addElem("バフグループ",
                               einfo.group == AdditionalEffectGroup.Others ? "その他"
                                                                           : einfo.group.to!dstring);
                layout.addElem("効果時間", format("%s 秒"d, einfo.duration));


                return einfo.remarks;
            }
        }
    }
    case Medicine:
        break;
    case Weapon:{
        auto info = item.extraInfo.peek!WeaponInfo;

        auto damageStr = Grade.values
                              .filter!(g => info.damage.keys.canFind(g))
                              .map!(g => format("%s: %.1f"d, g.to!Grade, info.damage[g.to!Grade]))
                              .join(", ");
        layout.addElem("ダメージ",
                       damageStr);
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
        if (info.restriction != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.to!dstring~"系");
        }

        if (!info.additionalEffect.keys.empty)
        {
            layout.addElem("付与効果",
                           info.additionalEffect
                               .byKeyValue
                               .map!(kv => format("%s (%s)"d, kv.key, kv.value))
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
        return ""d;
    }
    case Armor:
        break;
    case Bullet:{
        auto info = item.extraInfo.peek!BulletInfo;

        layout.addElem("ダメージ", format("%.1f"d, info.damage));
        layout.addElem("有効レンジ", format("%.1f"d, info.range));
        layout.addElem("角度補正角", info.angle.to!dstring);
        layout.addElem("必要スキル",
                       info.skills
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)"d, kv.key, kv.value))
                           .join(", "));
        layout.addElem("装備スロット", "矢/弾");
        if (info.restriction != ShipRestriction.Any)
        {
            layout.addElem("装備可能シップ", info.restriction.to!dstring~"系");
        }
        return ""d;
    }
    case Asset:
        break;
    case Others:
        break;
    case UNKNOWN:
        break;
    }
    return ""d;
}

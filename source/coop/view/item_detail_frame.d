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

import std.array;
import std.algorithm;
import std.conv;
import std.math;
import std.format;

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
                        colCount: 2

                        TextWidget { text: "名前: " }
                        TextWidget { id: name }

                        TextWidget { text: "英名: " }
                        TextWidget { id: ename }

                        TextWidget { text: "重さ: " }
                        TextWidget { id: weight }

                        /// 食べ物，飲み物，酒情報
                        TextWidget { id: effCap; text: "効果: "}
                        TextWidget { id: effect }

                        TextWidget { id: addCap; text: "付加効果: "}
                        TextWidget { id: additional }

                        TextWidget { id: addDetailCap; text: ""}
                        TextWidget { id: additionalDetail }

                        TextWidget { id: groupCap; text: "バフグループ: "}
                        TextWidget { id: group }

                        TextWidget { id: durCap; text: "効果時間: "}
                        TextWidget { id: duration }

                        /// 武器
                        /// 防具

                        TextWidget { text: "NPC売却価格: " }
                        TextWidget { id: price }

                        TextWidget { text: "転送可: " }
                        TextWidget { id: transferable }

                        TextWidget { text: "スタック可: " }
                        TextWidget { id: stackable }

                        TextWidget { id: specialPropCap ; text: "特殊条件: " }
                        TextWidget { id: specialProp }

                        TextWidget {
                            id: petItemCaption
                            text: "ペットアイテム: "
                        }
                        TextWidget { id: petItem }

                        TextWidget {
                            id: infoCap
                            text: "info: "
                        }
                        TextWidget { id: info }
                    }

                    HorizontalLayout {
                        id: remarksInfo
                        TextWidget { text: "備考: " }
                        TextWidget { id: remarks }
                    }
                }
            });

        with(layout)
        {
            /// 食べ物，飲み物，酒情報
            childById("effCap").visibility           = Visibility.Gone;
            childById("effect").visibility           = Visibility.Gone;
            childById("addCap").visibility           = Visibility.Gone;
            childById("additional").visibility       = Visibility.Gone;
            childById("addDetailCap").visibility     = Visibility.Gone;
            childById("additionalDetail").visibility = Visibility.Gone;
            childById("groupCap").visibility         = Visibility.Gone;
            childById("group").visibility            = Visibility.Gone;
            childById("durCap").visibility           = Visibility.Gone;
            childById("duration").visibility         = Visibility.Gone;
        }
        contentWidget = layout;
        backgroundColor = "white";
    }

    static auto create(Item i, int idx, Wisdom wisdom)
    {
        auto ret = new typeof(this)("detail"~idx.to!string);
        ret.item_ = i;
        with(ret)
        {
            childById("name").text = i.name;
            childById("ename").text =
                i.ename.empty ? "わからん（´・ω・｀）" : i.ename;
            childById("weight").text =
                i.weight.isNaN ? "そこそこの重さ" : format("%.2f"d, i.weight);
            childById("price").text = format("%s g"d, i.price);
            childById("transferable").text
                = i.transferable ? "はい" : "いいえ";
            childById("stackable").text = i.stackable ? "はい": "いいえ";

            childById("info").text = i.info;
            childById("info").visibility =
                i.info.empty ? Visibility.Gone : Visibility.Visible;
            childById("infoCap").visibility =
                i.info.empty ? Visibility.Gone : Visibility.Visible;

            childById("remarks").text = i.remarks;
            childById("remarksInfo").visibility
                = i.remarks.empty ? Visibility.Gone : Visibility.Visible;

            // ペットアイテム情報
            auto petCap = childById("petItemCaption");
            auto pFoodInfo = childById("petItem");
            if (i.petFoodInfo.keys.empty || i.petFoodInfo.keys[0] == PetFoodType.NoEatable)
            {
                petCap.visibility = Visibility.Gone;
                pFoodInfo.visibility = Visibility.Gone;
            }
            else
            {
                petCap.visibility = Visibility.Visible;
                pFoodInfo.visibility = Visibility.Visible;
                auto str = i.petFoodInfo
                           .byKeyValue
                           .map!(kv => format("%s (%.1f)"d,
                                              kv.key.toString,
                                              kv.value)).join;
                pFoodInfo.text = str;
            }

            auto spCap = childById("specialPropCap");
            auto sp = childById("specialProp");
            if (i.properties == 0)
            {
                spCap.visibility = Visibility.Gone;
                sp.visibility = Visibility.Gone;
            }
            else
            {
                spCap.visibility = Visibility.Visible;
                sp.visibility = Visibility.Visible;
                sp.text = i.properties.toStrings.join(", ").to!dstring;
            }
        }

        final switch(i.type) with(ItemType)
        {
        case Food:
            if (auto info = i.name in wisdom.foodList)
            {
                ret.setFoodInfo(*info, wisdom);
            }
            break;
        case Drink:
            if (auto info = i.name in wisdom.drinkList)
            {
                ret.setFoodInfo(*info, wisdom);
            }
            break;
        case Liquor:
            if (auto info = i.name in wisdom.liquorList)
            {
                ret.setFoodInfo(*info, wisdom);
            }
            break;
        case Medicine:
            break;
        case Weapon:
            break;
        case Armor:
            break;
        case Asset:
            break;
        case Others:
            break;
        }
        return ret;
    }

    @property auto item()
    {
        return item_;
    }

    @property auto foodInfo()
    {
        return food_;
    }

    @property auto setFoodInfo(Food f, Wisdom wisdom)
    {
        childById("effCap").visibility = Visibility.Visible;
        childById("effect").visibility = Visibility.Visible;

        childById("effect").text = format("%.1f"d, f.effect);

        if (auto effectName = f.additionalEffect)
        {
            setFoodEffect(effectName, wisdom);
        }
    }

    @property auto foodEffect()
    {
        return effect_;
    }

    // AdditionalEffect eff にしたいが，まだデータができてないのでうまくいかない
    auto setFoodEffect(dstring eff, Wisdom wisdom)
    {
        childById("addCap").visibility           = Visibility.Visible;
        childById("additional").visibility       = Visibility.Visible;
        childById("addDetailCap").visibility     = Visibility.Visible;
        childById("additionalDetail").visibility = Visibility.Visible;
        childById("groupCap").visibility         = Visibility.Visible;
        childById("group").visibility            = Visibility.Visible;
        childById("durCap").visibility           = Visibility.Visible;
        childById("duration").visibility         = Visibility.Visible;

        childById("additional").text = eff;
        if (auto f = eff in wisdom.foodEffectList)
        {
            auto effectInfo = *f;
            auto effectStr = effectInfo
                             .effects
                             .byKeyValue
                             .map!(kv => format("%s: %s%s"d,
                                                kv.key,
                                                kv.value > 0 ? "+" : "",
                                                kv.value))
                             .join(", ");
            if (effectInfo.otherEffects)
            {
                if (effectStr)
                    effectStr ~= ", ";
                effectStr ~= effectInfo.otherEffects;
            }
            childById("additionalDetail").text = effectStr;
            childById("group").text =
                effectInfo.group == AdditionalEffectGroup.Others
                ? "その他"
                : effectInfo.group.to!dstring;
            childById("duration").text =
                format("%s 秒"d, effectInfo.duration);

            if (effectInfo.remarks)
            {
                auto rInfo = childById("remarksInfo");
                auto rText = childById("remarks");
                rInfo.visibility = Visibility.Visible;
                rText.visibility = Visibility.Visible;
                if (rText.text)
                    rText.text = rText.text ~ ", ";
                rText.text = rText.text ~ effectInfo.remarks;
            }
        }
    }
private:
    Item item_;
    /// 料理固有
    Food food_;
    AdditionalEffect effect_;
}

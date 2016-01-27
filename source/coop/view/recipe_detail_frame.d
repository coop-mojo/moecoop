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
module coop.view.recipe_detail_frame;

import dlangui;
import dlangui.widgets.metadata;

import std.algorithm;
import std.array;
import std.container.rbtree;
import std.format;
import std.range;
import std.traits;
import std.typecons;

import coop.model.recipe;
import coop.model.wisdom;
import coop.model.character;

class RecipeDetailFrame: ScrollWidget
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

                        TextWidget { text: "レシピ名: " }
                        TextWidget { id: recipe }

                        TextWidget { text: "テクニック: " }
                        TextWidget { id: tech  }

                        TextWidget { text: "必要スキル: "  }
                        TextWidget { id: skills  }

                        TextWidget { text: "材料: " }
                        VerticalLayout { id: ingredients }

                        TextWidget { text: "生成物: " }
                        VerticalLayout { id: products }

                        TextWidget { text: "収録バインダー: " }
                        TextWidget { id: binders }

                        TextWidget { text: "所持キャラクター: " }
                        TextWidget { id: owners }

                        TextWidget { text: "レシピ必須: " }
                        TextWidget { id: requireRecipe }

                        TextWidget { text: "ルーレット: " }
                        TextWidget { id: roulette }
                    }
                    HorizontalLayout {
                        id: remarksInfo
                        TextWidget { text: "備考:" }
                        TextWidget { id: remarks }
                    }
                }
            });

        contentWidget = layout;
        backgroundColor = "white";
    }

    static auto create(Recipe r, Wisdom wisdom, Character[dstring] chars)
    {
        auto ret = new typeof(this)(r.name.to!string);
        ret.recipe_ = r;
        with(ret)
        {
            childById("recipe").text = r.name;
            childById("tech").text = r.techniques[].join(" or ");
            childById("skills").text = r.requiredSkills
                                       .byKeyValue
                                       .map!(kv => format("%s (%s)"d,
                                                          kv.key, kv.value))
                                       .join(", ");

            auto pLayout = childById("products");
            r.products.byKeyValue
                .map!(kv => format("%s x %s"d, kv.key, kv.value))
                .map!(s => new TextWidget("product", s))
                .each!(w => pLayout.addChild(w));

            auto ingLayout = childById("ingredients");
            r.ingredients.byKeyValue
                .map!(kv => format("%s x %s"d, kv.key, kv.value))
                .map!(s => new TextWidget(null, s))
                .each!(w => ingLayout.addChild(w));

            childById("requireRecipe").text =
                r.requiresRecipe ? "はい" : "いいえ";

            dstring rouletteText;
            if (!r.isGambledRoulette && !r.isPenaltyRoulette)
            {
                rouletteText = "通常"d;
            }
            else
            {
                dstring[] attrs;
                if (r.isGambledRoulette) attrs ~= "ギャンブル";
                if (r.isPenaltyRoulette) attrs ~= "ペナルティ";
                rouletteText = attrs.join(", ");
            }
            childById("roulette").text = rouletteText;
            childById("remarksInfo").visibility =
                r.remarks.empty ? Visibility.Gone : Visibility.Visible;
            childById("remarks").text = r.remarks;
        }
        ret.binders = wisdom.bindersFor(r.name);
        ret.owners = chars
                     .keys
                     .filter!(k =>
                              ret.binders
                                 .any!(b => chars[k].hasRecipe(r.name, b)))
                     .map!(k => tuple(k,
                                      make!(RedBlackTree!dstring)(ret.binders.filter!(b => chars[k].hasRecipe(r.name, b)).array)))
                     .assocArray;
        return ret;
    }

    @property auto recipe()
    {
        return recipe_;
    }

    @property auto remarks()
    {
        return recipe_.remarks;
    }

    @property auto name()
    {
        return recipe_.name;
    }

    @property auto techniques()
    {
        return recipe_.techniques;
    }

    @property auto skills()
    {
        return recipe_.requiredSkills;
    }

    @property auto products()
    {
        return recipe_.products;
    }

    @property auto ingredients()
    {
        return recipe_.ingredients;
    }

    @property auto isGambled()
    {
        return recipe_.isGambledRoulette;
    }

    @property auto isPenalty()
    {
        return recipe_.isPenaltyRoulette;
    }

    @property auto requiresRecipe()
    {
        return recipe_.requiresRecipe;
    }

    @property auto binders()
    {
        return filedBinders_;
    }

    @property auto binders(R)(R bs)
        if (isInputRange!R && is(ElementType!R == dstring))
    {
        filedBinders_ = bs;
        childById("binders").text = bs.empty ? "なし": bs.join(", ");
    }

    @property auto owners()
    {
        return owners_;
    }

    @property auto owners(RedBlackTree!dstring[dstring] os)
    {
        owners_ = os;
        auto bLen = binders.length;
        childById("owners").text =
            os.keys.empty
            ? "なし"
            : os.keys.map!((k) {
                    if (bLen == 1)
                    {
                        return k;
                    }
                    else
                    {
                        return format("%s (%s)"d,
                                      k,os[k][].join(", "));
                    }
                }).join(", ");
    }
private:
    Recipe recipe_;
    dstring[] filedBinders_;
    RedBlackTree!dstring[dstring] owners_;
}

mixin(registerWidgets!RecipeDetailFrame);

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
module coop.controller.recipe_frame_controller;

import dlangui;

import std.algorithm;
import std.container.util;
import std.exception;
import std.file;
import std.range;
import std.regex;
import std.typecons;

import coop.migemo;
import coop.model.character;
import coop.model.config;
import coop.model.item;
import coop.model.recipe;
import coop.model.wisdom;
import coop.view.recipe_base_frame;

class RecipeFrameController
{
    this(RecipeBaseFrame frame, Wisdom wisdom, Character[] chars, Config config)
    {
        frame_ = frame;
        wisdom_ = wisdom;
        chars_ = chars;
        config_ = config;
        frame_.queryFocused = {
            if (frame_.queryText == defaultTxtMsg)
            {
                frame_.queryText = ""d;
            }
        };

        frame_.queryChanged =
            frame_.metaSearchOptionChanged =
            frame_.migemoOptionChanged =
            frame_.categoryChanged =
            frame_.nColumnChanged = {
            showBinderRecipes;
        };

        // モーダル窓が作れないから設定を即時反映できない
        if (config_.migemoDLL.exists && config_.migemoDict.exists)
        {
            migemo_ = new Migemo(config_.migemoDLL, config_.migemoDict);
            migemo_.load("resource/dict/moe-dict");
            enforce(migemo_.isEnable);
        }
        else
        {
            frame_.disableMigemoBox;
        }

        Recipe dummy;
        dummy.techniques = make!(typeof(dummy.techniques))(cast(dstring)[]);
        frame_.recipeDetail = toRecipeWidget(dummy);

        frame_.hideItemDetail(0);
        frame_.hideItemDetail(1);
    }

    auto showBinderRecipes()
    {
        import std.string;

        if (frame_.queryText == defaultTxtMsg)
        {
            frame_.queryText = ""d;
        }

        auto query = frame_.queryText.removechars(r"/[ 　]/");
        if (frame_.useMetaSearch && query.empty)
            return;

        dstring[][dstring] recipes;
        if (frame_.useMetaSearch)
        {
            recipes = wisdom_.binders.map!(b => tuple(b, wisdom_.recipesIn(Binder(b)))).assocArray;
        }
        else
        {
            auto binder = frame_.selectedCategory;
            recipes = [tuple(binder, wisdom_.recipesIn(Binder(binder)))].assocArray;
        }

        if (!query.empty)
        {
            bool delegate(dstring) matchFun =
                s => !find(s.removechars(r"/[ 　]/"), boyerMooreFinder(query)).empty;
            if (frame_.useMigemo)
            {
                try{
                    auto q = migemo_.query(query).regex;
                    matchFun = s => !s.removechars(r"/[ 　]/").matchFirst(q).empty;
                } catch(RegexException e) {
                    // use default matchFun
                }
            }
            recipes = recipes
                      .byKeyValue
                      .map!(kv =>
                            tuple(kv.key,
                                  kv.value.filter!matchFun.array))
                      .assocArray;
        }

        Widget[] tableElems;
        if (frame_.useMetaSearch)
        {
            tableElems = recipes.byKeyValue.map!((kv) {
                    auto binder = kv.key;
                    auto recipes = kv.value;
                    if (recipes.empty)
                        return cast(Widget[])[];
                    Widget header = new TextWidget("", binder);
                    header.backgroundColor = "gray";
                    return header~toBinderRecipeWidgets(binder, kv.value);
                }).join;
        }
        else
        {
            auto binder = frame_.selectedCategory;
            tableElems = toBinderRecipeWidgets(binder, recipes[binder]);
        }
        frame_.showRecipeList(tableElems, frame_.numberOfColumns);
    }

    auto categories(dstring[] cats)
    {
        frame_.categories = cats;
    }
private:

    auto toBinderRecipeWidgets(dstring binder, dstring[] recipes)
    {
        return recipes.map!((r) {
                import std.stdio;
                auto ret = new RecipeEntryWidget(r);

                ret.filedStateChanged = (bool marked) {
                    if (marked)
                    {
                        chars_.front.markFiledRecipe(r, binder);
                    }
                    else
                    {
                        chars_.front.unmarkFiledRecipe(r, binder);
                    }
                };
                ret.checked = chars_.front.hasRecipe(r, binder);
                ret.detailClicked = {
                    auto rDetail = wisdom_.recipeFor(r);
                    if (rDetail.name.empty)
                    {
                        rDetail.name = r;
                        rDetail.remarks = "作り方がわかりません（´・ω・｀）";
                    }
                    frame_.recipeDetail = toRecipeWidget(rDetail);

                    auto itemNames = rDetail.products.keys;
                    enforce(itemNames.length <= 2);
                    if (itemNames.empty)
                    {
                        // レシピ情報が完成するまでの間に合わせ
                        itemNames = [ r~"のレシピで作れる何か" ];
                    }

                    frame_.hideItemDetail(1);

                    itemNames.enumerate(0).each!((idx_name) {
                            auto idx = idx_name[0];
                            dstring name = idx_name[1];
                            Item item;
                            if (auto i = name in wisdom_.itemList)
                            {
                                item = *i;
                            }
                            else
                            {
                                item.name = name;
                                item.remarks = "細かいことはわかりません（´・ω・｀）";
                            }

                            frame_.showItemDetail(idx);
                            frame_.setItemDetail(toItemWidget(item), idx);
                        });
                };
                return cast(Widget)ret;
            }).array;
    }

    auto toRecipeWidget(Recipe r)
    {
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

        import std.format;
        layout.childById("recipe").text = r.name;
        layout.childById("tech").text = r.techniques[].join(" or ");
        layout.childById("skills").text = r.requiredSkills
                                          .byKeyValue
                                          .map!(kv => format("%s (%s)"d, kv.key, kv.value))
                                          .join(", ");
        auto productsList = r.products
                            .byKeyValue
                            .map!(kv => format("%s x %s"d, kv.key, kv.value))
                            .map!(s => new TextWidget("product", s));
        auto productsLayout = layout.childById!VerticalLayout("products");
        productsList.each!(w => productsLayout.addChild(w));

        auto ingredientsList = r.ingredients
                               .byKeyValue
                               .map!(kv => format("%s x %s"d, kv.key, kv.value))
                               .map!(s => new TextWidget("ingredients", s));
        auto ingredientsLayout = layout.childById!VerticalLayout("ingredients");
        ingredientsList.each!(w => ingredientsLayout.addChild(w));

        auto filedBinders = wisdom_.bindersFor(r.name);
        layout.childById("binders").text = filedBinders.empty ? "なし": filedBinders.join(", ");
        layout.childById("requireRecipe").text = r.requiresRecipe ? "はい": "いいえ";

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
        layout.childById("roulette").text = rouletteText;

        auto l = layout.childById("remarksInfo");
        if (r.remarks.empty)
        {
            l.visibility = Visibility.Gone;
        }
        else
        {
            l.visibility = Visibility.Visible;
            auto remarksText = layout.childById("remarks");
            remarksText.text = r.remarks;
        }

        auto ret = new ScrollWidget;
        ret.contentWidget = layout;
        ret.backgroundColor = "white";
        return ret;
    }

    auto toItemWidget(Item item)
    {
        import std.format;
        auto itemBasiclayout = parseML(q{
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

                    /// 食べ物情報
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

                    /// 飲み物
                    /// 武器
                    /// 防具

                    TextWidget { text: "NPC売却価格: " }
                    TextWidget { id: price }

                    TextWidget { text: "転送可: " }
                    TextWidget { id: transferable }

                    TextWidget { text: "スタック可: " }
                    TextWidget { id: stackable }

                    TextWidget { text: "ペットアイテム: "; id: petItemCaption }
                    TextWidget { id: petItem }

                    TextWidget { text: "info: " }
                    TextWidget { id: info }
                    }

                HorizontalLayout {
                id: remarksInfo
                TextWidget { text: "備考: " }
                TextWidget { id: remarks }
                }
                }
            });
        import std.math;
        itemBasiclayout.childById("name").text = item.name;
        itemBasiclayout.childById("ename").text = item.ename.empty ? "わからん（´・ω・｀）": item.ename;
        itemBasiclayout.childById("weight").text = item.weight.isNaN ? "そこそこの重さ": item.weight.to!dstring;
        itemBasiclayout.childById("price").text = format("%s g"d, item.price);
        itemBasiclayout.childById("transferable").text = item.transferable ? "はい" : "いいえ";
        itemBasiclayout.childById("stackable").text = item.stackable ? "はい": "いいえ";
        itemBasiclayout.childById("info").text = item.info;

        auto remInfo = itemBasiclayout.childById("remarksInfo");
        auto remarksText = itemBasiclayout.childById("remarks");
        if (item.remarks.empty)
        {
            remInfo.visibility = Visibility.Gone;
            remarksText.text = ""d;
        }
        else
        {
            remInfo.visibility = Visibility.Visible;
            remarksText.text = item.remarks;
        }

        auto petCap = itemBasiclayout.childById("petItemCaption");
        auto petFoodInfo = itemBasiclayout.childById("petItem");
        if (item.petFoodInfo.keys.empty)
        {
            petCap.visibility = Visibility.Gone;
            petFoodInfo.visibility = Visibility.Gone;
        }
        else
        {
            petCap.visibility = Visibility.Visible;
            petFoodInfo.visibility = Visibility.Visible;
            auto str = item.petFoodInfo.byKeyValue.map!(kv => format("%s (%s)"d, kv.key.toString, kv.value)).front;
            petFoodInfo.text = str;
        }

        with(itemBasiclayout)
        {
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

        /// 食べ物情報を表示
        auto showFoodBasicInfo()
        {
            with(itemBasiclayout)
            {
                childById("effCap").visibility = Visibility.Visible;
                childById("effect").visibility = Visibility.Visible;
            }
        }

        /// 食べ物のバフ効果を表示
        auto showFoodAdditionalEffect()
        {
            with(itemBasiclayout)
            {
                childById("addCap").visibility           = Visibility.Visible;
                childById("additional").visibility       = Visibility.Visible;
                childById("addDetailCap").visibility     = Visibility.Visible;
                childById("additionalDetail").visibility = Visibility.Visible;
                childById("groupCap").visibility         = Visibility.Visible;
                childById("group").visibility            = Visibility.Visible;
                childById("durCap").visibility           = Visibility.Visible;
                childById("duration").visibility         = Visibility.Visible;
            }
        }

        final switch (item.type) with (ItemType)
        {
        case Food:
            if (auto info = item.name in wisdom_.foodList)
            {
                auto foodInfo = *info;
                showFoodBasicInfo;
                itemBasiclayout.childById("effect").text = foodInfo.effect.to!dstring;
                if (auto effectName = foodInfo.additionalEffect)
                {
                    showFoodAdditionalEffect;
                    itemBasiclayout.childById("additional").text = foodInfo.additionalEffect;
                    if (auto f = effectName in wisdom_.foodEffectList)
                    {
                        auto effectInfo = *f;

                        auto effectStr = effectInfo.effects
                                         .byKeyValue
                                         .map!(kv => format("%s: %s%s"d, kv.key, kv.value > 0 ? "+" : "", kv.value))
                                         .join(", ");
                        if (effectInfo.otherEffects)
                        {
                            if (effectStr)
                                effectStr ~= ", ";
                            effectStr ~= effectInfo.otherEffects;
                        }
                        itemBasiclayout.childById("additionalDetail").text = effectStr;
                        itemBasiclayout.childById("group").text = effectInfo.group.to!dstring;
                        itemBasiclayout.childById("duration").text =  format("%s 秒"d, effectInfo.duration);

                        if (effectInfo.remarks)
                        {
                            auto rInfo = itemBasiclayout.childById("remarksInfo");
                            auto rText = itemBasiclayout.childById("remarks");
                            rInfo.visibility = Visibility.Visible;
                            rText.visibility = Visibility.Visible;
                            if (rText.text)
                                rText.text = rText.text ~ ", ";
                            rText.text = rText.text ~ effectInfo.remarks;
                        }
                    }
                }
            }
            break;
        case Drink:
            break;
        case Weapon:
            break;
        case Armor:
            break;
        case Other:
            break;
        }

        auto ret = new ScrollWidget;
        ret.contentWidget = itemBasiclayout;
        ret.backgroundColor = "white";
        return ret;
    }

    enum defaultTxtMsg = "見たいレシピ";
    RecipeBaseFrame frame_;
    Config config_;
    Migemo migemo_;
    Character[] chars_;
    Wisdom wisdom_;
}

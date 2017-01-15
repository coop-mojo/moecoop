/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.recipe_detail_frame;

import dlangui;
import dlangui.widgets.metadata;

class RecipeDetailFrame: ScrollWidget, MenuItemActionHandler
{
    import std.container;
    import std.range;

    import coop.core.character;
    import coop.core.recipe;
    import coop.core.wisdom;
    import coop.model;

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

    static auto create(dstring n, WisdomModel model, Character[dstring] chars)
    {
        auto r = model.getRecipe(n);
        auto ret = new typeof(this)(n.to!string);
        ret.recipe_ = r;
        with(ret)
        {
            import std.algorithm;
            import std.array;
            import std.conv;
            import std.format;

            childById("recipe").text = n;
            childById("tech").text = r.techniques[].array.to!(dstring[]).join(" or ");
            childById("skills").text = r.requiredSkills
                                       .byKeyValue
                                       .map!(kv => format("%s (%.1f)"d,
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
            auto rem = r ? r.remarks.to!dstring : "作り方がわかりません（´・ω・｀）";
            childById("remarksInfo").visibility =
                rem.empty ? Visibility.Gone : Visibility.Visible;
            childById("remarks").text = rem;
        }
        ret.binders = model.getBindersFor(n).to!(dstring[]);
        if (!chars.keys.empty)
        {
            import std.algorithm;
            import std.typecons;

            ret.owners = chars
                         .keys
                         .filter!(k =>
                                  ret.binders
                                  .any!(b => chars[k].hasRecipe(n.to!string, b.to!string)))
                         .map!(k => tuple(k,
                                          make!(RedBlackTree!dstring)(ret.binders.filter!(b => chars[k].hasRecipe(n.to!string, b.to!string)).array)))
                         .assocArray;
        }

        auto popupItem = new MenuItem(null);
        popupItem.add(new Action(EditorActions.Copy, "このレシピをコピー"d, "edit-cut"));
        ret.popupMenu = popupItem;
        return ret;
    }

    // @property auto recipe()
    // {
    //     return recipe_;
    // }

    // @property auto remarks()
    // {
    //     return recipe_.remarks;
    // }

    @property auto name()
    {
        return recipe_.name;
    }

    // @property auto techniques()
    // {
    //     return recipe_.techniques;
    // }

    // @property auto skills()
    // {
    //     return recipe_.requiredSkills;
    // }

    // @property auto products()
    // {
    //     return recipe_.products;
    // }

    // @property auto ingredients()
    // {
    //     return recipe_.ingredients;
    // }

    // @property auto isGambled()
    // {
    //     return recipe_.isGambledRoulette;
    // }

    // @property auto isPenalty()
    // {
    //     return recipe_.isPenaltyRoulette;
    // }

    // @property auto requiresRecipe()
    // {
    //     return recipe_.requiresRecipe;
    // }

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
        import std.algorithm;

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
                        import std.format;

                        return format("%s (%s)"d,
                                      k,os[k][].join(", "));
                    }
                }).join(", ");
    }

    @property auto popupMenu(MenuItem popupMenu)
    {
        _popupMenu = popupMenu;
    }

    override bool canShowPopupMenu(int x, int y)
    {
        if (_popupMenu is null)
        {
            return false;
        }
        else if (_popupMenu.openingSubmenu.assigned &&
            !_popupMenu.openingSubmenu(_popupMenu))
        {
                return false;
        }
        else if (recipe_.products.keys.empty)
        {
            return false;
        }
        return true;
    }

    override void showPopupMenu(int x, int y)
    {
        if (_popupMenu.openingSubmenu.assigned &&
            !_popupMenu.openingSubmenu(_popupMenu))
        {
            return;
        }
        _popupMenu.updateActionState(this);
        PopupMenu popupMenu = new PopupMenu(_popupMenu);
        popupMenu.menuItemAction = this;
        PopupWidget popup = window.showPopup(popupMenu, this, PopupAlign.Point | PopupAlign.Right, x, y);
        popup.flags = PopupFlags.CloseOnClickOutside;
    }

    override bool onMenuItemAction(const Action action)
    {
        return dispatchAction(action);
    }

    override bool handleAction(const Action a)
    {
        if (a)
        {
            if (a.id == EditorActions.Copy)
            {
                platform.setClipboardText(recipe_.toShortString.to!dstring);
                return true;
            }
        }
        return false;
    }

private:
    MenuItem _popupMenu;
    Recipe recipe_;
    dstring[] filedBinders_;
    RedBlackTree!dstring[dstring] owners_;
}

mixin(registerWidgets!RecipeDetailFrame);

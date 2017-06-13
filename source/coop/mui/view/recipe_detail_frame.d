/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.view.recipe_detail_frame;

import dlangui;
import dlangui.widgets.metadata;

class RecipeDetailFrame: ScrollWidget, MenuItemActionHandler
{
    import std.container;
    import std.range;

    import coop.mui.model.character;
    import coop.mui.model.wisdom_adapter;

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

    static auto create(dstring n, ModelAPI model, Character[dstring] chars)
    {
        import std.algorithm;
        import std.exception;

        import vibe.http.common;
        auto r = n.empty ? RecipeInfo.init : model.getRecipe(n.to!string).ifThrown!HTTPStatusException(RecipeInfo.init);
        auto ret = new typeof(this)(n.to!string);
        ret.recipe_ = r;
        with(ret)
        {
            import std.array;
            import std.conv;
            import std.format;

            childById("recipe").text = n;
            childById("tech").text = r.テクニック.to!(dstring[]).join(" or ");
            childById("skills").text = r.必要スキル
                                        .byKeyValue
                                        .map!(kv => format("%s (%.1f)"d,
                                                           kv.key, kv.value))
                                        .join(", ");

            auto pLayout = childById("products");
            r.生成物.map!(pr => format("%s x %s"d, pr.アイテム名, pr.個数))
                    .map!(s => new TextWidget("product", s))
                    .each!(w => pLayout.addChild(w));

            auto ingLayout = childById("ingredients");
            r.材料.map!(ing => format("%s x %s"d, ing.アイテム名, ing.個数))
                  .map!(s => new TextWidget(null, s))
                  .each!(w => ingLayout.addChild(w));

            childById("requireRecipe").text =
                r.レシピ必須 ? "はい" : "いいえ";

            dstring rouletteText;
            if (!r.ギャンブル型 && !r.ペナルティ型)
            {
                rouletteText = "通常"d;
            }
            else
            {
                dstring[] attrs;
                if (r.ギャンブル型) attrs ~= "ギャンブル";
                if (r.ペナルティ型) attrs ~= "ペナルティ";
                rouletteText = attrs.join(", ");
            }
            childById("roulette").text = rouletteText;
            auto rem = r.レシピ名.empty ? "作り方がわかりません（´・ω・｀）" : r.備考.to!dstring;
            childById("remarksInfo").visibility =
                rem.empty ? Visibility.Gone : Visibility.Visible;
            childById("remarks").text = rem;
        }
        ret.binders = r.収録バインダー.map!"a.バインダー名".array.to!(dstring[]);
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
        return recipe_.レシピ名;
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

    private @property auto binders()
    {
        return filedBinders_;
    }

    private @property auto binders(R)(R bs)
        if (isInputRange!R && is(ElementType!R == dstring))
    {
        filedBinders_ = bs;
        childById("binders").text = bs.empty ? "なし": bs.join(", ");
    }

    @property auto owners()
    {
        return owners_;
    }

    private @property auto owners(RedBlackTree!dstring[dstring] os)
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
        else if (recipe_.レシピ名.empty)
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
                import std.algorithm;
                import std.format;
                import std.string;

                import coop.util;

                auto str = format("%s (%s%s) = %s"d,
                                  recipe_.生成物.map!(pr => format("%sx%s", pr.アイテム名.toHankaku.removechars(" "), pr.個数)).join(","),
                                  recipe_.必要スキル.byKeyValue.map!(kv => format("%s%.1f", kv.key.toHankaku.removechars(" "), kv.value)).join(","),
                                  ([recipe_.レシピ必須 ? ": ﾚｼﾋﾟ必須" : ""]~recipe_.収録バインダー.map!"a.バインダー名".array).join(", "),
                                  recipe_.材料.map!(ing => format("%sx%s", ing.アイテム名.toHankaku.removechars(" "), ing.個数)).join(" "));
                platform.setClipboardText(str);
                return true;
            }
        }
        return false;
    }

private:
    MenuItem _popupMenu;
    RecipeInfo recipe_;
    dstring[] filedBinders_;
    RedBlackTree!dstring[dstring] owners_;
}

mixin(registerWidgets!RecipeDetailFrame);

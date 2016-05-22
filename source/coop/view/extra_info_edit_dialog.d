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
module coop.view.extra_info_edit_dialog;

import dlangui;
import dlangui.dialogs.dialog;

import std.array;
import std.conv;
import std.format;
import std.math;
import std.regex;

import coop.model.item;

class ExtraInfoEditDialog: Dialog
{
    this(Window parent, Item orig)
    {
        super(UIString("アイテム種別情報編集"d), parent, DialogFlag.Popup);
        original = orig;
    }
    override void initialize()
    {
        auto root = parseML(q{
                VerticalLayout {
                    TableLayout {
                        id: main
                        colCount: 2
                        padding: 10
                        minWidth: 400
                    }

                    HorizontalLayout {
                        id: dlgButtons
                        FrameLayout {
                            layoutWidth: 250
                        }
                    }
                }
            });
        addChild(root);

        auto item = original;

        auto main = root.childById("main");
        main.addExtraInfoLayout(item);

        with(root.childById("dlgButtons"))
        {
            addChild(new Button(ACTION_OK));
            addChild(new Button(ACTION_CANCEL));
            _buttonActions = [ACTION_OK, ACTION_CANCEL];
        }
    }

    override void close(const Action action)
    {
        if (action) {
            if (action.id == StandardAction.Ok)
            {
                /// TODO
            }
        }
        _parentWindow.removePopup(_popup);
    }
private:
    Item original;
    typeof(Item.init.extraInfo) extra;
}

auto showExtraInfoEditDialog(Window parent, Item item)
{
    auto dlg = new ExtraInfoEditDialog(parent, item);
    dlg.show;
}

auto addExtraInfoLayout(Widget layout, Item item)
{
    final switch(item.type) with(ItemType)
    {
    case Food, Drink, Liquor:{
        auto extra = item.extraInfo.peek!FoodInfo;
        layout.addTextElem!r"^\d+(\.\d+)?$"("効果", extra.effect.to!dstring, extra.effect.isNaN);
        layout.addTextElem("付加効果", extra.additionalEffect, extra.additionalEffect.empty);
        return;
    }
    case Medicine:
        break;
    case Weapon:{
        auto extra = item.extraInfo.peek!WeaponInfo;
        layout.addChild(new TextWidget("", "ダメージ"d));
        auto dmgLayout = new HorizontalLayout;
        foreach(st; Grade.values)
        {
            dmgLayout.addChild(new TextWidget("", st.to!dstring));
            if (auto v = st.to!Grade in extra.damage)
            {
                dmgLayout.addChild(new EditLine("", format("%.2f"d, v)));
            }
            else
            {
                auto editLine = new EditLine("", "");
                dmgLayout.addChild(editLine);
                editLine.contentChange = (EditableContent content) {
                    auto txt = content.text;
                    if (txt.empty || txt.matchFirst(ctRegex!r"^\d+(\.\d+)?$"d))
                    {
                        editLine.textColor = "black";
                    }
                    else
                    {
                        editLine.textColor = "red";
                    }
                };

            }
        }
        layout.addChild(dmgLayout);

        // real[Grade] damage; // 劣化, NG, HG, MG
        // int duration;
        // real range;
        // real[dstring] skills; // 最大3個まで
        // bool isDoubleHands;
        // WeaponSlot slot;
        // ShipRestriction restriction;
        // Material material;
        // ExhaustionType type;
        // int exhaustion;
        // real[dstring] effects; // 0 もありうる
        // int[dstring] additionalEffect; // 0 もありうる
        return;
    }
    case Armor:
        break;
    case Bullet:
        break;
    case Asset:
        break;
    case Others:
        break;
    case UNKNOWN:
        assert(false);
    }
}

auto addTextElem(dstring AllowedRegex = "")(Widget layout, dstring caption, dstring elem, bool editable)
{
    layout.addChild(new TextWidget("", caption));
    auto editLine = new EditLine("", elem);
    layout.addChild(editLine);
    with(editLine)
    {
        enabled = editable;
        static if (AllowedRegex.empty)
        {
            alias matchFun = s => true;
        }
        else
        {
            alias matchFun = (s) {
                if (s.empty || s.matchFirst(ctRegex!AllowedRegex))
                {
                    textColor = "black";
                    return true;
                }
                else
                {
                    textColor = "red";
                    return false;
                }
            };
        }
        contentChange = (EditableContent content) {
            if (matchFun(content.text))
            {
                // set text to the custom item
            }
        };
    }
}

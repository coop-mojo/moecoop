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
module coop.view.item_edit_dialog;

import dlangui;
import dlangui.dialogs.dialog;

import std.algorithm;
import std.exception;
import std.format;
import std.math;
import std.range;
import std.regex;
import std.traits;

import coop.model.item;
import coop.model.wisdom;
import coop.view.item_detail_frame;

import coop.util;

class ItemEditDialog: Dialog
{
    this(Window parent, Item orig, Wisdom cw)
    {
        super(UIString("アイテム情報編集"d), parent, DialogFlag.Popup);
        original = orig;
        cWisdom = cw;
        if (auto item = original.name in cw.itemList)
        {
            updated = *item;
        }
        else
        {
            updated = original;
        }
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
        with(updated)
        {
            name = item.name;
            properties = item.properties;
            remarks = "";
        }

        auto main = root.childById("main");

        main.addTextElem!("name", true)("名前", item, updated);
        main.addTextElem!"ename"("英名", item, updated);
        main.addTextElem!"weight"("重さ", item, updated);
        main.addTextElem!"price"("NPC売却価格", item, updated);

        auto tr = new HorizontalLayout;
        tr.addCheckElem("転送可", item.transferable, !item.transferable,
                        (b) { updated.transferable = b; return; });

        auto st = new HorizontalLayout;
        st.addCheckElem("スタック可", item.stackable, !item.stackable,
                        (b) { updated.stackable = b; return; });

        main.addChild(tr);
        main.addChild(st);

        auto petCap = new TextWidget("", "ペットアイテム"d);
        auto pet = new HorizontalLayout;
        with(pet)
        {
            auto petTypes = PetFoodType.svalues.to!(dstring[]);

            auto petComboBox = new ComboBox("", petTypes);
            auto textBox = new EditLine("");

            petComboBox.itemClick = (Widget src, int idx) {
                updated.petFoodInfo.clear;
                if (idx == 0 || idx == petTypes.length-1)
                {
                    textBox.text = "";
                    textBox.enabled = false;
                    updated.petFoodInfo[idx.to!PetFoodType] = 0;
                }
                else
                {
                    textBox.enabled = true;
                }
                return true;
            };
            petComboBox.selectedItemIndex = PetFoodType.values.indexOf(item.petFoodInfo.keys[0]).to!int;
            auto i = petComboBox.selectedItemIndex;
            if (i == 0 || i == petTypes.length-1)
            {
                textBox.enabled = false;
            }

            textBox.contentChange = (EditableContent content) {
                auto txt = content.text;
                auto idx = petComboBox.selectedItemIndex;
                if(idx == 0 && idx == petTypes.length-1)
                    return;
                if (!txt.empty && txt.matchFirst(ctRegex!r"^\d+(\.\d+)?$"d))
                {
                    updated.petFoodInfo.clear;
                    updated.petFoodInfo[idx.to!PetFoodType] = txt.to!real;
                    textBox.textColor = "black";
                }
                else
                {
                    textBox.textColor = "red";
                }
            };

            auto key = item.petFoodInfo.keys[0];
            if (key != PetFoodType.UNKNOWN)
            {
                if (key != PetFoodType.NoEatable)
                {
                    textBox.text = item.petFoodInfo[key].to!dstring;
                }
                textBox.enabled = false;
                petComboBox.enabled = false;
            }
            addChild(petComboBox);
            addChild(textBox);
        }
        main.addChild(petCap);
        main.addChild(pet);


        auto propCap = new TextWidget("", "特殊条件"d);
        auto table = new TableLayout;
        table.colCount = 14;
        auto props = item.properties;
        foreach(p; [EnumMembers!SpecialProperty])
        {
            alias updateFun = (bool c) {
                if (c) {
                    updated.properties |= p;
                }
                else
                {
                    updated.properties &= ~p;
                }
            };
            table.addCheckElem(p.to!dstring, (props&p) != 0, (props&p) == 0, updateFun, p.toStrings.join.to!dstring);
            }
        main.addChild(propCap);
        main.addChild(table);

        main.addTextElem!"info"("info", item, updated);
        main.addTextElem!"remarks"("備考", item, updated);

        auto itemTypeCap = new TextWidget("", "種別"d);
        auto itemComboBox = new ComboBox("", ItemType.svalues.to!(dstring[]));
        auto kv = ItemType.values.enumerate.find!"a[1] == b"(item.type).front;
        itemComboBox.selectedItemIndex = kv[0].to!int;
        if (kv[1] != ItemType.UNKNOWN)
        {
            itemComboBox.enabled = false;
        }
        main.addChild(itemTypeCap);
        itemComboBox.itemClick = (Widget src, int idx) {
            updated.type = idx;
            return true;
        };

        auto extraItem = new HorizontalLayout;
        auto extraButton = new Button("", "詳細"d);
        extraItem.addChild(itemComboBox);
        extraItem.addChild(extraButton);
        main.addChild(extraItem);

        extraButton.enabled = false;
        extraButton.click = (Widget _) {
            // showExtraInfoEditDialog(this.window, original);
            return true;
        };

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
                if (original != updated)
                {
                    cWisdom.itemList[updated.name] = updated;
                }
            }
        }
        _parentWindow.removePopup(_popup);
    }
private:
    Item original;
    Item updated;
    Wisdom cWisdom;
}

auto showItemEditDialog(Window parent, Item item, Wisdom cw)
{
    auto dlg = new ItemEditDialog(parent, item, cw);
    dlg.show;
}


auto addTextElem(dstring prop, bool frozen = false)(Widget layout, dstring caption, Item original, ref Item updated)
    if (hasMember!(Item, prop))
{
    mixin("alias PropType = typeof(Item.init."~prop~");");
    auto ref getProp(ref Item i) {
        return mixin("i."~prop);
    }
    auto isValidValue(PropType val)
    {
        static if (isFloatingPoint!PropType)
            return !val.isNaN;
        else static if (is(PropType == dstring))
            return !val.empty;
        else static if (isIntegral!PropType)
            return val > 0;
        else
            static assert(false, "Invalid property type: "~PropType.stringof);
    }
    auto toPropString(PropType val)
    {
        static if (isFloatingPoint!PropType)
        {
            return val.isNaN ? "" : format("%.2f"d, val);
        }
        else
        {
            return val.to!dstring;
        }
    }
    layout.addChild(new TextWidget("", caption));

    dstring elm;
    if (isValidValue(getProp(original)))
    {
        elm = toPropString(getProp(original));
    }
    else
    {
        elm = toPropString(getProp(updated));
    }
    auto editLine = new EditLine("", elm);
    layout.addChild(editLine);

    with(editLine)
    {
        enabled = !isValidValue(getProp(original)) && !frozen;
        enum regex = isFloatingPoint!PropType ? r"^\d+(\.\d+)?$"d :
                     isIntegral!PropType      ? r"^\d+$"d : ""d;
        contentChange = (EditableContent content) {
            auto txt = content.text;
            if (txt.empty || regex.empty || txt.matchFirst(ctRegex!regex))
            {
                textColor = "black";
                getProp(updated) = txt.empty ? PropType.init : txt.to!PropType;
            }
            else
            {
                textColor = "red";
            }
        };
    }
}

auto addCheckElem(Widget layout, dstring caption, bool checked, bool enabled, void delegate(bool) fun, dstring tooltip = "")
{
    auto cap = new TextWidget("", caption);
    layout.addChild(cap);
    auto checkBox = new CheckBox("");
    layout.addChild(checkBox);

    checkBox.checked = checked;
    checkBox.enabled = enabled;

    if (!tooltip.empty)
    {
        cap.tooltipText = tooltip;
        checkBox.tooltipText = tooltip;
    }
    checkBox.checkChange = (Widget _, bool checked) {
        fun(checked);
        return true;
    };
}

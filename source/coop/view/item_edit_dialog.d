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
import std.range;
import std.traits;

import coop.model.item;
import coop.view.item_detail_frame;

import std.stdio;
import std.exception;

class ItemEditDialog: Dialog
{
    this(Window parent, ItemDetailFrame frame)
    {
        super(UIString("アイテム編集"d), parent, DialogFlag.Popup);
        frame_ = enforce(frame);
    }

    override void initialize()
    {
        auto root = parseML(q{
                VerticalLayout {
                    TableLayout {
                        colCount: 2
                        padding: 10
                        minWidth: 400

                        TextWidget { text: "名前" }
                        EditLine { id: name }

                        TextWidget { text: "英名" }
                        EditLine { id: ename }

                        TextWidget { text: "重さ" }
                        EditLine { id: weight }

                        TextWidget { text: "NPC売却価格" }
                        EditLine { id: price }

                        HorizontalLayout {
                            TextWidget { text: "転送可" }
                            CheckBox { id: transferable }
                        }

                        HorizontalLayout {
                            TextWidget { text: "スタック可" }
                            CheckBox { id: stackable }
                        }

                        TextWidget { text: "ペットアイテム" }
                        HorizontalLayout {
                            ComboBox { id: petFoodType }
                            EditLine { id: petFoodEffect }
                        }

                        TextWidget { text: "特殊条件" }
                        TableLayout {
                            colCount: 14
                            TextWidget { id: NTcap; text: "NT" }
                            CheckBox { id: NT }

                            TextWidget { id: OPcap; text: "OP" }
                            CheckBox { id: OP }

                            TextWidget { id: CScap; text: "CS" }
                            CheckBox { id: CS }

                            TextWidget { id: CRcap; text: "CR" }
                            CheckBox { id: CR }

                            TextWidget { id: PMcap; text: "PM" }
                            CheckBox { id: PM }

                            TextWidget { id: NCcap; text: "NC" }
                            CheckBox { id: NC }

                            TextWidget { id: NBcap; text: "NB" }
                            CheckBox { id: NB }

                            TextWidget { id: NDcap; text: "ND" }
                            CheckBox { id: ND }

                            TextWidget { id: CAcap; text: "CA" }
                            CheckBox { id: CA }

                            TextWidget { id: DLcap; text: "DL" }
                            CheckBox { id: DL }

                            TextWidget { id: TCcap; text: "TC" }
                            CheckBox { id: TC }

                            TextWidget { id: LOcap; text: "LO" }
                            CheckBox { id: LO }

                            TextWidget { id: ALcap; text: "AL" }
                            CheckBox { id: AL }

                            TextWidget { id: WAcap; text: "WA" }
                            CheckBox { id: WA }
                        }

                        TextWidget { text: "info" }
                        EditLine { id: info }

                        TextWidget { text: "備考" }
                        EditLine { id: remarks }

                        TextWidget { text: "種別" }
                        ComboBox { id: type }
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

        auto item = frame_.item;

        with(root.childById!EditLine("name"))
        {
            text = item.name;
            enabled = false;
        }

        with(root.childById!EditLine("ename"))
        {
            if (!item.ename.empty)
            {
                text = item.ename;
                enabled = false;
            }
        }

        with(root.childById!EditLine("weight"))
        {
            import std.math;
            import std.format;
            if (!item.weight.isNaN)
            {
                text = format("%.2f"d, item.weight);
                enabled = false;
            }
        }

        with(root.childById!EditLine("price"))
        {
            if (item.price != 0)
            {
                text = item.price.to!dstring;
                enabled = false;
            }
        }

        with(root.childById!CheckBox("transferable"))
        {
            if (item.transferable)
            {
                checked = true;
                enabled = false;
            }
        }

        with(root.childById!CheckBox("stackable"))
        {
            if (item.stackable)
            {
                checked = true;
                enabled = false;
            }
        }

        with(root.childById!EditLine("info"))
        {
            if (!item.info.empty)
            {
                text = item.info;
                enabled = false;
            }
        }

        with(root.childById!EditLine("remarks"))
        {
            if (!item.remarks.empty)
            {
                text = item.remarks;
                enabled = false;
            }
        }

        with(root.childById!ComboBox("petFoodType"))
        {
            import coop.model.item: toStr = toString;
            auto types = [EnumMembers!PetFoodType].map!(t => toStr(t)).array.to!(dstring[]);
            auto textBox = root.childById!EditLine("petFoodEffect");

            items = types;
            itemClick = (Widget src, int idx) {
                if (idx == 0 || idx == types.length-1)
                {
                    textBox.text = "";
                    textBox.enabled = false;
                }
                else
                {
                    textBox.enabled = true;
                }
                return true;
            };
            selectedItemIndex = [EnumMembers!PetFoodType].enumerate.find!"a[1] == b"(item.petFoodInfo.keys[0]).front[0].to!int;
            auto key = item.petFoodInfo.keys[0];
            if (key != PetFoodType.UNKNOWN)
            {
                if (key != PetFoodType.NoEatable)
                {
                    textBox.text = item.petFoodInfo[key].to!dstring;
                }
                textBox.enabled = false;
                enabled = false;
            }
        }

        auto props = item.properties;
        foreach(p; [EnumMembers!SpecialProperty])
        {
            auto tip = p.toStrings.join.to!dstring;
            with(root.childById!CheckBox(p.to!string))
            {
                if (props & p)
                {
                    checked = true;
                    enabled = false;
                }
                tooltipText = tip;
            }
            root.childById(p.to!string~"cap").tooltipText = tip;
        }

        with(root.childById!ComboBox("type"))
        {
            import coop.model.item: toStr = toString;
            auto types = [EnumMembers!ItemType].map!(t => toStr(t)).array.to!(dstring[]);
            items = types;
            auto kv = [EnumMembers!ItemType].enumerate.find!"a[1] == b"(item.type).front;
            selectedItemIndex = kv[0].to!int;
            if (kv[1] != ItemType.UNKNOWN)
            {
                enabled = false;
            }
        }

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
    ItemDetailFrame frame_;
}

auto showItemEditDialog(Window parent, ItemDetailFrame frame)
{
    auto dlg = new ItemEditDialog(parent, frame);
    dlg.show;
}

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
                            TextWidget { text: "NT" }
                            CheckBox { id: NT }

                            TextWidget { text: "OP" }
                            CheckBox { id: OP }

                            TextWidget { text: "CS" }
                            CheckBox { id: CS }

                            TextWidget { text: "CR" }
                            CheckBox { id: CR }

                            TextWidget { text: "PM" }
                            CheckBox { id: PM }

                            TextWidget { text: "NC" }
                            CheckBox { id: NC }

                            TextWidget { text: "NB" }
                            CheckBox { id: NB }

                            TextWidget { text: "ND" }
                            CheckBox { id: ND }

                            TextWidget { text: "CA" }
                            CheckBox { id: CA }

                            TextWidget { text: "DL" }
                            CheckBox { id: DL }

                            TextWidget { text: "TC" }
                            CheckBox { id: TC }

                            TextWidget { text: "LO" }
                            CheckBox { id: LO }

                            TextWidget { text: "AL" }
                            CheckBox { id: AL }

                            TextWidget { text: "WA" }
                            CheckBox { id: WA }
                        }

                        TextWidget { text: "info" }
                        EditLine { id: info }

                        TextWidget { text: "備考" }
                        EditLine { id: remarks }
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

        with(root.childById!EditLine("name"))
        {
            import std.stdio;
            writeln("AAA");
            frame_.item;
            
            writeln("BBB");
            text = frame_.item.name;
            enabled = false;
        }

        with(root.childById!ComboBox("petFoodType"))
        {
            import coop.model.item: toStr = toString;
            auto types = chain([EnumMembers!PetFoodType].map!(t => toStr(t)).array, ["犬も食わない"]).array.to!(dstring[]);
            items = types;
            itemClick = (Widget src, int idx) {
                auto textBox = root.childById!EditLine("petFoodEffect");
                if (idx == 0 || idx == types.length-1)
                {
                    textBox.enabled = false;
                }
                else
                {
                    textBox.enabled = true;
                }
                return true;
            };
            selectedItemIndex = 1;
            // (types.length-1).to!int を設定した場合には textBox は disabled される
            selectedItemIndex = 0;
            invalidate; // 効いてない
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

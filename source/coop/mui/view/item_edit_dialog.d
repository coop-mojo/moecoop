/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.view.item_edit_dialog;
/+
import dlangui;
import dlangui.dialogs.dialog;

import std.traits;

import coop.core.item: overlaid;
// import coop.core.wisdom;
import coop.mui.model.custom_info;
import coop.mui.model.wisdom_adapter;
import coop.mui.view.recipe_tab_frame;
import coop.util;

class ItemEditDialog: Dialog
{

    this(Window parent, RecipeTabFrame fr, ItemInfo orig, int index, CustomInfo ci)
    {
        super(UIString("アイテム情報編集"d), parent, DialogFlag.Popup);
        tabFrame = fr;
        original = orig;
        idx = index;
        customInfo = ci;
        if (auto item = original.name in ci.itemList)
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
        import std.algorithm;
        import std.range;

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

        auto item = overlaid(original, &updated);
        auto main = root.childById("main");

        main.addTextElem!"アイテム名"("名前", item);
        main.addTextElem!"英名"("英名", item);
        main.addTextElem!"重さ"("重さ", item);
        main.addTextElem!"NPC売却価格"("NPC売却価格", item);

        auto tr = new HorizontalLayout;
        tr.addCheckElem("転送可", item.転送可, item.isWritable!"転送可",
                        (b) { item.転送可 = b; return; });

        auto st = new HorizontalLayout;
        st.addCheckElem("スタック可", item.スタック可, item.isWritable!"スタック可",
                        (b) { item.スタック可 = b; return; });

        main.addChild(tr);
        main.addChild(st);

        auto petCap = new TextWidget("", "ペットアイテム"d);
        auto pet = new HorizontalLayout;
        with(pet)
        {
            import std.format;

            import coop.mui.view.editors;
            import coop.util;

            auto petTypes = PetFoodType.svalues.to!(dstring[]);

            auto petComboBox = new ComboBox("", petTypes);
            auto textBox = new EditRealLine("");

            petComboBox.selectedItemIndex = PetFoodType.values.indexOf(item.petFoodInfo.keys[0]).to!int;
            petComboBox.itemClick = (Widget src, int idx) {
                item.ペットアイテム.種別 = petTypes[idx];
                if (idx == 0 || idx == petTypes.length-1)
                {
                    textBox.text = "";
                    textBox.enabled = false;
                    item.ペットアイテム.効果 = 0;
                }
                else
                {
                    textBox.enabled = true;
                    auto txt = textBox.text;
                    item.ペットアイテム.効果 = txt.empty ? 0 : txt.to!real;
                }
                return true;
            };
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
                if (!txt.empty)
                {
                    updated.ペットアイテム.効果 = text.to!real;
                }
            };

            auto type = item.ペットアイテム.種別;
            textBox.enabled = type != PetFoodType.UNKNOWN &&
                              type != PetFoodType.NoEatable &&
                              item.isWritable!"ペットアイテム";
            petComboBox.enabled = item.isWritable!"ペットアイテム";
            textBox.text = (type == PetFoodType.UNKNOWN || type == PetFoodType.NoEatable) ?
                           ""d : format("%.1f"d, item.ペットアイテム.効果);
            addChild(petComboBox);
            addChild(textBox);
        }
        main.addChild(petCap);
        main.addChild(pet);


        auto propCap = new TextWidget("", "特殊条件"d);
        auto table = new TableLayout;
        table.colCount = 14;
        auto props = item.特殊条件;
        foreach(pr; [EnumMembers!SpecialProperty])
        {
            import std.array;

            alias updateFun = p => (bool c) {
                if (c) {
                    auto newElems = updated.properties~p;
                    updated.properties = [EnumMembers!SpecialProperty].filter!(e => newElems.canFind(e)).array;
                }
                else
                {
                    updated.properties = updated.properties.filter!(a => a != p).array;
                }
            };
            table.addCheckElem(pr.to!dstring, props.canFind(pr), item.isWritable!"properties",
                               updateFun(pr), (cast(string)pr).to!dstring);
        }
        main.addChild(propCap);
        main.addChild(table);

        main.addTextElem!"info"("info", item);
        main.addTextElem!"remarks"("備考", item);

        auto itemTypeCap = new TextWidget("", "種別"d);
        auto types = [EnumMembers!ItemType];
        auto itemComboBox = new ComboBox("", (cast(string[])types).to!(dstring[]));
        auto kv = types.enumerate.find!"a[1] == b"(item.type).front;
        itemComboBox.selectedItemIndex = kv[0].to!int;
        itemComboBox.enabled = item.isWritable!"type";
        main.addChild(itemTypeCap);
        itemComboBox.itemClick = (Widget src, int idx) {
            updated.type = cast(ItemType)types[idx];
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
                    customInfo.itemList[updated.name] = updated;
                    updateFrame;
                }
            }
        }
        _parentWindow.removePopup(_popup);
    }
private:

    auto updateFrame()
    {
        import coop.mui.view.item_detail_frame;

        tabFrame.setItemDetail(ItemDetailFrame.create(original.name.to!dstring, idx+1, tabFrame.controller.model, customInfo), idx);
    }

    ItemInfo original;
    ItemInfo updated;
    CustomInfo customInfo;
    RecipeTabFrame tabFrame;
    int idx;
}

auto showItemEditDialog(Window parent, RecipeTabFrame frame, ItemInfo item, int index, CustomInfo ci)
{
    auto dlg = new ItemEditDialog(parent, frame, item, index, ci);
    dlg.show;
}


auto addTextElem(dstring prop)(Widget layout, dstring caption, Overlaid!Item item)
    if (hasMember!(Item, prop))
{
    import coop.mui.view.editors;

    mixin("alias PropType = typeof(Item.init."~prop~");");
    auto toPropString(PropType val)
    {
        static if (isFloatingPoint!PropType)
        {
            import std.format;
            import std.math;

            return val.isNaN ? "" : format("%.2f"d, val);
        }
        else
        {
            return val.to!dstring;
        }
    }
    layout.addChild(new TextWidget("", caption));

    static if (isFloatingPoint!PropType)
    {
        alias ELine = EditRealLine;
    }
    else static if (isIntegral!PropType)
    {
        alias ELine = EditIntLine;
    }
    else
    {
        alias ELine = EditLine;
    }
    auto editLine = new ELine("", toPropString(mixin("item."~prop)));
    layout.addChild(editLine);

    with(editLine)
    {
        enabled = item.isWritable!prop;
        contentChange = (EditableContent content) {
            auto txt = content.text;
            if (enabled)
            {
                import std.range;

                static if (isFloatingPoint!PropType)
                {
                    enum initVal = 0;
                }
                else
                {
                    enum initVal = PropType.init;
                }
                mixin("item."~prop) = txt.empty ? initVal : txt.to!PropType;
            }
        };
    }
}

auto addCheckElem(Widget layout, dstring caption, bool checked, bool enabled, void delegate(bool) fun, dstring tooltip = "")
{
    import std.range;

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
+/


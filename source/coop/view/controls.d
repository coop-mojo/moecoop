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
module coop.view.controls;

import dlangui;

import std.algorithm;
import std.array;
import std.conv;
import std.functional;
import std.range;
import std.traits;
import std.typecons;

import coop.util;

class CheckableEntryWidget: HorizontalLayout
{
    this()
    {
        super();
    }

    this(dstring text)
    {
        super(text.to!string);
        box = new CheckBox(null, ""d);
        link = new LinkWidget(null, text);
        addChild(box);
        addChild(link);
        box.checkChange = (Widget src, bool checked) {
            checkStateChanged(checked);
            return true;
        };
        link.click = (Widget src) {
            detailClicked();
            return true;
        };
    }

    override @property bool checked() { return box.checked; }
    override @property Widget checked(bool c) {
        box.checked = c;
        return this;
    }

    override @property Widget enabled(bool c) {
        box.enabled = c;
        return this;
    }

    auto highlight()
    {
        link.backgroundColor = 0xfffacd;
    }
    auto unhighlight()
    {
        link.backgroundColor = backgroundColor;
    }

    override typeof(this) popupMenu(Fn)(Tuple!(dstring, Fn)[] items) if (isCallable!Fn)
    {
        _menuItems = items.map!"a[1].toDelegate".array;
        auto menu = new MenuItem(null);
        items.map!"a[0]".enumerate.each!((vals) {
                menu.add(new Action(vals[0].to!int, vals[1]));
            });
        popupMenu = menu;
        return this;
    }

    @property override dstring text()
    {
        return link.text;
    }
    alias text = Widget.text;

    @property override Widget textColor(string col)
    {
        link.textColor = col;
        return this;
    }

    EventHandler!(bool) checkStateChanged;
    EventHandler!() detailClicked;
private:
    CheckBox box;
    LinkWidget link;
}

class LinkWidget: TextWidget, MenuItemActionHandler
{
    this()
    {
        super();
        clickable = true;
        styleId = STYLE_CHECKBOX_LABEL;
        enabled = true;
        trackHover = true;
    }

    this(string id, dstring txt)
    {
        super(id, txt);
        clickable = true;
        styleId = STYLE_CHECKBOX_LABEL;
        enabled = true;
        trackHover = true;
    }

    @property MenuItem popupMenu() { return _popupMenu; }
    @property typeof(this) popupMenu(Fn)(Tuple!(dstring, Fn)[] items) if (isCallable!Fn)
    {
        _menuItems = items.map!"a[1].toDelegate".array;
        auto menu = new MenuItem(null);
        items.map!"a[0]".enumerate.each!((vals) {
                menu.add(new Action(vals[0].to!int, vals[1]));
            });
        popupMenu = menu;
        return this;
    }

    override bool canShowPopupMenu(int x, int y)
    {
        if (_popupMenu is null)
        {
            return false;
        }
        if (_popupMenu.openingSubmenu.assigned &&
            !_popupMenu.openingSubmenu(_popupMenu))
        {
                return false;
        }
        return true;
    }

    override void showPopupMenu(int x, int y) {
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
        auto a = action.clone;
        a.objectParam = this;
        return dispatchAction(a);
    }

    override bool handleAction(const Action a)
    {
        if (a)
        {
            if (a.id < _menuItems.length)
            {
                _menuItems[a.id]();
                return true;
            }
        }
        return false;
    }
private:
    MenuItem _popupMenu;
    void delegate()@safe[] _menuItems;
}

import dlangui.widgets.metadata;
mixin(registerWidgets!CheckableEntryWidget);

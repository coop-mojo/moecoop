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

import std.conv;

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

class LinkWidget: TextWidget
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
}

import dlangui.widgets.metadata;
mixin(registerWidgets!CheckableEntryWidget);

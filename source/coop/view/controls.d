/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.controls;

import dlangui;

class CheckableEntryWidget: HorizontalLayout, MenuItemActionHandler
{
    import std.traits;
    import std.typecons;

    import coop.util;

    this()
    {
        super();
    }

    this(string id, dstring text)
    {
        super(id);
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

    override @property bool enabled() {
        return box.enabled;
    }
    override @property Widget enabled(bool c) {
        box.enabled = c;
        return this;
    }

    @property auto highlight()
    {
        link.highlight;
    }

    @property auto unhighlight()
    {
        link.unhighlight;
    }

    @property void popupMenu(MenuItem menu)
    {
        link.popupMenu(menu);
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

    @property override Widget textFlags(uint value)
    {
        return link.textFlags(value);
    }

    override bool canShowPopupMenu(int x, int y)
    {
        return link.canShowPopupMenu(x, y);
    }

    override void showPopupMenu(int x, int y)
    {
        link.showPopupMenu(x, y);
    }

    override bool onMenuItemAction(const Action action)
    {
        return link.onMenuItemAction(action);
    }

    override bool handleAction(const Action a)
    {
        return link.handleAction(a);
    }

    EventHandler!(bool) checkStateChanged;
    EventHandler!() detailClicked;
private:
    CheckBox box;
    LinkWidget link;
}

class LinkWidget: TextWidget, MenuItemActionHandler
{
    import std.traits;
    import std.typecons;

    this()
    {
        super();
        clickable = true;
        styleId = STYLE_CHECKBOX_LABEL;
        enabled = true;
        trackHover = true;
        defaultBackgroundColor = backgroundColor;
    }

    this(string id, dstring txt)
    {
        super(id, txt);
        clickable = true;
        styleId = STYLE_CHECKBOX_LABEL;
        enabled = true;
        trackHover = true;
        defaultBackgroundColor = backgroundColor;
    }

    @property auto highlight()
    {
        backgroundColor = 0xfffacd;
    }

    @property auto unhighlight()
    {
        backgroundColor = defaultBackgroundColor;
    }

    @property void popupMenu(MenuItem menu)
    {
        _popupMenu = menu;
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

    immutable uint defaultBackgroundColor;
private:
    MenuItem _popupMenu;
}

import dlangui.widgets.metadata;
mixin(registerWidgets!CheckableEntryWidget);

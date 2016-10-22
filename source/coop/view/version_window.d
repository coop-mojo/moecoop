/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.version_window;

import dlangui;
import dlangui.dialogs.dialog;

class VersionDialog: Dialog
{
    this(Window parent)
    {
        super(UIString("バージョン情報"d), parent, DialogFlag.Popup);
    }

    override void initialize()
    {
        import std.format;

        import coop.util;

        auto wLayout = parseML(q{
                HorizontalLayout {
                    FrameLayout {
                        id: icon
                    }
                    VerticalLayout {
                        id: info
                        TextWidget {
                            id: name
                        }
                    }
                }
            });
        wLayout.childById("icon").addChild(new ImageWidget(null, "coop-icon-large"));

        wLayout.childById("name").text = verString;
        auto urlButton = new UrlImageTextButton(null, URL, format("%sja/%s/", URL, Version.isRelease ? Version : "latest"));
        urlButton.click = (Widget w) {
            Platform.instance.openURL(w.action.stringParam);
            return true;
        };
        wLayout.childById("info").addChild(urlButton);
        addChild(wLayout);
        auto exits = new HorizontalLayout;
        auto spacer = new HSpacer;
        spacer.minWidth = 300;
        exits.addChild(spacer);
        exits.addChild(new Button(ACTION_CLOSE).minWidth(80).text("閉じる"));
        _buttonActions = [ACTION_CLOSE];
        addChild(exits);
    }

    override void close(const Action action)
    {
        window.removePopup(_popup);
    }

    auto verString()
    {
        import std.format;

        import coop.util;

        auto fmt = Version.isRelease ? "%s %s"d : "%s 生焼け版 (%s)"d;
        return format(fmt, AppName, Version);
    }
}

auto showVersionWindow(Window parent)
{
    auto dlg = new VersionDialog(parent);
    dlg.show;
}

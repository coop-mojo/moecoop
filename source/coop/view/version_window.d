/**
 * Authors: Mojo
 * License: MIT License
 */
module coop.view.version_window;

import dlangui;
import dlangui.dialogs.dialog;

import coop.util;

import std.conv;

class VersionDialog: Dialog
{
    this(Window parent)
    {
        super(UIString("バージョン情報"d), parent, DialogFlag.Popup);
    }

    override void initialize()
    {
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
        wLayout.childById("icon").addChild(new ImageWidget(null, "coop-icon"));
        wLayout.childById("name").text = verString;
        auto urlButton = new UrlImageTextButton(null, URL, URL);
        urlButton.click = (Widget _) {
            Platform.instance.openURL(URL);
            return true;
        };
        wLayout.childById("info").addChild(urlButton);
        addChild(wLayout);
        auto exits = new HorizontalLayout;
        exits.addChild(new HSpacer);
        exits.addChild(new Button(ACTION_OK));
        _buttonActions = [ACTION_OK];
        addChild(exits);
    }

    override void close(const Action action)
    {
        window.removePopup(_popup);
    }

    auto verString()
    {
        import std.algorithm;
        import std.format;
        auto fmt = Version.canFind("-") ? "%s 生焼け版 (%s)"d: "%s %s"d;
        return format(fmt, AppName, Version);
    }
}

auto showVersionWindow(Window parent)
{
    auto dlg = new VersionDialog(parent);
    dlg.show;
}

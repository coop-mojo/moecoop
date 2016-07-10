/**
 * Authors: Mojo
 * License: MIT License
 */
import dlangui;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.typecons;

import coop.model.character;
import coop.model.config;
import coop.model.wisdom;
import coop.view.main_frame;
import coop.util;

version(linux)
{
    static this()
    {
        import etc.linux.memoryerror;
        assert(registerMemoryErrorHandler());
    }
}

mixin APP_ENTRY_POINT;

extern(C) int UIAppMain(string[] args)
{
    auto wisdom = new Wisdom(SystemResourceBase);

    auto cWisdomDir = buildPath(UserResourceBase, "wisdom");
    mkdirRecurse(cWisdomDir);
    auto customWisdom = new Wisdom(cWisdomDir);
    scope(success) customWisdom.save;

    auto config = new Config(buildPath(UserResourceBase, "config.json"));
    scope(success) config.save;
    auto userDir = buildPath(UserResourceBase, "users");
    mkdirRecurse(userDir);

    auto userNames = dirEntries(userDir, SpanMode.shallow)
                     .map!((string s) => s.baseName.to!dstring)
                     .array;
    if (userNames.empty)
    {
        userNames = ["かきあげ"d];
    }
    auto chars = userNames
                 .map!(name => tuple(name, new Character(name, userDir.to!dstring)))
                 .assocArray;
    scope(exit) chars.values.each!(c => c.save);

    Platform.instance.uiLanguage = "ja";
    Platform.instance.uiTheme = "theme_default";
    auto window = Platform.instance.createWindow(AppName, null, WindowFlag.Resizable,
                                                 config.windowWidth,
                                                 config.windowHeight);
    window.mainWidget = new MainFrame(wisdom, chars, config, customWisdom);
    window.show;
    window.onClose = {
        version(Windows) {
            config.windowWidth = pixelsToPoints(window.width);
            config.windowHeight = pixelsToPoints(window.height);
        }
        else {
            config.windowWidth = window.width;
            config.windowHeight = window.height;
        }
    };
    return Platform.instance.enterMessageLoop();
}

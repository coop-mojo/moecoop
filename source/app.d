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
    scope(exit) chars.values.each!(c => c.writeConfig);

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

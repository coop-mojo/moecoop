/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
import dlangui;

version(linux)
{
    version(DMD)
    {
        static this()
        {
            import etc.linux.memoryerror;
            assert(registerMemoryErrorHandler());
        }
    }
}

mixin APP_ENTRY_POINT;

extern(C) int UIAppMain(string[] args)
{
    import std.algorithm;
    import std.array;
    import std.conv;
    import std.file;
    import std.path;
    import std.typecons;

    import coop.core.character;
    import coop.mui.model.config;
    import coop.mui.model.custom_info;
    import coop.core: WisdomModel;
    import coop.core.wisdom: Wisdom;
    import coop.mui.model.wisdom_adapter;
    import coop.mui.view.main_frame;
    import coop.util;

    embeddedResourceList.addResources(embedResourcesFromList!"resources.list"());

    auto wisdom = new Wisdom(SystemResourceBase);

    CustomInfo customInfo;
    auto customInfoFile = buildPath(UserResourceBase, "custom-info.json");

    if (buildPath(UserResourceBase, "wisdom").exists)
    {
        auto cInfoDir = buildPath(UserResourceBase, "wisdom");
        customInfo = new CustomInfo(cInfoDir);
    }
    else
    {
        if (customInfoFile.exists)
        {
            import vibe.data.json;
            customInfo = customInfoFile
                         .readText
                         .parseJsonString
                         .deserialize!(JsonSerializer, CustomInfo);
        }
        else
        {
            customInfo = new CustomInfo;
            customInfo.ver = Version;
        }
    }
    scope(success)
    {
        import std.stdio;
        import vibe.data.json;
        File(customInfoFile, "w").write(customInfo.serializeToPrettyJson);
    }

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
                 .map!(name => tuple(name, new Character(name.to!string, userDir)))
                 .assocArray;
    scope(exit) chars.values.each!(c => c.save);

    Platform.instance.uiLanguage = "ja";
    Platform.instance.uiTheme = "theme_default";
    auto window = Platform.instance.createWindow(AppName, null, WindowFlag.Resizable,
                                                 config.windowWidth,
                                                 config.windowHeight);

    auto model = new WisdomModel(wisdom);
    model__ = new WisdomAdapter(model);
    window.mainWidget = new MainFrame(model, chars, config, customInfo);
    window.windowIcon = drawableCache.getImage("coop-icon");
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

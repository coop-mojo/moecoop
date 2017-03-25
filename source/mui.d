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
    import std.getopt;
    import std.path;
    import std.typecons;

    import coop.mui.model.character;
    import coop.mui.model.config;
    import coop.mui.model.custom_info;
    import coop.mui.model.wisdom_adapter;
    import coop.mui.view.main_frame;
    import coop.util;

    embeddedResourceList.addResources(embedResourcesFromList!"resources.list"());

    string endpoint = "https://moecoop-api.arukascloud.io/";
    version(Windows){}
    else {
        auto helpInfo = args.getopt("endpoint", "知恵袋サーバーのベース URL を指定します。", &endpoint);
        if (helpInfo.helpWanted)
        {
            defaultGetoptPrinter("生協の知恵袋クライアントです。",
                                 helpInfo.options);
            return 0;
        }
    }

    CustomInfo customInfo;
    auto customInfoFile = buildPath(UserResourceBase, "custom-info.json");

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
    scope(success) chars.values.each!(c => c.save);

    Platform.instance.uiLanguage = "ja";
    Platform.instance.uiTheme = "theme_default";
    auto window = Platform.instance.createWindow(AppName, null, WindowFlag.Resizable,
                                                 config.windowWidth,
                                                 config.windowHeight);

    ModelAPI model = new WisdomAdapter(endpoint).wrap!ModelAPI;
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

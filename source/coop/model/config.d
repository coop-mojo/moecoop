/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.model.config;

class Config {
    this(string file)
    {
        import std.file;
        import std.path;

        configFile = file;
        if (file.exists)
        {
            import std.exception;
            import std.json;

            import coop.util;

            auto json = file.readText.parseJSON;
            enforce(json.type == JSON_TYPE.OBJECT);
            windowWidth = json["initWindowWidth"].jto!uint;
            windowHeight = json["initWindowHeight"].jto!uint;
        }
        else
        {
            // デフォルト値を設定
            windowWidth = 400;
            windowHeight = 300;
        }
    }

    auto save()
    {
        import std.file;
        import std.path;
        import std.stdio;

        mkdirRecurse(configFile.dirName);
        auto f = File(configFile, "w");
        f.write(toJSON);
    }

    auto toJSON()
    {
        import std.json;
        auto json = JSONValue([ "initWindowWidth": JSONValue(windowWidth),
                                "initWindowHeight": JSONValue(windowHeight),
                                  ]);
        return json.toPrettyString;
    }
    uint windowWidth, windowHeight;
private:
    string configFile;
}

module coop.config;

import std.conv;
import std.exception;
import std.file;
import std.json;

struct Config {
    this(string file)
    {
        if (file.exists)
        {
            auto json = file.readText.parseJSON;
            enforce(json.type == JSON_TYPE.OBJECT);
            windowWidth = json["initWindowWidth"].integer.to!uint;
            windowHeight = json["initWindowHeight"].integer.to!uint;
            font = json["font"].str;
        }
        configFile = file;
    }

    ~this()
    {
        import std.stdio;
        auto f = File(configFile, "w");
        f.write(toJSON);
    }

    auto toJSON() {
        auto json = JSONValue([ "initWindowWidth": JSONValue(windowWidth),
                                "initWindowHeight": JSONValue(windowHeight),
                                "font": JSONValue(font),
                                  ]);
        return json.to!string;
    }

    uint windowWidth, windowHeight;
    immutable string font;
private:
    string configFile;
}

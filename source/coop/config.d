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
            migemoDLL = json["migemoDLL"].str.to!dstring;
            migemoDict = json["migemoDict"].str.to!dstring;
        }
        else
        {
            // デフォルト値を設定
            windowWidth = 400;
            windowHeight = 300;
            version(Windows) {
                migemoDLL = ""d;
                migemoDict = ""d;
            }
            version(linux) {
                migemoDLL = ""d;
                migemoDict = ""d;
            }
            else version(OSX)
            {
                migemoDLL = "/usr/local/opt/cmigemo/lib/libmigemo.dylib"d;
                migemoDict = "/usr/local/opt/cmigemo/share/migemo/utf-8"d;
            }
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
                                "migemoDLL": JSONValue(migemoDLL.to!string),
                                "migemoDict": JSONValue(migemoDict.to!string),
                                  ]);
        return json.toPrettyString;
    }

    uint windowWidth, windowHeight;
    immutable string font;
    dstring migemoDLL;
    dstring migemoDict;
private:
    string configFile;
}

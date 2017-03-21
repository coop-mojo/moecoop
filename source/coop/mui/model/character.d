/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.model.character;

class Character
{
    import std.container.rbtree;

    this(string n, string baseDir)
    {
        import std.file;
        import std.path;

        dir_ = baseDir;
        name_ = n;
        if (buildPath(dir_, name_).exists)
        {
            import std.algorithm;
            import std.array;
            import std.conv;

            auto binderDir = buildPath(dir_, name_, "バインダー").to!string;
            mkdirRecurse(binderDir);
            filedMap_ = dirEntries(binderDir, "*.json", SpanMode.breadth)
                        .map!(s => s.readBindersInfo)
                        .joiner
                        .assocArray;

            auto configFile = buildPath(dir_, name_, "config.json");
            if (configFile.exists)
            {
                import vibe.data.json;
                url = configFile.readText.parseJsonString["URL"].get!string;
            }
        }
    }

    import coop.common: RecipeInfo;
    auto hasSkillFor(double[string] skill)
    {
        import std.algorithm;
        return skill.byKeyValue.all!(kv => (kv.key in skills) && skills[kv.key] >= kv.value);
    }

    auto hasRecipe(string recipe, string binder = "")
    {
        import std.array;
        import std.algorithm;
        if (binder.empty)
        {
            return filedMap_.values.canFind!(binder => recipe in binder);
        }
        else
        {
            return (binder in filedMap_) && (recipe in filedMap_[binder]);
        }
    }

    auto markFiledRecipe(string recipe, string binder)
    {
        if (binder !in filedMap_)
            filedMap_[binder] = new RedBlackTree!string;
        filedMap_[binder].insert(recipe);
    }

    auto unmarkFiledRecipe(string recipe, string binder)
    in{
        assert(binder in filedMap_);
        assert(recipe in filedMap_[binder]);
    } body {
        filedMap_[binder].removeKey(recipe);
    }

    @property auto name()
    {
        return name_;
    }

    @property auto name(string newName)
    {
        name_ = newName;
    }

    @property auto url() @safe pure nothrow @nogc
    {
        return url_;
    }

    @property auto url(string u)
    {
        import coop.mui.model.skills;
        import std.exception;
        import std.traits;
        import std.typecons;

        url_ = u;
        skills = parseSimulatorURL(url_).ifThrown!SkillSimulatorException(ReturnType!parseSimulatorURL.init)[2];
    }

    auto save()
    {
        import std.conv;
        import std.file;
        import std.path;

        auto dir = buildPath(dir_, name_);
        if (!dir.exists)
        {
            mkdirRecurse(dir.to!string);
        }
        writeURLInfo;
        writeBindersInfo;
    }

    auto deleteConfig()
    {
        import std.conv;
        import std.file;
        import std.path;

        auto configDir = buildPath(dir_, name_);
        if (configDir.exists)
        {
            configDir.to!string.rmdirRecurse;
        }
    }

    auto baseDirectory()
    {
        return dir_;
    }

private:

    auto writeURLInfo()
    {
        import vibe.data.json;
        import std.path;
        import std.stdio;

        auto file = buildPath(dir_, name_, "config.json");
        auto vals = [
            "URL": Json(url),
            ];
        auto f = File(file, "w");
        f.write(vals.serializeToPrettyJson);
    }

    auto writeBindersInfo()
    {
        import std.conv;
        import std.file;
        import std.json;
        import std.path;

        auto binderDir = buildPath(dir_, name_, "バインダー").to!string;
        if (binderDir.exists)
        {
            rmdirRecurse(binderDir);
        }
        mkdirRecurse(binderDir);

        JSONValue[string] binderFiles;
        foreach(kv; filedMap_.byKeyValue)
        {
            import std.algorithm;
            import std.array;
            import std.exception;
            import std.regex;

            auto binder = kv.key.to!string;
            auto elems = kv.value.array;
            if (elems.empty) continue;
            auto fileName = binder
                            .replaceFirst(ctRegex!r" No\.(\d)+$", "")
                            .replaceFirst(ctRegex!r"/", "_")
                            .to!string;
            bool[string] jsonElems;
            elems.each!(r => jsonElems[r.to!string] = true);
            if (fileName !in binderFiles)
            {
                binderFiles[fileName] = JSONValue([binder: jsonElems]);
            }
            else
            {
                enforce(binderFiles[fileName].type == JSON_TYPE.OBJECT);
                binderFiles[fileName][binder] = jsonElems;
            }
        }

        foreach(kv; binderFiles.byKeyValue)
        {
            import std.stdio;
            auto path = buildPath(binderDir, kv.key~".json");
            auto f = File(path, "w");
            f.write(kv.value.toPrettyString);
        }
    }

    RedBlackTree!string[string] filedMap_;
    string name_;
    string dir_;
    string url_;
    double[string] skills;
}

auto readBindersInfo(string file)
{
    import std.algorithm;
    import std.exception;
    import std.file;
    import std.json;

    auto json = file.readText.parseJSON;
    enforce(json.type == JSON_TYPE.OBJECT);
    return json.object.byKeyValue.map!((kv) {
            import std.container.rbtree;
            import std.conv;
            import std.typecons;

            auto binder = kv.key.to!string;
            auto recipes = make!(RedBlackTree!string)(kv.value.object.keys.to!(string[]));
            return tuple(binder, recipes);
        });
}

module coop.model.character;

import std.algorithm;
import std.container.rbtree;
import std.json;
import std.exception;
import std.file;
import std.path;
import std.array;
import std.conv;
import std.regex;

class Character
{
    this(string baseDir)
    {
        dir_ = baseDir;
        name = baseDir.baseName;
        if (dir_.exists)
        {
            filedMap_ = dirEntries(buildPath(dir_, "バインダー"),
                                   "*.json", SpanMode.breadth)
                        .map!(s => s.readBindersInfo)
                        .joiner
                        .assocArray;
        }
    }

    auto hasRecipe(dstring recipe, dstring binder = "")
    {
        if (binder.empty)
        {
            return filedMap_.values.canFind!(binder => recipe in binder);
        }
        else
        {
            return (binder in filedMap_) && (recipe in filedMap_[binder]);
        }
    }

    auto markFiledRecipe(dstring recipe, dstring binder)
    {
        if (binder !in filedMap_)
            filedMap_[binder] = make!(RedBlackTree!dstring)(cast(dstring[])[]);
        filedMap_[binder].insert(recipe);
    }

    auto unmarkFiledRecipe(dstring recipe, dstring binder)
    in{
        assert(binder in filedMap_);
        assert(recipe in filedMap_[binder]);
    } body {
        filedMap_[binder].removeKey(recipe);
    }

    ~this()
    {
        writeBindersInfo;
    }

    immutable string name;
private:

    auto writeBindersInfo()
    {
        auto binderDir = buildPath(dir_, "バインダー");
        if (!binderDir.exists)
        {
            mkdirRecurse(binderDir);
        }

        JSONValue[string] binderFiles;
        foreach(kv; filedMap_.byKeyValue)
        {
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

        auto existingBinders = make!(RedBlackTree!string)(dirEntries(buildPath(dir_, "バインダー"), "*.json", SpanMode.breadth));
        foreach(kv; binderFiles.byKeyValue)
        {
            import std.stdio;
            auto path = buildPath(binderDir, kv.key~".json");
            auto f = File(path, "w");
            f.write(kv.value.toPrettyString);
            existingBinders.removeKey(path);
        }
    }

    RedBlackTree!dstring[dstring] filedMap_;
    string dir_;
}

auto readBindersInfo(string file)
{
    import std.typecons;
    import std.conv;
    auto json = file.readText.parseJSON;
    enforce(json.type == JSON_TYPE.OBJECT);
    return json.object.byKeyValue.map!((kv) {
            auto binder = kv.key.to!dstring;
            auto recipes = make!(RedBlackTree!dstring)(kv.value.object.keys.to!(dstring[]));
            return tuple(binder, recipes);
        });
}

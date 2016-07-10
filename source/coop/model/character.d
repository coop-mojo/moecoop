/**
 * Authors: Mojo
 * License: MIT License
 */
module coop.model.character;

import std.algorithm;
import std.array;
import std.container.rbtree;
import std.conv;
import std.exception;
import std.file;
import std.json;
import std.path;
import std.regex;

class Character
{
    this(dstring n, dstring baseDir)
    {
        dir_ = baseDir;
        name_ = n;
        if (buildPath(dir_, name_).exists)
        {
            auto binderDir = buildPath(dir_, name_, "バインダー"d).to!string;
            mkdirRecurse(binderDir);
            filedMap_ = dirEntries(binderDir, "*.json", SpanMode.breadth)
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
            filedMap_[binder] = new RedBlackTree!dstring;
        filedMap_[binder].insert(recipe);
    }

    auto unmarkFiledRecipe(dstring recipe, dstring binder)
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

    @property auto name(dstring newName)
    {
        name_ = newName;
    }

    auto save()
    {
        writeBindersInfo;
    }

    auto deleteConfig()
    {
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

    auto writeBindersInfo()
    {
        auto binderDir = buildPath(dir_, name_, "バインダー"d).to!string;
        if (binderDir.exists)
        {
            rmdirRecurse(binderDir);
        }
        mkdirRecurse(binderDir);

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

        foreach(kv; binderFiles.byKeyValue)
        {
            import std.stdio;
            auto path = buildPath(binderDir, kv.key~".json");
            auto f = File(path, "w");
            f.write(kv.value.toPrettyString);
        }
    }

    RedBlackTree!dstring[dstring] filedMap_;
    dstring name_;
    dstring dir_;
}

auto readBindersInfo(string file)
{
    import std.typecons;
    auto json = file.readText.parseJSON;
    enforce(json.type == JSON_TYPE.OBJECT);
    return json.object.byKeyValue.map!((kv) {
            auto binder = kv.key.to!dstring;
            auto recipes = make!(RedBlackTree!dstring)(kv.value.object.keys.to!(dstring[]));
            return tuple(binder, recipes);
        });
}

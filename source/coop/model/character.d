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

    @property auto name()
    {
        return name_;
    }

    @property auto name(dstring newName)
    {
        name_ = newName;
    }

    ~this()
    {
        writeBindersInfo;
    }

    auto deleteConfig()
    {
        buildPath(dir_, name_).to!string.rmdirRecurse;
    }

private:

    auto writeBindersInfo()
    {
        auto binderDir = buildPath(dir_, name_, "バインダー"d).to!string;
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

        auto existingBinders = make!(RedBlackTree!string)(dirEntries(buildPath(dir_, name_, "バインダー"d).to!string,
                                                                     "*.json", SpanMode.breadth));
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
    dstring name_;
    dstring dir_;
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

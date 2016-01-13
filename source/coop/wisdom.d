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
module coop.wisdom;

import std.algorithm;
import std.array;
import std.exception;
import std.file;
import std.path;

import coop.union_binder;

struct Wisdom{
    BinderElement[][dstring] binderList;
    immutable string sysBase_;
    immutable string userBase_;

    this(string sysBase, string userBase)
    {
        sysBase_ = sysBase;
        userBase_ = userBase;
        binderList = readBinderList(sysBase, userBase);
    }

    auto readBinderList(string sysBase, string userBase)
    {
        enforce(sysBase.exists);
        enforce(sysBase.isDir);

        return dirEntries(buildPath(sysBase, "バインダー"), "*.json", SpanMode.breadth)
            .map!(s => s.readBinders(sysBase, userBase))
            .joiner
            .assocArray;
    }

    @property auto binders()
    {
        import std.algorithm.sorting;
        import std.range;
        return binderList.keys.sort().array;
    }

    auto recipesIn(dstring name)
    {
        enforce(name in binderList);
        return binderList[name];
    }

    ~this()
    {
        writeBinderList;
    }

    auto writeBinderList()
    {
        import std.json;
        import std.container.rbtree;

        auto userBinderDir = buildPath(userBase_, "バインダー");
        if (!userBinderDir.exists)
        {
            mkdirRecurse(userBinderDir);
        }

        JSONValue[string] binderFiles;
        foreach(kv; binderList.byKeyValue)
        {
            import std.conv;
            import std.regex;
            auto binder = kv.key.to!string;
            auto elems = kv.value.filter!(e => e.isFiled);
            if (elems.empty) continue;
            auto fileName = binder
                            .replaceFirst(ctRegex!r" No\.(\d)+$", "")
                            .replaceFirst(ctRegex!r"/", "_")
                            .to!string;
            bool[string] jsonElems;
            elems.each!(r => jsonElems[r.recipe.to!string] = r.isFiled);
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

        auto existingBinders = make!(RedBlackTree!string)(dirEntries(buildPath(userBase_, "バインダー"), "*.json", SpanMode.breadth));
        foreach(kv; binderFiles.byKeyValue)
        {
            import std.stdio;
            auto path = buildPath(userBinderDir, kv.key~".json");
            auto f = File(path, "w");
            f.write(kv.value.toPrettyString);
            existingBinders.removeKey(path);
        }

        existingBinders[].each!((string file) {
                file.remove;
            });
    }
}

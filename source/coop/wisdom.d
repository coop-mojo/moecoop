module coop.wisdom;
import coop.union_binder;

import std.algorithm;
import std.exception;
import std.file;
import std.path;

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
        import std.array;

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

    auto binderElements(dstring name)
    {
        return name in binderList;
    }

    auto searchBinderElements(dstring name, dstring query)
    {
        import std.range;
        if (auto lst = binderElements(name))
        {
            return (*binderElements(name)).filter!(s => !find(s.recipe, boyerMooreFinder(query)).empty).array;
        }
        else
        {
            return null;
        }
    }

    ~this()
    {
        writeBinderList;
    }

    auto writeBinderList()
    {
        import std.json;

        auto userBinderDir = buildPath(userBase_, "バインダー");
        if (!userBinderDir.exists)
        {
            mkdirRecurse(userBinderDir);
        }

        JSONValue[string] binderFiles;
        foreach(kv; binderList.byKeyValue)
        {
            import std.array;
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

        foreach(kv; binderFiles.byKeyValue)
        {
            import std.stdio;
            auto path = buildPath(userBinderDir, kv.key~".json");
            auto f = File(path, "w");
            f.write(kv.value.toPrettyString);
        }
    }
}

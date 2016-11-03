/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.migemo;

import std.exception;

class MigemoException: Exception
{
    import coop.fallback;
    mixin basicExceptionCtors;
}

alias migemoEnforce = enforceEx!MigemoException;

class Migemo{
    import std.traits;

    this(String)(String path, String dictDir) @trusted if (isSomeString!String)
    in{
        import std.file;

        assert(path.exists);
        assert(path.isFile);
    } body {
        import derelict.util.exception;
        try{
            import std.conv;
            import std.file;
            import std.path;
            import std.string;

            DerelictMigemo.load(path.to!string);
            m = migemo_open(null);
            migemo_setproc_int2char(m, &int2char);
            migemo_setproc_char2int(m, &char2int);

            auto roma2hira = buildPath(dictDir, "roma2hira.dat".to!String);
            if (roma2hira.exists)
            {
                migemoEnforce(migemo_load(m, MIGEMO_DICTID.ROMA2HIRA, roma2hira.to!string.toStringz) != MIGEMO_DICTID.INVALID,
                              "Failed to initialize migemo");
            }
            auto hira2kata = buildPath(dictDir, "hira2kata.dat".to!String);
            if (hira2kata.exists)
            {
                migemoEnforce(migemo_load(m, MIGEMO_DICTID.HIRA2KATA, hira2kata.to!string.toStringz) != MIGEMO_DICTID.INVALID,
                              "Failed to initialize migemo");
            }
        } catch(SharedLibLoadException e) {
            throw new MigemoException("Migemo.dll のロードに失敗しました");
        }
    }

    void load(String)(String path) @trusted if (isSomeString!String)
    {
        import std.conv;
        import std.file;
        import std.format;
        import std.string;

        migemoEnforce(path.exists, format("%s does not exist.", path));
        migemoEnforce(path.isFile, format("%s is not a file.", path));
        migemoEnforce(migemo_load(m, MIGEMO_DICTID.MIGEMO, path.to!string.toStringz) != MIGEMO_DICTID.INVALID,
                      format("Failed to load %s.", path));
    }

    bool isEnable() @trusted nothrow @nogc
    {
        return cast(bool)migemo_is_enable(m);
    }

    auto query(String)(String query) @trusted if (isSomeString!String)
    {
        import std.conv;
        import std.string;

        auto cstr = migemo_query(m, query.to!string.toStringz);
        scope(exit) migemo_release(m, cstr);
        return fromStringz(cstr).idup.to!String;
    }

    ~this() @trusted nothrow @nogc
    {
        migemo_close(m);
    }
private:
    import coop.migemo.derelict.migemo;

    migemo *m;
}

private:
pure nothrow @nogc:

extern(C)
{

    int char2int(const(char)* input, uint* output)
    {
        if (input[0] != '\\')
            return 0;
        switch(input[1])
        {
        case '?':
            *output = '?';
            break;
        case '(':
            *output = '(';
            break;
        case ')':
            *output = ')';
            break;
        default:
            return 0;
        }
        return 2;
    }

    int int2char(uint input, char* output)
    {
        switch(input)
        {
        case '?':
            output[0..2] = `\?`;
            break;
        case '(':
            output[0..2] = `\(`;
            break;
        case ')':
            output[0..2] = `\)`;
            break;
        default:
            return 0;
        }
        return 2;
    }
}

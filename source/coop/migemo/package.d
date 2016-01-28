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
module coop.migemo;

import derelict.util.exception;

import std.conv;
import std.exception;
import std.file;
import std.path;
import std.string;
import std.traits;

import coop.migemo.derelict.migemo;

class MigemoException: Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__,
        Throwable next = null) pure nothrow @nogc @safe
    {
        super(msg, file, line, next);
    }
}

alias migemoEnforce = enforceEx!MigemoException;

class Migemo{
    this(String)(String path, String dictDir) if (isSomeString!String)
    in{
        assert(path.exists);
        assert(path.isFile);
    } body {
        try{
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

    void load(String)(String path) if (isSomeString!String)
    {
        import std.format;

        migemoEnforce(path.exists, format("%s does not exist.", path));
        migemoEnforce(path.isFile, format("%s is not a file.", path));
        migemoEnforce(migemo_load(m, MIGEMO_DICTID.MIGEMO, path.to!string.toStringz) != MIGEMO_DICTID.INVALID,
                      format("Failed to load %s.", path));
    }

    bool isEnable()
    {
        return cast(bool)migemo_is_enable(m);
    }

    auto query(String)(String query) if (isSomeString!String)
    {
        auto cstr = migemo_query(m, query.to!string.toStringz);
        scope(exit) migemo_release(m, cstr);
        return fromStringz(cstr).idup.to!String;
    }

    ~this()
    {
        migemo_close(m);
    }
private:
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

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
module coop.util;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.format;
import std.json;
import std.range;
import std.traits;

immutable SystemResourceBase = "resource";
immutable UserResourceBase = "userdata";
immutable AppName = "生協の知恵袋"d;

struct EventHandler(T...)
{
    void opCall(T args) {
        if (proc == Proc.init)
        {
            // nop
        }
        else
        {
            proc(args);
        }
    }

    auto opAssign(Proc p)
    {
        proc = p;
        return p;
    }
private:
    alias Proc = void delegate(T);
    Proc proc;
}

auto indexOf(Range, Elem)(Range r, Elem e)
    if (isInputRange!Range && is(Elem: ElementType!Range))
{
    return r.enumerate.find!"a[1] == b"(e).front[0];
}

struct BiMap(T, U)
{
    this(T[U] kvs)
    in{
        auto len = kvs.keys.length;
        auto keys = kvs.keys.sort().uniq.array;
        assert(keys.length == len);
        auto vals = kvs.values.sort().uniq.array;
        assert(vals.length == len);
    } body {
        fmap = kvs;
        foreach(kv; kvs.byKeyValue())
        {
            bmap[kv.value] = kv.key;
        }
    }

    auto opUnary(string op)(U key) if (op == "in")
    {
        return key in fmap;
    }

    auto opUnary(string op)(T key) if (op == "in")
    {
        return key in bmap;
    }

    auto ref opIndex(U k) const
    {
        return fmap[k];
    }

    auto ref opIndex(T k) const
    {
        return bmap[k];
    }

    @property auto length()
    {
        return fmap.length;
    }

    @property auto empty()
    {
        return fmap.values.length == 0;
    }

private:
    T[U] fmap;
    U[T] bmap;
}


struct ExtendedEnum(string[] Keys, string[] Values)
{
    static assert(Keys.length == Values.length);

    mixin(format(q{
                enum{
                    %s
                }
            }, Keys.join(", ")));

    int val;
    alias val this;

    this(int m)
    {
        val = m;
    }

    this(S)(S s) if (isSomeString!S)
    {
        val = bimap[s];
    }

    auto toString()
    {
        return bimap[val];
    }

    @property static auto values()
    {
        return mixin(format("[%s]", Keys.join(", ")));
    }

    @property static auto svalues()
    {
        return values.map!(m => bimap[m]).array;
    }

private:
    static BiMap!(string, int) bimap;
    static this()
    {
        mixin(format(q{
                    bimap = [
                        %s
                        ];
                }, zip(Keys, Values).map!(kv => format(q{%s: "%s"}, kv[0], kv[1])).join(", ")));
    }
}

unittest
{
    alias EEnum = ExtendedEnum!(["A", "B", "C"],
                                ["い", "ろ", "は"]);
    assert(EEnum.values == [EEnum.A, EEnum.B, EEnum.C]);
    assert(EEnum.svalues == ["い", "ろ", "は"]);

    EEnum val = EEnum.A;
    assert(val.to!string == "い");
}

auto jto(T)(JSONValue json)
{
    static if (isSomeString!T || is(T == enum))
    {
        enforce(json.type == JSON_TYPE.STRING);
        return json.str.to!T;
    }
    else static if (isIntegral!T)
    {
        enforce(json.type == JSON_TYPE.INTEGER);
        return json.integer.to!T;
    }
    else static if (isFloatingPoint!T)
    {
        enforce(json.type == JSON_TYPE.FLOAT || json.type == JSON_TYPE.INTEGER);
        return json.type == JSON_TYPE.FLOAT ? json.floating.to!T :
            json.integer.to!T;
    }
    else static if (isAssociativeArray!T)
    {
        enforce(json.type == JSON_TYPE.OBJECT);
        return json.object.jto!T;
    }
    else static if (isArray!T)
    {
        enforce(json.type == JSON_TYPE.ARRAY);
        return json.array.jto!T;
    }
    else static if (is(T == bool))
    {
        enforce(json.type == JSON_TYPE.TRUE ||
                json.type == JSON_TYPE.FALSE);
        return json.type == JSON_TYPE.TRUE;
    }
    else static if (__traits(isSame, TemplateOf!T, ExtendedEnum))
    {
        enforce(json.type == JSON_TYPE.STRING);
        return json.str.to!T;
    }
    else
    {
        static assert(false, "Fail to T: "~T.stringof);
    }
}

auto jto(AA: V[K], V, K)(JSONValue[string] json)
{
    import std.typecons;
    return json.keys.map!(k => tuple(k.to!K, json[k].jto!V)).assocArray;
}

auto jto(Array: T[], T)(JSONValue[] json)
    if (!isSomeString!Array)
{
    return json.map!(jto!T).array;
}

unittest
{
    {
        auto i = 3;
        auto ival = JSONValue(i);
        assert(ival.jto!int == i);
    }

    {
        auto s = "foobar";
        auto sval = JSONValue(s);
        assert(sval.jto!string == s);
    }

    {
        auto f = 3.14;
        auto fval = JSONValue(f);
        assert(fval.jto!real == f);
    }

    {
        enum E { A, B, C }
        auto e = E.A;
        auto eval = JSONValue(e.to!string);
        assert(eval.jto!E == e);
    }

    {
        alias EEnum = ExtendedEnum!(["A", "B", "C"],
                                    ["い", "ろ", "は"]);
        EEnum e = EEnum.A;
        auto eval = JSONValue(e.to!string);
        assert(eval.jto!EEnum == e);
    }
}

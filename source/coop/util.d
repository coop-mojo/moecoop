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
import std.meta;
import std.range;
import std.traits;
import std.typecons;

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
    if (isInputRange!Range && is(Elem: ElementType!Range) && !isSomeChar!(ElementType!Range))
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

struct ExtendedEnum(KVs...)
{
    mixin(format(q{
                enum{
                    %s
                }
            }, [staticMap!(ParamName, KVs)].join(", ")));
    enum svalues = [staticMap!(ReturnValue, KVs)];
    enum values = mixin("["~[staticMap!(ParamName, KVs)].join(", ")~"]");

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

private:
    static BiMap!(string, int) bimap;
    static this()
    {
        bimap = zip(values, svalues).assocArray;
    }
}

private enum ReturnValue(alias T) = T!string("");

private enum ParamName(alias T) = {
    import std.string: indexOf;
    auto str = typeof(T!string).stringof;
    str = str[str.indexOf("function(string ") + "function(string ".length .. $];
    return str[0 .. str.indexOf(")")];
}();

version(unittest)
{
    alias util_EEnum = ExtendedEnum!(
        A => "い", B => "ろ", C => "は",
        );
}
unittest
{
    static assert(util_EEnum.values == [util_EEnum.A, util_EEnum.B, util_EEnum.C]);
    static assert(util_EEnum.svalues == ["い", "ろ", "は"]);

    util_EEnum val = util_EEnum.A;
    assert(val.to!string == "い");
    assert("い".to!util_EEnum == val);
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
        util_EEnum e = util_EEnum.A;
        auto eval = JSONValue(e.to!string);
        assert(eval.jto!util_EEnum == e);
    }
}

struct OrderedMap(T: V[K], V, K)
{
    auto opIndex(K k)
    {
        return payload_[k];
    }

    auto opIndexAssign(V v, K k)
    {
        if (k !in payload_)
        {
            keys_ ~= k;
        }
        payload_[k] = v;
    }

    auto opIndexOpAssign(string op)(V v, K k) if (op == "+")
    {
        if (k !in payload_)
        {
            keys_ ~= k;
        }
        payload_[k] += v;
    }

    auto keys()
    {
        return keys_;
    }

    auto values()
    {
        return keys_.map!(k => payload_[k]).array;
    }

    auto byKeyValue()
    {
        alias Pair = Tuple!(K, "key", V, "value");
        return keys_.map!(k => Pair(k, payload_[k]));
    }
private:
    V[K] payload_;
    K[] keys_;

    invariant()
    {
        assert(payload_.keys.length == keys_.length);
    }
}

unittest
{
    OrderedMap!(int[string]) aa;
    aa["foo"] = 3;
    aa["bar"] = 4;
    assert(aa.keys == ["foo", "bar"]);
    assert(aa.values == [3, 4]);
    assert(aa.byKeyValue.map!"a.key".array == aa.keys);
    assert(aa.byKeyValue.map!"a.value".array == aa.values);

    aa["foo"] += 4;
    assert(aa["foo"] == 7);
    assert(aa.keys == ["foo", "bar"]);
}

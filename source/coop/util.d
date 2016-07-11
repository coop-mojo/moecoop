/**
 * Authors: Mojo
 * License: MIT License
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
    this(const T[U] kvs)
    in{
        auto len = kvs.keys.length;
        auto keys = kvs.keys.sort().uniq.array;
        assert(keys.length == len);
        auto vals = kvs.values.dup.sort().uniq.array;
        assert(vals.length == len);
    } body {
        fmap = kvs;
        bmap = kvs.byKeyValue().map!(kv => tuple(kv.value, kv.key)).assocArray;
    }

    auto opBinaryRight(string op)(U key)
        @safe const pure nothrow if (op == "in")
    {
        return key in fmap;
    }

    auto opBinaryRight(string op)(T key)
        @safe const pure nothrow if (op == "in")
    {
        return key in bmap;
    }

    auto ref opIndex(U k) const pure nothrow
    in {
        assert(k in fmap);
    } body {
        return fmap[k];
    }

    auto ref opIndex(T k) const pure nothrow
    in {
        assert(k in bmap);
    } body {
        return bmap[k];
    }

    @property auto length() @safe const pure nothrow
    {
        return fmap.length;
    }

    @property auto empty() const pure nothrow
    {
        return fmap.values.length == 0;
    }

private:
    const T[U] fmap;
    const U[T] bmap;
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

    this(int m) @safe nothrow
    in {
        assert(m in bimap);
    } body {
        val = m;
    }

    this(S)(S s) @safe nothrow if (isSomeString!S)
    in {
        assert(s in bimap);
    } body {
        val = bimap[s];
    }

    auto toString() @safe const nothrow
    {
        return bimap[val];
    }

private:
    // _aaRange cannot be interpreted at compile time
    static const BiMap!(string, int) bimap;
    static this()
    {
        bimap = zip(values, svalues).assocArray;
    }

    invariant
    {
        assert(val in bimap);
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
@safe nothrow unittest
{
    static assert(util_EEnum.values == [util_EEnum.A, util_EEnum.B, util_EEnum.C]);
    static assert(util_EEnum.svalues == ["い", "ろ", "は"]);

    util_EEnum val = util_EEnum.A;
    assert(assertNotThrown(val.to!string) == "い");
    assert("い".to!util_EEnum == val);
}

auto jto(T)(JSONValue json)
{
    static if (isSomeString!T || is(T == enum))
    {
        enforce(json.type == JSON_TYPE.STRING);
        // JSONValue#str is not safe until 2.071.0
        auto s = () @trusted { return json.str; }();
        return s.to!T;
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
        enforce(json.type == JSON_TYPE.ARRAY, "Invalid value: "~json.to!string);
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
        // JSONValue#str is not safe until 2.071.0
        auto s = () @trusted { return json.str; }();
        return s.to!T;
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

@safe nothrow unittest
{
    {
        auto i = 3;
        auto ival = JSONValue(i);
        assert(assertNotThrown(ival.jto!int) == i);
    }

    {
        auto s = "foobar";
        auto sval = JSONValue(s);
        assert(assertNotThrown(sval.jto!string) == s);
    }

    {
        auto f = 3.14;
        auto fval = JSONValue(f);
        assert(assertNotThrown(fval.jto!real) == f);
    }

    {
        enum E { A, B, C }
        auto e = E.A;
        auto eval = JSONValue(assertNotThrown((e.to!string)));
        assert(assertNotThrown(eval.jto!E) == e);
    }

    {
        util_EEnum e = util_EEnum.A;
        auto eval = JSONValue(assertNotThrown(e.to!string));
        assert(assertNotThrown(eval.jto!util_EEnum) == e);
    }
}

version(D_Coverage)
{
    version(unittest)
    {
        extern(C) int UIAppMain(string[] args) {
            return 0;
        }
    }
}

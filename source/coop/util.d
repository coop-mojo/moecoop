/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.util;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.format;
import std.json;
import std.meta;
import std.path;
import std.range;
import std.string;
import std.traits;
import std.typecons;

/// 各種データファイルが置いてあるディレクトリ
immutable SystemResourceBase = buildPath(import("rootdir").strip, "resource");

/// ユーザーの設定ファイルが置いてあるディレクトリ
immutable UserResourceBase = buildPath(import("rootdir").strip, "userdata");

/// プログラム名
immutable AppName = "生協の知恵袋"d;

/// バージョン番号
immutable Version = import("version").chomp;

/// 公式サイト URL
enum URL = "http://docs.fukuro.coop.moe/";

/**
 * バージョン番号 `var` がリリース版を表しているかを返す。
 * リリース版の番号は、`v.a.b.c` となっている (`a`, `b`, `c` は数字)。
 * Returns: `var` がリリース版を表していれば `true`、それ以外は `false`
 */
@property auto isRelease(in string ver) @safe pure nothrow
{
    return !ver.canFind("-");
}

///
@safe pure nothrow unittest
{
    assert(!"v1.0.2-2-norelease".isRelease);
    assert("v1.0.2".isRelease);
}

///
struct EventHandler(T...)
{
    ///
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

    ///
    auto opAssign(Proc p) @safe pure nothrow
    {
        proc = p;
        return p;
    }
private:
    alias Proc = void delegate(T);
    Proc proc;
}

nothrow unittest
{
    EventHandler!int eh1;
    assertNotThrown(eh1(0));

    EventHandler!int eh2;
    eh2 = (int x) { /* nop */ };
    assertNotThrown(eh2(0));
}

///
auto indexOf(Range, Elem)(Range r, Elem e)
    if (isInputRange!Range && is(Elem: ElementType!Range) && !isSomeChar!(ElementType!Range))
{
    auto elm = r.enumerate.find!"a[1] == b"(e);
    return elm.empty ? -1 : elm.front[0];
}

///
@safe pure nothrow unittest
{
    assert([1, 2, 3, 4].indexOf(2) == 1);
    assert([1, 2, 3, 4].indexOf(5) == -1);
}

/**
 * 双方向マップ
 */
struct BiMap(T, U)
{
    ///
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

    ///
    auto opBinaryRight(string op)(U key)
        @safe const pure nothrow if (op == "in")
    {
        return key in fmap;
    }

    ///
    auto opBinaryRight(string op)(T key)
        @safe const pure nothrow if (op == "in")
    {
        return key in bmap;
    }

    ///
    auto ref opIndex(U k) const pure nothrow
    in {
        assert(k in fmap);
    } body {
        return fmap[k];
    }

    ///
    auto ref opIndex(T k) const pure nothrow
    in {
        assert(k in bmap);
    } body {
        return bmap[k];
    }
private:
    const T[U] fmap;
    const U[T] bmap;
}

///
struct ExtendedEnum(KVs...)
{
    mixin(format(q{
                enum{
                    %s
                }
            }, [staticMap!(ParamName, KVs)].join(", ")));
    ///
    enum svalues = [staticMap!(ReturnValue, KVs)];
    ///
    enum values = mixin("["~[staticMap!(ParamName, KVs)].join(", ")~"]");

    int val;
    alias val this;

    ///
    this(int m) @safe nothrow
    in {
        assert(m in bimap);
    } body {
        val = m;
    }

    ///
    this(S)(S s) @safe nothrow if (isSomeString!S)
    in {
        assert(s in bimap);
    } body {
        val = bimap[s];
    }

    ///
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
    ///
    alias util_EEnum = ExtendedEnum!(
        A => "い", B => "ろ", C => "は",
        );
}
///
@safe nothrow unittest
{
    static assert(util_EEnum.values == [util_EEnum.A, util_EEnum.B, util_EEnum.C]);
    static assert(util_EEnum.svalues == ["い", "ろ", "は"]);

    util_EEnum val = util_EEnum.A;
    assert(assertNotThrown(val.to!string) == "い");
    assert("い".to!util_EEnum == val);
}

/**
 * JSONValue から他の方への変換を行う。
 * Params: T = 変換後の型
 *         json = 変換を行う JSONValue
 */
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

/// ditto
auto jto(AA: V[K], V, K)(JSONValue[string] json)
{
    import std.typecons;
    return json.keys.map!(k => tuple(k.to!K, json[k].jto!V)).assocArray;
}

/// ditto
auto jto(Array: T[], T)(JSONValue[] json)
    if (!isSomeString!Array)
{
    return json.map!(jto!T).array;
}

///
@safe nothrow unittest
{
    // 各種プリミティブ型への変換
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

    // JSONValue(int) -> real への変換
    {
        auto i = 3;
        auto fval = JSONValue(i);
        assert(assertNotThrown(fval.jto!real) == i.to!real);
    }

    // ユーザー定義型への変換
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

/**
 * デバッグビルド時に、key の重複時にエラー出力にその旨を表示する std.array.assocArray
 * リリースビルド時には std.array.assocArray をそのまま呼び出す。
 */
auto checkedAssocArray(Range)(Range r) if (isInputRange!Range)
{
    debug
    {
        alias E = ElementType!Range;
        static assert(isTuple!E, "assocArray: argument must be a range of tuples");
        static assert(E.length == 2, "assocArray: tuple dimension must be 2");
        alias KeyType = E.Types[0];
        alias ValueType = E.Types[1];

        ValueType[KeyType] ret;
        return r.fold!((r, kv) {
                auto key = kv[0];
                auto val = kv[1];
                if (auto it = key in r)
                {
                    import std.stdio;
                    stderr.writef("キーが重複しています: %s", key);
                    static if (hasMember!(ValueType, "file") && is(typeof(ValueType.init.file) == string))
                    {
                        stderr.writef(" (%s, %s)", (*it).file, val.file);
                    }
                    stderr.writeln;
                }
                r[key] = val;
                return r;
            })(ret);
    }
    else
    {
        return r.assocArray;
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

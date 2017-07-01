/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.util;

import std.range;
import std.string;
import std.traits;

/// 各種データファイルが置いてあるディレクトリ
immutable SystemResourceBase = "resource";

/// ユーザーの設定ファイルが置いてあるディレクトリ
immutable UserResourceBase = "userdata";

/// プログラム名
immutable AppName = "生協の知恵袋"d;

/// バージョン番号
immutable Version = import("version").chomp;

/// 公式サイト URL
enum MoeCoopURL = "http://docs.fukuro.coop.moe/";

/**
 * バージョン番号 `var` がリリース版を表しているかを返す。
 * リリース版の番号は、`va.b.c` となっている (`a`, `b`, `c` は数字)。
 * Returns: `var` がリリース版を表していれば `true`、それ以外は `false`
 */
@property auto isRelease(in string ver) @safe pure nothrow
{
    import std.algorithm;
    return !ver.canFind("-");
}

///
@safe pure nothrow unittest
{
    assert(!"v1.0.2-2-norelease".isRelease);
    assert("v1.0.2".isRelease);
}

auto toReleaseArray(in string ver) @safe pure
{
    import std.algorithm;
    import std.conv;
    if (ver.isRelease)
    {
        return ver[1..$].split(".").to!(int[])~0;
    }
    else
    {
        auto vers = ver[1..$].split("-");
        return vers[0].split(".").to!(int[])~vers[1].to!int;
    }
}

@safe pure unittest
{
    assert("v1.2.0".toReleaseArray == [1, 2, 0, 0]);
    assert("v1.2.0-39-g591278a".toReleaseArray == [1, 2, 0, 39]);
}

auto versionLT(in string rhs, in string lhs) @safe pure
{
    return rhs.toReleaseArray < lhs.toReleaseArray;
}

@safe pure unittest
{
    assert("v1.2.0".versionLT("v1.2.0-39-g591278a"));
    assert("v1.2.0".versionLT("v1.2.1"));
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
    import std.exception;
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
    import std.algorithm;
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
 * デバッグビルド時に、key の重複時にエラー出力にその旨を表示する std.array.assocArray
 * リリースビルド時には std.array.assocArray をそのまま呼び出す。
 */
auto checkedAssocArray(Range)(Range r) if (isInputRange!Range)
{
    debug
    {
        import std.algorithm;
        import std.traits;
        import std.typecons;
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
                    import dlangui.core.logger;
                    Log.fd("キーが重複しています: %s", key);
                    static if (hasMember!(ValueType, "file") && is(typeof(ValueType.init.file) == string))
                    {
                        Log.fd(" (%s, %s)", (*it).file, val.file);
                    }
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

/**
 * 入力文字列の全角カタカナを半角カタカナに変換した文字列を返す
 * Note: std.string.tarnslate は濁点を含む全角カタカナを処理できない
 */
@property auto toHankaku(Str)(Str str) @safe pure
{
    static Str trans(ElementType!Str c)
    {
        import std.conv;
        switch(c)
        {
        case 'ア': return "ｱ"; case 'イ': return "ｲ"; case 'ウ': return "ｳ"; case 'エ': return "ｴ"; case 'オ': return "ｵ";
        case 'カ': return "ｶ"; case 'キ': return "ｷ"; case 'ク': return "ｸ"; case 'ケ': return "ｹ"; case 'コ': return "ｺ";
        case 'サ': return "ｻ"; case 'シ': return "ｼ"; case 'ス': return "ｽ"; case 'セ': return "ｾ"; case 'ソ': return "ｿ";
        case 'タ': return "ﾀ"; case 'チ': return "ﾁ"; case 'ツ': return "ﾂ"; case 'テ': return "ﾃ"; case 'ト': return "ﾄ";
        case 'ナ': return "ﾅ"; case 'ニ': return "ﾆ"; case 'ヌ': return "ﾇ"; case 'ネ': return "ﾈ"; case 'ノ': return "ﾉ";
        case 'ハ': return "ﾊ"; case 'ヒ': return "ﾋ"; case 'フ': return "ﾌ"; case 'ヘ': return "ﾍ"; case 'ホ': return "ﾎ";
        case 'マ': return "ﾏ"; case 'ミ': return "ﾐ"; case 'ム': return "ﾑ"; case 'メ': return "ﾒ"; case 'モ': return "ﾓ";
        case 'ヤ': return "ﾔ"; case 'ユ': return "ﾕ"; case 'ヨ': return "ﾖ";
        case 'ラ': return "ﾗ"; case 'リ': return "ﾘ"; case 'ル': return "ﾙ"; case 'レ': return "ﾚ"; case 'ロ': return "ﾛ";
        case 'ワ': return "ﾜ"; case 'ヲ': return "ｦ"; case 'ン': return "ﾝ";

        case 'ー': return "ｰ";

        case 'ァ': return "ｧ"; case 'ィ': return "ｨ"; case 'ゥ': return "ｩ"; case 'ェ': return "ｪ"; case 'ォ': return "ｫ";
        case 'ャ': return "ｬ"; case 'ュ': return "ｭ"; case 'ョ': return "ｮ";

        case 'ガ': return "ｶﾞ"; case 'ギ': return "ｷﾞ"; case 'グ': return "ｸﾞ"; case 'ゲ': return "ｹﾞ"; case 'ゴ': return "ｺﾞ";
        case 'ザ': return "ｻﾞ"; case 'ジ': return "ｼﾞ"; case 'ズ': return "ｽﾞ"; case 'ゼ': return "ｾﾞ"; case 'ゾ': return "ｿﾞ";
        case 'ダ': return "ﾀﾞ"; case 'ヂ': return "ﾁﾞ"; case 'ヅ': return "ﾂﾞ"; case 'デ': return "ﾃﾞ"; case 'ド': return "ﾄﾞ";
        case 'バ': return "ﾊﾞ"; case 'ビ': return "ﾋﾞ"; case 'ブ': return "ﾌﾞ"; case 'ベ': return "ﾍﾞ"; case 'ボ': return "ﾎﾞ";
        case 'パ': return "ﾊﾟ"; case 'ピ': return "ﾋﾟ"; case 'プ': return "ﾌﾟ"; case 'ペ': return "ﾍﾟ"; case 'ポ': return "ﾎﾟ";
        default:   return () @trusted { return [c].to!Str; }();
        }
    }
    import std.algorithm;
    return str.map!trans.join;
}

///
@safe pure unittest
{
    assert("アカサタナハマヤラワ".toHankaku == "ｱｶｻﾀﾅﾊﾏﾔﾗﾜ");
    assert("ァャガザダバパ".toHankaku == "ｧｬｶﾞｻﾞﾀﾞﾊﾞﾊﾟ");
    assert("ソート後の表".toHankaku == "ｿｰﾄ後の表");

    // - (ハイフン) と ｰ (半角カタカナ) は似ているが違うので注意！
    assert("ソート後の表".toHankaku != "ｿ-ﾄ後の表");
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

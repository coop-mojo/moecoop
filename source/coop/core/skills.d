/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.core.skills;

enum SkillPon = "http://www.ponz-web.com/skill/";

class SkillSimulatorException: Exception
{
    import std.exception;
    import coop.fallback;
    mixin basicExceptionCtors;
}

/**
 * スキルシミュレーターの URL を読み込んで、(名前、種族、スキル値) のタプルを返す
 */
auto parseSimulatorURL(string url)
{
    import std.algorithm;
    import std.exception;

    if (url.startsWith(SkillPon))
    {
        try{
            import std.array;
            import std.conv;
            import std.typecons;
            import std.uri;

            enum Races = [
                "Invalid", "ニューター", "コグニート", "エルモニー", "パンデモス",
                ];
            enum Skills = [
                "Invalid", "筋力", "着こなし", "攻撃回避", "生命力",
                "知能", "持久力", "精神力", "集中力", "呪文抵抗力",
                "素手", "刀剣", "こんぼう", "槍", "銃器", "弓", "盾",
                "投げ", "牙", "罠", "キック", "戦闘技術", "酩酊",
                "物まね", "調教", "破壊魔法", "回復魔法", "強化魔法",
                "神秘魔法", "召喚魔法", "死の魔法", "魔法熟練", "自然調和",
                "暗黒命令", "取引", "シャウト", "音楽", "盗み", "ギャンブル",
                "パフォーマンス", "ダンス", "落下耐性", "水泳", "死体回収",
                "包帯", "自然回復", "採掘", "伐採", "収穫", "釣り",
                "解読", "料理", "鍛冶", "醸造", "木工", "裁縫", "薬調合",
                "装飾細工", "複製", "栽培", "美容",
                ];

            auto baseStr = url.dup;
            enforce(baseStr.skipOver(SkillPon));
            auto tpl = baseStr[1..$].split("&");
            enforce(tpl.length >= 2);

            // 種族読み込み
            auto race = Races[tpl[0].to!int];

            // スキル値読み込み
            auto app = appender!(Tuple!(int, string)[]);
            auto str = tpl[1];
            while(!str.empty)
            {
                import std.regex;
                auto m = str.matchFirst(ctRegex!r"^(\d{1,2})([a-zA-F]{2})");
                enforce(!m.empty);
                app.put(tuple(m[1].to!int, m[2].assumeUnique));
                str = m.post;
            }

            // 名前読み込み
            auto name = tpl.length == 2 ? "" : tpl[2].decode.to!string;
            return tuple(name,
                         race,
                         app.data
                            .map!(tpl =>
                                  tuple(Skills[tpl[0]],
                                        tpl[1].ponHexToInt/10.0))
                            .assocArray);
        } catch(Exception e) {
            throw new SkillSimulatorException(e.msg, e);
        }
    }
    else
    {
        enforce!SkillSimulatorException(false, "未サポートのサイトです！");
    }
    assert(false);
}

///
unittest
{
    auto url = "http://www.ponz-web.com/skill/?3&1jm4gi6sy28se29cA34ew48Ce49Ce51Fi53Fi55Fi56Fi60ym";
    auto ret = parseSimulatorURL(url);
    assert(ret[0] == "");
    assert(ret[1] == "エルモニー");
    assert(ret[2] == [
               "筋力": 30.0, "生命力": 20.0, "持久力": 60.0,
               "収穫": 90.0, "釣り": 90.0, "料理": 100.0,
               "醸造": 100.0, "裁縫": 100.0, "薬調合": 100.0,
               "美容": 78.0, "神秘魔法": 58.0, "召喚魔法": 9.0,
               "取引": 15.0]);
}

///
unittest
{
    auto url = "http://www.ponz-web.com/skill/?3&1jm4gi6sy28se29cA34ew48Ce49Ce51Fi53Fi55Fi56Fi60ym&%E3%82%82%E3%81%98%E3%82%87%E3%81%B7%E3%83%BC";
    auto ret = parseSimulatorURL(url);
    assert(ret[0] == "もじょぷー");
    assert(ret[1] == "エルモニー");
    assert(ret[2] == [
               "筋力": 30.0, "生命力": 20.0, "持久力": 60.0,
               "収穫": 90.0, "釣り": 90.0, "料理": 100.0,
               "醸造": 100.0, "裁縫": 100.0, "薬調合": 100.0,
               "美容": 78.0, "神秘魔法": 58.0, "召喚魔法": 9.0,
               "取引": 15.0]);
}

unittest
{
    import std.exception;
    assertThrown!SkillSimulatorException(parseSimulatorURL("UnsupportedURL"));
}

unittest
{
    import std.exception;
    assertThrown!SkillSimulatorException(parseSimulatorURL("http://www.ponz-web.com/skill/?デデーン！&"));
}

/**
 * スキるぽんでスキル値の使われている文字列を整数値に変換する。
 * 有効な数字は a-zA-F で、それぞれ32進数の 0-9a-v に対応している。
 */
@property auto ponHexToInt(string str) @safe
{
    import std.conv;
    import std.regex;
    return str.replaceAll!(s => cast(dchar[])[s.hit[0]-'a'+'0'])(ctRegex!"[a-j]")
              .replaceAll!(s => cast(dchar[])[s.hit[0]-'k'+'a'])(ctRegex!"[k-z]")
              .replaceAll!(s => cast(dchar[])[s.hit[0]-'A'+'q'])(ctRegex!"[A-F]")
              .to!int(32);
}

///
@safe unittest
{
    assert("jm".ponHexToInt == 300);
    assert("Fi".ponHexToInt == 1000);
}

/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.server.model.data;

import vibe.data.json;

struct BinderLink
{
    this(string binder, string host)
    {
        import std.path;
        バインダー名 = binder;
        詳細 = buildPath(host, "binders", binder, "recipes");
    }
    string バインダー名;
    string 詳細;
}

struct SkillLink
{
    this(string skill, string host)
    {
        import std.path;
        スキル名 = skill;
        詳細 = buildPath(host, "skills", skill, "recipes");
    }
    string スキル名;
    string 詳細;
}

struct ItemLink
{
    this(string item, string host)
    {
        import std.path;
        アイテム名 = item;
        詳細 = buildPath(host, "items", item);
    }
    string アイテム名;
    string 詳細;
}

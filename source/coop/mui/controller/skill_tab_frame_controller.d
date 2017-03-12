/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.controller.skill_tab_frame_controller;

import coop.mui.controller.recipe_tab_frame_controller;

class SkillTabFrameController: RecipeTabFrameController
{
    import coop.mui.view.recipe_tab_frame;

    this(RecipeTabFrame frame, dstring[] categories)
    {
        import dlangui;
        import std.algorithm;
        import std.array;
        import std.conv;
        import std.exception;
        import std.math: ceil;
        import std.traits;

        import vibe.http.common;
        import vibe.data.json;

        import coop.mui.model.wisdom_adapter;

        super(frame, categories);
        frame.relatedBindersFor = (recipe, _) => recipe.追加情報["収録バインダー"]
                                                       .deserialize!(JsonSerializer, BinderLink[])
                                                       .map!"a.バインダー名"
                                                       .array.to!(dstring[]);
        frame.tableColumnLength = (nRecipes, nColumns) => (nRecipes.to!real/nColumns).ceil.to!int;
        with(frame.childById!ComboBox("sortBy"))
        {
            import std.algorithm;
            import std.range;
            import coop.core: SortOrder;

            items = only(EnumMembers!SortOrder).map!"cast(string)a".array.to!(dstring[])[0..$-1];
            selectedItemIndex = 0;
        }
        auto revSearch = new CheckBox("revSearch", "逆引き検索"d);
        frame.childById("searchOptions").addChild(revSearch);
    }

    override void showRecipeNames()
    {
        import std.algorithm;
        import std.array;
        import std.conv;
        import std.regex;
        import std.typecons;

        import coop.core: SortOrder;
        import coop.mui.model.wisdom_adapter;

        auto query = frame_.queryBox.text == frame_.defaultMessage ? ""d : frame_.queryBox.text;
        if (frame_.useMetaSearch && query.matchFirst(ctRegex!r"^\s*$"d))
        {
            return;
        }

        string key;
        final switch(frame_.sortKey.to!string) with(SortOrder)
        {
        case ByName:
            key = "name";
            break;
        case BySkill:
            key = "skill";
            break;
        case ByBinderOrder:
            key = "default";
            break;
        }
        auto skill = frame_.selectedCategory;
        auto rs = frame_.useMetaSearch
                  ? model.getRecipes(query.to!string, frame_.useMigemo, frame_.useReverseSearch, key, "レシピ必須,必要スキル,収録バインダー").レシピ一覧
                  : model.getSkillRecipes(skill.to!string, query.to!string, frame_.useMigemo, frame_.useReverseSearch, key, "レシピ必須,必要スキル,収録バインダー")
                         .レシピ一覧;

        RecipePair[] recipes;

        if (rs.empty || key == "name")
        {
            recipes = [RecipePair(skill, (RecipeLink[]).init)];
        }
        else
        {
            auto levels(RecipeLink ri)
            {
                import std.exception;
                import vibe.http.common;
                import vibe.data.json;

                import coop.mui.model.wisdom_adapter: RecipeLink;
                auto arr = ri.追加情報["必要スキル"]
                             .deserialize!(JsonSerializer, double[string])
                             .byKeyValue
                             .map!"tuple(a.key, a.value)"
                             .array;
                arr.multiSort!("a[0] < b[0]", "a[1] < b[1]");
                return arr;
            }
            auto lvToStr(Tuple!(string, double)[] tpls)
            {
                import std.format;
                return tpls.map!(t => format("%s (%.1f)"d, t.tupleof)).join(", ");
            }
            recipes = rs.map!(a => tuple(a, levels(a)))
                        .chunkBy!"a[1]"
                        .map!(a => RecipePair(lvToStr(a[0]), a[1].map!"a[0]".array))
                        .array;
        }
        frame_.showRecipeList(recipes);
    }
}

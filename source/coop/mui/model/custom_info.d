/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.model.custom_info;

class CustomInfo
{
    /// バージョン情報
    @name("version") string ver = Version;

    /// アイテムごとの調達価格
    int[string] prices;

    /// アイテムごとのメモ欄
    @optional string[string] memos;

    string[] leafMaterials;
    string[string] recipePreference;
private:
    import vibe.data.json;

    import coop.util;
}

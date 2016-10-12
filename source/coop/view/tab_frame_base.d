/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.tab_frame_base;

import dlangui;

abstract class TabFrameBase: HorizontalLayout
{
    this() { super(); }
    this(string id) { super(id); }

    abstract @property ComboBox charactersBox();

    @property bool useMetaSearch() { return useMeta_; }
    @property void useMetaSearch(bool _) { useMeta_ = _; }

    @property bool useMigemo() { return useMigemo_; }
    @property void useMigemo(bool _) { useMigemo_ = _; }

    @property void enableMigemoBox() {}
    @property void disableMigemoBox() {}

    abstract @property EditLine queryBox();

    dstring defaultMessage = "";
private:
    bool useMeta_, useMigemo_;
}

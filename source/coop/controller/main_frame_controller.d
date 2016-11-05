/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.main_frame_controller;

class MainFrameController
{
    import coop.migemo;
    import coop.core.character;
    import coop.model;
    import coop.model.config;
    import coop.core.wisdom;
    import coop.view.main_frame;

    this(MainFrame frame, WisdomModel model, Character[dstring] chars, Config config, Wisdom customWisdom)
    {
        frame_ = frame;
        // wisdom_ = wisdom;
        model_ = model;
        chars_ = chars;
        config_ = config;
        cWisdom_ = customWisdom;

        // loadMigemo;
    }

    @property auto frame() { return frame_; }
    @property auto config() { return config_; }
    @property auto characters() { return chars_; }
    // @property auto wisdom() { return model.wisdom; }
    @property auto model() { return model_; }
    @property auto cWisdom() { return cWisdom_; }
    // @property auto migemo() { return migemo_; }

    // auto loadMigemo()
    // {
    //     import std.file;

    //     auto info = migemoInfo;

    //     if (info.lib.exists)
    //     {
    //         try{
    //             import std.exception;
    //             import std.path;

    //             migemo_ = new Migemo(info.lib, info.dict);
    //             migemo_.load(buildPath("resource", "dict", "moe-dict"));
    //             enforce(migemo_.isEnable);
    //             frame_.enableMigemo;
    //         } catch(MigemoException e) {
    //             migemo_ = null;
    //             frame_.disableMigemo;
    //         }
    //     }
    // }

    Config config_;
    Character[dstring] chars_;
    Wisdom cWisdom_;
    WisdomModel model_;
    // Migemo migemo_;
    MainFrame frame_;
private:

    // auto migemoInfo()
    // {
    //     import std.algorithm;
    //     import std.file;
    //     import std.range;
    //     import std.typecons;

    //     alias LibInfo = Tuple!(string, "lib", string, "dict");
    //     version(Windows)
    //     {
    //         version(X86)
    //         {
    //             enum candidates = [LibInfo.init];
    //         }
    //         else version(X86_64)
    //         {
    //             enum candidates = [LibInfo(`migemo.dll`, `resource\dict\dict`)];
    //         }
    //     }
    //     else version(linux)
    //     {
    //         import std.format;

    //         version(X86)
    //         {
    //             enum arch = "i386-linux-gnu";
    //         }
    //         else
    //         {
    //             enum arch = "x86_64-linux-gnu";
    //         }
    //         enum candidates = [
    //             // Arch
    //             LibInfo("/usr/lib/libmigemo.so", "/usr/share/migemo/utf-8"),
    //             // Debian/Ubuntu
    //             LibInfo(format("/usr/lib/%s/libmigemo.so.1", arch), "/usr/share/cmigemo/utf-8"),
    //             // Fedora
    //             LibInfo("/usr/lib/libmigemo.so.1", "/usr/share/cmigemo/utf-8"),
    //             ];
    //     }
    //     else version(OSX)
    //     {
    //         enum candidates = [LibInfo("/usr/local/opt/cmigemo/lib/libmigemo.dylib",
    //                                    "/usr/local/opt/cmigemo/share/migemo/utf-8")];
    //     }
    //     auto ret = candidates.find!(a => a.lib.exists);
    //     return ret.empty ? LibInfo.init : ret.front;
    // }
}

mixin template TabController()
{
public:
    import std.format;
    mixin(format("alias FrameType = %s;", typeof(this).stringof[0..$-10]));

    FrameType frame() { return frame_; }

    @property auto config()
    {
        return frame_.root.controller.config;
    }

    @property auto characters()
    {
        return frame_.root.controller.characters;
    }

    @property auto wisdom()
    out(ret)
    {
        assert(ret);
    } body {
        return frame_.root.controller.model.wisdom;
    }

    @property auto model()
    out(ret)
    {
        assert(ret);
    } body {
        return frame_.root.controller.model;
    }

    @property auto cWisdom()
    out(ret)
    {
        assert(ret);
    } body {
        return frame_.root.controller.cWisdom;
    }

    @property auto migemo()
    {
        return frame_.root.controller.model.migemo;
    }
protected:
    FrameType frame_;
}

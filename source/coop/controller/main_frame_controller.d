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
    import coop.model.config;
    import coop.core.wisdom;
    import coop.view.main_frame;

    this(MainFrame frame, Wisdom wisdom, Character[dstring] chars, Config config, Wisdom customWisdom)
    {
        frame_ = frame;
        wisdom_ = wisdom;
        chars_ = chars;
        config_ = config;
        cWisdom_ = customWisdom;

        loadMigemo;
    }

    @property auto frame() { return frame_; }
    @property auto config() { return config_; }
    @property auto characters() { return chars_; }
    @property auto wisdom() { return wisdom_; }
    @property auto cWisdom() { return cWisdom_; }
    @property auto migemo() { return migemo_; }

    auto loadMigemo()
    {
        import dlangui.core.logger;
        import std.file;

        Log.d("Called loadMigemo");
        if (config.migemoLib.exists)
        {
            Log.d("MigemoLib exists");
            try{
                import std.exception;
                import std.path;

                Log.d("Init migemo...");
                migemo_ = new Migemo(config_.migemoLib, config_.migemoDict);
                Log.d("Loading moe-dict...");
                migemo_.load(buildPath("resource", "dict", "moe-dict"));
                enforce(migemo_.isEnable);
                frame_.enableMigemo;
            } catch(MigemoException e) {
                Log.d("Exception occurs");
                migemo_ = null;
                frame_.disableMigemo;
            }
        }
    }

    Config config_;
    Character[dstring] chars_;
    Wisdom wisdom_, cWisdom_;
    Migemo migemo_;
    MainFrame frame_;
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
        return frame_.root.controller.wisdom;
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
        return frame_.root.controller.migemo;
    }
protected:
    FrameType frame_;
}

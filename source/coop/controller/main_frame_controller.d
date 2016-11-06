/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.controller.main_frame_controller;

class MainFrameController
{
    import coop.core.character;
    import coop.model;
    import coop.model.config;
    import coop.core.wisdom;
    import coop.view.main_frame;

    this(MainFrame frame, WisdomModel model, Character[dstring] chars, Config config, Wisdom customWisdom)
    {
        frame_ = frame;
        model_ = model;
        chars_ = chars;
        config_ = config;
        cWisdom_ = customWisdom;
    }

    @property auto frame() { return frame_; }
    @property auto config() { return config_; }
    @property auto characters() { return chars_; }
    @property auto model() { return model_; }
    @property auto cWisdom() { return cWisdom_; }

    Config config_;
    Character[dstring] chars_;
    Wisdom cWisdom_;
    WisdomModel model_;
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
protected:
    FrameType frame_;
}

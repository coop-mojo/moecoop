/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */

version(linux)
{
    version(DMD)
    {
        static this()
        {
            import etc.linux.memoryerror;
            assert(registerMemoryErrorHandler());
        }
    }
}

import vibe.d;

void main()
{
    import coop.core.wisdom;
    import coop.core;
    import coop.server.model;
    import coop.util;

    if (!finalizeCommandLineOptions)
    {
        return;
    }

    auto wisdom = new Wisdom(SystemResourceBase);
    auto model = new WisdomModel(wisdom);

    auto router = new URLRouter;
    router.registerRestInterface(new WebModel(model));
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    listenHTTP(settings, router);
    lowerPrivileges;
    runEventLoop;
}

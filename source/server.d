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

void main(string[] args)
{
    import std.getopt;
    import std.process;

    import coop.server.model.internal;
    import coop.util;

    ushort port = 8080;
    string msg;

    auto hinfo = args.getopt("port|p", &port);

    if (hinfo.helpWanted)
    {
        defaultGetoptPrinter("生協の知恵袋サーバーです。", hinfo.options);
        return;
    }

    auto router = new URLRouter;
    router.any("*", &accControl);
    router.registerRestInterface(new WebModel(SystemResourceBase, environment.get("MOECOOP_MESSAGE", "")));
    auto settings = new HTTPServerSettings;
    settings.port = port;
    listenHTTP(settings, router);
    lowerPrivileges;
    runEventLoop;
}

void accControl(HTTPServerRequest req, HTTPServerResponse res)
{
    res.headers["Access-Control-Allow-Origin"] = "*";
    res.headers["X-Content-Type-Options"] = "nosniff";
}

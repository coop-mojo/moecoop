/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.mui.model.wisdom_adapter;

public import coop.server.model;
import coop.server.model.internal;

alias WisdomAdapter = WebModel;

WisdomAdapter model__;

// class WisdomAdapter
// {
//     this(string endpoint)
//     {
//         this.api = new typeof(api)(endpoint);
//         this.endpoint = endpoint;
//     }

//     alias api this;

//     RestInterfaceClient!ModelAPI api;
// private:
//     import vibe.web.rest;

//     string endpoint;
// }

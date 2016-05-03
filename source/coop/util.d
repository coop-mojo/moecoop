/**
   MoeCoop
   Copyright (C) 2016  Mojo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
module coop.util;

import std.exception;
import std.json;

immutable SystemResourceBase = "resource";
immutable UserResourceBase = "userdata";
immutable AppName = "生協の知恵袋"d;

auto toBool(JSONValue val)
{
    enforce(val.type == JSON_TYPE.TRUE ||
            val.type == JSON_TYPE.FALSE);
    return val.type == JSON_TYPE.TRUE;
}

struct EventHandler(T...)
{
    void opCall(T args) {
        if (proc == Proc.init)
        {
            // nop
        }
        else
        {
            proc(args);
        }
    }

    auto opAssign(Proc p)
    {
        proc = p;
        return p;
    }
private:
    alias Proc = void delegate(T);
    Proc proc;
}

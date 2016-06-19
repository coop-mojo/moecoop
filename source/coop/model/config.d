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
module coop.model.config;

import std.conv;
import std.exception;
import std.file;
import std.format;
import std.json;
import std.path;
import std.process;

import coop.util;

class Config {
    this(string file)
    {
        configFile = file;
        if (file.exists)
        {
            auto json = file.readText.parseJSON;
            enforce(json.type == JSON_TYPE.OBJECT);
            windowWidth = json["initWindowWidth"].jto!uint;
            windowHeight = json["initWindowHeight"].jto!uint;
        }
        else
        {
            // デフォルト値を設定
            windowWidth = 400;
            windowHeight = 300;
        }
        auto migemoDir = buildPath(file.dirName, "libs", "migemo");
        version(Windows)
        {
            migemoLib = buildPath(migemoDir, "migemo.dll");
            migemoDict = buildPath(migemoDir, "dict", "utf-8");
        }
        else version(linux)
        {
            migemoLib = buildPath(migemoDir, "libmigemo.so");
            migemoDict = buildPath(migemoDir, "dict");
        }
        else version(OSX)
        {
            migemoLib = buildPath(migemoDir, "libmigemo.dylib");
            migemoDict = buildPath(migemoDir, "dict");
        }
        initMigemoDir();
    }

    auto save()
    {
        import std.stdio;
        mkdirRecurse(configFile.dirName);
        auto f = File(configFile, "w");
        f.write(toJSON);
    }

    auto toJSON()
    {
        auto json = JSONValue([ "initWindowWidth": JSONValue(windowWidth),
                                "initWindowHeight": JSONValue(windowHeight),
                                  ]);
        return json.toPrettyString;
    }

    auto initMigemoDir()
    {
        import std.typecons;
        alias LibInfo = Tuple!(string, "lib", string, "dict");
        version(Windows)
        {
            version(X86)
            {
                enum bits = "32";
                enum footer = " (x86)";
            }
            else version(X86_64)
            {
                enum bits = "64";
                enum footer = "";
            }
            enum candidates = [
                LibInfo(format(`C:\Program Files%s\cmigemo-default-win%s\migemo.dll`, footer, bits),
                        format(`C:\Program Files%s\cmigemo-default-win%s\dict\utf-8`, footer, bits)),
                ];
        }
        else version(linux)
        {
            version(X86)
            {
                enum arch = "i386-linux-gnu";
            }
            else
            {
                enum arch = "x86_64-linux-gnu";
            }
            enum candidates = [
                // Arch
                LibInfo("/usr/lib/libmigemo.so", "/usr/share/migemo/utf-8"),
                // Debian/Ubuntu
                LibInfo(format("/usr/lib/%s/libmigemo.so.1", arch), "/usr/share/cmigemo/utf-8"),
                // Fedora
                LibInfo("/usr/lib/libmigemo.so.1", "/usr/share/cmigemo/utf-8"),
                ];
        }
        else version(OSX)
        {
            enum candidates = [
                LibInfo("/usr/local/opt/cmigemo/lib/libmigemo.dylib",
                        "/usr/local/opt/cmigemo/share/migemo/utf-8"),
                ];
        }

        auto libDir = migemoLib.dirName;
        if (migemoLib.exists)
        {
            if (migemoLib.isSymlink)
            {
                version(Windows)
                {
                    import std.algorithm;
                    import std.regex;
                    import std.string;
                    // ジャンクション先を調べる方法がない
                    auto line = executeShell(format("dir %s", libDir)).output.lineSplitter.filter!(a => a.matchFirst(ctRegex!"<JUNCTION>")).front;
                    auto libExists = line.matchFirst(ctRegex!`\s\[(.+)\]$`)[1].exists;
                }
                else version(Posix)
                {
                    auto libExists = migemoLib.readLink.exists;
                }
                if (!libExists)
                {
                    import std.file: remove;
                    migemoLib.remove;
                    migemoDict.remove;
                }
            }
        }
        else
        {
            foreach(cand; candidates)
            {
                if (cand.lib.exists && cand.dict.exists)
                {
                    mkdirRecurse(libDir);
                    ln(cand.lib, migemoLib);
                    mkdirRecurse(migemoDict.dirName);
                    ln(cand.dict, migemoDict);
                    break;
                }
            }
        }
    }

    uint windowWidth, windowHeight;
    string migemoLib;
    string migemoDict;
private:
    string configFile;
}

auto ln(string target, string linkname)
{
    version(Windows)
    {
        // ジャンクションを作る API が無い
        enforce(executeShell("mklink /j '%s' '%s'", linkname, target) != 0);
    }
    else version(Posix)
    {
        symlink(target, linkname);
    }
}

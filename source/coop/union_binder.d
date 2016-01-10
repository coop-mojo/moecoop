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
module coop.union_binder;

import std.algorithm;
import std.conv;
import std.exception;
import std.file;
import std.json;
import std.path;
import std.range;
import std.traits;
import std.typecons;

immutable SystemResourceBase = "resource";
immutable BinderResourcePath = buildPath(SystemResourceBase, "バインダー");
immutable UserResourceBase = "userdata";

struct BinderElement{
    this(dstring recipe, bool isFiled = false)
    {
        recipe_ = recipe;
        isFiled_ = isFiled;
    }

    @property auto recipe() const { return recipe_; }
    @property auto isFiled() const { return isFiled_; }
    @property auto isFiled(bool f) { return isFiled_ = f; }

    size_t toHash() const @safe pure nothrow
    {
        return recipe_.hashOf;
    }

    bool opEquals(ref const typeof(this) s) const @safe pure nothrow
    {
        return recipe_ == s.recipe;
    }
private:
    immutable dstring recipe_;
    bool isFiled_;
}

auto readBinders(string systemResourceFile, string sysBase, string userBase)
in{
    assert(systemResourceFile.exists);
} body {
    auto base = systemResourceFile.dirName;
    auto rest = systemResourceFile.drop(sysBase.length+1);
    auto userResourceFile = buildPath(userBase, rest);
    JSONValue[string] userRes;
    if (userResourceFile.exists)
    {
        auto tmp = userResourceFile.readText.parseJSON;
        enforce(tmp.type == JSON_TYPE.OBJECT);
        userRes = tmp.object;
    }

    auto sysRes = systemResourceFile
                  .readText
                  .parseJSON;
    enforce(sysRes.type == JSON_TYPE.OBJECT);
    return sysRes
        .object
        .byKeyValue
        .map!((kv) {
                auto binder = kv.key;
                enforce(kv.value.type == JSON_TYPE.ARRAY);
                auto sysRecipes = kv.value.array.map!(e => e.str).array.to!(dstring[]);
                JSONValue[string] userRecipes;
                if (userRes !is null)
                {
                    if (auto vals = (binder in userRes))
                    {
                        enforce(vals.type == JSON_TYPE.OBJECT);
                        userRecipes = vals.object;
                    }
                }
                return tuple(binder.to!dstring,
                             unionRange(sysRecipes, userRecipes).array);
            });
}

auto unionRange(AA)(dstring[] r, AA aa)
    if (isAssociativeArray!AA)
{
    struct UnionRange
    {
    private:
        dstring[] r_;
        AA aa_;
    public:
        this(dstring[] r, AA aa) {
            r_ = r;
            aa_ = aa;
        }

        @property auto front() {
            auto recipe = r_.front;
            bool isFiled;
            if (auto val = (recipe.to!string in aa_))
            {
                enforce(val.type == JSON_TYPE.TRUE ||
                        val.type == JSON_TYPE.FALSE);
                isFiled = (val.type == JSON_TYPE.TRUE);
            }
            return BinderElement(recipe, isFiled);
        }

        void popFront() {
            r_.popFront();
        }

        @property auto empty() {
            return r_.empty;
        }
    }

    return UnionRange(r, aa);
}

unittest{
    auto r = [
        "foo"d,
        "bar",
        "buzz",
        ];
    auto aa = [
        "bar": JSONValue(true),
        ];

    auto rng = unionRange(r, aa);
    assert(rng.front.recipe == "foo");
    assert(rng.front.isFiled == false);
    rng.popFront;
    assert(rng.front.recipe == "bar");
    assert(rng.front.isFiled == true);
    rng.popFront;
    assert(rng.front.recipe == "buzz");
    assert(rng.front.isFiled == false);
    rng.popFront;
    assert(rng.empty);
}

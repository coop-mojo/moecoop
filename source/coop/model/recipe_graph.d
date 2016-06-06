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
module coop.model.recipe_graph;

import coop.model.wisdom;

import std.algorithm;
import std.container;
import std.conv;
import std.format;
import std.range;
import std.typecons;

class RecipeGraph
{
    this(dstring name, Wisdom w)
    {
        root = init(name, cast(RecipeContainer)null, w);
    }

    auto init(dstring name, RecipeContainer parent, Wisdom w)
    {
        if (auto mat = name in materials)
        {
            return *mat;
        }
        auto mat = new MaterialContainer(name);
        materials[name] = mat;

        if (auto rs = name in w.rrecipeList)
        {
            mat.children = (*rs).map!(r => this.init(r, mat, w)).array;
        }
        else
        {
            materials[name].isProduct = false;
        }
        return mat;
    }

    auto init(dstring name, MaterialContainer parent, Wisdom w)
    {
        if (auto recipe = name in recipes)
        {
            return *recipe;
        }
        auto recipe = new RecipeContainer(name);
        recipes[name] = recipe;

        assert(w.recipeFor(name).name == name);

        recipe.children = w.recipeFor(name)
                           .ingredients.keys
                           .map!(m => this.init(m, recipe, w))
                           .array;
        return recipe;
    }

    override string toString()
    {
        auto rs = make!(RedBlackTree!string)(cast(string[])[]);
        auto ms = make!(RedBlackTree!string)(cast(string[])[]);
        return root.toGraphString(ms, rs);
    }

    MaterialContainer root;

    MaterialContainer[dstring] materials;
    RecipeContainer[dstring] recipes;
}


class RecipeContainer
{
    this(dstring name_)
    {
        name = name_;
    }

    override string toString()
    {
        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0)
    {
        if (name.to!string in rs)
        {
            return format("%sR: %s (already occured)", ' '.repeat.take(lv*2), name);
        }
        rs.insert(name.to!string);
        auto nextLv = lv+1;
        return format("%sR: %s\n%s", ' '.repeat.take(lv*2), name, children.map!(c => c.toGraphString(ms, rs, nextLv)).join("\n"));
    }

    dstring name;
    MaterialContainer[] children;
}

class MaterialContainer
{
    this(dstring name_)
    {
        name = name_;
    }

    auto isLeaf()
    {
        return !isProduct || false;
    }

    override string toString()
    {
        return name.to!string;
    }

    string toGraphString(ref RedBlackTree!string ms, ref RedBlackTree!string rs, int lv = 0)
    {
        if (!isProduct)
        {
            return format("%sM: %s (Leaf)", ' '.repeat.take(lv*2), name);
        }
        else if (name.to!string in ms)
        {
            return format("%sM: %s (already occured)", ' '.repeat.take(lv*2), name);
        }
        ms.insert(name.to!string);
        auto nextLv = lv+1;
        return format("%sM: %s\n%s", ' '.repeat.take(lv*2), name, children.map!(c => c.toGraphString(ms, rs, nextLv)).join("\n"));
    }

    dstring name;
    bool isProduct = true;;
    RecipeContainer[] children;
}

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
module coop.view.layouts;

import dlangui;

import std.algorithm;
import std.range;

auto rows(TableLayout l)
{
    return iota(0, l.childCount)
        .map!(i => l.child(i))
        .chunks(l.colCount)
        .array;
}

auto row(TableLayout l, int i)
{
    return l.rows[i];
}

auto row(TableLayout l, string name)
{
    auto ch = l.childById(name);
    auto idx = l.childIndex(ch);
    return l.row(idx/l.colCount);
}

auto columns(TableLayout l)
{
    return iota(0, l.colCount)
        .map!(i => iota(i, l.childCount, l.colCount).map!(j => l.child(j)).array)
        .array;
}

auto column(TableLayout l, int i)
{
    return l.columns[i];
}

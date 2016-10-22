/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.layouts;

import dlangui;

auto rows(TableLayout l)
{
    import std.algorithm;
    import std.range;

    return iota(0, l.childCount)
        .map!(i => l.child(i))
        .array
        .chunks(l.colCount)
        .array;
}

Widget[] row(TableLayout l, int i)
{
    return l.rows[i];
}

Widget[] row(TableLayout l, string name)
{
    auto ch = l.childById(name);
    if (ch is null)
    {
        return [];
    }
    auto idx = l.childIndex(ch);
    return l.row(idx/l.colCount);
}

auto columns(TableLayout l)
{
    import std.algorithm;
    import std.range;

    return iota(0, l.colCount)
        .map!(i => iota(i, l.childCount, l.colCount).map!(j => l.child(j)).array)
        .array;
}

auto column(TableLayout l, int i)
{
    return l.columns[i];
}

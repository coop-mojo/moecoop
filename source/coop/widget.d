module coop.widget;
import dlangui;
import dlangui.widgets.metadata;

import std.algorithm;
import std.stdio;
import std.range;

import coop.union_binder;
import coop.wisdom;

immutable MaxNumberOfBinderPages = 128;
immutable MaxColumns = 4;

immutable fontName = defaultFontName;

version(Windows) {
    immutable defaultFontName = "MS ゴシック";
}
else version(linux) {
    immutable defaultFontName = "源ノ角ゴシック JP";
}

class MainLayout : HorizontalLayout
{
    this()
    {
        super();
        ownStyle.theme.fontFamily(FontFamily.SansSerif).fontFace(fontName);
    }
}

auto createBinderListLayout(Window parent, ref Wisdom wisdom)
{
    auto layout = cast(MainLayout)parseML(q{
    MainLayout {
        margins: 20; padding: 10
        VerticalLayout {
            ComboBox {
                id: cbOptions
            }

            HorizontalLayout {
                EditLine { id: searchQuery; text: "Search for something" }
                Button { id: searchButton; text: "レシピを検索" }
            }

            TextWidget { text: "レシピ" }
            HorizontalLayout {
                id: recipes
            }
        }
        VerticalLayout {
            Button { text: "レシピ情報"}
            Button { text: "アイテム情報"}
            HorizontalLayout {
                Button { id: btnExit; text: "終了" }
            }
        }
    }
        });

    enum exitFun = (Widget src) { parent.close; return true; };
    layout.childById("btnExit").click = exitFun;

    import std.algorithm.sorting;
    auto keys = ["バインダー"d, "-----"] ~ wisdom.binders;
    layout.childById!ComboBox("cbOptions").items = keys;
    layout.childById!ComboBox("cbOptions").itemClick = (Widget src, int idx) {
        auto key = keys[idx];
        if (auto lst = wisdom.binderElements(key))
        {
            writefln("Binder[%s]", key);
            auto binderElems = layout.childById!HorizontalLayout("recipes");
            binderElems.updateElememnts(*lst);
        }
        return true;
    };

    layout.childById("searchButton").click = (Widget src) {
        auto query = layout.childById("searchQuery").text;
        auto binder = layout.childById!ComboBox("cbOptions").selectedItem;
        auto binderElems = layout.childById!HorizontalLayout("recipes");
        binderElems.updateElememnts(wisdom.searchBinderElements(binder, query));
        return true;
    };
    return layout;
}

void updateElememnts(Recipes)(HorizontalLayout layout, Recipes rs)
    if (isInputRange!Recipes && is(ElementType!Recipes == BinderElement))
{
    layout.removeAllChildren();
    rs.toBinderTableWidget.each!(column => layout.addChild(column));
}

auto toBinderTableWidget(Recipes)(Recipes rs)
    if (isInputRange!Recipes && is(ElementType!Recipes == BinderElement))
{
    return rs
        .map!((ref r) {
                auto box = new CheckBox("recipe", r.recipe.to!dstring);
                box.checked = r.isFiled;
                box.checkChange = (Widget src, bool checked) {
                    r.isFiled = checked;
                    return true;
                };
                return box;
            })
        .chunks(MaxNumberOfBinderPages/MaxColumns)
        .map!((rs) {
                auto l = new VerticalLayout();
                rs.each!(r => l.addChild(r));
                return l;
            });
}

mixin(registerWidgets!(MainLayout)());

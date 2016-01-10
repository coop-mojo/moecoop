import dlangui;
// import coop.union_binder;
import coop.wisdom;
import coop.widget;

mixin APP_ENTRY_POINT;

immutable SystemResourceBase = "resource";
immutable UserResourceBase = "userdata";

/*
  KNOWN ISSUE:

  CheckBox[] に対して ElementType が使えない
    -> init() が .init を上書きしているせい． initialize 等にリネームするべき
    -> masterでは修正済み

  フォント名には "Source Han Sans JP" じゃなくて "源ノ角ゴシック JP" を指定する必要あり
    -> FreeTypeFontManager が別名をちゃんと見てくれていない？
 */

extern(C) int UIAppMain(string[] args)
{
    auto wisdom = Wisdom(SystemResourceBase, UserResourceBase);

    Platform.instance.uiLanguage = "ja";
    Platform.instance.uiTheme = "theme_default";
    auto window = Platform.instance.createWindow("fukuro", null);
    auto layout = createBinderListLayout(window, wisdom);
    window.mainWidget = layout;
    window.show;
    return Platform.instance.enterMessageLoop();
}

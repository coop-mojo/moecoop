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
import dlangui;

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

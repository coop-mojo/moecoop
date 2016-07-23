# 開発に参加したい人向け
ゼロから始めるドキュメント整備ページにようこそ！

## 開発環境のインストール方法
生協では、知恵袋の開発環境をひとまとめにした[生協の知恵袋 裁縫セット](https://hub.docker.com/r/moecoop/docker-fukuro/)を公開しています。
裁縫セットの利用には[Docker](https://www.docker.com/)が必要です。

### Docker のインストール

### 裁縫セットの使い方

- Windows
- Linux
```
$ xhost local:root
$ sudo docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix moecoop/docker-fukuro
```

- Mac

## ビルド方法
```
$ dub build
```

## テスト方法
```
$ dub test
```

## データ構造
## ソース構造

## ライセンス
### 生協の知恵袋のライセンスについて
生協の知恵袋はMIT ライセンスのもとで配布されています。詳細は[LICENSE](https://github.com/coop-mojo/moecoop/blob/master/LICENSE)をご覧ください。
大雑把な説明をすると、MITライセンスは以下の特徴を持ったライセンスです。
- コピー許可
- 再配布許可
- 改変許可
- 商用利用なども許可
- 無保証

ただし改変や再配布、ソースソード(`resource`以下の JSON ファイルも) を利用する場合には、著作権表示をどこかに掲載してください。

よくわからない場合には、
- 再配布するファイル群には[LICENSE](https://github.com/coop-mojo/moecoop/blob/master/LICENSE)も含めてください。
    - ここで配布しているものをそのまま再配布する場合には、特に気にしなくても大丈夫です。
- 別プログラム中でソースコードを利用した場合には、例えば以下の文言を README のどこかに記載してください。

```
Copyright (c) 2016 Mojo
Released under the MIT license
https://github.com/coop-mojo/moecoop/blob/master/LICENSE
```

- また、生協の知恵袋は libcurl ライブラリと C/Migemo ライブラリを利用しています。
  ライブラリを利用している部分を流用する場合には、これらのライブラリの著作権表示を README のどこかに記載してください。
  libcurl と C/Mimemo は、共に MIT ライセンスです。

### 内部で利用しているソフトウェアのライランスについて
生協の知恵袋では以下のソフトウェアが利用されています。

- [libcurl](https://curl.haxx.se/)
```
COPYRIGHT AND PERMISSION NOTICE

Copyright (c) 1996 - 2016, Daniel Stenberg, daniel@haxx.se, and many contributors, see the THANKS file.

All rights reserved.

Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization of the copyright holder.
```

- [C/Migemo](https://www.kaoriya.net/software/cmigemo/)
```
Copyright (c) 2003-2007 MURAOKA Taro (KoRoN)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

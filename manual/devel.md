# 開発に参加したい人向け
ゼロから始めるドキュメント整備ページにようこそ！

## 開発環境のインストール方法
生協では、知恵袋の開発環境をひとまとめにした[生協の知恵袋 お裁縫セット](https://hub.docker.com/r/moecoop/docker-fukuro/)を公開しています。

### 推奨環境
- Windows
  - [Docker toolbox](https://www.docker.com/products/docker-toolbox)
  - [Xming-mesa](http://www.straightrunning.com/XmingNotes/)

- Linux
  - [Docker](https://www.docker.com/)
  - [Xサーバー](https://www.x.org/wiki/)
      - 通常はどちらも、パッケージ管理システム経由でインストールできます。

- Mac
  - まだ未検証

### 裁縫セットの使い方

- Windows
  - 事前に、PC の IP アドレスをご確認ください。通常は `ipconfig` で確認できます。
  - デスクトップにできた `Docker Quickstart Terminal` を開いて、以下の `$` もしくは `#` 以降を入力してください。
```
$ export DISPLAY=$ip:0.0
$ export PATH=/c/Program\ Files\ \(x86\)/Xming:$PATH
$ run Xming :0 -multiwindow -ac -clipboard
$ docker run -it --rm -e DISPLAY=$DISPLAY moecoop/docker-fukuro
```

- Linux
  - 事前に、docker デーモンが動作していることを確認してください。
```
$ xhost local:root
$ sudo docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix moecoop/docker-fukuro
```

- Mac
  - まだ未検証

### ビルド方法
Windows 環境の X サーバーと、知恵袋が使用している GUI ライブラリの相性問題のため、
環境によってビルド方法が若干異なるのでご注意ください。

- Windows 環境
```
# dub build -c fallback
```

- Linux、Mac 環境
```
# dub build
```

### 実行方法
- Windows 環境
```
# dub run -c fallback
```

- Linux、Mac 環境
```
# dub run
```

### テスト方法
```
# dub test
```

### ファイルを編集したい
- お裁縫セットではエディタは提供していません。以下のように、ローカルから知恵袋のリポジトリを参照できるようにしてから、お好みのエディタで編集してください。

```
## Windows 環境
$ sudo docker run -it --rm -v //c/Users/foo/repository:/work -e DISPLAY=$DISPLAY moecoop/docker-fukuro

## Linux 環境
$ sudo docker run -it --rm -v ~/repository:/work -v /tmp/.X11-unix:/tmp/.X11-unix moecoop/docker-fukuro
```

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

### 生協の知恵袋 お裁縫セットのライセンスについて
生協の知恵袋 お裁縫セットのリポジトリ内のファイルは、CC0 のもとで配布されています。詳細は[LICENSE](https://github.com/coop-mojo/docker-fukuro/blob/master/LICENSE)をご覧ください。

### 知恵袋が内部で利用しているソフトウェアのライランスについて
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

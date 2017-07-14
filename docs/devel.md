# 開発に参加したい人向け
ゼロから始める知恵袋開発ページにようこそ！

## バグ報告や要望について
バグ報告や機能追加の要望などは、[Github の Issues](https://github.com/coop-mojo/moecoop/issues)か、[FS生協の Twitter アカウント](https://twitter.com/coop_moe)にどうぞ！

## 生協の知恵袋の開発をしたい人向け

### ビルドやテストの方法について
#### ビルドに必要なソフトウェア
知恵袋の取得・ビルドには以下のプログラムが必要です。

- git (バージョン管理システム)
    - 知恵袋のソースの取得やビルドをするのに必要です。また生協に知恵袋のバグ修正や機能追加の要望を出す際にも使えます。
- dmd、dub (コンパイラとビルドツール)
    - 知恵袋のビルドに必要です。
- MkDocs (ドキュメント生成システム)
    - このドキュメントを生成するのに必要です。

各コマンドのインストール方法は環境ごとに異なるため、ここでは省略します。
手元にビルドツールを用意せずに開発を行う方法については、[知恵袋のビルドに利用している各種ウェブサービスについて](#_8)を参考にしてください。

#### ソースの取得方法
- 以下のコマンドで取得できます。
```console
$ git clone https://github.com/coop-mojo/moecoop.git
```

#### ビルド方法
生協の知恵袋はサーバーとクライアントから構成されるソフトウェアです。

- 知恵袋サーバーをビルドする場合には以下のコマンドを実行してください。ビルドディレクトリに `fukurod` が生成されます。
```console
$ dub build -c server
```

- 以下のコマンドを実行することで、知恵袋サーバーを動かすための Docker イメージを作成することができます。
```console
$ ./archive.sh && docker build -t moecoop .
```

- 知恵袋クライアントをビルドする場合には以下のコマンドを実行してください。ビルドディレクトリに `fukuro` が生成されます。
```conslole
$ dub build
```

#### テスト方法
```console
$ dub test
```

### 知恵袋のビルドに利用している各種ウェブサービスについて
生協の知恵袋は以下のウェブサービスを使用して、各環境のテストやビルドを行っています。

- [Github](https://github.com/)
    - 知恵袋のソースコードの管理
- [Travis CI](https://travis-ci.org/)
    - Linux、Mac 環境でのビルドテスト、知恵袋サーバーの Docker イメージ作成
- [AppVeyor](https://www.appveyor.com/)
    - Windows 環境でのビルドテスト、Windows 環境用の生焼け版の作成
- [Coveralls](https://coveralls.io/)
    - ソースコードのカバレッジの確認
- [Dockerhub](https://hub.docker.com/)
    - Travis CI でビルドした Docker イメージの保管
- [Read the Docs](https://readthedocs.org/)
    - 作成したドキュメントの公開
- [Google Cloud Platform](https://cloud.google.com/?hl=ja)
    - 知恵袋サーバーのホスティング
- [swagger.io](http://swagger.io/)
    - 知恵袋サーバーの API 仕様の公開、API 仕様の編集

## 生協の知恵袋 API を使って開発をしたい人向け

生協の知恵袋サーバーは API 仕様が公開されているため、知恵袋 API を利用したソフトウェアの開発も可能です。
API の仕様については [swagger-ui](http://petstore.swagger.io/?url=https://raw.githubusercontent.com/coop-mojo/moecoop-common/master/api/swagger.yml) か [swagger-editor](http://editor.swagger.io/?url=https://raw.githubusercontent.com/coop-mojo/moecoop-common/master/api/swagger.yml) をご覧ください。


## ライセンス
### 生協の知恵袋のライセンスについて
生協の知恵袋は MIT ライセンスのもとで配布されています。詳細は [LICENSE](https://github.com/coop-mojo/moecoop/blob/master/LICENSE) をご覧ください。
大雑把な説明をすると、MIT ライセンスは以下の特徴を持ったライセンスです。

- コピー許可
- 再配布許可
- 改変許可
- 商用利用なども許可
- 無保証

ただし改変や再配布、ソースソードを利用する場合には、著作権表示をどこかに掲載してください。

よくわからない場合には、

- 再配布するファイル群には [LICENSE](https://github.com/coop-mojo/moecoop/blob/master/LICENSE) も含めてください。
    - ここで配布しているものをそのまま再配布する場合には、特に気にしなくても大丈夫です。
- 別プログラム中でソースコードを利用した場合には、例えば以下の文言を README のどこかに記載してください。

```
Copyright (c) 2016 Mojo
Released under the MIT license
https://github.com/coop-mojo/moecoop/blob/master/LICENSE
```

- また、生協の知恵袋は C/Migemo ライブラリを利用しています。
  ライブラリを利用している部分を流用する場合には、ライブラリの著作権表示を README のどこかに記載してください。
  C/Mimemo は MIT ライセンスです。

### 知恵袋が内部で利用しているソフトウェアのライランスについて
生協の知恵袋では以下のソフトウェアが利用されています。

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

## 生協の知恵袋 お裁縫セットについて
生協の知恵袋の開発に必要なソフトウェアをひとまとめにした[生協の知恵袋 お裁縫セット](https://github.com/coop-mojo/docker-fukuro) ([Dockerhub](https://hub.docker.com/r/moecoop/docker-fukuro/))は、
遠い未来にリニューアル予定です…

### 生協の知恵袋 お裁縫セットのライセンスについて
生協の知恵袋 お裁縫セットのリポジトリ内のファイルは、CC0 のもとで配布されています。詳細は [LICENSE](https://github.com/coop-mojo/docker-fukuro/blob/master/LICENSE) をご覧ください。

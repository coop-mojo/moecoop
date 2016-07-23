# 生協の知恵袋

[![GitHub version](https://badge.fury.io/gh/coop-mojo%2Fmoecoop.svg)](https://badge.fury.io/gh/coop-mojo%2Fmoecoop)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/coop-mojo/moecoop/blob/master/LICENSE)
[![Documentation Status](https://readthedocs.org/projects/moecoop/badge/?version=latest)](http://docs.fukuro.coop.moe/ja/latest/?badge=latest)
[![Build Status](https://travis-ci.org/coop-mojo/moecoop.svg?branch=master)](https://travis-ci.org/coop-mojo/moecoop)
[![Build status](https://ci.appveyor.com/api/projects/status/9lju6b2f0y411x2a/branch/master?svg=true)](https://ci.appveyor.com/project/coop-mojo/moecoop/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/coop-mojo/moecoop/badge.svg?branch=master)](https://coveralls.io/github/coop-mojo/moecoop?branch=master)


生協の知恵袋は，[Master of Epic](http://moepic.com/top.php?mid=_) のバインダーやアイテム・レシピ情報を見るためのツールです．

リリース版は[リンク先](https://github.com/coop-mojo/moecoop/releases/latest)から`moecoop-*.zip`をダウンロードしてご利用ください．

また，開発中の生焼け版の公開を始めました([64bit版](https://ci.appveyor.com/api/projects/coop-mojo/moecoop/artifacts/moecoop-trunk-64bit.zip?branch=master&job=Environment%3a%20arch%3dx64)、[32bit版](https://ci.appveyor.com/api/projects/coop-mojo/moecoop/artifacts/moecoop-trunk-32bit.zip?branch=master&job=Environment%3A%20arch%3Dx86))．登録されているアイテム情報や新機能が増えているかもしれないですが，生焼けなので試すとお腹を壊したり爆発したり，鼻から LoC が出てくるかもしれません．

## 使い方
[マニュアル](http://docs.fukuro.coop.moe)をご覧ください。

## できること
- バインダーに登録されているレシピの管理
  - キャラクターごとのバインダー管理
  - 各バインダー内のレシピ検索
- 料理や醸造，調合等の生産スキルごとのレシピの確認
  - 各スキル内のレシピ検索
- 生産したいアイテムを複数個作成するのに必要な素材やレシピの確認
- レシピの詳細確認
- アイテムの詳細確認 (まだ一部)
  - 食事バフ等の詳細情報の確認 (まだ一部)
- バインダー内のレシピを検索
- 複数のバインダーや必要スキルからレシピをまとめて検索

- [C/Migemo](http://www.kaoriya.net/software/cmigemo/) を利用したいい感じの検索 (Windows 版では、オプションからインストールできます)
  - katsu でカツ丼やカツを検索できます (ローマ字のまま検索)
  - cookie でクッキーを，bread でパンを検索できます (英語でも検索)
  - soi でソード オブ インフェルノを検索できます (略称検索)

## そのうちやりたいこと

- レシピ完全対応
  - 順次作業中
- アイテム完全対応
  - 順次作業中
- 生産道具の性能確認
- レシピで作れるアイテムの価格の自動計算
- NPC店舗での販売アイテムの確認
- 各クエストでもらえるアイテムの確認
- 指定したスキルの範囲内で作れるレシピの検索
- 指定したアイテムを，端数が出ないように作成するための支援機能
- ルーレットのMGマス等の数の確認
  - 成功マスの算出式がわからないので対応できないかも．情報求む．
- 一番下に生協の広告を入れる
```
＿人人人人人人人人人人人人人＿
＞　グリードルの煮凝り@35g　＜
￣Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y
```

新機能の要望等は[Issues](https://github.com/coop-mojo/moecoop/issues)に登録してくれたら対応するかもしれません．
- 画面右上の `New Issue` をクリックして登録できます (Github のアカウントが必要です)．

## できないこと

- 選んだアイテムを自動で取ってくる機能
- 欲しいアイテムを値切る機能
- 御庭番を召喚する機能

## 開発に参加したい人向け

マニュアルの[開発者向けページ](http://docs.fukuro.coop.moe/ja/latest/devel.html)にどうぞ！

生協の知恵袋の作成には以下が必要です．

- DMD (D言語処理系)
- DUB (D言語のパッケージマネージャ)

DMD と DUB は，Windows のパッケージマネージャーの[chocolatey](https://chocolatey.org)からインストールできます．

生協の知恵袋は，Windows，Linux，Mac 環境で動作するマルチプラットフォームアプリケーションです．

## レシピやアイテムを追加したい人向け

resource 以下を編集することで，レシピやアイテム，食事バフ等の追加や編集を行えます．
以下がフォルダ構成です．

- `resource`
  - `バインダー`
    - 各バインダーに登録されているレシピ名の情報
    - 例えば `食べ物.json` 等には，`食べ物`，`食べ物 No.2`，`食べ物 No.3` のバインダー情報が書かれています．
  - `食べ物`
    - 効果や食事バフ等の，食べ物固有の情報
    - `食べ物.json` に情報が書かれています．
    - 量が多いため，中間素材や肉料理等のカテゴリごとにファイルを分けるかも
  - `飲み物`
    - 効果や飲み物バフ等の，飲み物固有の情報
    - `飲み物.json` に情報が書かれています．
  - `飲食バフ`
    - 飲食バフの効果時間やグループ等の詳細情報
    - `食べ物バフ.json` に食べ物バフ，`飲み物.json` に飲み物バフの情報が書かれています．
    - 1つのファイルにまとめるかも
  - `武器`
    - 攻撃力や射程等の武器固有の情報
    - `武器.json` に情報を追加する予定ですが，まだ仕様が決まっていません．
    - 刀剣や槍等の武器カテゴリごとにファイルを分けるかも
  - `素材`
    - 重さやNPCへの売却価格等の，全てのアイテムに共通する情報
    - ペットアイテム情報はここに書かれています
    - 他と同様にファイルを分けるかも
  - `レシピ`
    - 必要な素材や要求されるスキル等の詳細情報
    - `料理.json` や `鍛冶.json` 等，[Moe Wiki](http://moeread.usamimi.info/index.php?MoE%20Wiki%20-%20Master%20of%20Epic)の各カテゴリごとに分割されています．
  - `クエスト`
    - まだ仕様が決まっていません．
    - 大体愛のかけらのせい
  - `dict`
    - Migemo 検索で使用するための辞書ファイル
    - `moe-dict` が辞書ファイルです．

データは全てテキストとして保存されているため，テキストエディタで編集を行えます．
- Migemo の辞書ファイルである `moe-dict` の各行は変換前の単語，タブ，変換後の単語が順に並んでいます．
- `moe-dict` 以外のファイルは [JSON 形式](https://ja.wikipedia.org/wiki/JavaScript_Object_Notation)で書かれています．
  - 各ファイルの詳細は，`doc/spec` 以下のファイルに書かれています．
  - 読めば大体の構造はわかるかも
- メモ帳には `resource` 以下のファイルをまともに編集するための機能が備わっていないため，[サクラエディタ](http://sakura-editor.sourceforge.net) や [Atom](https://atom.io) 等の他のエディタを使いましょう．

## このドキュメントに不足しているもの

- データ仕様
  - 各ファイル形式の詳細を追加する
  - 追加，修正したものを送る方法を追加する

## ライセンス
### 生協の知恵袋のライセンスについて
MIT ライセンスです。 詳細は[LICENSE](LICENSE)をご覧ください。

### 内部で利用しているソフトウェアのライランスについて
また、生協の知恵袋では以下のソフトウェアが利用されています。
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

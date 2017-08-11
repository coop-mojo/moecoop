# 生協の知恵袋

[![GitHub version](https://badge.fury.io/gh/coop-mojo%2Fmoecoop.svg)](https://badge.fury.io/gh/coop-mojo%2Fmoecoop)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/coop-mojo/moecoop/blob/master/LICENSE)
[![Documentation Status](https://readthedocs.org/projects/moecoop/badge/?version=latest)](http://docs.fukuro.coop.moe/ja/latest/?badge=latest)
[![Build Status](https://travis-ci.org/coop-mojo/moecoop.svg?branch=master)](https://travis-ci.org/coop-mojo/moecoop)
[![Build status](https://ci.appveyor.com/api/projects/status/9lju6b2f0y411x2a/branch/master?svg=true)](https://ci.appveyor.com/project/coop-mojo/moecoop/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/coop-mojo/moecoop/badge.svg?branch=master)](https://coveralls.io/github/coop-mojo/moecoop?branch=master)


生協の知恵袋は，[Master of Epic](http://moepic.com/top.php?mid=_) のバインダーやアイテム・レシピ情報を見るためのツールです．

リリース版は[リンク先](https://github.com/coop-mojo/moecoop/releases/latest)から`moecoop-*.zip`をダウンロードしてご利用ください．

また，開発中の生焼け版の公開を始めました([64bit版](https://ci.appveyor.com/api/projects/coop-mojo/moecoop/artifacts/moecoop-trunk-64bit.zip?branch=master&job=Environment%3A%20DC%3Ddmd%2C%20DVersion%3D2.075.0%3B%20Platform%3A%20x64)、[32bit版](https://ci.appveyor.com/api/projects/coop-mojo/moecoop/artifacts/moecoop-trunk-32bit.zip?branch=master&job=Environment%3A%20DC%3Ddmd%2C%20DVersion%3D2.075.0%3B%20Platform%3A%20x86))．登録されているアイテム情報や新機能が増えているかもしれないですが，生焼けなので試すとお腹を壊したり爆発したり，鼻から LoC が出てくるかもしれません．

## 使い方
[マニュアル](http://docs.fukuro.coop.moe)をご覧ください。

## できること
- 生産したいアイテムを複数個作成するのに必要な素材やレシピの確認
- レシピで作れるアイテムの価格の自動計算
- レシピの詳細確認
- アイテムの詳細確認 (まだ一部)
  - 食事バフ等の詳細情報の確認 (まだ一部)
- バインダーに登録されているレシピの管理
  - キャラクターごとのバインダー管理
  - 各バインダー内のレシピ検索
- 料理や醸造，調合等の生産スキルごとのレシピの確認
  - 各スキル内のレシピ検索
- バインダー内のレシピを検索
- 複数のバインダーや必要スキルからレシピをまとめて検索

- とてもいい感じの検索
  - katsu でカツ丼やカツを検索できます (ローマ字のまま検索)
  - cookie でクッキーを，bread でパンを検索できます (英語でも検索)
  - soi でソード オブ インフェルノを検索できます (略称検索)

- 広告機能 (リアル広告ではなく、生協の販促メッセージ表示機能です)
```
＿人人人人人人人人人人人人人＿
＞　グリードルの煮凝り@35g　＜
￣Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y
```

## そのうちやりたいこと

- レシピ完全対応
  - 複製等の特殊な物以外は大体対応完了！
- アイテム完全対応
  - 順次作業中
- 生産道具の性能確認
- NPC店舗での販売アイテムの確認
- 各クエストでもらえるアイテムの確認
- 指定したアイテムを，端数が出ないように作成するための支援機能
- ルーレットのMGマス等の数の確認
  - 成功マスの算出式がわからないので対応できないかも．情報求む．

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

## ライセンス
### 生協の知恵袋のライセンスについて
MIT ライセンスです。 詳細は[LICENSE](LICENSE)をご覧ください。

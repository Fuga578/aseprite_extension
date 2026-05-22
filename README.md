# AseCLI

Aseprite の画面内から Aseprite の CLI コマンドを実行できるコンソール拡張機能。

スプライトシート生成・一括フォーマット変換など、GUI に代替手段が無い
`aseprite -b ...` バッチ操作を、Aseprite を離れずに実行できます。

## 動作要件

- **Aseprite v1.3.7 以降**
  `os.execute` の戻り値が正しく取得できる最初のバージョンです。v1.3.6 以前では
  終了コードを取得できないため動作しません。
- 主対象 OS: Windows(macOS / Linux は将来対応)

## インストール

1. `scripts/build.ps1` を実行して `dist/AseCLI.aseprite-extension` を生成する
   (または配布されたパッケージを入手する)
2. Aseprite で `Edit > Preferences > Extensions > Add Extension` を開く
3. `AseCLI.aseprite-extension` を選択する

## 使い方

1. メニューから `CLI Console` を開く
2. コマンド入力欄に `aseprite -b ...` 形式のコマンドを入力する
   - 先頭の `aseprite` は、設定した実行ファイルパスへ自動的に置換されます
3. `Run`(または入力欄で Enter)で実行する
4. 出力ログに標準出力・標準エラー出力と終了コードが表示される

初回利用前に `Settings` から **Aseprite 実行ファイルのパス** を設定してください。

### コマンド例

```
aseprite -b player.ase --sheet player-sheet.png --data player.json
aseprite -b icon.ase --scale 2 --save-as icon@2x.png
aseprite -b animation.ase --save-as frame{frame}.png
```

### 注意事項

- コマンドは **ディスク上のファイル** を別プロセスで処理します。Aseprite で編集中
  (未保存)の内容には作用しません。実行前に保存してください。
- 実行中は Aseprite の UI が一時的にブロックされます(`os.execute` は同期実行)。
  一般的なバッチ処理は通常1秒未満で完了します。
- 初回実行時、Aseprite のセキュリティ許可ダイアログが表示されます。

## 開発

### ディレクトリ構成

```
src/        拡張機能ソース(.aseprite-extension にパッケージされる)
  init.lua      プラグインエントリ
  package.json  拡張マニフェスト
  ui/           UIレイヤー(Dialog)
  core/         コアレイヤー(コマンド生成・実行・履歴)
  infra/        インフラレイヤー(os.execute・ファイル・設定永続化)
  lib/          共通ユーティリティ
tests/      ユニットテスト(busted)
scripts/    ビルドスクリプト
docs/       永続ドキュメント(設計仕様)
```

### ビルド

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
# -> dist/AseCLI.aseprite-extension が生成される
```

### テスト

```bash
# ユニットテスト(Lua 5.4 のみで実行可能・追加依存なし)
lua tests/run.lua

# busted がインストール済みの環境では busted も利用可能
busted tests/unit
```

純粋ロジック(`command-builder` / `history-store` / `lib/strings`)は
Aseprite ランタイム外でテストできます(全29ケース)。
`tests/run.lua` は busted 非依存の軽量ランナーで、Lua 5.4 さえあれば動作します
(Windows では `busted`/`luacheck` が C 拡張依存のため導入が難しいため)。
UI・`os.execute` の挙動は Aseprite 実機での手動確認が必要です。

### 未検証事項(実機確認が必要)

本拡張は Aseprite 実機なしで実装されているため、以下は対象 Aseprite での
確認を推奨します:

- `package.json` のスキーマがインストール対象の Aseprite バージョンで有効か
- `init.lua` のメニューグループ id `file_scripts` が有効で、想定どおりの位置に
  コマンドが表示されるか
- `Dialog` ウィジェットの表示・`os.execute` の挙動・セキュリティ許可ダイアログ

## ドキュメント

設計仕様は `docs/` を参照してください:

- `docs/product-requirements.md` - プロダクト要求定義書
- `docs/functional-design.md` - 機能設計書
- `docs/architecture.md` - 技術仕様書
- `docs/repository-structure.md` - リポジトリ構造定義書
- `docs/development-guidelines.md` - 開発ガイドライン
- `docs/glossary.md` - 用語集

## ライセンス

`LICENSE` を参照してください。

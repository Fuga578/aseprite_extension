# リポジトリ構造定義書 (Repository Structure Document)

> 本書は `docs/architecture.md` で定義したレイヤードアーキテクチャを、
> 具体的なディレクトリ・ファイル構造に落とし込む。
> 言語は Lua、成果物は `.aseprite-extension`(ZIP)である点に留意する。

## プロジェクト構造

```
aseprite_extension/
├── src/                      # 拡張機能のソース(★これがパッケージ対象)
│   ├── package.json          # Aseprite拡張マニフェスト
│   ├── init.lua              # プラグインエントリポイント(init/exit)
│   ├── ui/                   # UIレイヤー
│   │   ├── console-dialog.lua
│   │   └── settings-dialog.lua
│   ├── core/                 # コアレイヤー(ビジネスロジック)
│   │   ├── command-builder.lua
│   │   ├── command-runner.lua
│   │   ├── history-store.lua
│   │   ├── license.lua       # Pro機能
│   │   └── preset-store.lua  # Pro機能
│   ├── infra/                # インフラレイヤー
│   │   ├── process-executor.lua
│   │   ├── temp-file.lua
│   │   └── settings.lua
│   └── lib/                  # レイヤーをまたぐ共通ユーティリティ
│       ├── platform.lua      # OS判定・OS依存定数
│       └── strings.lua       # 文字列ユーティリティ(クオート等)
├── tests/                    # テストコード(パッケージ対象外)
│   ├── unit/                 # ユニットテスト(busted)
│   │   ├── core/
│   │   └── lib/
│   └── support/              # テスト補助(Aseprite APIモック等)
│       └── aseprite-mock.lua
├── scripts/                  # 開発・ビルド補助スクリプト
│   └── build.ps1             # .aseprite-extension を生成するパッケージスクリプト
├── dist/                     # ビルド成果物(.gitignore対象)
├── docs/                     # 永続ドキュメント
│   ├── ideas/                # 下書き・アイデアメモ
│   ├── product-requirements.md
│   ├── functional-design.md
│   ├── architecture.md
│   ├── repository-structure.md
│   ├── development-guidelines.md
│   └── glossary.md
├── .steering/                # 作業単位ドキュメント(.gitignore対象)
├── .claude/                  # Claude Code 設定
├── CLAUDE.md                 # プロジェクトメモリ
├── README.md
└── LICENSE
```

## ディレクトリ詳細

### src/ (拡張機能ソースディレクトリ)

`src/` 配下が `.aseprite-extension` パッケージの中身になる。
**`package.json` はパッケージ(ZIP)のルートに来る必要がある**ため、`src/` 直下に置く。

#### src/(直下)

**役割**: 拡張マニフェストとエントリポイント

**配置ファイル**:
- `package.json`: 拡張のメタ情報、`contributes`(メニューコマンド)定義
- `init.lua`: `init(plugin)` / `exit(plugin)` を実装。メニューコマンドを登録

**命名規則**: Aseprite の規約により `package.json` / `init.lua` の名称は固定

#### src/ui/

**役割**: UIレイヤー。`Dialog` の構築とユーザー操作の受付

**配置ファイル**:
- `*-dialog.lua`: 1ダイアログ = 1ファイル

**命名規則**: kebab-case、`-dialog` 接尾辞

**依存関係**:
- 依存可能: `core/`, `infra/settings`(設定読み込みのみ), `lib/`
- 依存禁止: `infra/process-executor`, `infra/temp-file`(コア経由で利用すること)

#### src/core/

**役割**: コアレイヤー。コマンド生成・実行統括・履歴・Pro機能

**配置ファイル**:
- `command-builder.lua`: コマンド文字列の組み立て(純粋ロジック)
- `command-runner.lua`: 実行フローの統括
- `history-store.lua`: 履歴管理
- `license.lua` / `preset-store.lua`: Pro機能

**命名規則**: kebab-case。役割を表す名詞(`-builder`, `-runner`, `-store`)

**依存関係**:
- 依存可能: `infra/`, `lib/`
- 依存禁止: `ui/`

#### src/infra/

**役割**: インフラレイヤー。OS・ファイル・Aseprite永続化との境界

**配置ファイル**:
- `process-executor.lua`: `os.execute` ラッパー
- `temp-file.lua`: 一時ファイルI/O
- `settings.lua`: `plugin.preferences` による永続化

**命名規則**: kebab-case

**依存関係**:
- 依存可能: `lib/`, Lua標準ライブラリ, Aseprite API
- 依存禁止: `ui/`, `core/`

#### src/lib/

**役割**: 複数レイヤーで共有する汎用ユーティリティ

**配置ファイル**:
- `platform.lua`: OS判定、OS依存定数(パス区切り・cd構文等)
- `strings.lua`: 文字列処理(クオート・トリム等)

**命名規則**: kebab-case。汎用的すぎる名前(`utils` 等)は避け、役割を明示する

**依存関係**:
- 依存可能: Lua標準ライブラリのみ
- 依存禁止: `ui/`, `core/`, `infra/`(共通ライブラリは他レイヤーに依存しない)

### tests/ (テストディレクトリ)

#### tests/unit/

**役割**: Asepriteランタイム外で実行するユニットテスト(busted)

**構造**: `src/` のレイヤー構造に対応させる

```
tests/unit/
├── core/
│   ├── command-builder_spec.lua
│   └── history-store_spec.lua
└── lib/
    └── strings_spec.lua
```

**命名規則**: `[テスト対象]_spec.lua`(busted の慣例)

#### tests/support/

**役割**: テスト補助。Aseprite API(`app`, `plugin`, `Dialog` 等)のモックを提供

**配置ファイル**: `aseprite-mock.lua`

### scripts/ (スクリプトディレクトリ)

**役割**: 開発・ビルド補助

**配置ファイル**:
- `build.ps1`: `src/` を ZIP 化し `dist/AseCLI.aseprite-extension` を生成する PowerShell スクリプト

### docs/ (ドキュメントディレクトリ)

**配置ドキュメント**:
- `ideas/`: 下書き・アイデアメモ(`/setup-project` で読み込まれる)
- `product-requirements.md`: プロダクト要求定義書
- `functional-design.md`: 機能設計書
- `architecture.md`: 技術仕様書
- `repository-structure.md`: リポジトリ構造定義書(本書)
- `development-guidelines.md`: 開発ガイドライン
- `glossary.md`: 用語集

### dist/ (ビルド成果物 - .gitignore対象)

**役割**: `build.ps1` が生成する `.aseprite-extension` の出力先。Git管理しない

## ファイル配置規則

### ソースファイル

| ファイル種別 | 配置先 | 命名規則 | 例 |
|------------|--------|---------|-----|
| 拡張マニフェスト | `src/` | 固定名 | `package.json` |
| エントリポイント | `src/` | 固定名 | `init.lua` |
| ダイアログ(UI) | `src/ui/` | `[名前]-dialog.lua` | `console-dialog.lua` |
| コアモジュール | `src/core/` | `[役割].lua` | `command-runner.lua` |
| インフラモジュール | `src/infra/` | `[役割].lua` | `process-executor.lua` |
| 共通ユーティリティ | `src/lib/` | `[役割].lua` | `platform.lua` |

### テストファイル

| テスト種別 | 配置先 | 命名規則 | 例 |
|-----------|--------|---------|-----|
| ユニットテスト | `tests/unit/[レイヤー]/` | `[対象]_spec.lua` | `command-builder_spec.lua` |
| テスト補助 | `tests/support/` | `[役割].lua` | `aseprite-mock.lua` |

> 統合テスト・E2Eテストは Aseprite 実機での手動実施のため、コードファイルは持たない。
> 手順は `docs/development-guidelines.md` のテスト戦略に記す。

## 命名規則

### ディレクトリ名
- すべて kebab-case・小文字。レイヤー名はアーキテクチャの呼称(`ui`, `core`, `infra`)に合わせる

### ファイル名(Lua)
- **モジュールファイル**: kebab-case + 役割を表す名詞・接尾辞
  - 例: `command-builder.lua`, `temp-file.lua`, `console-dialog.lua`
- **テストファイル**: `[対象]_spec.lua`

### Lua モジュールの require
- ドット区切りでパスを表現する
  - 例: `local CommandBuilder = require("core.command-builder")`
- 各モジュールは関数テーブルを `return` する(グローバル変数を作らない)

## 依存関係のルール

### レイヤー間の依存

```
UIレイヤー (ui/)
    ↓ (OK)
コアレイヤー (core/)
    ↓ (OK)
インフラレイヤー (infra/)

共通ライブラリ (lib/) ← 各レイヤーから参照可。lib/ は他レイヤーに依存しない
```

**禁止される依存**:
- `infra/` → `core/`(❌)
- `infra/` → `ui/`(❌)
- `core/` → `ui/`(❌)
- `lib/` → `ui/` / `core/` / `infra/`(❌)

### 循環依存の禁止

Lua の `require` は循環依存で `nil` を返す危険があるため厳禁。
共通の処理は `lib/` に抽出して解消する。

```lua
-- ❌ 悪い例: 相互参照
-- core/command-runner.lua → require("core.history-store")
-- core/history-store.lua  → require("core.command-runner")

-- ✅ 良い例: 共通処理を lib/ に抽出、または依存方向を一方向に整理
```

## スケーリング戦略

### 機能の追加
1. **小規模**: 既存モジュールに関数を追加
2. **中規模**: 該当レイヤーに新しいモジュールファイルを追加
3. **大規模**: レイヤー内にサブディレクトリを作成(例: `core/export/`)

### ファイルサイズの管理
- 1ファイル 200行以下を推奨
- 300行を超えたら責務分割を検討

### 将来機能の配置方針
- **フォーム型ランチャー(PRD 機能10)**: `ui/` に新ダイアログを追加。`core/` は再利用
- **macOS/Linux対応(PRD 機能11)**: OS差異は `lib/platform.lua` と `core/command-builder.lua` に閉じ込め済み。これらの分岐を追加する

## 特殊ディレクトリ

### .steering/(ステアリングファイル)
作業単位の一時ドキュメント。`[YYYYMMDD]-[task-name]/` 形式。
`requirements.md` / `design.md` / `tasklist.md` を格納。Git管理しない。

### .claude/(Claude Code設定)
`commands/`(スラッシュコマンド)、`skills/`(スキル)、`agents/`(サブエージェント)。

## 除外設定

### .gitignore に含めるもの
- `dist/`(ビルド成果物)
- `.steering/`(作業単位の一時ファイル)
- `*.aseprite-extension`(生成パッケージ)
- 一時ファイル・OS生成ファイル(`*.tmp`, `Thumbs.db`, `.DS_Store`)
- Lua関連の生成物(`luacov.*` 等、ツール導入時)

### パッケージ(.aseprite-extension)に含めないもの
- `tests/`, `scripts/`, `docs/`, `.steering/`, `.claude/`, `dist/`
- `package.json` と `src/` 配下の Lua ソースのみをパッケージする

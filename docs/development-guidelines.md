# 開発ガイドライン (Development Guidelines)

> 本書は AseCLI(Aseprite拡張・Lua)の実装規約と開発プロセスを定義する。
> 汎用テンプレートは TypeScript 前提だが、本書は **Lua / Aseprite 拡張** の
> 実態に合わせて規約を定めている。

## コーディング規約

### 言語・スタイルの基本

- 言語: **Lua 5.4**(Aseprite組み込み)
- インデント: **半角スペース2つ**(タブ禁止)
- 行の長さ: 最大 **100文字**
- 文字エンコーディング: UTF-8(BOMなし)
- 1ファイル = 1モジュール。末尾でモジュールテーブルを `return` する

```lua
-- モジュールの基本形
local CommandBuilder = {}

function CommandBuilder.build(rawInput, opts)
  -- 実装
end

return CommandBuilder
```

### 命名規則

#### 変数・関数

```lua
-- ✅ 良い例
local workingDir = resolveWorkingDir(sprite)
local function buildFullCommand(rawInput, opts) end

-- ❌ 悪い例
local d = resolve(s)
local function build(a, b) end
```

**原則**:
- ローカル変数・関数: **camelCase**、変数は名詞、関数は動詞で始める
- モジュールテーブル: **PascalCase**(例: `CommandBuilder`, `HistoryStore`)
- 定数: **UPPER_SNAKE_CASE**(例: `MAX_HISTORY = 100`)
- Boolean: `is` / `has` / `should` で始める(例: `isProEnabled`)
- プライベート関数: ファイル内 `local function` で定義し、モジュールテーブルに公開しない

#### ファイル・モジュール

- ファイル名: kebab-case(例: `command-builder.lua`)
- `require` はドット区切り(例: `require("core.command-builder")`)

### 変数スコープ

```lua
-- ✅ 良い例: 常に local を付ける
local result = CommandRunner.run(input, context)

-- ❌ 悪い例: グローバル変数を作る(Aseprite環境を汚染する)
result = CommandRunner.run(input, context)
```

**原則**:
- すべての変数・関数に `local` を付ける。グローバル変数は作らない
- Aseprite が提供するグローバル(`app`, `Dialog`, `Sprite` 等)以外のグローバル参照を禁止
- luacheck で未定義グローバルを検出する

### 関数設計

- 1関数 = 1責務。目標 30行以内、50行を超えたら分割を検討
- 引数が4つを超える場合はテーブル(オプションテーブル)にまとめる

```lua
-- ✅ 良い例: オプションテーブル
function CommandBuilder.build(rawInput, opts)
  -- opts = { executablePath = ..., workingDir = ..., outputFile = ... }
end

-- ❌ 悪い例: 引数が多すぎる
function CommandBuilder.build(rawInput, exePath, workDir, outFile, redirect, quote)
end
```

### コメント規約

#### モジュール・関数のドキュメントコメント

LuaDoc 風の注釈を用いる。

```lua
--- ユーザー入力から os.execute へ渡す完全なコマンドを生成する。
-- @param rawInput string ユーザーが入力した生コマンド
-- @param opts table { executablePath:string, workingDir:string, outputFile:string }
-- @return string|nil fullCommand 生成された完全なコマンド(失敗時 nil)
-- @return string|nil errorMessage 失敗理由(成功時 nil)
function CommandBuilder.build(rawInput, opts)
  -- 実装
end
```

#### インラインコメント

```lua
-- ✅ 良い例: なぜそうするかを説明
-- Windowsのcmdは、内部にクオートを含むコマンド全体を
-- さらにクオートで囲まないと正しくパースされない
fullCommand = '"' .. fullCommand .. '"'

-- ❌ 悪い例: コードを見れば分かることの繰り返し
-- fullCommand をクオートで囲む
fullCommand = '"' .. fullCommand .. '"'
```

- `TODO:` / `FIXME:` / `HACK:` を活用し、可能なら関連Issueを併記する

### エラーハンドリング

Lua には例外クラスが無いため、**戻り値でエラーを返す**方式を基本とする
(`value, errorMessage` の2値返し)。`error()` は回復不能な実装バグにのみ使う。

```lua
-- ✅ 良い例: エラーは戻り値で返す
function CommandBuilder.build(rawInput, opts)
  if rawInput == nil or rawInput:match("^%s*$") then
    return nil, "コマンドを入力してください"
  end
  if opts.executablePath == "" then
    return nil, "Aseprite実行ファイルのパスが未設定です"
  end
  -- ...
  return fullCommand, nil
end

-- 呼び出し側
local fullCommand, err = CommandBuilder.build(input, opts)
if not fullCommand then
  ConsoleDialog.showError(err)
  return
end
```

**原則**:
- 予期されるエラー(入力不正・設定不足)は戻り値で返し、呼び出し側で表示する
- エラーを握り潰さない。`pcall` で握った場合も必ずログまたはUIに反映する
- エラーメッセージは「原因」と「対処」を日本語で具体的に書く

```lua
-- ✅ 良い例: 具体的で対処が分かる
return nil, "作業ディレクトリが見つかりません: " .. workingDir

-- ❌ 悪い例: 曖昧
return nil, "エラー"
```

### Aseprite API 利用上の規約

- `os.execute` を直接呼ぶのは `infra/process-executor.lua` のみ。他レイヤーから直接呼ばない
- `Dialog` の生成は `ui/` レイヤーのみ
- `plugin.preferences` へのアクセスは `infra/settings.lua` に集約する
- 一時ファイルは作成したら必ず削除する(`pcall` で削除失敗を握っても、次回起動時のクリーンアップで補完する)

## Git運用ルール

### ブランチ戦略

個人〜小規模開発のため、Git Flow を簡略化した運用とする。

```
main (リリース可能な安定版・タグでバージョン管理)
  ├─ feature/[機能名]   新機能開発
  ├─ fix/[修正内容]     バグ修正
  └─ refactor/[対象]    リファクタリング
```

**運用ルール**:
- `main`: 常にリリース可能な状態を保つ。リリース時に `v1.0.0` 等のタグを打つ
- 機能・修正は `main` から分岐したブランチで行い、完了後 `main` へマージ
- 1ブランチ = 1まとまりの作業

### コミットメッセージ規約

Conventional Commits 形式を採用する。

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `style`: フォーマット(動作に影響なし)
- `refactor`: リファクタリング
- `perf`: パフォーマンス改善
- `test`: テスト追加・修正
- `chore`: ビルド・補助ツール等

**scope の例**: `ui`, `core`, `infra`, `builder`, `runner`, `pkg`

**例**:
```
feat(core): コマンド履歴の永続化を追加

HistoryStore が plugin.preferences に履歴を保存・復元するようにした。
- 上限100件のFIFOで肥大化を防止
- ↑↓キーでの呼び出しに対応

Closes #12
```

### プルリクエスト / マージ前チェック

**マージ前のチェック**:
- [ ] `luac -p` で全 Lua ファイルに構文エラーがない
- [ ] `lua tests/run.lua` のユニットテストが全てパス
- [ ] Aseprite v1.3.7 実機で対象機能の手動確認を実施
- [ ] ドキュメント(該当する場合)を更新

**PR本文テンプレート**(GitHubでPRを使う場合):
```markdown
## 概要
[変更内容の簡潔な説明]

## 変更理由
[なぜこの変更が必要か]

## 変更内容
- [変更点1]
- [変更点2]

## テスト
- [ ] ユニットテスト追加/更新
- [ ] Aseprite実機で手動確認

## 関連Issue
Closes #[番号]
```

## テスト戦略

Aseprite拡張は Aseprite ランタイムに依存するため、テストを2層に分ける。

### テストの種類

#### ユニットテスト(Asepriteランタイム外)

**対象**: 純粋ロジック — `CommandBuilder`、`HistoryStore`、`lib/strings`、`lib/platform`

**方法**: `*_spec.lua` は busted 互換の構文で記述する。実行は2通り:
- `lua tests/run.lua` — busted 非依存の軽量ランナー(Lua 5.4 のみで動作・推奨)。新しい spec を追加したら `tests/run.lua` の `SPECS` リストにも追記する
- `busted tests/unit` — busted を導入済みの環境向け

Windows では `busted`/`luacheck` が C 拡張(luafilesystem)に依存し導入が難しいため、
通常は `lua tests/run.lua` を使う。Aseprite API に依存するモジュールをテストする場合は
`tests/support/aseprite-mock.lua` でモックする。

**例**:
```lua
-- tests/unit/core/command-builder_spec.lua
local CommandBuilder = require("core.command-builder")

describe("CommandBuilder.build", function()
  it("先頭の aseprite トークンを実行ファイルパスに置換する", function()
    -- Given
    local opts = {
      executablePath = "C:\\Program Files\\Aseprite\\Aseprite.exe",
      workingDir = "C:\\work",
      outputFile = "C:\\tmp\\out.txt",
    }

    -- When
    local fullCommand, err = CommandBuilder.build("aseprite -b in.ase", opts)

    -- Then
    assert.is_nil(err)
    assert.is_truthy(fullCommand:find("Aseprite.exe", 1, true))
  end)

  it("空入力の場合はエラーメッセージを返す", function()
    local fullCommand, err = CommandBuilder.build("   ", { executablePath = "x" })
    assert.is_nil(fullCommand)
    assert.is_not_nil(err)
  end)
end)
```

**カバレッジ目標**: `core/` のロジックモジュールで 80% 以上

#### 統合テスト / E2Eテスト(Aseprite実機 / 手動)

**対象**: `ProcessExecutor`(`os.execute` の実挙動)、`CommandRunner`、UIダイアログ全般

**理由**: `os.execute`・一時ファイル・セキュリティ許可ダイアログ・`Dialog` の挙動は
実機でしか検証できない

**手順**:
1. `scripts/build.ps1` で `.aseprite-extension` を生成
2. Aseprite v1.3.7+ にインストール
3. 下記の受け入れシナリオを手動実行

**受け入れシナリオ**:
| # | シナリオ | 期待結果 |
|---|---------|---------|
| 1 | スプライトシート書き出しコマンドを実行 | 出力ファイルが生成され ✓ Done 表示 |
| 2 | 存在しないファイルを指定して実行 | ✗ Failed 表示、エラー出力が見える |
| 3 | 実行ファイルパス未設定で実行 | 実行されず、設定誘導メッセージ表示 |
| 4 | ↑↓キーで履歴を呼び出し | 直前のコマンドが入力欄に復元される |
| 5 | 拡張の再インストール後に設定が保持される | 実行ファイルパス・履歴が残っている |

### テスト命名規則

- ファイル: `[対象]_spec.lua`
- `describe` にモジュール・関数名、`it` に「条件 → 期待結果」を日本語で記述

## コードレビュー基準

### レビューポイント

**機能性**:
- [ ] PRD/機能設計書の要件を満たしているか
- [ ] エラー(空入力・パス未設定・実行失敗)が適切に処理されているか

**可読性**:
- [ ] 命名が明確か。グローバル変数を作っていないか
- [ ] 複雑なロジック(特にクオート処理)にコメントがあるか

**アーキテクチャ**:
- [ ] レイヤー依存方向(UI→Core→Infra)を守っているか
- [ ] `os.execute` / `Dialog` / `plugin.preferences` が規定のレイヤーに閉じているか

**保守性**:
- [ ] 重複コードがないか。OS依存が `lib/` と `command-builder` に閉じているか

**セキュリティ**:
- [ ] 拡張が付加する文字列が適切にクオートされているか
- [ ] ライセンスキー等がハードコードされていないか

### レビューコメントの優先度

- `[必須]`: 修正必須
- `[推奨]`: 修正推奨
- `[提案]`: 検討してほしい
- `[質問]`: 理解のための質問

## 開発環境セットアップ

### 必要なツール

| ツール | バージョン | 用途 | 備考 |
|--------|-----------|------|------|
| Aseprite | v1.3.7 以降 | 動作確認・統合テスト | 必須 |
| Lua | 5.4 | ユニットテスト実行(`lua tests/run.lua`)・構文チェック(`luac -p`) | 必須 |
| busted | 2.x | ユニットテスト(別の実行手段) | 任意 |
| luacheck | 0.26+ | 静的解析 | 任意(C拡張依存のためWindowsでは導入困難) |
| PowerShell | 5.1+ | パッケージング(`build.ps1`) | Windows標準 |

### セットアップ手順

```powershell
# 1. リポジトリのクローン
git clone [リポジトリURL]
cd aseprite_extension

# 2. Lua 5.4 の導入(ユニットテスト実行に必要)
#    Windows は winget で導入可能
winget install --id DEVCOM.Lua --exact --source winget

# 3. ユニットテストの実行(busted 不要・Lua のみで動作)
lua tests/run.lua

# 4. 構文チェック(全 Lua ファイル)
Get-ChildItem src -Recurse -Filter *.lua | ForEach-Object { luac -p $_.FullName }

# 5. 拡張のパッケージング
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
#    → dist/AseCLI.aseprite-extension が生成される

# 6. Aseprite へインストール
#    Aseprite で Edit > Preferences > Extensions > Add Extension
#    から dist/AseCLI.aseprite-extension を選択
```

### 推奨開発ツール

- **エディタ**: Lua 言語サポートのあるエディタ(VS Code + Lua 拡張など)
- **Aseprite API リファレンス**: 開発中は公式 API ドキュメントを参照する

## 品質チェックの自動化(任意)

CI を導入する場合、Asepriteランタイム不要のチェックのみ自動化する
(実機テストは手動)。

```yaml
# .github/workflows/ci.yml(例)
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Lua
        uses: leafo/gh-actions-lua@v10
        with:
          luaVersion: "5.4"
      - name: Setup LuaRocks
        uses: leafo/gh-actions-luarocks@v4
      - run: luarocks install busted
      - run: luarocks install luacheck
      - run: luacheck src
      - run: busted tests/unit
```

**導入効果**: コミット/PRごとにLintとユニットテストが自動実行され、
ロジックの不具合(特にクオート処理の退行)を早期に検出できる。

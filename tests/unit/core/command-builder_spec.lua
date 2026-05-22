--- core/command-builder のユニットテスト。
-- OS差異は opts.os で注入し、環境に依存せず両OSを検証する。
local CommandBuilder = require("core.command-builder")

--- 既定の opts を生成し、over で上書きする。
local function opts(over)
  local o = {
    executablePath = "C:\\Program Files\\Aseprite\\Aseprite.exe",
    workingDir = "C:\\work",
    outputFile = "C:\\tmp\\out.txt",
    os = "windows",
  }
  for k, v in pairs(over or {}) do
    o[k] = v
  end
  return o
end

describe("CommandBuilder.build バリデーション", function()
  it("空入力はエラーを返す", function()
    local cmd, err = CommandBuilder.build("   ", opts())
    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

  it("実行ファイルパス未設定はエラーを返す", function()
    local cmd, err = CommandBuilder.build("aseprite -b x.ase", opts({ executablePath = "" }))
    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

  it("出力ファイル未指定はエラーを返す", function()
    local cmd, err = CommandBuilder.build("aseprite -b x.ase", opts({ outputFile = "" }))
    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)
end)

describe("CommandBuilder.build トークン置換", function()
  it("先頭の aseprite トークンを実行ファイルパスへ置換する", function()
    local cmd = CommandBuilder.build("aseprite -b x.ase", opts())
    assert.is_not_nil(cmd)
    assert.is_truthy(cmd:find("Aseprite.exe", 1, true))
    assert.is_nil(cmd:find(" aseprite ", 1, true))
  end)

  it("aseprite で始まらない入力は全体を引数として扱う", function()
    local cmd = CommandBuilder.build("-b x.ase", opts())
    assert.is_truthy(cmd:find("-b x.ase", 1, true))
    assert.is_truthy(cmd:find("Aseprite.exe", 1, true))
  end)

  it("スペースを含む実行ファイルパスをクオートする", function()
    local cmd = CommandBuilder.build("aseprite -b x.ase", opts())
    assert.is_truthy(cmd:find('"C:\\Program Files\\Aseprite\\Aseprite.exe"', 1, true))
  end)
end)

describe("CommandBuilder.build リダイレクト", function()
  it("標準出力・標準エラー出力を一時ファイルへリダイレクトする", function()
    local cmd = CommandBuilder.build("aseprite -b x.ase", opts())
    assert.is_truthy(cmd:find("2>&1", 1, true))
    assert.is_truthy(cmd:find("out.txt", 1, true))
  end)
end)

describe("CommandBuilder.build OS差異", function()
  it("Windows では cd /d と外側クオートを使う", function()
    local cmd = CommandBuilder.build("aseprite -b x.ase", opts({ os = "windows" }))
    assert.is_truthy(cmd:find("cd /d", 1, true))
    assert.are.equal('"', cmd:sub(1, 1))
    assert.are.equal('"', cmd:sub(-1))
  end)

  it("Unix では cd(/d なし)を使い外側クオートを付けない", function()
    local cmd = CommandBuilder.build("aseprite -b x.ase", opts({ os = "unix" }))
    assert.is_nil(cmd:find("cd /d", 1, true))
    assert.is_truthy(cmd:find("cd ", 1, true))
    assert.are_not.equal('"', cmd:sub(1, 1))
  end)

  it("作業ディレクトリ未指定なら cd を付けない", function()
    local cmd = CommandBuilder.build("aseprite -b x.ase", opts({ workingDir = "" }))
    assert.is_nil(cmd:find("cd ", 1, true))
  end)
end)

--- 生コマンドから `os.execute` へ渡す完全なコマンドを生成する。
-- コアレイヤーの純粋ロジック。Aseprite API には依存しない。
local strings = require("lib.strings")
local platform = require("lib.platform")

local CommandBuilder = {}

--- 実行ファイルパスへ置換する先頭トークン。
local ASEPRITE_TOKEN = "aseprite"

--- Windows のクオート規則を使うかどうかを判定する。
-- `opts.os`("windows"/"unix")が指定されていればそれを優先し、
-- 未指定なら実行環境から自動判定する(テストで両OSを検証できるようにする)。
-- @param opts table
-- @return boolean
local function useWindowsRules(opts)
  if opts.os == "windows" then
    return true
  end
  if opts.os == "unix" then
    return false
  end
  return platform.isWindows()
end

--- 生コマンドから引数部分を取り出す。
-- 先頭トークンが `aseprite` ならそれ以降を、そうでなければ全体を引数とみなす。
-- @param rawInput string
-- @return string
local function extractArgs(rawInput)
  local firstWord, rest = strings.splitFirstWord(rawInput)
  if firstWord:lower() == ASEPRITE_TOKEN then
    return rest
  end
  return strings.trim(rawInput)
end

--- 生コマンドから完全なコマンドを生成する。
-- @param rawInput string ユーザーが入力した生コマンド
-- @param opts table { executablePath:string, workingDir:string?, outputFile:string, os:string? }
-- @return string|nil fullCommand 生成された完全なコマンド(失敗時 nil)
-- @return string|nil errorMessage 失敗理由(成功時 nil)
function CommandBuilder.build(rawInput, opts)
  opts = opts or {}

  if strings.isBlank(rawInput) then
    return nil, "コマンドを入力してください"
  end
  if strings.isBlank(opts.executablePath) then
    return nil, "Aseprite実行ファイルのパスが未設定です。設定を開いてください"
  end
  if strings.isBlank(opts.outputFile) then
    return nil, "出力ファイルのパスが指定されていません"
  end

  local isWindows = useWindowsRules(opts)
  local args = extractArgs(rawInput)

  -- 中核部分: "<実行ファイル>" <引数>
  local command = strings.quote(opts.executablePath)
  if not strings.isBlank(args) then
    command = command .. " " .. args
  end

  -- 作業ディレクトリへ移動してから実行する
  if not strings.isBlank(opts.workingDir) then
    local cd
    if isWindows then
      -- /d はドライブをまたいだ移動を許可する
      cd = "cd /d " .. strings.quote(opts.workingDir) .. " && "
    else
      cd = "cd " .. strings.quote(opts.workingDir) .. " && "
    end
    command = cd .. command
  end

  -- 標準出力・標準エラー出力を一時ファイルへリダイレクト
  command = command .. " > " .. strings.quote(opts.outputFile) .. " 2>&1"

  -- Windows の cmd /c は、入れ子のクオートを含むコマンドを正しく解釈するために
  -- コマンド全体をさらに外側のクオートで囲む必要がある。
  if isWindows then
    command = '"' .. command .. '"'
  end

  return command, nil
end

return CommandBuilder

--- コマンド実行フロー全体を統括するコアモジュール。
-- CommandBuilder → TempFile → ProcessExecutor → 出力回収 → HistoryStore記録 を行う。
local CommandBuilder = require("core.command-builder")
local HistoryStore = require("core.history-store")
local ProcessExecutor = require("infra.process-executor")
local TempFile = require("infra.temp-file")

local CommandRunner = {}

--- 生コマンドを実行し、結果(CommandResult)を返す。
-- 検証エラー・実行失敗を含め、常に CommandResult テーブルを返す。
-- @param rawInput string ユーザーが入力した生コマンド
-- @param context table { executablePath:string, workingDir:string? }
-- @return table CommandResult
function CommandRunner.run(rawInput, context)
  context = context or {}

  local startClock = os.clock()
  local result = {
    rawCommand = rawInput or "",
    fullCommand = "",
    output = "",
    exitCode = -1,
    success = false,
    errorMessage = nil,
    durationMs = 0,
  }

  -- 出力リダイレクト用の一時ファイルパスを用意(実ファイルはリダイレクトで生成される)
  local outputFile = TempFile.create()

  local fullCommand, buildErr = CommandBuilder.build(rawInput, {
    executablePath = context.executablePath,
    workingDir = context.workingDir,
    outputFile = outputFile,
  })

  -- ビルド失敗(検証エラー)の場合は実行せずに返す
  if not fullCommand then
    result.errorMessage = buildErr
    result.durationMs = math.floor((os.clock() - startClock) * 1000)
    return result
  end
  result.fullCommand = fullCommand

  local ok, exitType, exitCode = ProcessExecutor.execute(fullCommand)

  -- 一時ファイルから出力を回収し、ただちに削除する。
  -- 出力の回収に失敗しても、終了コードによる成否判定は継続する。
  local content, readErr = TempFile.read(outputFile)
  if readErr then
    result.output = "(出力の回収に失敗しました: " .. readErr .. ")"
  else
    result.output = content or ""
  end
  TempFile.remove(outputFile)

  -- os.execute の戻り値を解釈する
  if exitCode ~= nil then
    result.exitCode = exitCode
    result.success = (exitType == "exit" and exitCode == 0)
  elseif ok == true then
    -- 成功ブール値のみが返る環境
    result.exitCode = 0
    result.success = true
  else
    -- 何も意味のある値が返らない: Aseprite v1.3.7 未満、または起動失敗の可能性
    result.errorMessage =
      "実行に失敗しました。Aseprite v1.3.7 以降が必要か、コマンドを起動できませんでした"
    result.exitCode = -1
    result.success = false
  end

  -- os.clock は近似値(同期待機中のCPU時間は計上されにくい)だが目安として記録する
  result.durationMs = math.floor((os.clock() - startClock) * 1000)

  -- 実行した(=検証を通過した)コマンドを履歴へ記録する
  HistoryStore.add({
    command = result.rawCommand,
    timestamp = os.time(),
    exitCode = result.exitCode,
    success = result.success,
  })

  return result
end

return CommandRunner

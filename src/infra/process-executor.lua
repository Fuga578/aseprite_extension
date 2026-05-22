--- `os.execute` の薄いラッパー。
-- インフラレイヤー。外部コマンドを実行する唯一のモジュールであり、
-- ここに集約することでテスト時のモック差し替えを容易にする。
local ProcessExecutor = {}

--- 完全なコマンドを実行する。
-- `os.execute` は同期的で、プロセス終了まで待機する(この間Aseprite UIはブロックされる)。
-- Aseprite v1.3.7 以降では本来の `os.execute` の戻り値が返る。
-- v1.3.6 以前は戻り値が nil になるため、解釈は呼び出し側(command-runner)で行う。
-- @param fullCommand string command-builder が生成した完全なコマンド
-- @return boolean|nil ok       成功時 true
-- @return string|nil  exitType "exit" または "signal"
-- @return number|nil  exitCode 終了コード
function ProcessExecutor.execute(fullCommand)
  return os.execute(fullCommand)
end

return ProcessExecutor

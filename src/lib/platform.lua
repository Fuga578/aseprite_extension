--- OS判定とOS依存定数を提供する共通ユーティリティ。
-- Aseprite API に依存せず、Lua標準の `package.config` のみで動作する。
local platform = {}

--- ディレクトリ区切り文字を返す(Windows は "\\"、Unix系は "/")。
-- @return string
function platform.pathSeparator()
  return package.config:sub(1, 1)
end

--- 実行環境が Windows かどうかを返す。
-- @return boolean
function platform.isWindows()
  return platform.pathSeparator() == "\\"
end

return platform

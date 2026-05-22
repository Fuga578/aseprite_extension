--- コマンド出力をリダイレクトして回収するための一時ファイルを扱う。
-- インフラレイヤー。
local platform = require("lib.platform")

local TempFile = {}

--- 一時ファイルの配置ディレクトリを解決する。
-- Aseprite の `app.fs.tempPath` を優先し、無ければ環境変数をフォールバックする。
-- @return string
local function tempDir()
  if app and app.fs and app.fs.tempPath and app.fs.tempPath ~= "" then
    return app.fs.tempPath
  end
  return os.getenv("TEMP") or os.getenv("TMP") or "."
end

--- ディレクトリ名とファイル名を結合する。
-- @param dir string
-- @param name string
-- @return string
local function joinPath(dir, name)
  if app and app.fs and app.fs.joinPath then
    return app.fs.joinPath(dir, name)
  end
  return dir .. platform.pathSeparator() .. name
end

--- 一意な一時ファイルのパスを生成して返す(ファイル自体はまだ作らない)。
-- 実ファイルは出力リダイレクトによって生成される。
-- @return string
function TempFile.create()
  local name = string.format(
    "asecli-output-%d-%d.txt",
    os.time(),
    math.random(100000, 999999)
  )
  return joinPath(tempDir(), name)
end

--- 一時ファイルの内容を読み取る。
-- @param path string
-- @return string|nil content, string|nil errorMessage
function TempFile.read(path)
  local f, openErr = io.open(path, "r")
  if not f then
    return nil, "一時ファイルを読み取れませんでした: " .. tostring(openErr)
  end
  local content = f:read("*a")
  f:close()
  return content or "", nil
end

--- 一時ファイルを削除する。削除失敗は致命的でないため握りつぶす。
-- @param path string
function TempFile.remove(path)
  if path and path ~= "" then
    os.remove(path)
  end
end

return TempFile

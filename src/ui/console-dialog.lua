--- メインのコンソールパネル。コマンド入力・実行・結果表示を担う。
-- UIレイヤー。
local CommandRunner = require("core.command-runner")
local HistoryStore = require("core.history-store")
local Settings = require("infra.settings")
local SettingsDialog = require("ui.settings-dialog")
local strings = require("lib.strings")

local ConsoleDialog = {}

--- ログ表示用のラベル行数(固定)。
local LOG_VISIBLE_LINES = 14
--- メモリ上に保持するログ行の上限。
local MAX_LOG_LINES = 200
--- 1行の表示幅の上限(超過分は省略)。
local MAX_LINE_WIDTH = 96

--- セッション中のログバッファ(Asepriteを開いている間は保持される)。
local logLines = {}

--- 表示用に文字列を指定幅で切り詰める。
-- @param s any
-- @param width number
-- @return string
local function truncate(s, width)
  s = tostring(s or "")
  if #s > width then
    return s:sub(1, width - 3) .. "..."
  end
  return s
end

--- テキスト(複数行可)をログバッファへ追加する。上限超過時は最古から破棄する。
-- @param text any
local function appendLog(text)
  text = tostring(text or "")
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(logLines, line)
  end
  while #logLines > MAX_LOG_LINES do
    table.remove(logLines, 1)
  end
end

--- ログバッファの末尾を、ダイアログのラベル行へ描画する。
-- @param dlg table Dialog
local function renderLog(dlg)
  local total = #logLines
  local startIdx = math.max(1, total - LOG_VISIBLE_LINES + 1)
  for i = 1, LOG_VISIBLE_LINES do
    local line = logLines[startIdx + i - 1]
    local text = " "
    if line and line ~= "" then
      text = truncate(line, MAX_LINE_WIDTH)
    end
    dlg:modify{ id = "log" .. i, text = text }
  end
end

--- コマンド実行時の作業ディレクトリを解決する。
-- 設定で追従が有効かつ開いているスプライトが保存済みなら、そのフォルダを使う。
-- それ以外は既定の作業ディレクトリ、最後にユーザードキュメントフォルダを使う。
-- @return string
local function resolveWorkingDir()
  if Settings.get("followActiveSprite") then
    local spr = app.sprite or app.activeSprite
    if spr and spr.filename and spr.filename ~= "" then
      if app.fs and app.fs.filePath then
        local dir = app.fs.filePath(spr.filename)
        if dir and dir ~= "" then
          return dir
        end
      end
    end
  end
  local defaultDir = Settings.get("defaultWorkingDir")
  if defaultDir and defaultDir ~= "" then
    return defaultDir
  end
  if app.fs and app.fs.userDocsPath then
    return app.fs.userDocsPath
  end
  return ""
end

--- 入力されたコマンドを実行し、結果をログへ反映する。
-- @param dlg table Dialog
local function doRun(dlg)
  local input = dlg.data.command
  if strings.isBlank(input) then
    appendLog("[ERROR] コマンドを入力してください")
    renderLog(dlg)
    return
  end

  appendLog("> " .. input)

  local result = CommandRunner.run(input, {
    executablePath = Settings.get("asepriteExecutablePath"),
    workingDir = resolveWorkingDir(),
  })

  if result.errorMessage then
    appendLog("[ERROR] " .. result.errorMessage)
  elseif result.success then
    appendLog("[OK] Done (exit " .. tostring(result.exitCode) .. ")")
  else
    appendLog("[FAIL] exit " .. tostring(result.exitCode))
  end

  if result.output and result.output ~= "" then
    appendLog(result.output)
  end
  appendLog("")

  renderLog(dlg)
  dlg:modify{ id = "command", text = "" }
end

--- 履歴をたどり、入力欄へ反映する。
-- @param dlg table Dialog
-- @param direction string "up" または "down"
local function doRecall(dlg, direction)
  local cmd = HistoryStore.recall(direction)
  if cmd ~= nil then
    dlg:modify{ id = "command", text = cmd }
  end
end

--- コンソールパネルを構築して表示する。
function ConsoleDialog.show()
  local dlg = Dialog{ title = "AseCLI Console" }

  dlg:label{
    id = "workingdir",
    label = "Working dir:",
    text = truncate(resolveWorkingDir(), MAX_LINE_WIDTH),
  }

  dlg:separator{ text = "Command" }
  dlg:entry{ id = "command", text = "" }
  dlg:newrow()
  -- Run を focus にすることで、入力欄での Enter が実行に割り当てられる
  dlg:button{
    id = "run",
    text = "Run",
    focus = true,
    onclick = function() doRun(dlg) end,
  }
  dlg:button{
    id = "prev",
    text = "Prev",
    onclick = function() doRecall(dlg, "up") end,
  }
  dlg:button{
    id = "next",
    text = "Next",
    onclick = function() doRecall(dlg, "down") end,
  }
  dlg:button{
    id = "settings",
    text = "Settings",
    onclick = function()
      SettingsDialog.show()
      dlg:modify{
        id = "workingdir",
        text = truncate(resolveWorkingDir(), MAX_LINE_WIDTH),
      }
    end,
  }

  dlg:separator{ text = "Output" }
  for i = 1, LOG_VISIBLE_LINES do
    dlg:label{ id = "log" .. i, text = " " }
  end

  renderLog(dlg)
  dlg:show{ wait = false }
end

return ConsoleDialog

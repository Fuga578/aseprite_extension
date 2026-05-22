--- AseCLI 拡張のプラグインエントリポイント。
-- Aseprite は拡張ロード時に init(plugin)、終了時に exit(plugin) を呼ぶ。
local Settings = require("infra.settings")
local HistoryStore = require("core.history-store")
local ConsoleDialog = require("ui.console-dialog")

--- 拡張の初期化。設定・履歴を準備し、メニューコマンドを登録する。
-- @param plugin table Aseprite が渡すプラグインオブジェクト
function init(plugin)
  Settings.init(plugin)

  -- 履歴の永続化を Settings(plugin.preferences)へ委譲する
  HistoryStore.init({
    load = function()
      return Settings.getSection("history") or {}
    end,
    save = function(list)
      Settings.setSection("history", list)
    end,
  })

  -- メニューコマンドを登録する。
  -- 注: メニューグループ id "file_scripts" は対象 Aseprite で要確認(README参照)。
  plugin:newCommand{
    id = "asecli_open_console",
    title = "CLI Console",
    group = "file_scripts",
    onclick = function()
      ConsoleDialog.show()
    end,
  }
end

--- 拡張の終了処理。現状は後始末不要。
-- @param plugin table
function exit(plugin)
end

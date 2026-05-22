--- 設定ダイアログ。Aseprite実行ファイルパスと作業ディレクトリ設定を編集する。
-- UIレイヤー。
local Settings = require("infra.settings")

local SettingsDialog = {}

--- 設定ダイアログをモーダル表示する。Save 押下時に設定を永続化する。
function SettingsDialog.show()
  local current = Settings.load()
  local dlg = Dialog{ title = "AseCLI Settings" }

  dlg:separator{ text = "Aseprite executable" }
  dlg:file{
    id = "executablePath",
    label = "Aseprite path:",
    filename = current.asepriteExecutablePath,
    open = true,
  }

  dlg:separator{ text = "Working directory" }
  dlg:check{
    id = "followActiveSprite",
    text = "Use the active sprite's folder",
    selected = current.followActiveSprite,
  }
  dlg:entry{
    id = "defaultWorkingDir",
    label = "Default working dir:",
    text = current.defaultWorkingDir,
  }

  dlg:separator{}
  dlg:button{
    id = "save",
    text = "Save",
    focus = true,
    onclick = function()
      Settings.save({
        asepriteExecutablePath = dlg.data.executablePath or "",
        followActiveSprite = dlg.data.followActiveSprite and true or false,
        defaultWorkingDir = dlg.data.defaultWorkingDir or "",
      })
      dlg:close()
    end,
  }
  dlg:button{ id = "cancel", text = "Cancel" }

  dlg:show{ wait = true }
end

return SettingsDialog

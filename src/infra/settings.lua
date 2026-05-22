--- 設定・履歴の永続化を担うモジュール。
-- Aseprite の `plugin.preferences`(プラグイン単位で自動永続化される)を利用する。
-- インフラレイヤー。`plugin.preferences` へのアクセスを本モジュールに集約する。
local Settings = {}

--- 設定項目の既定値。未設定キーはこの値を返す。
local DEFAULTS = {
  asepriteExecutablePath = "",
  defaultWorkingDir = "",
  followActiveSprite = true,
  showUnsavedWarning = true,
}

local pluginRef = nil

--- 設定テーブル(plugin.preferences.settings)を取得する。
-- @return table|nil
local function settingsTable()
  if pluginRef and pluginRef.preferences then
    if pluginRef.preferences.settings == nil then
      pluginRef.preferences.settings = {}
    end
    return pluginRef.preferences.settings
  end
  return nil
end

--- プラグイン参照を保持する。`init(plugin)` から一度だけ呼ぶ。
-- @param plugin table Aseprite が渡すプラグインオブジェクト
function Settings.init(plugin)
  pluginRef = plugin
  settingsTable()
end

--- 設定値を1件取得する。未設定時は既定値を返す。
-- @param key string
-- @return any
function Settings.get(key)
  local t = settingsTable()
  local value = t and t[key]
  if value == nil then
    return DEFAULTS[key]
  end
  return value
end

--- 設定値を1件保存する。
-- @param key string
-- @param value any
function Settings.set(key, value)
  local t = settingsTable()
  if t then
    t[key] = value
  end
end

--- 全設定項目を既定値で補完したテーブルとして返す。
-- @return table
function Settings.load()
  local result = {}
  for key in pairs(DEFAULTS) do
    result[key] = Settings.get(key)
  end
  return result
end

--- 複数の設定値をまとめて保存する。
-- @param values table
function Settings.save(values)
  for key, value in pairs(values) do
    Settings.set(key, value)
  end
end

--- 履歴など、設定テーブル以外のセクションを取得する。
-- @param name string セクション名(例: "history")
-- @return any
function Settings.getSection(name)
  if pluginRef and pluginRef.preferences then
    return pluginRef.preferences[name]
  end
  return nil
end

--- 履歴など、設定テーブル以外のセクションを保存する。
-- @param name string
-- @param value any
function Settings.setSection(name, value)
  if pluginRef and pluginRef.preferences then
    pluginRef.preferences[name] = value
  end
end

return Settings

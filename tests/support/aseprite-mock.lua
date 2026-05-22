--- ユニットテスト用の最小限の Aseprite API モック。
-- 現在の純粋ロジックのテスト(strings / command-builder / history-store)では
-- 未使用だが、`app` に依存するモジュールを今後テストする際の足場として提供する。
local mock = {}

--- グローバル `app` に最小限のモックを設定する。
function mock.installApp()
  _G.app = {
    fs = {
      tempPath = "/tmp",
      pathSeparator = "/",
      joinPath = function(a, b) return a .. "/" .. b end,
      filePath = function(p) return (p:gsub("[/\\][^/\\]*$", "")) end,
      userDocsPath = "/home/user/Documents",
    },
  }
end

--- グローバル `app` を解除する。
function mock.uninstallApp()
  _G.app = nil
end

return mock

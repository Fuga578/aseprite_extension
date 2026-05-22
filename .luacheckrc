-- luacheck 設定(`luacheck src` で使用)

std = "lua54"

-- このプロジェクトが定義するグローバル(Aseprite が呼び出すエントリ関数)
globals = {
  "init",
  "exit",
}

-- Aseprite が提供するグローバル(読み取りのみ)
read_globals = {
  "app",
  "Dialog",
  "Color",
  "Point",
  "Rectangle",
  "Size",
  "Sprite",
  "Image",
  "MouseButton",
  "KeyModifier",
}

-- コールバック中心のコードのため、未使用引数は警告しない
unused_args = false

-- 日本語コメントを含むため、行長チェックは無効化(byte数で誤検出するため)
max_line_length = false

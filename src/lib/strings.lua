--- 文字列処理の共通ユーティリティ。
-- 他レイヤーに依存しない純粋関数のみを提供する。
local strings = {}

--- 文字列前後の空白を取り除く。
-- @param s string|nil
-- @return string|nil 入力が文字列でない場合はそのまま返す
function strings.trim(s)
  if type(s) ~= "string" then
    return s
  end
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- 値が nil または空白のみの文字列かどうかを返す。
-- @param s any
-- @return boolean
function strings.isBlank(s)
  if s == nil then
    return true
  end
  if type(s) ~= "string" then
    return false
  end
  return s:match("^%s*$") ~= nil
end

--- シェルに渡すためにダブルクオートで囲む。
-- 実行ファイルパスや一時ファイルパスのスペース対応に使用する。
-- @param s string
-- @return string
function strings.quote(s)
  return '"' .. tostring(s) .. '"'
end

--- 文字列が指定の接頭辞で始まるかを返す。
-- @param s string
-- @param prefix string
-- @return boolean
function strings.startsWith(s, prefix)
  return s:sub(1, #prefix) == prefix
end

--- 文字列を最初の単語(空白区切り)と残りに分割する。
-- @param s string
-- @return string firstWord, string rest 入力が空のときは "", "" を返す
function strings.splitFirstWord(s)
  local trimmed = strings.trim(s) or ""
  local firstWord, rest = trimmed:match("^(%S+)%s*(.*)$")
  if not firstWord then
    return "", ""
  end
  return firstWord, rest
end

return strings

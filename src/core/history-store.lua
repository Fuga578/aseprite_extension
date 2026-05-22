--- コマンド履歴の保持・FIFO上限管理・呼び出しナビゲーション・永続化。
-- コアレイヤー。永続化バックエンドは注入式で、テスト時は偽バックエンドを渡せる。
local HistoryStore = {}

--- 履歴の上限件数。超過時は最古から削除する。
local MAX_HISTORY = 100

local entries = {}        -- HistoryEntry のリスト(古い順)
local recallIndex = nil   -- recall() のナビゲーションカーソル
local storage = nil       -- 永続化バックエンド { load:fn->list, save:fn(list) }

--- 履歴ストアを初期化する。永続化バックエンドを任意で受け取る。
-- @param storageBackend table|nil { load:function->table, save:function(table) }
function HistoryStore.init(storageBackend)
  storage = storageBackend
  if storage and storage.load then
    entries = storage.load() or {}
  else
    entries = {}
  end
  recallIndex = nil
end

--- 履歴を1件追加する。FIFO上限を適用し、バックエンドがあれば永続化する。
-- @param entry table HistoryEntry { command, timestamp, exitCode, success }
function HistoryStore.add(entry)
  table.insert(entries, entry)
  while #entries > MAX_HISTORY do
    table.remove(entries, 1)
  end
  recallIndex = nil
  if storage and storage.save then
    storage.save(entries)
  end
end

--- 履歴リスト(古い順)を返す。
-- @return table HistoryEntry の配列
function HistoryStore.list()
  return entries
end

--- 履歴の件数を返す。
-- @return number
function HistoryStore.count()
  return #entries
end

--- 履歴をたどってコマンド文字列を返す。
-- @param direction string "up"(より古い) または "down"(より新しい)
-- @return string|nil カーソル位置のコマンド。最新より新しい位置では ""。履歴が空なら nil
function HistoryStore.recall(direction)
  if #entries == 0 then
    return nil
  end
  if recallIndex == nil then
    -- 初回はカーソルを「最新の1つ次(空の入力位置)」に置く
    recallIndex = #entries + 1
  end
  if direction == "up" then
    recallIndex = math.max(1, recallIndex - 1)
  elseif direction == "down" then
    recallIndex = math.min(#entries + 1, recallIndex + 1)
  end
  local entry = entries[recallIndex]
  if entry then
    return entry.command
  end
  return ""
end

--- recall のカーソルをリセットする(ユーザーが入力を編集したとき等に呼ぶ)。
function HistoryStore.resetRecall()
  recallIndex = nil
end

return HistoryStore

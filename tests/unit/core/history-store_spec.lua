--- core/history-store のユニットテスト。
local HistoryStore = require("core.history-store")

--- HistoryEntry を生成するヘルパー。
local function entry(cmd)
  return { command = cmd, timestamp = 0, exitCode = 0, success = true }
end

describe("HistoryStore 追加と上限", function()
  before_each(function()
    HistoryStore.init(nil)
  end)

  it("追加した履歴を保持する", function()
    HistoryStore.add(entry("a"))
    HistoryStore.add(entry("b"))
    assert.are.equal(2, HistoryStore.count())
  end)

  it("FIFOで上限100件を超えない", function()
    for i = 1, 105 do
      HistoryStore.add(entry("cmd" .. i))
    end
    assert.are.equal(100, HistoryStore.count())
    local list = HistoryStore.list()
    assert.are.equal("cmd6", list[1].command)
    assert.are.equal("cmd105", list[#list].command)
  end)
end)

describe("HistoryStore recall", function()
  before_each(function()
    HistoryStore.init(nil)
  end)

  it("空の履歴では nil を返す", function()
    assert.is_nil(HistoryStore.recall("up"))
  end)

  it("up で新しい順にコマンドを返す", function()
    HistoryStore.add(entry("first"))
    HistoryStore.add(entry("second"))
    assert.are.equal("second", HistoryStore.recall("up"))
    assert.are.equal("first", HistoryStore.recall("up"))
  end)

  it("up は先頭で止まる", function()
    HistoryStore.add(entry("only"))
    HistoryStore.recall("up")
    assert.are.equal("only", HistoryStore.recall("up"))
  end)

  it("down で新しい方へ戻り、最新より先は空文字を返す", function()
    HistoryStore.add(entry("first"))
    HistoryStore.add(entry("second"))
    HistoryStore.recall("up")
    HistoryStore.recall("up")
    assert.are.equal("second", HistoryStore.recall("down"))
    assert.are.equal("", HistoryStore.recall("down"))
  end)
end)

describe("HistoryStore 永続化バックエンド", function()
  it("init で load、add で save を呼ぶ", function()
    local saved = nil
    local backend = {
      load = function()
        return { entry("persisted") }
      end,
      save = function(list)
        saved = list
      end,
    }
    HistoryStore.init(backend)
    assert.are.equal(1, HistoryStore.count())
    assert.are.equal("persisted", HistoryStore.list()[1].command)

    HistoryStore.add(entry("new"))
    assert.is_not_nil(saved)
    assert.are.equal(2, #saved)
  end)
end)

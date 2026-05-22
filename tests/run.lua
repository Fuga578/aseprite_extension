-- Pure-Lua unit test runner for AseCLI.
--
-- Runs the *_spec.lua files with a plain Lua interpreter -- no busted and no
-- luarocks required. This is the practical way to run the tests on Windows,
-- where building the Lua C toolchain (needed by busted/luacheck) is awkward.
--
-- Usage, from the project root:
--   lua tests/run.lua
--
-- A .busted config is also provided for environments that have busted.
-- The runner implements just the subset of the busted/luassert API the
-- specs use: describe / it / before_each and assert.are(.equal) etc.

-- Spec files, relative to the project root. Add new spec files here.
local SPECS = {
  "tests/unit/lib/strings_spec.lua",
  "tests/unit/core/command-builder_spec.lua",
  "tests/unit/core/history-store_spec.lua",
}

-- Make src/ modules require-able, e.g. require("core.command-builder").
package.path = package.path .. ";./src/?.lua"

-- ---- assertion shim (subset of luassert used by the specs) ----
local function fail(msg)
  error(msg, 2)
end

local A = {}
A.are = {
  equal = function(expected, actual)
    if expected ~= actual then
      fail(string.format("are.equal: expected [%s] got [%s]",
        tostring(expected), tostring(actual)))
    end
  end,
}
A.are_not = {
  equal = function(notExpected, actual)
    if notExpected == actual then
      fail(string.format("are_not.equal: did not expect [%s]", tostring(notExpected)))
    end
  end,
}
function A.is_true(v)
  if v ~= true then fail("is_true: got [" .. tostring(v) .. "]") end
end
function A.is_false(v)
  if v ~= false then fail("is_false: got [" .. tostring(v) .. "]") end
end
function A.is_nil(v)
  if v ~= nil then fail("is_nil: got [" .. tostring(v) .. "]") end
end
function A.is_not_nil(v)
  if v == nil then fail("is_not_nil: got nil") end
end
function A.is_truthy(v)
  if not v then fail("is_truthy: got [" .. tostring(v) .. "]") end
end
setmetatable(A, {
  __call = function(_, v, msg)
    if not v then fail(msg or "assertion failed") end
    return v
  end,
})
assert = A

-- ---- describe / it / before_each shim ----
local beforeStack = {}
local prefixStack = {}
local passCount = 0
local failCount = 0
local failures = {}

function describe(name, fn)
  prefixStack[#prefixStack + 1] = name
  beforeStack[#beforeStack + 1] = {}
  local ok, err = pcall(fn)
  if not ok then
    failCount = failCount + 1
    failures[#failures + 1] =
      table.concat(prefixStack, " > ") .. " :: describe error: " .. tostring(err)
  end
  beforeStack[#beforeStack] = nil
  prefixStack[#prefixStack] = nil
end

function before_each(fn)
  local scope = beforeStack[#beforeStack]
  scope[#scope + 1] = fn
end

function it(name, fn)
  local function run()
    for _, scope in ipairs(beforeStack) do
      for _, hook in ipairs(scope) do
        hook()
      end
    end
    fn()
  end
  local ok, err = pcall(run)
  local label = table.concat(prefixStack, " > ") .. " > " .. name
  if ok then
    passCount = passCount + 1
    print("  PASS  " .. label)
  else
    failCount = failCount + 1
    failures[#failures + 1] = label .. "\n          " .. tostring(err)
    print("  FAIL  " .. label)
  end
end

-- ---- run the spec files ----
for _, spec in ipairs(SPECS) do
  print("# " .. spec)
  local chunk, loadErr = loadfile(spec)
  if not chunk then
    failCount = failCount + 1
    failures[#failures + 1] = spec .. " :: load error: " .. tostring(loadErr)
    print("  FAIL  (load) " .. tostring(loadErr))
  else
    local ok, err = pcall(chunk)
    if not ok then
      failCount = failCount + 1
      failures[#failures + 1] = spec .. " :: run error: " .. tostring(err)
      print("  FAIL  (run) " .. tostring(err))
    end
  end
end

print("")
print(string.format("RESULT: %d passed, %d failed", passCount, failCount))
if #failures > 0 then
  print("")
  print("FAILURES:")
  for _, f in ipairs(failures) do
    print("  - " .. f)
  end
  os.exit(1)
end
os.exit(0)

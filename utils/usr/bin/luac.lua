-- luac: A simple preprocessor for Lua programs. Probably works for other languages as well. --
-- Supports simple, one-line macros (Lua only) and includes. --

local args, options = shell.parse(...)

local verbose = options.v or options.verbose or false

if #args < 1 and not options.help then
  return print("luac: error: no input files specified")
end

if options.help then
  return print("Usage: luac FILE OUT")
end

local pwd = os.getenv("PWD")

local function proc(c)
  local seg = string.tokenize(" ", c)
  local cmd = seg[1]
  table.remove(seg, 1)
  if cmd == "--#macro" or cmd == "##macro" then
    local name = seg[1]
    table.remove(seg, 1)
    print("luac: macro " .. name)
    local m = table.concat(seg, " ")
    local ok, err = load(m, "=luac.macro(" .. name .. ")", "t", _G)
    if not ok then
      return false, "error " .. err " running macro " .. name
    end
    local s, r = pcall(ok)
    if not s then
      return false, "error " .. r .. " running macro " .. name
    end
    return r
  elseif cmd == "--#include" or cmd == "##include" then
    print("luac: include " .. pwd .. "/" .. seg[1])
    local handle, err = io.open(pwd .. "/" .. seg[1], "r")
    if not handle then
      return false, pwd .. "/" .. seg[1] .. ": " .. err
    end
    local data = handle:readAll()
    handle:close()
    return data
  elseif cmd == "--#log" or cmd == "##log" then
    print("luac: log " .. table.concat(seg, " " ))
    return ""
  end
end

local function procfname(d)
  local seg = string.tokenize("/", d)
  local fname = seg[#seg]
  table.remove(seg, #seg)
  local dname = table.concat(seg, "/")
  return dname, fname
end

local function procline(l)
  if l:sub(1,2) == "##" then
    return proc(l)
  else
    return l
  end
end

print("luac: running preprocessor on " .. args[1])
local d, f = procfname(shell.resolve(args[1]))
local out = shell.resolve(args[2])
local handle, err = io.open(d .. "/" .. f)
if not handle then
  return false, err, error("luac: " .. d .. "/" .. f .. ": " .. err)
end
local data = handle:readAll()
handle:close()
local out = io.open(out, "w")
for line in data:gmatch("[^\n]+") do
  local ln, err = procline(line, d)
  if not ln then
    return error("luac: " .. err)
  end
  out:write(ln .. "\n")
end
out:close()

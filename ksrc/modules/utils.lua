kernel.log("Setting up utilities")

kernel.log("util: loadfile")
function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  local file = cleanPath(file)
  local mode = mode or "bt"
  local env = env or _G
  kernel.log("loadfile: loading " .. file .. " with mode " .. mode)
  local handle, err = fs.open(file, "r")
  if not handle then
    return false, err
  end

  local data = ""
  repeat
    local d = handle.read(math.huge)
    data = data .. (d or "")
  until not d

  handle.close()

  return load(data, "=" .. file, mode, env)
end

kernel.log("util: table.new")
function table.new(...)
  local tbl = {...} or {}
  return setmetatable(tbl, {__index = table})
end

kernel.log("util: table.copy")
function table.copy(tbl)
  checkArg(1, tbl, "table")
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end
  return rtn
end

kernel.log("util: table.serialize")
function table.serialize(tbl) -- Readability is not a strong suit of this function's output.
  checkArg(1, tbl, "table")
  local rtn = "{"
  for k, v in pairs(tbl) do
    if type(k) == "string" then
      rtn = rtn .. "[\"" .. k .. "\"] = "
    else
      rtn = rtn .. "[" .. tostring(k) .. "] = "
    end
    if type(v) == "table" then
      rtn = rtn .. table.serialize(v)
    elseif type(v) == "string" then
      rtn = rtn .. "\"" .. tostring(v) .. "\""
    else
      rtn = rtn .. tostring(v)
    end
    rtn = rtn .. ","
  end
  rtn = rtn .. "}"
  return rtn
end

kernel.log("util: table.iter")
function table.iter(tbl) -- Iterate over the items in a table
  checkArg(1, tbl, "table")
  local i = 1
  return setmetatable(tbl, {__call = function()
    if tbl[i] then
      i = i + 1
      return tbl[i - 1]
    else
      return nil
    end
  end})
end

kernel.log("util: string.tokenize")
function string.tokenize(sep, ...)
  checkArg(1, sep, "string")
  local line = table.concat({...}, sep)
  local words = table.new()
  for word in line:gmatch("[^" .. sep .. "]+") do
    words:insert(word)
  end
  local i = 1
  setmetatable(words, {__call = function() -- iterators! they're great!
    if words[i] then
      i = i + 1
      return words[i - 1]
    else
      return nil
    end
  end})
  return words
end

kernel.log("util: os.sleep")
local pullSignal = computer.pullSignal
function os.sleep(time)
  local dest = uptime() + time
  repeat
    pullSignal(dest - uptime())
  until uptime() >= dest
end

kernel.log("util: fs.clean")
function fs.clean(path)
  checkArg(1, path, "string")
  return cleanPath(path)
end

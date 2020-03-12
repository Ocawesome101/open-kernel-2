kernel.log("Initializing device FS")
do
  local dfs = {}

  local devices = {}

  local handles = {}

  -- Generate a component address --
  local s = {4,2,2,2,6}
  local addr = ""
  local p = 0

  for _,_s in ipairs(s) do
    if #addr > 0 then
      addr = addr .. "-"
    end
    for _=1, _s, 1 do
      local b = math.random(0, 255)
      if p == 6 then
        b = (b & 0x0F) | 0x40
      elseif p == 8 then
        b = (b & 0x3F) | 0x80
      end
      addr = addr .. ("%02x"):format(b)
      p = p + 1
    end
  end

  dfs.type = "filesystem"
  dfs.address = addr

  local types = {
    ["filesystem"] = "fs",
    ["gpu"] = "gpu",
    ["screen"] = "scrn",
    ["keyboard"] = "kb",
    ["eeprom"] = "eeprom",
    ["redstone"] = "rs",
    ["computer"] = "comp",
    ["disk_drive"] = "sr",
    ["internet"] = "inet",
    ["modem"] = "mnet"
  }

  local function addDfsDevice(addr, dtype)
    if addr == dfs.address then return end
  --  kernel.log(addr .. " " .. dtype)
    local path = "/" .. (types[dtype] or dtype)
    if dtype == "filesystem" and kernel.__component.invoke(addr, "getLabel") == "devfs" then
      return
    end
    local n = 0
    for k,v in pairs(devices) do
      if v.proxy and v.path and v.proxy.address then
        if v.proxy.address == addr then
          return
        end
        if v.proxy.type == dtype then
          n = n + 1
        end
      end
    end
    path = path .. n
    kernel.log("devfs: adding device " .. addr .. " at /dev" .. path)
    devices[#devices + 1] = {path = path, proxy = kernel.__component.proxy(addr)}
  end

  event.listen("device_added", addDfsDevice)

  local function resolveDevice(d)
    for k,v in pairs(devices) do
      if v.path == d then
        return v
      end
    end
    return false, "No such device"
  end

  local function makeHandleEEPROM(eepromProxy, mode)
    checkArg(1, eepromProxy, "table")
    checkArg(2, mode, "string", "nil")
    if eepromProxy.type ~= "eeprom" then return false, "Device is not an EEPROM" end
    local d = {}
    function d:read()
      return eepromProxy.get(), "Failed to read EEPROM"
    end
    handles[#handles + 1] = d
    return d, #handles
  end

  function dfs.open(dev, mode)
    checkArg(1, dev, "string")
    checkArg(2, mode, "string", "nil")
    local device = resolveDevice(dev)
    if device.proxy.type == "eeprom" then
      local handle = makeHandleEEPROM(device, mode)
      return handle
    else
      return false, "Only EEPROMs are currently supported for opening"
    end
  end

  function dfs.isDirectory(d)
    checkArg(1, d, "string")
    if d == "/" then
      return true
    else
      return false
    end
  end

  function dfs.exists(f)
    checkArg(1, f, "string")
    kernel.log("devfs: checking existence " .. f)
    if resolveDevice(f) or fs.clean(f) == "/" then
      return true
    else
      return false
    end
  end

  function dfs.list(p)
    checkArg(1, p, "string")
    local l = {}
    if not dfs.isDirectory(p) then
      return false, "Not a directory"
    end
    for k,v in pairs(devices) do
      l[#l + 1] = fs.clean(v.path):sub(#p + 1)
    end
    return l
  end

  function dfs.permissions()
    return 0
  end

  function dfs.lastModified()
    return 0
  end

  function dfs.close(num)
    handles[num] = nil
  end

  function dfs.spaceTotal()
    return 1024
  end

  function dfs.isReadOnly()
    return true
  end

  function dfs.getLabel() return "devfs" end
  function dfs.setLabel() return true end

  component.create(dfs)
  fs.mount(dfs.address, "/dev")

  for addr, ctype in component.list() do
    addDfsDevice(addr, ctype)
  end

  _G.devfs = {
    getAddress = function(device)
      local proxy = resolveDevice(device)
      return proxy.address
    end,
    poke = function(device, operation, ...)
      local proxy = resolveDevice(device)
      if proxy[operation] then
        return proxy[operation](...)
      end
    end
  }
end

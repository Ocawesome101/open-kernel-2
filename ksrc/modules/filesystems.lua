kernel.log("Initializing filesystems")

bootfs.remove("/mnt")

_G.fs = {}

local mounts = {
  {
    path = "/",
    proxy = bootfs
  }
}

kernel.log("Stage 1: helpers")
local function cleanPath(p)
  checkArg(1, p, "string")
  local path = ""
  for segment in p:gmatch("[^%/]+") do
    path = path .. "/" .. (segment or "")
  end
  if path == "" then
    path = "/"
  end
  return path
end

local function resolve(path) -- Resolve a path to a filesystem proxy
  checkArg(1, path, "string")
  local proxy
  local path = cleanPath(path)
  for i=1, #mounts, 1 do
    if mounts[i] and mounts[i].path then
      local pathSeg = cleanPath(path:sub(1, #mounts[i].path))
--      kernel.log(pathSeg .. " =? " .. mounts[i].path)
      if pathSeg == mounts[i].path then
        path = cleanPath(path:sub(#mounts[i].path + 1))
        proxy = mounts[i].proxy
      end
    end
  end
  if proxy then
     return cleanPath(path), proxy
  end
end

kernel.__component = component

kernel.log("Stage 2: mounting, unmounting")
function fs.mount(addr, path)
  checkArg(1, addr, "string")
  checkArg(2, path, "string", "nil")
  local label = kernel.__component.invoke(addr, "getLabel")
  label = (label ~= "" and label) or nil
  local path = path or "/mnt/" .. (label or addr:sub(1, 6))
  path = cleanPath(path)
  local p, pr = resolve(path)
  for _, data in pairs(mounts) do
    if data.path == path then
      if data.proxy.address == addr then
        return true, "Filesystem already mounted"
      else
        return false, "Cannot override existing mounts"
      end
    end
  end
  if kernel.__component.type(addr) == "filesystem" then
    if path == "/mnt/devfs" then
      return
    end
    kernel.log("Mounting " .. addr .. " on " .. path)
    if fs.makeDirectory then
      fs.makeDirectory(path)
    else
      bootfs.makeDirectory(path)
    end
    mounts[#mounts + 1] = {path = path, proxy = kernel.__component.proxy(addr)}
    return true
  end
  kernel.log("Failed mounting " .. addr .. " on " .. path)
  return false, "Unable to mount"
end

function fs.unmount(path)
  checkArg(1, path, "string")
  for k, v in pairs(mounts) do
    if v.path == path then
      kernel.log("Unmounting filesystem " .. path)
      mounts[k] = nil
      fs.remove(v.path)
      return true
    elseif v.proxy.address == path then
      kernel.log("Unmounting filesystem " .. v.proxy.address)
      mounts[k] = nil
      fs.remove(v.path)
    end
  end
  return false, "No such mount"
end

function fs.mounts()
  local rtn = {}
  for k,v in pairs(mounts) do
    rtn[k] = {path = v.path, address = v.proxy.address, label = v.proxy.getLabel()}
  end
  return rtn
end

kernel.log("Stage 3: standard FS API")
function fs.exists(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(cleanPath(path))
  if not proxy.exists(path) then
    return false
  else
    return true
  end
end

function fs.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  if not fs.exists(file) and mode ~= "w"  then
    return false, "No such file or directory"
  end
  local mode = mode or "r"
  if mode ~= "r" and mode ~= "rw" and mode ~= "w" then
    return false, "Unsupported mode"
  end
  kernel.log("Opening file " .. file .. " with mode " .. mode)
  local path, proxy = resolve(file)
  local h, err = proxy.open(path, mode)
  if not h then
    return false, err
  end
  local handle = {}
  if mode == "r" or mode == "rw" or not mode then
    handle.read = function(n)
      return proxy.read(h, n)
    end
  end
  if mode == "w" or mode == "rw" then
    handle.write = function(d)
      return proxy.write(h, d)
    end
  end
  handle.close = function()
    proxy.close(h)
  end
  handle.handle = function()
    return h
  end
  return handle
end

fs.read = bootfs.read
fs.write = bootfs.write
fs.close = bootfs.close

function fs.list(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.list(path)
end

function fs.remove(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.remove(path)
end

function fs.spaceUsed(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceUsed()
end

function fs.makeDirectory(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.makeDirectory(path)
end

function fs.isReadOnly(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.isReadOnly()
end

function fs.spaceTotal(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceTotal()
end

function fs.isDirectory(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

--  kernel.log(path .. " " .. proxy.type .. " " .. proxy.address .. " " .. type(proxy.isDirectory))
  return proxy.isDirectory(path)
end

function fs.copy(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local spath, sproxy = resolve(source)
  local dpath, dproxy = resolve(dest)

  local s, err = sproxy.open(spath, "r")
  if not s then
    return false, err
  end
  local d, err = dproxy.open(dpath, "w")
  if not d then
    sproxy.close(s)
    return false, err
  end
  repeat
    local data = sproxy.read(s, 0xFFFF)
    dproxy.write(d, (data or ""))
  until not data
  sproxy.close(s)
  dproxy.close(d)
  return true
end

function fs.rename(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")

  local ok, err = fs.copy(source, dest)
  if ok then
    fs.remove(source)
  else
    return false, err
  end
end

function fs.canonicalPath(path)
  checkArg(1, path, "string")
  local segments = string.tokenize("/", path)
  for i=1, #segments, 1 do
    if segments[i] == ".." then
      segments[i] = ""
      table.remove(segments, i - 1)
    end
  end
  return cleanPath(table.concat(segments, "/"))
end

function fs.path(path)
  checkArg(1, path, "string")
  local segments = string.tokenize("/", path)
  
  return cleanPath(table.concat({table.unpack(segments, 1, #segments - 1)}, "/"))
end

function fs.name(path)
  checkArg(1, path, "string")
  local segments = string.tokenize("/", path)

  return segments[#segments]
end

function fs.get(path)
  checkArg(1, path, "string")
  if not fs.exists(path) then
    return false, "Path does not exist"
  end
  local path, proxy = resolve(path)

  return proxy
end

function fs.lastModified(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.lastModified(path)
end

function fs.getLabel(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.getLabel()
end

function fs.setLabel(label, path)
  checkArg(1, label, "string")
  checkArg(2, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.setLabel(label)
end

function fs.size(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.size(path)
end

for addr, _ in component.list("filesystem") do
  if addr ~= bootfs.address then
    if component.invoke(addr, "getLabel") == "tmpfs" then
      fs.mount(addr, "/tmp")
    else
      fs.mount(addr)
    end
  end
end

kernel.log("Reading /etc/fstab")

-- /etc/fstab specifies filesystems to mount in locations other than /mnt, if any. Note that this is fileystem-specific and as such noin other news, I've t included by default.

local fstab = {}

local handle, err = fs.open("/etc/fstab", "r")
if not handle then
  kernel.log("Failed to read fstab: " .. err)
else
  local buffer = ""
  repeat
    local data = handle.read(0xFFFF)
    buffer = buffer .. (data or "")
  until not data
  handle.close()

  local ok, err = load("return " .. buffer, "=kernel.parse_fstab", "bt", _G)
  if not ok then
    kernel.log("Failed to parse fstab: " .. err)
  else
    fstab = ok()
  end
end

for k, v in pairs(fstab) do
  for a, t in component.list() do
    if a == k and t == "filesystem" then
      fs.mount(k, fstab[v])
    end
  end
end

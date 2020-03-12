-- kernel API --

local uptime = computer.uptime
local function time() -- Properly format the computer's uptime so we can print it nicely
  local r = tostring(uptime()):sub(1,7)
  local c,_ = r:find("%.")
  local c = c or 4
  if c < 4 then
    r = string.rep("0",4-c) .. r
  elseif c > 4 then
    r = r .. string.rep("0",c-4)
  end
  while #r < 7 do
    r = r .. "0"
  end
  return r
end

pcall(bootfs.rename("/boot/log", "/boot/log.old"))

local kernelLog, err = bootfs.open("/boot/log", "w")
local verbose = flags.verbose

_G.kernel = {}

kernel._VERSION = _KERNEL_VERSION
kernel._BUILDID = _KERNEL_BUILDID

function kernel.uname(o)
  checkArg(1, o, "string", "nil")
  return (o == "full" and _KERNEL_VERSION_FULL) or (o == "name" and _KERNEL_NAME) or (o == "arch" and _KERNEL_ARCH) or (o == "build" and _KERNEL_BUILDDATE) or "Invalid option " .. o
end

function kernel.log(msg)
  local m = "[" .. time() .. "] " .. msg
  if not flags.disableLogging then bootfs.write(kernelLog, m .. "\n") end
  if verbose then
    print(m)
  end
end

function kernel.setlogs(boolean)
  checkArg(1, boolean, "boolean")
  verbose = boolean
end

kernel.log(kernel._VERSION .. " booting on " .. _VERSION)

kernel.log("Total memory: " .. tostring(math.floor(computer.totalMemory() / 1024)) .. "K")
kernel.log("Free memory: " .. tostring(math.floor(computer.freeMemory() / 1024)) .. "K")

local native_shutdown = computer.shutdown
computer.shutdown = function(b) -- make sure the log file gets properly closed
  kernel.log("Shutting down")
  bootfs.close(kernelLog)
  native_shutdown(b)
end

local native_error = error

local pullSignal = computer.pullSignal
local shutdown = computer.shutdown
function _G.error(err, level)
  if level == -1 or level == "__KPANIC__" then
    kernel.setlogs(true) -- The user should see this
    kernel.log(("="):rep(25))
    kernel.log("PANIC: " .. err)
    local traceback = debug.traceback(nil, 2)
    for line in traceback:gmatch("[^\n]+") do
      kernel.log(line)
    end
    kernel.log("Press S to shut down.")
    kernel.log(("="):rep(25))
    while true do
      local e, _, id = pullSignal()
      if e == "key_down" and string.char(id):lower() == "s" then
        shutdown()
      end
    end
  else
    return native_error(err, level or 2)
  end
end

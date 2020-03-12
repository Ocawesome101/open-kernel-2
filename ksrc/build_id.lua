local time = os.time()
local date = os.date()

local name_string = "Open Kernel 2"
local id_string = string.format("%08x", time)
local ver_string = name_string .. "-" .. id_string
local arch_string = "Lua 5.3"
local date_string = date
local ver_full = table.concat({ver_string, date_string, arch_string}, " ")

local v = [[
local _KERNEL_VERSION = "]] .. ver_string .. [["
local _KERNEL_BUILDDATE = "]] .. date .. [["
local _KERNEL_BUILDID = "]] .. id_string .. [["
local _KERNEL_ARCH = "]] .. arch_string .. [["
local _KERNEL_NAME = "]] .. name_string .. [["
local _KERNEL_VERSION_FULL = "]] .. ver_full .. [["
]]

local h, err = io.open(os.getenv("PWD") .. "/modules/version.lua", "w")
if not h then
  error(err)
end
h:write(v)
h:close()

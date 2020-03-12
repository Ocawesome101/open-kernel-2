local flags = ... or {}

local bootAddress = computer.getBootAddress()
local startTime = computer.uptime()

local bootfs = component.proxy(((pcall(component.type, flags.bootAddress)) and flags.bootAddress) or bootAddress) -- You can specify a custom boot-address, this should check if it's valid
local init = flags.init or "/sbin/init.lua"
 

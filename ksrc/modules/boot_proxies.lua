-- component proxies
_G.gpu = component.list("gpu")()
local screen = component.list("screen")()

if not (gpu and screen) then
  error("Open Kernel 2 requires a screen and GPU")
end

gpu = component.proxy(gpu)

gpu.setResolution(gpu.maxResolution())
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)

local x, y = 1, 1
local w, h = gpu.getResolution()

gpu.fill(1, 1, w, h, " ")

function gpu.getCursor()
  return x, y
end

function gpu.setCursor(X,  Y)
  checkArg(1, X, "number")
  checkArg(2, Y, "number")
  x, y = X, Y
end

function gpu.scroll(amount)
  checkArg(1, amount, "number")
  gpu.copy(1, 1, w, h, 0, 0 - amount)
  gpu.fill(1, h, w, amount, " ")
end

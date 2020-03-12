kernel.log("Initializing fancy event handling")
do
  _G.event = {}
  local pullSignal, pushSignal = computer.pullSignal, computer.pushSignal

  event.push = function(e, ...)
    kernel.log("events: Pushing signal " .. e)
    pushSignal(e, ...)
  end

  local listeners = {
    ["component_added"] = function(addr, ctype)
      if ctype == "filesystem" then
        fs.mount(addr)
      elseif ctype == "eeprom" then
        package.loaded["eeprom"] = kernel.__component.proxy(addr)
      end
      pushSignal("device_added", addr, ctype) -- for devfs processing. Bit hacky.
    end,
    ["component_removed"] = function(addr, ctype)
      if ctype == "filesystem" then
        fs.unmount(addr)
      elseif ctype == "eeprom" then
        package.loaded["eeprom"] = nil
      end
      pushSignal("device_removed", addr) -- again, for devfs processing, bit hacky, yadda yadda yadda
    end
  }

  event.listen = function(evt, func)
    checkArg(1, evt, "string")
    checkArg(2, func, "function")
    if listeners[evt] then
      return false, "Event listener already in place for event " .. evt
    else
      listeners[evt] = func
      return true
    end
  end

  event.cancel = function(evt)
    checkArg(1, evt, "string")
    if not listeners[evt] then
      return false, "No event listener for event " .. evt
    else
      listeners[evt] = nil
      return true
    end
  end

  event.pull = function(filter, timeout)
    checkArg(1, filter, "string", "nil")
    checkArg(2, timeout, "number", "nil")
--    kernel.log("events: pulling event " .. (filter or "<any>") .. ", timeout " .. (tostring(timeout) or "none"))
    if timeout then
      local e = {pullSignal(timeout)}
--      kernel.log("events: got " .. (e[1] or "nil"))
      if listeners[e[1]] then
        listeners[e[1]](table.unpack(e, 2, #e))
      end
      if e[i] == filter or not filter then
        return table.unpack(e)
      end
    else
      local e = {}
      repeat
        e = {pullSignal()}
--        kernel.log("events: got " .. e[1])
        if listeners[e[1]] then
          listeners[e[1]](table.unpack(e, 2, #e))
        end
      until e[1] == filter or filter == nil
      return table.unpack(e)
    end
  end
end

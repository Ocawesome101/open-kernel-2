kernel.log("Initializing cooperative scheduler")
do
  local tasks = {}
  local pid = 1
  local currentpid = 0
  local timeout = (type(flags.processTimeout) == "number" and flags.processTimeout) or 0.10
  local freeMemory = computer.freeMemory
    
  function os.spawn(func, name)
    checkArg(1, func, "function")
    checkArg(2, name, "string")
    if freeMemory() < 128 then
      error("Out of memory", -1)
    end
    kernel.log("scheduler: Spawning task " .. tostring(pid) .. " with ID " .. name)
    tasks[pid] = {
      coro = coroutine.create(func),
      id = name,
      pid = pid,
      parent = currentpid
    }
    pid = pid + 1
    return pid - 1
  end

  function os.kill(pid)
    checkArg(1, pid, "number")
    if not tasks[pid] then return false, "No such process" end
    if pid == 1 then return false, "Cannot kill init" end
    kernel.log("scheduler: Killing task " .. tasks[pid].id .. " (PID ".. tostring(pid) .. ")")
    tasks[pid] = nil
  end

  function os.tasks()
    local r = {}
    for k,v in pairs(tasks) do
      r[#r + 1] = k
    end
    return r
  end

  function os.pid()
    return currentpid
  end

  function os.info(pid)
    checkArg(1, pid, "number", "nil")
    local pid = pid or os.pid()
    if not tasks[pid] then return false, "No such process" end
    return {name = tasks[pid].id, parent = tasks[pid].parent, pid = tasks[pid].pid}
  end
  
  function os.exit()
    os.kill(currentpid)
    coroutine.yield()
  end
  
  function os.start() -- Start the scheduler
    os.start = nil
    while #tasks > 0 do
      local eventData = {pullSignal(timeout)}
      for k, v in pairs(tasks) do
        if freeMemory() < 256 then
          error("Out of memory", -1)
        end
        if v.coro and coroutine.status(v.coro) ~= "dead" then
          currentpid = k
--          kernel.log("Current: " .. tostring(k))
          local ok, err = coroutine.resume(v.coro, table.unpack(eventData))
          if not ok and err then
            local err = "ERROR IN THREAD " .. tostring(k) .. ": " .. v.id .. "\n" .. debug.traceback(err, 1)
            kernel.log(err)
            print(err)
            kernel.log("scheduler: Task " .. v.id .. " (PID " .. tostring(k) .. ") died: " .. err)
            tasks[k] = nil
          end
        elseif v.coro then
          kernel.log("scheduler: Task " .. v.id .. " (PID " .. tostring(k) .. ") died")
          tasks[k] = nil
        end
      end
    end
    kernel.log("scheduler: all tasks exited")
    shutdown()
  end
end

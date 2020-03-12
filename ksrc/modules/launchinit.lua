kernel.log("Loading init from " .. init)
local ok, err = loadfile(init)
if not ok then
  error(err, -1)
end

--local s, e = pcall(ok, flags.runlevel)
local s, e = os.spawn(function()return ok(flags.runlevel)end, "[init]")
if not s then
  error(e, -1)
end

os.start()

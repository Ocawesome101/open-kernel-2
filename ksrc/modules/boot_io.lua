function write(str)
  checkArg(1, str, "string")
  local written = 0
  local function newline()
    x = 1
    if y + 1 <= h then
      y = y + 1
    else
      gpu.scroll(1)
      y = h
    end
    written = written + 1
  end
  str = str:gsub("\t", "    ")
  while #str > 0 do
    local space = str:match("^[ \t]+")
    if space then
      gpu.set(x, y, space)
      x = x + #space
      str = str:sub(#space + 1)
    end

    local newLine = str:match("^\n")
    if newLine then
      newline()
      str = str:sub(2)
    end

    local word = str:match("^[^ \t\n]+")
    if word then
      str = str:sub(#word + 1)
      if #word > w then
        while #str > 0 do
          if x > w then
            newline()
          end
          gpu.set(x, y, text)
          x = x + #text
          text = text:sub((w - x) + 2)
        end
      else
        if x + #word > w then
          newline()
        end
        gpu.set(x, y, word)
        x = x + #word
      end
    end
  end
  return written
end

function print(...)
  local args = {...}
  local printed = 0
  for i=1, #args, 1 do
    local written = write(tostring(args[i]))
    if i < #args then
      write(" ")
    end
    printed = printed + written
  end
  write("\n")
  return printed
end 

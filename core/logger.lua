local logger = {}

local function ensureDir(path)
  local parts = {}
  for part in string.gmatch(path, "[^/]+") do
    parts[#parts + 1] = part
  end
  if #parts <= 1 then
    return
  end

  local acc = ""
  for i = 1, #parts - 1 do
    acc = acc == "" and parts[i] or (acc .. "/" .. parts[i])
    if not fs.exists(acc) then
      fs.makeDir(acc)
    end
  end
end

local function timestamp()
  return textutils.formatTime(os.time(), true)
end

function logger.new(logPath)
  ensureDir(logPath)
  return {
    logPath = logPath,
  }
end

function logger.append(self, level, message)
  local line = string.format("[%s] [%s] %s", timestamp(), level, message)
  local h = fs.open(self.logPath, "a")
  if h then
    h.writeLine(line)
    h.close()
  end
end

function logger.info(self, message)
  self:append("INFO", message)
end

function logger.warn(self, message)
  self:append("WARN", message)
end

function logger.error(self, message)
  self:append("ERROR", message)
end

return logger

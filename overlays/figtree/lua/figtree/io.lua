local m = {}

local utils = require('figtree.utils')
local root = vim.fn.stdpath('cache') .. '/figtree.nvim'
local dir = root .. '/banners'
local textfile = root .. '/text.txt'

---@return string output, boolean ok
local function figlet(config)
  local ok, res = pcall(vim.system, { 'figlet', '-w', '999', '-f', config.font, config.text }, { text = true })
  if not ok then return string.format('figlet error: %s', res), false end
  res = res:wait()
  if res.code ~= 0 then return string.format('figlet error: %s', res.stderr), false end
  return res.stdout, true
end

---@param filename string
local function write_error(filename) utils.error(string.format('couldn\'t open %s for writing', filename)) end

local function save_text(text)
  local file = io.open(textfile, 'w')
  if file == nil then
    write_error(textfile)
  else
    file:write(text)
    file:close()
  end
end

--- Checks if cache
---@param text string
---@return boolean
local function is_valid(text)
  local file = io.open(textfile, 'r')
  if file == nil then
    return false
  else
    local contents = file:read('*a')
    file:close()
    return contents == text
  end
end

--- Read-through cache wrapper for figlet
---@return string[]
function m.get_banner(config)
  -- file with the cached banner
  local filename = dir .. string.format('/%s.txt', config.font)

  local wipe = not is_valid(config.text)
  if wipe then vim.fn.delete(dir, 'rf') end
  vim.fn.mkdir(dir, 'p')
  if wipe then save_text(config.text) end

  -- read || generate && write
  local chars
  local file = io.open(filename, 'r')
  if file ~= nil then
    -- hit
    chars = file:read('*a')
    file:close()
  else
    -- miss
    local ok
    chars, ok = figlet(config)
    if ok then
      file = io.open(filename, 'w')
      if file == nil then
        write_error(filename)
      else
        file:write(chars)
        file:close()
      end
    end
  end
  return vim.split(chars, '\n', { trimempty = true })
end

return m

local u = require('utils.helpers')

local start_time = vim.loop.hrtime()

-- XXX don't forget to clear cache!
local input = 'neovim'
local myfont = 'puffy'

local function figlet(font)
  local figlet_res = vim.system({ 'figlet', '-w', '999', '-f', font, input }, { text = true }):wait()
  return figlet_res.stdout
end

local function cache(font)
  local dir = vim.fn.stdpath('cache') .. '/greeter'
  vim.fn.mkdir(dir, 'p')
  local filename = dir .. string.format('/%s.txt', font)

  local function open(mode)
    local file = io.open(filename, mode)
    if file == nil then error(string.format('Couldn\'t open (%s) the figlet cache file %s', mode, filename)) end
    return file
  end

  local res = ''
  if not u.file_exists(filename) then
    res = figlet(font)
    local file = open('w')
    file:write(res)
    file:close()
  else
    local file = open('r')
    res = file:read('*a')
    file:close()
  end
  return res
end

local function random_font()
  local font_cmd = [[
      figlist |
      sed -n '/Figlet fonts in this directory:/,/Figlet control files in this directory:/{//!p}' |
      shuf |
      head -n 1
      ]]
  local font_res = vim.system({ 'bash', '-c', font_cmd }, { text = true }):wait()
  return vim.trim(font_res.stdout)
end

--- Generates a banner with a random font
---@return string
local function getbanner(font)
  if font == '' then font = random_font() end
  vim.g.figlet_font = font
  return cache(font)
end

-- returns a version string
---@return string
local function version_string()
  local version = vim.version()
  local nvim_version_info = ' ' .. version.major .. '.' .. version.minor .. '.' .. version.patch
  return nvim_version_info
end

-- adds a prefix to every string in a list
---@param lines string[]
---@param prefix string
local function add_prefix(lines, prefix)
  local result = {}
  for i, v in ipairs(lines) do
    table.insert(result, i, prefix .. v)
  end
  return result
end

-- returns a list of empty strings
---@param n integer
---@return string[]
local function empty(n)
  local result = {}
  for _ = 1, n do
    table.insert(result, '')
  end
  return result
end

-- returns a function that builds lines for the greeter
---@return function
local function make_renderer()
  local body = getbanner(myfont)
  local ver_string = version_string()
  local lines = vim.split(body, '\n', { trimempty = true })
  local tx = #lines[1] -- assuming all lines have equal width
  local ty = #lines
  -- center align the version string with the main block
  ver_string = string.rep(' ', math.floor((tx - #ver_string) / 2)) .. ver_string
  -- add some space between the two
  local spacing = 3
  local space = empty(spacing)
  ty = ty + spacing + 1

  return function()
    local wx = vim.fn.winwidth(0)
    local wy = vim.fn.winheight(0)

    local xpad = math.floor((wx - tx) / 2)
    local ypad = math.floor((wy - ty) / 2)

    if xpad <= 0 or ypad <= 0 then
      -- body doesn't fit, hide
      return {}
    end

    local prefix = string.rep(' ', xpad)
    local head = empty(ypad)

    local parts = {
      head,
      add_prefix(lines, prefix),
      space,
      add_prefix({ ver_string }, prefix),
    }

    return u.concat_list(parts)
  end
end

-- maps almost all keys to noop
---@param allowed_keys string
local function unmap(allowed_keys)
  for i = 32, 126 do
    local c = string.char(i)
    if not vim.tbl_contains(allowed_keys, c) then vim.api.nvim_buf_set_keymap(0, 'n', c, '<nop>', {}) end
  end
end

local render = make_renderer()

local function set()
  vim.opt_local.modifiable = true
  vim.api.nvim_buf_set_lines(0, 0, -1, false, render())
  vim.opt_local.modifiable = false
end

local old_gcr = vim.opt.guicursor

local function hide()
  local hl = vim.api.nvim_get_hl(0, { name = 'Cursor' })
  hl.blend = 100
  vim.api.nvim_set_hl(0, 'HiddenCursor', hl)
  vim.opt.guicursor:append('a:HiddenCursor,ci-c-cr:Cursor')
end

local function unhide() vim.opt.guicursor = old_gcr end

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    -- skip greeter when opening files
    if vim.fn.argc() ~= 0 then return end

    -- greet
    set()
    hide()

    -- when a new window is created, replace the greeter buffer with an empty buffer
    local old = vim.fn.win_getid()
    vim.api.nvim_create_autocmd('WinNew', {
      buffer = 1,
      callback = function(ev)
        unhide()
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(old, buf)
        if ev.buf == 1 then vim.api.nvim_win_set_buf(0, buf) end
      end,
      once = true,
    })

    -- when the buffer is closed, unhide the cursor
    vim.api.nvim_create_autocmd('BufDelete', {
      buffer = 1,
      callback = function() unhide() end,
      once = true,
    })

    -- rerender on resize
    vim.api.nvim_create_autocmd('VimResized', {
      buffer = 1,
      callback = set,
    })

    -- make it special
    vim.opt_local.bufhidden = 'wipe'
    vim.opt_local.buftype = 'nofile'
    vim.opt_local.cursorline = false
    vim.opt_local.list = false
    vim.opt_local.modifiable = false
    vim.opt_local.number = false
    vim.opt_local.readonly = true
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.stl = ' '
    vim.opt_local.swapfile = false
    vim.opt_local.sidescrolloff = 0

    -- some remaps
    local allowed_keys = vim.split(':`', '')
    unmap(allowed_keys)
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', '<cmd>quit<cr>', {})
    vim.api.nvim_buf_set_keymap(0, 'n', 'i', '<cmd>enew<cr>i', {})
    vim.api.nvim_buf_set_keymap(0, 'n', 'a', '<cmd>enew<cr>a', {})
  end,
})

local elapsed = (vim.loop.hrtime() - start_time) / 1e6 -- ms
vim.g.figlet_elapsed = string.format('figlet done in %.3f ms', elapsed)

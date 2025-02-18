local input = 'neovim'

local u = require('utils.helpers')

--- Generates a banner with a random font
---@param text string
---@param font? string
---@return string
local function figlet(text, font)
  if not font then
    -- hehe
    local font_cmd = [[
      figlist |
      sed -n '/Figlet fonts in this directory:/,/Figlet control files in this directory:/{//!p}' |
      shuf |
      head -n 1
      ]]
    local font_res = vim.system({ 'bash', '-c', font_cmd }, { text = true }):wait()
    font = vim.trim(font_res.stdout)
  end
  vim.g.figlet_font = font
  local figlet_res = vim.system({ 'figlet', '-w', '999', '-f', font, text }, { text = true }):wait()
  return figlet_res.stdout
end

local function version_string()
  local version = vim.version()
  local nvim_version_info = ' ' .. version.major .. '.' .. version.minor .. '.' .. version.patch
  return nvim_version_info
end

local function add_prefix(lines, prefix)
  local result = {}
  for i, v in ipairs(lines) do
    table.insert(result, i, prefix .. v)
  end
  return result
end

local function empty(n)
  local result = {}
  for _ = 1, n do
    table.insert(result, '')
  end
  return result
end

-- calc padding, add version string
local function pook()
  local body = figlet(input)
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

    local result = u.concat_list(parts)
    result[1] = '█' .. string.sub(result[1], 2) -- hide cursor
    return result
  end
end

-- TODO create autocommand to redraw on resize
-- TODO hide cursor or lock at least

local render = pook()
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() ~= 0 then
      return
    end
    vim.cmd('enew')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, render())

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

    vim.api.nvim_buf_set_keymap(0, 'n', 'q', '<cmd>quit<cr>', {})
    vim.api.nvim_buf_set_keymap(0, 'n', 'i', '<cmd>enew<cr>i', {})
    vim.api.nvim_buf_set_keymap(0, 'n', 'a', '<cmd>enew<cr>a', {})
  end,
})

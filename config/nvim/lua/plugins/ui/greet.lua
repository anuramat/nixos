local input = 'neovim'

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

-- calc padding, add version string
local function pook()
  local raw = figlet(input)
  local ver_string = version_string()
  local lines = vim.split(raw, '\n', { trimempty = true })
  local tx = #lines[1] -- assuming all lines have equal width
  local ty = #lines
  -- center align the version string with the main block
  ver_string = string.rep(' ', math.floor((tx - #ver_string) / 2)) .. ver_string
  -- add some space between the two
  local spacing = 3
  raw = raw .. string.rep(' \n', spacing) .. ver_string
  ty = ty + spacing -- +1 from ver string but -1 from button = 0

  return function()
    local wx = vim.fn.winwidth(0)
    local wy = vim.fn.winheight(0)

    local xpad = math.floor((wx - tx) / 2)
    local ypad = math.floor((wy - ty) / 2)

    if xpad <= 0 or ypad <= 0 then
      return ''
    end

    return string.rep(' \n', ypad) .. raw
  end
end

return {
  lazy = false,
  enabled = false,
  'goolord/alpha-nvim',
  event = 'VimEnter',
  -- enabled = false,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function()
    vim.api.nvim_create_autocmd('Filetype', {
      pattern = 'alpha',
      callback = function()
        vim.api.nvim_buf_set_keymap(0, 'n', 'q', '<cmd>quit<cr>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', 'i', '<cmd>enew<cr>i', {})
        vim.api.nvim_buf_set_keymap(0, 'n', 'a', '<cmd>enew<cr>a', {})
        vim.cmd('setlocal fcs=eob:\\ ')
      end,
    })
    return {
      layout = {
        { type = 'button', val = '█' }, -- hides cursor
        { type = 'text', opts = { position = 'center' }, val = pook() },
      },
      opts = {
        keymap = {
          press = nil,
          press_queue = nil,
        },
      },
    }
  end,
}

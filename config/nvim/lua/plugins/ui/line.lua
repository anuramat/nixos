-- vim: fdm=marker fdl=0

-- vars {{{1

local error_color = 'ErrorMsg'

local dap_status = {
  function()
    return '  ' .. require('dap').status()
  end,
  cond = function()
    return package.loaded['dap'] and require('dap').status() ~= ''
  end,
}

local diagnostics = { 'diagnostics', symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' } }

local git_branch = {
  'branch',
  icon = '󰊢',
  align = 'right',
  padding = { left = 1, right = 1 },
}

local function cwd_fn()
  local fullpath = vim.fn.getcwd()
  local home = vim.fn.getenv('HOME')
  return string.gsub(fullpath, '^' .. home, '~')
end

local cwd = {
  cwd_fn,
  padding = 1,
  separator = '',
}

local function layout_fn()
  local keymap = vim.o.keymap
  if keymap == '' then
    return ''
  end
  if vim.o.iminsert == 1 then
    return string.upper(keymap:sub(1, 2))
  else
    return 'EN'
  end
end

local layout = {
  layout_fn,
  padding = { left = 1, right = 1 },
}

local progress = {
  'progress',
  padding = { left = 1, right = 1 },
  separator = '',
}

local filename = {
  'filename',
  path = 1,
  newfile_status = true,
  symbols = { modified = '[modified]', readonly = '[read-only]', unnamed = '[no name]', newfile = '[new]' },
  separator = '',
  padding = { left = 1, right = 1 },
}

local filetype = {
  'filetype',
}

local tabs = {
  'tabs',
  mode = 0,
  use_mode_colors = true,
  show_modified_status = false,
}

local location = {
  'location',
  padding = { left = 1, right = 1 },
  fmt = vim.trim,
}

local encoding = {
  function()
    if vim.o.fileencoding ~= 'utf-8' then
      return vim.o.fileencoding
    end
    return ''
  end,
  color = error_color,
}

local fileformat = {
  'fileformat',
  symbols = { unix = '' },
  color = error_color,
}

local molten = {
  function()
    return require('molten.status').initialized()
  end,
  cond = function()
    return pcall(function()
      require('molten')
    end) and require('molten.status').initialized() ~= ''
  end,
}

-- }}}

return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  opts = function()
    vim.o.showmode = false

    return {
      options = {
        theme = 'neopywal',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        refresh = { statusline = 300, tabline = 300 },
        disabled_filetypes = {
          statusline = { 'alpha' },
        },
      },
      extensions = { 'aerial', 'fugitive', 'lazy', 'man', 'neo-tree', 'nvim-dap-ui', 'oil', 'quickfix' },
      tabline = {
        lualine_a = { cwd, git_branch },
        lualine_b = { tabs },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { layout },
      },
      sections = {
        lualine_a = {
          filename,
        },
        lualine_b = { filetype },
        lualine_c = {
          encoding,
          fileformat,
          diagnostics,
        },
        lualine_x = {
          dap_status,
          molten,
        },
        lualine_y = { location },
        lualine_z = { progress },
      },
    }
  end,
}

local function dap()
  if package.loaded['dap'] and require('dap').status() ~= '' then
    return '  ' .. require('dap').status()
  else
    return ''
  end
end

local git_icon = '󰊢'

local function cwd_fn()
  local fullpath = vim.fn.getcwd()
  local home = vim.fn.getenv('HOME')
  return string.gsub(fullpath, '^' .. home, '~')
end

local function layout_fn()
  if vim.o.iminsert == 0 then
    return ''
  elseif vim.o.iminsert == 1 then
    return 'LMAP'
  elseif vim.o.iminsert == 2 then
    return 'IM'
  end
  return 'ERR'
end

local function encoding_fn()
  if vim.o.fileencoding ~= 'utf-8' then
    return vim.o.fileencoding
  end
  return ''
end

local function encoding_fn()
  if vim.o.fileformat ~= 'unix' then
    return vim.o.fileencoding
  end
  return ''
end

local function molten()
  local ok, v = pcall(function()
    return require('molten.status').initialized()
  end)
  if ok then
    return v
  else
    return ''
  end
end

return {}

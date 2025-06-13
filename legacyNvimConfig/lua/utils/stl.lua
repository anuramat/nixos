local m = {}

function m.dap()
  if package.loaded['dap'] and require('dap').status() ~= '' then
    return '  ' .. require('dap').status()
  else
    return ''
  end
end

function m.cwd()
  local fullpath = vim.fn.getcwd()
  local home = vim.fn.getenv('HOME')
  return string.gsub(fullpath, '^' .. home, '~')
end

function m.layout()
  if vim.o.iminsert == 0 then
    return ''
  elseif vim.o.iminsert == 1 then
    return 'LMAP'
  elseif vim.o.iminsert == 2 then
    return 'IM'
  end
  return 'ERR'
end

function m.encoding()
  if vim.o.fileencoding ~= 'utf-8' then return vim.o.fileencoding end
  return ''
end

function m.format()
  if vim.o.fileformat ~= 'unix' then return vim.o.fileencoding end
  return ''
end

function m.molten()
  local ok, v = pcall(function() return require('molten.status').initialized() end)
  if ok then
    return v
  else
    return ''
  end
end

-- TODO add some of these after %= in stl in adhoc/stl or something

return m

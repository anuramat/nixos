local function hide_cursor()
  local hl = vim.api.nvim_get_hl_by_name('Cursor', true)
  hl.blend = 100
  vim.api.nvim_set_hl(0, 'Cursor', hl)
  vim.opt.guicursor:append('a:Cursor/lCursor')
end

local function unhide_cursor()
  local hl = vim.api.nvim_get_hl_by_name('Cursor', true)
  hl.blend = 0
  vim.api.nvim_set_hl(0, 'Cursor', hl)
  vim.opt.guicursor:remove('a:Cursor/lCursor')
end

return function()
  vim.api.nvim_create_autocmd({ 'Filetype' }, {
    pattern = { 'alpha' },
    desc = 'hide cursor for alpha',
    callback = hide_cursor,
  })

  vim.api.nvim_create_autocmd({ 'CmdlineEnter'}, {
    desc = 'show cursor after alpha',
    callback = function()
      unhide_cursor()
    end,
  })
  vim.api.nvim_create_autocmd({ 'CmdlineLeave', 'BufEnter', 'WinEnter', 'BufWinEnter' }, {
    desc = 'show cursor after alpha',
    callback = function()
      if vim.o.ft == 'alpha' then
        return hide_cursor()
      end
      unhide_cursor()
    end,
  })
end

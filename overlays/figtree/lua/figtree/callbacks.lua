local m = {}

---@param state state
local function hide_cursor(state)
  state.gcr = vim.opt.guicursor
  local hl = vim.api.nvim_get_hl(0, { name = 'Cursor' })
  hl.blend = 100
  vim.api.nvim_set_hl(0, 'HiddenCursor', hl)
  vim.opt.guicursor:append('a:HiddenCursor,ci-c-cr:Cursor')
end

---@param state state
local function unhide_cursor(state) vim.opt.guicursor = state.gcr end

--- Startup callback
---@param state state
---@param config config
local function enter(state, config)
  -- skip greeter when opening files
  if vim.fn.argc() ~= 0 then return end

  -- greet
  state.draw()
  hide_cursor(state)

  -- when a new window is created, replace the greeter buffer with an empty buffer
  local old = vim.fn.win_getid()
  vim.api.nvim_create_autocmd('WinNew', {
    buffer = 1,
    callback = function(ev)
      -- TODO do not close the greeter on fzf-lua and so on, waiting for <https://github.com/neovim/neovim/issues/25844>
      unhide_cursor(state)
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_win_set_buf(old, buf) -- new buffer in the original window
      -- HACK idk how this works but it does
      vim.api.nvim_win_set_buf(0, buf) -- new buffer in the new window eg on :vs
    end,
    once = true,
  })

  -- when the buffer is closed, unhide the cursor
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = 1,
    callback = function() unhide_cursor(state) end,
    once = true,
  })

  -- rerender on resize
  vim.api.nvim_create_autocmd('VimResized', {
    buffer = 1,
    callback = state.draw,
  })

  -- make the buffer special
  -- luacheck: ignore 613 -- trailing whitespace
  -- XXX should rather be wipe, but that breaks image-nvim:
  -- their WinNew autocommand references the buffer which doesn't exist
  -- idk why 'delete' is fine tho
  vim.cmd([[
      setl bh=delete bt=nofile scl=no siso=0
      setl fcs+=eob:\ 
      setl nocul nolist noma nonu nornu noswf ro
      setl stl=\ 
      ]])

  -- apply remaps for the greeter buffer
  config.remaps()
end

---@param state state
---@param config config
---@return function
function m.enter(state, config)
  return function() enter(state, config) end
end

return m

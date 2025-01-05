--- Prints triggered events for debug purposes
--- Usage:
--- ```lua
--- M.follow_events({ 'BufReadPre', 'BufNewFile' })
--- ```
--- @param events string[] List of events to subscribe to
local function follow_events(events)
  local g = vim.api.nvim_create_augroup('event_debugger', { clear = true })
  local counter = 0
  if events == nil or events == {} then
    return
  end
  for _, e in pairs(events) do
    vim.api.nvim_create_autocmd(e, {
      group = g,
      callback = function(opts)
        vim.notify('Event ' .. tostring(counter) .. ' triggered: ' .. opts.event)
        counter = counter + 1
      end,
    })
  end
end

follow_events({})

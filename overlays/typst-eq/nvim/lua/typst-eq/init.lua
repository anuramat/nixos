-- Shows the equations of typst buffers as images, cut out of the compiled document by the
-- `typst-eq` daemon, and placed by snacks.image, which has to be set up.
local M = {}

M.config = {
  -- draw the default black in the foreground color of the editor; other colors are kept as
  -- they are in the document, and the background is always transparent
  match_colors = false,
}

-- image pixels per screen pixel
local OVERSAMPLE = 2

local daemon ---@type vim.SystemObj?
local busy ---@type {buf: integer, tick: integer}? the request the daemon is working on
-- sent: changedtick of the last request; tick: the one `eqs` belong to
local bufs = {} ---@type table<integer, {sent?: integer, tick?: integer, eqs: table[], imgs: snacks.image.Placement[]}>

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
end

-- Reconciles the images with the equations in the visible lines.
local function sync(buf)
  local s = bufs[buf]
  if s.tick ~= vim.api.nvim_buf_get_changedtick(buf) then
    return -- the equations are those of an older text; the pending answer will get us here again
  end
  local wins = vim.tbl_map(function(win)
    return vim.fn.getwininfo(win)[1]
  end, vim.fn.win_findbuf(buf))
  local term, doc = Snacks.image.terminal.size(), Snacks.image.config.doc
  local old, new = s.imgs, {}
  for _, eq in ipairs(s.eqs) do
    local range = { eq.range[1] + 1, eq.range[2], eq.range[3] + 1, eq.range[4] }
    local visible = vim.iter(wins):any(function(win)
      return range[1] <= win.botline and range[3] >= win.topline
    end)
    if visible then
      local img
      for i, o in ipairs(old) do
        if o.img.src == eq.png then
          img = table.remove(old, i)
          break
        end
      end
      if img then
        img.opts.pos, img.opts.range = { range[1], range[2] }, range
        img:update()
      else
        local size = Snacks.image.util.dim(eq.png)
        img = Snacks.image.placement.new(buf, eq.png, {
          pos = { range[1], range[2] },
          range = range,
          inline = true,
          conceal = true,
          type = "math",
          -- snacks takes the image to be bigger than this, and fits it into these
          max_width = math.min(doc.max_width, math.ceil(size.width / OVERSAMPLE / term.cell_width)),
          max_height = math.min(doc.max_height, math.ceil(size.height / OVERSAMPLE / term.cell_height)),
          -- show the source instead, while the cursor is on it; without conceal, it is visible anyway
          on_update_pre = function(p)
            local from, to = vim.fn.line("v"), vim.fn.line(".")
            local on_cursor = vim.api.nvim_get_current_buf() == buf
              and p.opts.range[1] <= math.max(from, to)
              and p.opts.range[3] >= math.min(from, to)
            p.hidden = on_cursor
              and vim.wo.conceallevel > 0
              and not vim.wo.concealcursor:find(vim.fn.mode():sub(1, 1):lower())
          end,
        })
      end
      new[#new + 1] = img
    end
  end
  for _, img in ipairs(old) do
    img:close()
  end
  s.imgs = new
end

local request

local function on_response(line)
  local res, buf, tick = vim.json.decode(line), busy.buf, busy.tick
  busy = nil
  local s = bufs[buf]
  if s and res.equations and tick == vim.api.nvim_buf_get_changedtick(buf) then
    s.eqs, s.tick = res.equations, tick
    sync(buf)
  end
  vim.iter(vim.tbl_keys(bufs)):each(request) -- whichever changed in the meantime
end

-- Asks the daemon for the equations of the buffer, unless it has been asked already, or is busy.
function request(buf)
  local s = bufs[buf]
  local tick = s and vim.api.nvim_buf_get_changedtick(buf)
  if not s or busy or s.sent == tick then
    return
  end
  busy, s.sent = { buf = buf, tick = tick }, tick
  if not daemon then
    local rest = ""
    -- the images go where neovim deletes them on exit
    daemon = vim.system({ "typst-eq", vim.fn.tempname() }, {
      stdin = true,
      stdout = function(_, data)
        local lines = vim.split(rest .. (data or ""), "\n")
        rest = table.remove(lines)
        vim.iter(lines):each(vim.schedule_wrap(on_response))
      end,
    }, function()
      daemon, busy = nil, nil
    end)
  end
  daemon:write(vim.json.encode({
    path = vim.api.nvim_buf_get_name(buf),
    text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n",
    fg = M.config.match_colors and Snacks.util.color("Normal") or nil,
    scale = OVERSAMPLE * 96 / 72 * Snacks.image.terminal.size().scale,
  }) .. "\n")
end

function M.attach(buf)
  Snacks.image.terminal.detect(function()
    if bufs[buf] or not Snacks.image.terminal.env().placeholders then
      return
    end
    bufs[buf] = { eqs = {}, imgs = {} }
    -- snacks would render the math as well, out of context; this is its query without the math
    vim.treesitter.query.set(
      "typst",
      "images",
      [[
        (call
          (ident) @ident
          (#eq? @ident "image")
          (group (string) @image.src)
          (#offset! @image.src 0 1 0 -1)
        ) @image
      ]]
    )
    local group = vim.api.nvim_create_augroup("typst-eq." .. buf, {})
    vim.api.nvim_create_autocmd({ "WinScrolled", "BufWinEnter" }, {
      group = group,
      buffer = buf,
      callback = function()
        sync(buf)
      end,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged" }, {
      group = group,
      buffer = buf,
      callback = function()
        for _, img in ipairs(bufs[buf].imgs) do
          img:update()
        end
      end,
    })
    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function()
        vim.schedule(function()
          request(buf)
        end)
      end,
      on_detach = function()
        vim.api.nvim_del_augroup_by_id(group)
        vim.iter(bufs[buf].imgs):each(vim.schedule_wrap(function(img)
          img:close()
        end))
        bufs[buf] = nil
      end,
    })
    request(buf)
  end)
end

return M

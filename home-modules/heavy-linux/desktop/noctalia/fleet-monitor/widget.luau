-- desktop widget: renders the sections of `fleet --json` (see default.nix), rerun every few seconds; click a section to
-- hide or show its rows, right-click it to refresh it
local FONT_SIZE = noctalia.getConfig("font_size")
-- sizes below are given for noctalia's default 14px font and scale with FONT_SIZE
local SCALE = FONT_SIZE / 14
-- a character's width: the font is stylix's monospace one, Monaspace, whose characters are 0.6em wide
local CHAR = 0.6 * FONT_SIZE
local FLEET, LOCAL_HOST = "@fleet@", "@localHost@"
-- in ms; it probes the current host, and reads the cached rest
local INTERVAL = 5000

-- 3723 -> 1h2m3s
local function duration(s)
  local h, m = s // 3600, s % 3600 // 60
  return (h > 0 and h .. "h" or "") .. ((h > 0 or m > 0) and m .. "m" or "") .. s % 60 .. "s"
end

-- seconds -> the two largest units: 1d2h, 1h2m, 2m
local function eta(s)
  s = math.max(s, 0)
  local d, h, m = s // 86400, s % 86400 // 3600, s % 3600 // 60
  return d > 0 and `{d}d{h}h` or h > 0 and `{h}h{m}m` or `{m}m`
end

-- the logical size of the widget's output
local function outputSize()
  for _, o in noctalia.outputs() do
    if o.name == desktopWidget.outputName() then return o.width, o.height end
  end
  return 0, 0
end

local function label(text, color, props)
  props = props or {}
  props.text, props.color, props.fontSize = text, color, FONT_SIZE
  return ui.label(props)
end

-- a column, indented, filling the rest of the row
local function indented(children)
  return ui.row({ align = "start" },
    { ui.box({ width = 16 * SCALE }), ui.column({ gap = 4 * SCALE, flexGrow = 1 }, children) })
end

-- the text of a cell and its color: the time since, or the time left until (or how long it's overdue), or text
local function cellText(c, now)
  if c.since then return duration(now - c.since), "outline" end
  if c["until"] then
    local left = c["until"] - now
    if left >= 0 then return eta(left), "outline" end
    return "+" .. eta(-left), "error"
  end
  return c.text, c.style or "on_surface"
end

local function cells(node, now)
  local t = {}
  for _, c in node.cells or {} do table.insert(t, label(cellText(c, now))) end
  return t
end

-- a row per child, followed by its own children, indented; the cells are aligned in columns as wide as their widest
-- cell, up to `width` characters, which wraps the longer ones, except for each row's last cell, which takes the rest
-- of the row, and wraps at its end
local function rows(node, now)
  local texts, widths = {}, {}
  for i, c in node.children or {} do
    texts[i] = {}
    for j, x in c.cells or {} do
      local text, color = cellText(x, now)
      texts[i][j] = { text, color }
      if j < #c.cells then
        widths[j] = math.max(widths[j] or 0, math.min(utf8.len(text) or #text, x.width or math.huge))
      end
    end
  end
  local t = {}
  for i, c in node.children or {} do
    local row = {}
    for j, x in texts[i] do
      if j == #texts[i] then
        table.insert(row, label(x[1], x[2], { flexGrow = 1 }))
      else
        -- with a pixel to spare, so that rounding doesn't wrap the widest cell
        local w = widths[j] * CHAR + 1
        table.insert(row, ui.row({ width = w }, { label(x[1], x[2], { maxWidth = w }) }))
      end
    end
    row = ui.row({ gap = 8 * SCALE, align = "start" }, row)
    table.insert(t, c.children and #c.children > 0
      and ui.column({ gap = 4 * SCALE }, { row, indented(rows(c, now)) }) or row)
  end
  return t
end

local sections, due, fetching = {}, 0, false

local function fetch()
  due, fetching = noctalia.nowMs() + INTERVAL, true
  noctalia.runAsync(FLEET .. " --json", function(r)
    fetching = false
    sections = noctalia.json.decode(r.stdout) or sections
    update()
  end, INTERVAL)
end

-- names of the sections whose rows are hidden, as a set shared by every widget instance
local hidden = noctalia.state.get("hidden") or {}
-- names of the sections being refreshed
local busy = {}

local function section(s, now)
  local header = cells(s, now)
  table.insert(header, 1, label(s.name, "primary", { fontWeight = "semibold" }))
  if s.err then table.insert(header, label(s.err, "error", { maxWidth = 400 * SCALE })) end
  local onRightClick
  -- the local host is probed on every fetch, so it needs neither a refresh time nor right-clicks
  if s.name ~= LOCAL_HOST then
    if busy[s.name] then
      table.insert(header, label("updating...", "outline"))
    elseif s.at then
      table.insert(header, label(duration(now - s.at), "outline"))
    end
    function onRightClick()
      busy[s.name] = true
      noctalia.runAsync(`{FLEET} refresh {s.name}`, function()
        busy[s.name] = nil
        fetch()
      end, 60000)
      update()
    end
  end
  local function onClick()
    local t = table.clone(hidden)
    t[s.name] = not t[s.name] or nil
    noctalia.state.set("hidden", t)
  end
  -- a gutter marks hidden rows with a `+`, transparent otherwise, so that hiding them doesn't shift the section
  return ui.row({ gap = 8 * SCALE, align = "start", key = s.name, onClick = onClick, onRightClick = onRightClick }, {
    label("+", "outline", { opacity = hidden[s.name] and 1 or 0 }),
    ui.column({ gap = 4 * SCALE, flexGrow = 1 }, {
      ui.row({ gap = 8 * SCALE, align = "start" }, header),
      not hidden[s.name] and indented(rows(s, now)) or nil,
    }),
  })
end

-- called every second (the desktop widget default), which keeps the times current
function update()
  if not fetching and noctalia.nowMs() >= due then fetch() end
  local children, now = {}, noctalia.nowMs() // 1000
  for _, s in sections do table.insert(children, section(s, now)) end
  -- a scroll view only sizes right when its parent hands it an exact size, so the card has a fixed one, filled by it
  local w, h = outputSize()
  desktopWidget.render(ui.column({ padding = 12 * SCALE, radius = 12 * SCALE, fill = "surface/0.8",
    width = noctalia.getConfig("width") * w, height = noctalia.getConfig("height") * h },
    { ui.scroll({ gap = 12 * SCALE, flexGrow = 1 }, children) }))
end

noctalia.state.watch("hidden", function(s)
  hidden = s
  update()
end)

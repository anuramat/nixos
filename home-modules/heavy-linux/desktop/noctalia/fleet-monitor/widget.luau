-- desktop widget: renders the sections of `fleet --json` (see default.nix), rerun every few seconds; click a section to
-- hide or show its rows, right-click it to refresh it
local FONT_SIZE = noctalia.getConfig("font_size")
-- sizes below are given for noctalia's default 14px font and scale with FONT_SIZE
local SCALE = FONT_SIZE / 14
-- the font is monospace (stylix's Monaspace, 0.6em per character), so rows are laid out in characters: padded with
-- spaces into aligned columns, and wrapped with newlines; a character's width only decides how many fit in the card,
-- so it's taken as 0.6em plus a device pixel, which the rendering may round it up by
local ADVANCE = 0.6 * FONT_SIZE + 1
local INDENT = "  "
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

-- a column, indented
local function indented(children)
  return ui.row({ align = "start" }, { label(INDENT), ui.column({ gap = 4 * SCALE }, children) })
end

-- text -> lines of at most n characters, broken after spaces and hyphens where possible
local function wrap(text, n)
  n = math.max(n, 1)
  local lines = {}
  while utf8.len(text) > n do
    local head = text:sub(1, utf8.offset(text, n + 1) - 1)
    local cut = head:match(".*[ %-]()") or #head + 1
    table.insert(lines, (text:sub(1, cut - 1):gsub(" +$", "")))
    text = (text:sub(cut):gsub("^ +", ""))
  end
  table.insert(lines, text)
  return lines
end

-- text wrapped at n characters, with its lines padded with spaces to `pad` characters
local function block(text, n, pad)
  local lines = wrap(text, n)
  for i, l in lines do lines[i] = l .. string.rep(" ", pad - utf8.len(l)) end
  return table.concat(lines, "\n")
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

-- a row per child, followed by its own children, indented, in `room` characters; the cells are aligned in columns as
-- wide as their widest cell, up to `width` characters, which wraps the longer ones, except for each row's last cell,
-- which takes the rest of the row
local function rows(node, now, room)
  local texts, widths = {}, {}
  for i, c in node.children or {} do
    texts[i] = {}
    for j, x in c.cells or {} do
      local text, color = cellText(x, now)
      texts[i][j] = { text, color }
      if j < #c.cells then widths[j] = math.max(widths[j] or 0, math.min(utf8.len(text), x.width or math.huge)) end
    end
  end
  local t = {}
  for i, c in node.children or {} do
    local row, used = {}, 0
    for j, x in texts[i] do
      local w = j < #texts[i] and widths[j]
      table.insert(row, label(w and block(x[1], w, w + 1) or block(x[1], room - used, 0), x[2]))
      used += w and w + 1 or 0
    end
    row = ui.row({ align = "start" }, row)
    table.insert(t, c.children and #c.children > 0
      and ui.column({ gap = 4 * SCALE }, { row, indented(rows(c, now, room - #INDENT)) }) or row)
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

-- a section in `room` characters: its name, cells, refresh time and error, then its rows
local function section(s, now, room)
  local header = { { s.name, "primary" } }
  for _, c in s.cells or {} do table.insert(header, { cellText(c, now) }) end
  local onRightClick
  -- the local host is probed on every fetch, so it needs neither a refresh time nor right-clicks
  if s.name ~= LOCAL_HOST then
    if busy[s.name] then
      table.insert(header, { "updating...", "outline" })
    elseif s.at then
      table.insert(header, { duration(now - s.at), "outline" })
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
  if s.err then table.insert(header, { s.err, "error" }) end
  -- separated by spaces, with the last one, usually the error, wrapped at the end of the row
  local used = 0
  for i, h in header do
    local text = i < #header and h[1] .. " " or block(h[1], room - #INDENT - used, 0)
    used += utf8.len(text)
    header[i] = label(text, h[2], i == 1 and { fontWeight = "semibold" } or nil)
  end
  -- a gutter marks hidden rows with a `+`, transparent otherwise, so that hiding them doesn't shift the section
  return ui.row({ align = "start", key = s.name, onClick = onClick, onRightClick = onRightClick }, {
    label("+ ", "outline", { opacity = hidden[s.name] and 1 or 0 }),
    ui.column({ gap = 4 * SCALE }, {
      ui.row({ align = "start" }, header),
      not hidden[s.name] and indented(rows(s, now, room - 2 * #INDENT)) or nil,
    }),
  })
end

-- called every second (the desktop widget default), which keeps the times current
function update()
  if not fetching and noctalia.nowMs() >= due then fetch() end
  -- a scroll view only sizes right when its parent hands it an exact size, so the card has a fixed one, filled by it
  local w, h = outputSize()
  w, h = noctalia.getConfig("width") * w, noctalia.getConfig("height") * h
  local padding = 12 * SCALE
  local children, now = {}, noctalia.nowMs() // 1000
  for _, s in sections do table.insert(children, section(s, now, (w - 2 * padding) // ADVANCE)) end
  desktopWidget.render(ui.column({ padding = padding, radius = 12 * SCALE, fill = "surface/0.8", width = w, height = h },
    { ui.scroll({ gap = 12 * SCALE, flexGrow = 1 }, children) }))
end

noctalia.state.watch("hidden", function(s)
  hidden = s
  update()
end)

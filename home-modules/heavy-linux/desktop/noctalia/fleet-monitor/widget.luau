-- desktop widget: renders the sections of `fleet --json` (see default.nix), rerun every few seconds; click a section to
-- hide or show its rows, right-click it to refresh it
local FONT_SIZE = noctalia.getConfig("font_size")
-- sizes below are given for noctalia's default 14px font and scale with FONT_SIZE
local SCALE = FONT_SIZE / 14
-- the rows are laid out in characters (see layout.luau), so a character's width only decides how many fit in the
-- card: the font is stylix's monospace one, Monaspace, 0.6em per character, plus a device pixel that the rendering
-- may round it up by
local ADVANCE = 0.6 * FONT_SIZE + 1
-- marks sections with hidden rows
local GUTTER = "+ "
local FLEET, LOCAL_HOST = "@fleet@", "@localHost@"
-- in ms; it probes the current host, and reads the cached rest
local INTERVAL = 5000
local layout = require("./layout.luau")

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

-- layout.luau's pieces, side by side
local function row(pieces)
  local t = {}
  for _, p in pieces do table.insert(t, label(p[1], p[2], p[3] and { fontWeight = "semibold" } or nil)) end
  return ui.row({ align = "start" }, t)
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

-- a section in `room` characters
local function section(s, now, room)
  local onRightClick
  -- the local host is probed on every fetch, so it needs neither a refresh time nor right-clicks
  if s.name ~= LOCAL_HOST then
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
  local header, rows = layout.section(s, now, room - #GUTTER, busy[s.name])
  local children = { row(header) }
  if not hidden[s.name] then
    for _, r in rows do table.insert(children, row(r)) end
  end
  -- the gutter's `+` is transparent while the rows are shown, so that hiding them doesn't shift the section
  return ui.row({ align = "start", key = s.name, onClick = onClick, onRightClick = onRightClick }, {
    label(GUTTER, "outline", { opacity = hidden[s.name] and 1 or 0 }),
    ui.column({ gap = 4 * SCALE }, children),
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

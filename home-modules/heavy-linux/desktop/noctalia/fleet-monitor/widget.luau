-- desktop widget: renders the `sections` state published by service.luau; click a section to refresh it
local FONT_SIZE = noctalia.getConfig("font_size")
-- sizes below are given for noctalia's default 14px font and scale with FONT_SIZE
local SCALE = FONT_SIZE / 14

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

local function label(text, color, props)
  props = props or {}
  props.text, props.color, props.fontSize = text, color, FONT_SIZE
  return ui.label(props)
end

-- a column, indented
local function indented(children)
  return ui.row({ align = "start" }, { ui.box({ width = 16 * SCALE }), ui.column({ gap = 4 * SCALE }, children) })
end

local function hostRows(h)
  local rows = {}
  for _, job in h.jobs do
    table.insert(rows, ui.row({ gap = 8 * SCALE, key = job.unit }, {
      label(job.unit, "on_surface"),
      label(duration(job.t), "outline"),
      label(job.cmd, "on_surface_variant", { maxWidth = 400 * SCALE, maxLines = 1 }),
    }))
  end
  for _, line in h.sessions do table.insert(rows, label(line, "outline")) end
  return rows
end

local function uc3Rows(h)
  local rows = {}
  for _, j in h.jobs do
    table.insert(rows, ui.row({ gap = 8 * SCALE, key = j.id }, {
      label(j.id, "on_surface"),
      label(j.name, "on_surface", { maxWidth = 160 * SCALE, maxLines = 1 }),
      label(j.part, "on_surface_variant"),
      label(j.state, j.state == "RUNNING" and "primary" or "outline"),
      label(j.t, "outline"),
      label(j.reason, "on_surface_variant", { maxWidth = 200 * SCALE, maxLines = 1 }),
    }))
  end
  for _, line in h.idle do table.insert(rows, label(line, "outline")) end
  return rows
end

-- a rate limit window's remaining percentage, and the time left until it resets
local function limit(w, now)
  return ui.row({ gap = 8 * SCALE }, {
    label(`{w.name}: {w.left}%`, "on_surface_variant"),
    w.resets and label(eta(w.resets - now), "outline") or nil,
  })
end

-- a row per provider, followed by its limits, or with several of them, by an indented line for each
local function tokenRows(h)
  local rows, now = {}, noctalia.nowMs() // 1000
  for _, p in h.providers do
    local name, limits = label(p.name, "on_surface"), {}
    for _, w in p.windows do table.insert(limits, limit(w, now)) end
    table.insert(rows, #limits > 1 and ui.column({ gap = 4 * SCALE, key = p.name }, { name, indented(limits) })
      or ui.row({ gap = 8 * SCALE, key = p.name }, { name, limits[1] }))
  end
  return rows
end

local rows = { host = hostRows, uc3 = uc3Rows, tokens = tokenRows }

local function section(h)
  local header = { label(h.name, "primary", { fontWeight = "semibold" }) }
  if h.power == "quiet" then table.insert(header, label("quiet", "outline")) end
  if h.err then table.insert(header, label(h.err, "error", { maxWidth = 400 * SCALE, maxLines = 1 })) end
  if h.zellij then table.insert(header, label(h.zellij, "on_surface_variant")) end
  local onClick
  -- the local host is polled often, so it needs neither a refresh time nor clicks
  if not h.isLocal then
    -- only clicks get "updating...", so frequent polling doesn't flicker
    if h.busy and h.clicked then
      table.insert(header, label("updating...", "outline"))
    elseif h.at then
      table.insert(header, label(duration((noctalia.nowMs() - h.at) // 1000), "outline"))
    end
    function onClick()
      noctalia.state.set("refresh", h.name)
    end
  end
  return ui.column({ gap = 4 * SCALE, key = h.name, onClick = onClick }, {
    ui.row({ gap = 8 * SCALE }, header),
    indented(rows[h.kind](h)),
  })
end

local sections = noctalia.state.get("sections") or {}

-- called every second (the desktop widget default), which keeps the refresh times current
function update()
  local children = {}
  for _, h in sections do table.insert(children, section(h)) end
  desktopWidget.render(ui.column({ gap = 12 * SCALE, padding = 12 * SCALE, radius = 12 * SCALE, fill = "surface/0.8",
    minWidth = noctalia.getConfig("width"), minHeight = noctalia.getConfig("height") }, children))
end

noctalia.state.watch("sections", function(s)
  sections = s
  update()
end)

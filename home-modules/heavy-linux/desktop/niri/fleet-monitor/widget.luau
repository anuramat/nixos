-- desktop widget: renders the `sections` state published by service.luau; click a section to refresh it
local FONT_SIZE = noctalia.getConfig("font_size")
-- sizes below are given for noctalia's default 14px font and scale with FONT_SIZE
local SCALE = FONT_SIZE / 14

-- 3723 -> 1h2m3s
local function duration(s)
  local h, m = s // 3600, s % 3600 // 60
  return (h > 0 and h .. "h" or "") .. ((h > 0 or m > 0) and m .. "m" or "") .. s % 60 .. "s"
end

local function label(text, color, props)
  props = props or {}
  props.text, props.color, props.fontSize = text, color, FONT_SIZE
  return ui.label(props)
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

local rows = { host = hostRows, uc3 = uc3Rows }

local function section(h)
  local header = { label(h.name, "primary", { fontWeight = "semibold" }) }
  if h.power == "quiet" then table.insert(header, label("(quiet)", "outline")) end
  if h.err then table.insert(header, label(h.err, "error", { maxWidth = 400 * SCALE, maxLines = 1 })) end
  if h.zellij then table.insert(header, label(h.zellij, "on_surface_variant")) end
  local onClick
  -- the local host is polled often, so it needs neither a refresh time nor clicks
  if not h.isLocal then
    -- only clicks get "updating…", so frequent polling doesn't flicker
    if h.busy and h.clicked then
      table.insert(header, label("updating…", "outline"))
    elseif h.at then
      table.insert(header, label(duration((noctalia.nowMs() - h.at) // 1000), "outline"))
    end
    function onClick()
      noctalia.state.set("refresh", h.name)
    end
  end
  return ui.column({ gap = 4 * SCALE, key = h.name, onClick = onClick }, {
    ui.row({ gap = 8 * SCALE }, header),
    ui.row({ align = "start" }, { ui.box({ width = 16 * SCALE }), ui.column({ gap = 4 * SCALE }, rows[h.kind](h)) }),
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

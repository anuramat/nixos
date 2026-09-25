-- desktop widget: agent jobs, agent and zellij sessions per host, then uc3; click a section to refresh it
-- the current host is queried without ssh, so it can be polled often
local LOCAL_INTERVAL, REMOTE_INTERVAL = 5000, 30000
-- uc3 is polled hourly, failures included, so a flaky login can't hammer the
-- cluster; the broker behind uc3ctl additionally stops logging in after a refused login
local UC3_INTERVAL = 3600000
local UC3_CMD = [[@uc3ctl@ -t 60 'sinfo_t_idle && echo --- && squeue --me -h -o "%i|%P|%T|%M|%l|%R|%j"']]
local localHost = (noctalia.readFile("/proc/sys/kernel/hostname") or ""):match("%S+")

-- 3723 -> 1h2m3s
local function duration(s)
  local h, m = s // 3600, s % 3600 // 60
  return (h > 0 and h .. "h" or "") .. ((h > 0 or m > 0) and m .. "m" or "") .. s % 60 .. "s"
end

-- ps etime, [[dd-]hh:]mm:ss -> seconds
local function etimeSeconds(t)
  local days, rest = t:match("^(%d+)-(.*)$")
  local s = 0
  for n in (rest or t):gmatch("%d+") do s = s * 60 + tonumber(n) end
  return s + (tonumber(days) or 0) * 86400
end

local function label(text, color, props)
  props = props or {}
  props.text, props.color = text, color
  return ui.label(props)
end

-- fleet-status lines; sessions are grouped by project dir basename
local function parseHost(h, out)
  h.jobs, h.sessions = {}, {}
  local projects, total, detached = {}, 0, 0
  for line in out:gmatch("[^\n]+") do
    local kind, rest = line:match("^.-\t(.-)\t(.*)$")
    if kind == "job" then
      local unit, t, cmd = rest:match("^(.-)\t(.-)\t(.*)$")
      table.insert(h.jobs, { unit = unit:gsub("%.service$", ""), t = duration(etimeSeconds(t)), cmd = cmd })
    elseif kind == "session" then
      local name, dir = rest:match("^(.-)\t(.*)$")
      local project = dir:match("([^/]*)/*$")
      local p = projects[project]
      if p then p.n += 1 else projects[project] = { n = 1, name = name } end
    elseif kind == "zellij" then
      total += 1
      if rest:match("\t0$") then detached += 1 end
    end
  end
  -- nothing without sessions, `z` for a lone detached one, else `z(detached/total)`
  h.zellij = total > 0 and (total == 1 and detached == 1 and "z" or `z({detached}/{total})`) or nil
  for project, p in projects do
    table.insert(h.sessions, project .. "(" .. (p.n > 1 and p.n or p.name) .. ")")
  end
  table.sort(h.sessions)
end

local function hostRows(h)
  local rows = {}
  for _, job in h.jobs do
    table.insert(rows, ui.row({ gap = 8, key = job.unit }, {
      label(job.unit, "on_surface"),
      label(job.t, "outline"),
      label(job.cmd, "on_surface_variant", { maxWidth = 400, maxLines = 1 }),
    }))
  end
  for _, line in h.sessions do table.insert(rows, label(line, "outline")) end
  return rows
end

-- `Partition cpu_il   :   3 nodes idle` lines, then `---`, then squeue lines
local function parseUc3(h, out)
  h.idle, h.jobs = {}, {}
  local head, tail = out:match("^(.-)\n%-%-%-\n?(.*)$")
  for part, n in head:gmatch("Partition%s+(%S+)%s*:%s*(%d+) nodes idle") do
    if n ~= "0" and part:find("gpu", 1, true) then table.insert(h.idle, part .. "(" .. n .. ")") end
  end
  for line in tail:gmatch("[^\n]+") do
    local id, part, st, t, limit, reason, name = line:match("^(.-)|(.-)|(.-)|(.-)|(.-)|(.-)|(.*)$")
    table.insert(h.jobs, { id = id, part = part, state = st, t = t .. "/" .. limit, reason = reason, name = name })
  end
end

local function uc3Rows(h)
  local rows = {}
  for _, j in h.jobs do
    table.insert(rows, ui.row({ gap = 8, key = j.id }, {
      label(j.id, "on_surface"),
      label(j.name, "on_surface", { maxWidth = 160, maxLines = 1 }),
      label(j.part, "on_surface_variant"),
      label(j.state, j.state == "RUNNING" and "primary" or "outline"),
      label(j.t, "outline"),
      label(j.reason, "on_surface_variant", { maxWidth = 200, maxLines = 1 }),
    }))
  end
  for _, line in h.idle do table.insert(rows, label(line, "outline")) end
  return rows
end

local sections = {}
for _, name in @hosts@ do
  local interval = name == localHost and LOCAL_INTERVAL or REMOTE_INTERVAL
  -- the local host goes first
  table.insert(sections, name == localHost and 1 or #sections + 1, {
    name = name, interval = interval, cmd = "@exe@ " .. name, timeout = REMOTE_INTERVAL,
    parse = parseHost, rows = hostRows, jobs = {}, sessions = {}, due = 0 })
end
-- no fetch on startup: noctalia restarts would each cost a cluster login
table.insert(sections, { name = "uc3", interval = UC3_INTERVAL, cmd = UC3_CMD, timeout = 90000, stderr = true,
  parse = parseUc3, rows = uc3Rows, jobs = {}, idle = {}, due = noctalia.nowMs() + UC3_INTERVAL })

local render

local function refresh(h)
  h.due = noctalia.nowMs() + h.interval
  h.busy = noctalia.runAsync(h.cmd, function(r)
    h.busy, h.clicked, h.err = false, false, nil
    if r.exitCode ~= 0 then
      h.err = h.stderr and r.stderr:match("([^\n]+)\n*$") or "unreachable"
    else
      h.at = noctalia.nowMs()
      h.parse(h, r.stdout)
    end
    render()
  end, h.timeout)
end

local function section(h)
  local header = { label(h.name, "primary", { fontWeight = "semibold" }) }
  if h.err then table.insert(header, label(h.err, "error", { maxWidth = 400, maxLines = 1 })) end
  if h.zellij then table.insert(header, label(h.zellij, "on_surface_variant")) end
  local onClick
  -- the local host is polled often, so it needs neither a refresh time nor clicks
  if h.name ~= localHost then
    -- only clicks get "updating…", so frequent polling doesn't flicker
    if h.busy and h.clicked then
      table.insert(header, label("updating…", "outline"))
    elseif h.at then
      table.insert(header, label(duration((noctalia.nowMs() - h.at) // 1000), "outline"))
    end
    function onClick()
      h.due, h.clicked = 0, true
      update()
    end
  end
  return ui.column({ gap = 4, key = h.name, onClick = onClick }, {
    ui.row({ gap = 8 }, header),
    ui.row({}, { ui.box({ width = 16 }), ui.column({ gap = 4 }, h.rows(h)) }),
  })
end

function render()
  local children = {}
  for _, h in sections do table.insert(children, section(h)) end
  desktopWidget.render(ui.column({ gap = 12, padding = 12, radius = 12, fill = "surface/0.8" }, children))
end

-- called every second (the desktop widget default)
function update()
  for _, h in sections do
    if not h.busy and noctalia.nowMs() >= h.due then refresh(h) end
  end
  render()
end

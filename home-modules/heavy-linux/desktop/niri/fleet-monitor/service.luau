-- polls agent jobs, agent and zellij sessions per host, follows the uc3 snapshot, and publishes them as the `sections`
-- state, shared by every widget instance; setting the `refresh` state to a section name refreshes that section
-- the current host is queried without ssh, so it can be polled often
local LOCAL_INTERVAL, REMOTE_INTERVAL = 5000, 30000
-- uc3 is fetched hourly by uc3-status.service (see agents/uc3), which a refresh starts early; noctalia caps command
-- timeouts at 60s, but a slower fetch is still picked up once it lands
local UC3_OUT, UC3_ERR = "@uc3state@/status", "@uc3state@/status.err"
local UC3_CMD = "@systemctl@ --user start uc3-status.service"
local localHost = (noctalia.readFile("/proc/sys/kernel/hostname") or ""):match("%S+")

-- ps etime, [[dd-]hh:]mm:ss -> seconds
local function etimeSeconds(t)
  local days, rest = t:match("^(%d+)-(.*)$")
  local s = 0
  for n in (rest or t):gmatch("%d+") do s = s * 60 + tonumber(n) end
  return s + (tonumber(days) or 0) * 86400
end

-- fleet-status lines; sessions are grouped by project dir basename
local function parseHost(h, out)
  h.jobs, h.sessions, h.power = {}, {}, nil
  local projects, total, detached = {}, 0, 0
  for line in out:gmatch("[^\n]+") do
    local kind, rest = line:match("^.-\t(.-)\t(.*)$")
    if kind == "job" then
      local unit, t, cmd = rest:match("^(.-)\t(.-)\t(.*)$")
      table.insert(h.jobs, { unit = unit:gsub("%.service$", ""), t = etimeSeconds(t), cmd = cmd })
    elseif kind == "session" then
      local name, dir = rest:match("^(.-)\t(.*)$")
      local project = dir:match("([^/]*)/*$")
      local p = projects[project]
      if p then p.n += 1 else projects[project] = { n = 1, name = name } end
    elseif kind == "power" then
      h.power = rest
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

-- `Partition cpu_il   :   3 nodes idle` lines, then a `---` line, then squeue lines; other lines are skipped
local function parseUc3(h, out)
  h.idle, h.jobs = {}, {}
  local head, tail = ("\n" .. out .. "\n"):match("^(.-)\n%-%-%-\n(.*)$")
  for part, n in head:gmatch("Partition%s+(%S+)%s*:%s*(%d+) nodes idle") do
    if n ~= "0" and part:find("gpu", 1, true) then table.insert(h.idle, part .. "(" .. n .. ")") end
  end
  for line in tail:gmatch("[^\n]+") do
    local id, part, st, t, limit, reason, name = line:match("^(.-)|(.-)|(.-)|(.-)|(.-)|(.-)|(.*)$")
    if id then
      table.insert(h.jobs, { id = id, part = part, state = st, t = t .. "/" .. limit, reason = reason, name = name })
    end
  end
end

local parse = { host = parseHost, uc3 = parseUc3 }

local sections = {}
for _, name in @hosts@ do
  local isLocal = name == localHost
  -- the local host goes first
  table.insert(sections, isLocal and 1 or #sections + 1, {
    name = name, kind = "host", isLocal = isLocal, interval = isLocal and LOCAL_INTERVAL or REMOTE_INTERVAL,
    cmd = "@exe@ " .. name, timeout = REMOTE_INTERVAL, jobs = {}, sessions = {}, due = 0 })
end
-- no due time: uc3-status.timer schedules the fetch, a refresh only starts it early
table.insert(sections, { name = "uc3", kind = "uc3", cmd = UC3_CMD, timeout = 60000, jobs = {}, idle = {} })

local function publish()
  noctalia.state.set("sections", sections)
end

-- parses out into h, returning an error message on failure, else the last line of err, if any; errors raised in
-- callbacks would count towards noctalia auto-disabling the service, so none may escape
local function ingest(h, out, err)
  -- state.set rejects invalid UTF-8, so a section holding it would fail every later publish
  if not (utf8.len(out) and utf8.len(err)) then return "invalid UTF-8 output" end
  local ok, e = pcall(parse[h.kind], h, out)
  return not ok and tostring(e) or err:match("([^\n]+)\n*$")
end

-- reloads the uc3 section whenever uc3-status.service rewrites the snapshot or its stderr; there is nothing to show
-- before the first successful fetch
local function loadUc3(h)
  local out, err = noctalia.fileInfo(UC3_OUT), noctalia.fileInfo(UC3_ERR)
  if not out then return end
  local stamp = `{out.mtime}/{err and err.mtime}`
  if stamp == h.stamp then return end
  h.stamp, h.at = stamp, out.mtime * 1000
  h.err = ingest(h, noctalia.readFile(UC3_OUT) or "", noctalia.readFile(UC3_ERR) or "")
  publish()
end

local function refresh(h)
  h.due = h.interval and noctalia.nowMs() + h.interval
  h.busy = noctalia.runAsync(h.cmd, function(r)
    h.busy, h.clicked = false, false
    -- uc3 results are files, picked up by loadUc3
    if h.kind == "host" then
      h.err = r.exitCode ~= 0 and "unreachable" or ingest(h, r.stdout, "")
      if not h.err then h.at = noctalia.nowMs() end
    end
    publish()
  end, h.timeout)
end

-- called every second (the service default)
function update()
  for _, h in sections do
    if h.kind == "uc3" then loadUc3(h) end
    if not h.busy and h.due and noctalia.nowMs() >= h.due then refresh(h) end
  end
end

noctalia.state.watch("refresh", function(name)
  for _, h in sections do
    if h.name == name then h.due, h.clicked = 0, true end
  end
  update()
  publish()
end)

publish()

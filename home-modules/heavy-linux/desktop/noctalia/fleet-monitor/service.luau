-- polls agent jobs, agent and zellij sessions per host, and the agents' rate limits, follows the uc3 snapshot, and
-- publishes them as the `sections` state, shared by every widget instance; setting the `refresh` state to a section
-- name refreshes that section
-- the current host is queried without ssh, so it can be polled often
local LOCAL_INTERVAL, REMOTE_INTERVAL = 5000, 30000
-- uc3 is fetched hourly by uc3-status.service (see agents/uc3), which a refresh starts early; noctalia caps command
-- timeouts at 60s, but a slower fetch is still picked up once it lands
local UC3_OUT, UC3_ERR = "@uc3state@/status", "@uc3state@/status.err"
local UC3_CMD = "@systemctl@ --user start uc3-status.service"
-- `caut usage` reads no cache: every run queries the providers' APIs, so it is polled no more often than caut's own
-- freshness threshold; noctalia runs as a user service, without the session variables that locate the credentials
local USAGE_INTERVAL = 300000
local USAGE_CMD = ". @sessionVars@ && @caut@ usage --json"
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

-- RFC 3339 UTC -> seconds since the epoch; Luau's os.time reads the table as UTC
local function epoch(t)
  local y, mo, d, h, mi, s = t:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  return os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = s })
end

-- caut's rate limit window, named by its length (5h, 7d) unless given a name
local function window(w, name)
  local m = w.windowMinutes
  return { name = name or (m % 1440 == 0 and `{m // 1440}d` or `{m // 60}h`), used = math.round(w.usedPercent),
    resets = w.resetsAt and epoch(w.resetsAt) }
end

-- `caut usage --json`: the windows of each provider, then the scoped (per model) ones under their labels; a failed
-- provider is missing from `data`, and reported in `errors`
local function parseUsage(h, out)
  local res = assert(noctalia.json.decode(out))
  h.providers = {}
  for _, p in res.data do
    local u, windows = p.usage, {}
    if u.primary then table.insert(windows, window(u.primary)) end
    if u.secondary then table.insert(windows, window(u.secondary)) end
    for _, s in u.scoped or {} do table.insert(windows, window(s.window, s.label)) end
    table.insert(h.providers, { name = p.provider, windows = windows })
  end
  -- after the rest is parsed, so that it is still shown
  if res.errors[1] then error(res.errors[1], 0) end
end

local parse = { host = parseHost, uc3 = parseUc3, usage = parseUsage }

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
table.insert(sections, { name = "usage", kind = "usage", interval = USAGE_INTERVAL, cmd = USAGE_CMD, timeout = 60000,
  providers = {}, due = 0 })

local function publish()
  noctalia.state.set("sections", sections)
end

-- parses out into h, returning an error message on failure, else the last line of err, if any; errors raised in
-- callbacks would count towards noctalia auto-disabling the service, so none may escape
local function ingest(h, out, err)
  -- state.set rejects invalid UTF-8, so a section holding it would fail every later publish
  if not (utf8.len(out) and utf8.len(err)) then return "invalid UTF-8 output" end
  local ok, e = pcall(parse[h.kind], h, out)
  if not ok then return tostring(e) end
  -- not err:match("([^\n]+)\n*$"): it backtracks quadratically, and noctalia checks the CPU budget, a syscall, on
  -- every step of a match
  local last
  for line in err:gmatch("[^\n]+") do last = line end
  return last
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
    if h.kind == "host" then
      h.err = r.exitCode ~= 0 and "unreachable" or ingest(h, r.stdout, "")
    elseif h.kind == "usage" then
      -- caut prints nothing when it fails as a whole; when only some providers fail, it exits non-zero too, but prints
      -- the rest along with the errors
      h.err = r.stdout == "" and "failed" or ingest(h, r.stdout, "")
    end
    -- uc3 results are files, picked up by loadUc3
    if h.kind ~= "uc3" and not h.err then h.at = noctalia.nowMs() end
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

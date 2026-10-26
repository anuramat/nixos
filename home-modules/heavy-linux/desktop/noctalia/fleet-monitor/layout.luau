-- the fleet monitor's layout, shared by the noctalia widget and `fleet`: a section of `fleet --json` (see default.nix)
-- -> rows of pieces, { text, color, bold }, placed side by side, where `color` is a noctalia color role, and `text` a
-- block of lines; the font is monospace, so it's all laid out in characters: padded with spaces into aligned columns,
-- and wrapped with newlines
local layout = {}

local INDENT = "  "

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

-- appends a row per child of `node`, each followed by its own children's, to `out`, indented by `indent`, in `room`
-- characters; the cells are aligned in columns as wide as their widest cell, up to `width` characters, which wraps the
-- longer ones, except for each row's last cell, which takes the rest of the row
local function rows(node, now, room, indent, out)
  local texts, widths = {}, {}
  for i, c in node.children or {} do
    texts[i] = {}
    for j, x in c.cells or {} do
      local text, color = cellText(x, now)
      texts[i][j] = { text, color }
      if j < #c.cells then widths[j] = math.max(widths[j] or 0, math.min(utf8.len(text), x.width or math.huge)) end
    end
  end
  room -= #INDENT
  indent ..= INDENT
  for i, c in node.children or {} do
    local row, used = { { indent } }, 0
    for j, x in texts[i] do
      local w = j < #texts[i] and widths[j]
      table.insert(row, { w and block(x[1], w, w + 1) or block(x[1], room - used, 0), x[2] })
      used += w and w + 1 or 0
    end
    table.insert(out, row)
    rows(c, now, room, indent, out)
  end
end

-- a section in `room` characters, at `now` (seconds since the epoch) -> its header: its name, cells, refresh time
-- ("updating..." while `busy`) and error, the last one wrapped at the end of the row; and its rows, indented
function layout.section(s, now, room, busy)
  local header = { { s.name, "primary", true } }
  for _, c in s.cells or {} do table.insert(header, { cellText(c, now) }) end
  if busy then
    table.insert(header, { "updating...", "outline" })
  elseif s.at then
    table.insert(header, { duration(now - s.at), "outline" })
  end
  if s.err then table.insert(header, { s.err, "error" }) end
  local used = 0
  for i, h in header do
    h[1] = i < #header and h[1] .. " " or block(h[1], room - used, 0)
    used += utf8.len(h[1])
  end
  local out = {}
  rows(s, now, room, "", out)
  return header, out
end

return layout

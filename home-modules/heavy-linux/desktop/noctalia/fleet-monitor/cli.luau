-- `fleet`'s renderer, run with lune: the sections of `fleet --json`, from stdin, laid out by layout.luau in WIDTH
-- characters, like the widget does, with ANSI colors if COLOR is "color"
-- usage: lune run cli.luau WIDTH [COLOR]
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local layout = require("./layout")

local width, color = tonumber(process.args[1]), process.args[2] == "color"
-- noctalia's color roles, as used by the widget
local CODES = { primary = "34", outline = "2", error = "31" }
-- the widget's gutter, which marks sections with hidden rows
local GUTTER = "  "

-- with the padding left unpainted, so that it can be trimmed
local function paint(text, role, bold)
  local code = CODES[role]
  if bold then code = code and "1;" .. code or "1" end
  local body, pad = text:match("^(.-)( *)$")
  return color and code and body ~= "" and `\27[{code}m{body}\27[0m{pad}` or text
end

-- prints pieces side by side, line by line
local function render(row)
  local blocks, height = {}, 1
  for _, p in row do
    local lines, w = string.split(p[1], "\n"), 0
    for _, l in lines do w = math.max(w, utf8.len(l)) end
    table.insert(blocks, { lines = lines, width = w, piece = p })
    height = math.max(height, #lines)
  end
  for i = 1, height do
    local line, pad = "", ""
    for _, b in blocks do
      local l = b.lines[i] or ""
      line ..= pad .. paint(l, b.piece[2], b.piece[3])
      pad = string.rep(" ", b.width - utf8.len(l))
    end
    print((line:gsub(" +$", "")))
  end
end

local now = os.time()
for _, s in serde.decode("json", stdio.readToEnd()) do
  local header, rows = layout.section(s, now, width - #GUTTER, false)
  table.insert(header, 1, { GUTTER })
  render(header)
  for _, row in rows do
    table.insert(row, 1, { GUTTER })
    render(row)
  end
end

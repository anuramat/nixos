# `fleet --json` -> an indented tree per section, with ANSI
# colors if $color; times are rendered relative to now, like the widget does

# 3723 -> 1h2m3s
def duration:
  (. / 3600 | floor) as $h | (. % 3600 / 60 | floor) as $m
  | (if $h > 0 then "\($h)h" else "" end) + (if $h > 0 or $m > 0 then "\($m)m" else "" end) + "\(. % 60)s";

# seconds -> the two largest units: 1d2h, 1h2m, 2m
def eta:
  (. / 86400 | floor) as $d | (. % 86400 / 3600 | floor) as $h | (. % 3600 / 60 | floor) as $m
  | if $d > 0 then "\($d)d\($h)h" elif $h > 0 then "\($h)h\($m)m" else "\($m)m" end;

# noctalia's color roles, as used by the widget
def paint($style):
  {primary: "34", title: "1;34", outline: "2", error: "31"}[$style // ""] as $c
  | if $color and $c then "\u001b[\($c)m\(.)\u001b[0m" else . end;

def cell:
  if .since then now - .since | floor | duration | paint("outline")
  elif .until then
    (.until - now | floor) as $left
    | if $left >= 0 then $left | eta | paint("outline") else "+\(-$left | eta)" | paint("error") end
  else
    . as $c
    | .text | (if $c.clip and length > $c.clip then .[:$c.clip - 3] + "..." else . end)
    | paint($c.style)
  end;

def row: [.cells[]? | cell] | join("  ");

# a row per child, followed by its own children, indented
def children($depth): .children[]? | ("  " * $depth) + row, children($depth + 1);

.[]
| ([(.name | paint("title")), (.cells[]? | cell), (.err // empty | paint("error")),
    (.at // empty | now - . | floor | duration | paint("outline"))] | join("  ")),
  children(1)

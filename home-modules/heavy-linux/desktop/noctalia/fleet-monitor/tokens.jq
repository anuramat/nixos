# `caut usage --json` -> the tokens section: a row per provider, followed by
# its rate limit windows (then the scoped, per model ones under their labels),
# or with several of them, with a child row for each; a failed provider is
# missing from `data`, and reported in `errors`

# a window's name (its length, 5h or 7d, unless given one), its remaining
# percentage, and the time left until it resets
def window($name):
  [
    {
      text: ($name // (.windowMinutes | if . % 1440 == 0 then "\(. / 1440)d" else "\(. / 60)h" end)),
      style: "on_surface_variant"
    },
    {text: "\(100 - .usedPercent | round)%", style: "on_surface_variant"},
    (.resetsAt | select(.) | {until: (sub("\\.\\d+"; "") | fromdateiso8601)})
  ];

{
  err: .errors[0],
  children: [.data[] | {text: .provider} as $name | .usage
    | [(.primary, .secondary | select(.) | window(null)),
       (.scoped // [] | .[] | .label as $l | .window | window($l | ascii_downcase))]
    | if length == 1 then {cells: [$name] + .[0]} else {cells: [$name], children: map({cells: .})} end
  ]
}

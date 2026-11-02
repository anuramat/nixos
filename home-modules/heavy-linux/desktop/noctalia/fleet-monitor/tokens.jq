# the usage responses ($claude: api.anthropic.com/api/oauth/usage, $codex:
# chatgpt.com/backend-api/wham/usage, or {error} if the fetch failed) -> the
# tokens section: a row per provider, followed by its rate limit windows, or
# with several of them, with a child row for each; a failed provider is
# missing from the rows, and reported in `err`

# a window's name, its remaining percentage, and the time left until it resets
def window($name; $used; $reset):
  [
    {text: $name, style: "on_surface_variant"},
    {text: "\(100 - $used | round)%", style: "on_surface_variant"},
    ($reset | select(.) | {until: .})
  ];

# a Codex window, named by its length, after an optional prefix
def codex($prefix):
  (.primary_window, .secondary_window) | select(.)
  | window($prefix + (.limit_window_seconds | if . % 86400 == 0 then "\(. / 86400)d" else "\(. / 3600)h" end);
      .used_percent; .reset_at);

def section($name; windows):
  if .error then {err: "\($name): \(.error)"}
  else [windows] | {row: (if length == 1 then {cells: [{text: $name}] + .[0]}
    else {cells: [{text: $name}], children: map({cells: .})} end)}
  end;

[
  ($claude | section("claude"; .limits[]
    | window((.scope.model.display_name | strings | ascii_downcase) // {session: "5h", weekly_all: "7d"}[.kind] // .kind;
        .percent; (.resets_at | strings | .[:19] + "Z" | fromdateiso8601) // null))),
  ($codex | section("codex"; (.rate_limit | codex("")),
    (.additional_rate_limits // [] | .[] | .limit_name as $l | .rate_limit | codex("\($l) "))))
]
| {err: (map(.err // empty) | first), children: map(.row // empty)}

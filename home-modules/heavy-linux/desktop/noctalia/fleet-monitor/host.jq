# fleet-probe's lines (read with -R) -> a host section: power profile, battery
# and zellij sessions in the header; jobs, then sandboxed sessions grouped by
# project dir basename, as rows

# ps etime, [[dd-]hh:]mm:ss -> seconds
def etime:
  split("-") as $p
  | ($p[-1] | split(":") | reduce (.[] | tonumber) as $n (0; . * 60 + $n))
    + (if $p | length > 1 then ($p[0] | tonumber) * 86400 else 0 end);

[inputs | split("\t")] as $lines
| (now | floor) as $now
| def kind($k): $lines[] | select(.[0] == $k) | .[1:];
[kind("zellij")] as $z
| ($z | map(select(.[1] == "0")) | length) as $detached
| {
    cells: [
      (kind("power") | select(.[0] == "quiet") | {text: "quiet", style: "outline"}),
      (kind("battery") | {text: "\(.[0])%", style: "outline"}),
      # `z` for a lone detached session, else `z(detached/total)`
      (select($z != []) | {
        text: (if $z | length == 1 and $detached == 1 then "z" else "z(\($detached)/\($z | length))" end),
        style: "on_surface_variant"
      })
    ],
    children: (
      [kind("job") | {cells: [
        # a `job run` job goes by its name
        {text: (.[0] | sub("^job-"; "") | sub("\\.service$"; ""))},
        {since: ($now - (.[1] | etime))},
        (.[2] | select(. != "") | {until: tonumber}),
        (.[3] | select(. != "") | {text: ., style: "on_surface_variant", clip: 50})
      ]}]
      + ([kind("session") | {name: .[0], project: (.[1] | sub("/+$"; "") | sub(".*/"; ""))}]
        | group_by(.project)
        | map({cells: [{
            text: "\(.[0].project)(\(if length > 1 then length else .[0].name end))",
            style: "outline"
          }]}))
    )
  }

# uc3-status.service's snapshot (read with -Rs): `Partition cpu_il   :   3
# nodes idle` lines, then a `---` line, then squeue lines; other lines are
# skipped -> the uc3 section: our jobs, then the GPU partitions with idle nodes,
# as rows

("\n" + . + "\n" | capture("^(?<head>.*?)\n---\n(?<tail>.*)$"; "p")) as $s
| {
    children: (
      [$s.tail | split("\n")[] | split("|") | select(length == 7) | {cells: [
        {text: .[0]},
        {text: .[6], width: 20},
        {text: .[1], style: "on_surface_variant"},
        {text: .[2], style: (if .[2] == "RUNNING" then "primary" else "outline" end)},
        {text: "\(.[3])/\(.[4])", style: "outline"},
        {text: .[5], style: "on_surface_variant", width: 25}
      ]}]
      + [$s.head | capture("Partition\\s+(?<p>\\S+)\\s*:\\s*(?<n>\\d+) nodes idle"; "g")
        | select(.n != "0" and (.p | contains("gpu")))
        | {cells: [{text: "\(.p)(\(.n))", style: "outline"}]}]
    )
  }

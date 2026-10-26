# uc3-status.service's snapshot (read with -Rs), taken at $at: `Partition
# cpu_il   :   3 nodes idle` lines, then a `---` line, then squeue lines;
# other lines are skipped -> the uc3 section: our jobs, then the GPU partitions
# with idle nodes, as rows; $err is the last fetch's error

include "etime";

("\n" + . + "\n" | capture("^(?<head>.*?)\n---\n(?<tail>.*)$"; "p")) as $s
| {
    at: $at,
    err: (if $err == "" then null else $err end),
    children: (
      [$s.tail | split("\n")[] | split("|") | select(length == 7) | {cells: [
        {text: .[6], width: 20},
        {text: .[1], style: "on_surface_variant"},
        # running: the elapsed time, pending: why, else the state
        if .[2] == "RUNNING" then {since: ($at - (.[3] | etime))}
        elif .[2] == "PENDING" then
          {text: "pending: \(.[5] | ltrimstr("(") | rtrimstr(")"))", style: "outline", width: 25}
        else {text: .[2] | ascii_downcase, style: "outline"}
        end
      ]}]
      + [$s.head | capture("Partition\\s+(?<p>\\S+)\\s*:\\s*(?<n>\\d+) nodes idle"; "g")
        | select(.n != "0" and (.p | contains("gpu")))
        | {cells: [{text: "\(.p)(\(.n))", style: "outline"}]}]
    )
  }

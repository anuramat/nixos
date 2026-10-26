# ps etime and squeue's elapsed time, [[dd-]hh:]mm:ss -> seconds
def etime:
  split("-") as $p
  | ($p[-1] | split(":") | reduce (.[] | tonumber) as $n (0; . * 60 + $n))
    + (if $p | length > 1 then ($p[0] | tonumber) * 86400 else 0 end);

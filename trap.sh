#
# This is a crappy little script that waits for a container's cpu usage to fall below a threshold and 
#  then profiles it for one second.  You can use something like it but way better to diagnose
#  thread starvation issues.
#
count=0
threshold=3
pid=1034
containerid=3883c31f9b55
 
while true; do
 perc=100
 
  while [ $perc -gt $threshold ]; do
    perc=$(docker stats --format '{{.CPUPerc}}' --no-stream $containerid | sed 's/.$//')
    perc=$(printf "%.0f" $perc)

    sleep 1
  done
 
  count=$((count+1))
  
  ## Generate flamegraph
  timelimit -t 1 perf record -p $pid -g
  perf script | FlameGraph/stackcollapse-perf.pl | FlameGraph/flamegraph.pl > $count.svg

  ## -or-

  ## Create trace zip
  ./perfcollect collect sample -collectsec 5
done
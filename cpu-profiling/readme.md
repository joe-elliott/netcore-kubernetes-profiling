# cpu-profiling

This collection of scripts is designed to support cpu profiling of a netcore application running in Kubernetes cluster.  It is designed to run on the node outside of the container.  Be warned they will install lttng, perf tools and probably other stuff.

Most information pulled from:

- [Linux Performance Tracing](https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/linux-performance-tracing.md)
- [Profiling Net Core App Linux](https://codeblog.dotsandbrackets.com/profiling-net-core-app-linux/)
- [Flamegraphs](https://github.com/brendangregg/FlameGraph)

### 1. Run your netcore app in K8s
Start a new pod that you want to profile with the following env vars set.

#### Environment Variables

```
env:
- name: COMPlus_PerfMapEnabled 
  value: "1"
- name: COMPlus_EnableEventLog
  value: "1"
- name: COMPlus_ZapDisable
  value: "1"
```

**COMPlus_PerfMapEnabled**
Creates a perf map in `/tmp` that perf can read to symbolicate stack traces.  `./setup.sh` copies them from the container to the host system.

**COMPlus_EnableEventLog**
Passes events to the lttng daemon. 

**COMPlus_ZapDisable**
Will force netcore runtime to be JITted.  This is normally not desirable, but it will cause the netcore runtime dll symbols to be included in the perf maps.  This will allow perf to gather symbols for both the runtime as well as your application.

There are other ways to do this if you are interested. https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/linux-performance-tracing.md#resolving-framework-symbols

#### Hostdir mount

Additionally, for lttng to work, you have to mount a hostdir.  This dir contains sockets that are used to communciate events to the lttng daemon.  I think.

```
volumes:
  - name: lttng
    hostPath:
      type: DirectoryOrCreate
      path: /var/run/lttng
containers:
  - name: netcoreapp
    volumeMounts:
    - mountPath: /var/run/lttng
      name: lttng
```

### 2. Run ./setup.sh
SSH to the node and run [`./setup.sh <pid on host>`](./setup.sh) with the pid of the process you want to profile as root.  This script will

- Move map files out of the container's `/tmp` directory to the host so perf can pick them up.
- Download and run `perfcollect install`
- Download [Flamegraph Utilities](https://github.com/brendangregg/FlameGraph) to `./FlameGraph`

### 3. Profile!

#### Option 1 - Manual

**perf**

You can generate an interactable flamegraph svg by running the following:
```
perf record -g -p <pid>
<Ctrl+C>
perf script | FlameGraph/stackcollapse-perf.pl | FlameGraph/flamegraph.pl > flamegraph.svg
```

**lttng**

You can view raw events passed to lttng using:

```
lttng create session --output=./lttng-events
lttng enable-event --userspace --all
lttng track --pid=1 -u
lttng start
# events are being recored now
lttng stop
lttng destroy

babeltrace ./lttng-events
```

Note that the above example is tracking pid 1.  This is because in most cases your netcore app will see itself as pid 1 in its container.  Adjust if necessary.

#### Option 2 - Perfcollect and Perfview

The perfcollect script itself will collect both stack traces and events at the same time.  The below will collect for 5 seconds.  If you leave the `collectsec` argument off you will need to Ctrl+C to interrupt `perfcollect`

`./perfcollect collect sample -collectsec 5`

This will create a `sample.trace.zip` file which can then be viewed with [PerfView](https://github.com/Microsoft/perfview/blob/master/documentation/Downloading.md)

I don't have as much experience with this tool as I do with just looking at flamegraphs, but seems to be a rich tool with a lot of options for analysis.

## Traps

Profiling for long periods of time can often generate too much data to be worthwhile.  Often you only want to start tracing during certain events when a service is misbehaving.  See [`./trap.sh`](./trap.sh) script for an example.

This script uses docker stats to only trigger profiling when the CPU usage dips below a threshold.  This is useful if you have a netcore application that is experiencing thread starvation and causing the service to stall out.

## Weirdness

- Lttng events are registered for pid 1, but perf will be running against a different pid.  Unsure if this has negative impacts on Perfview.  This has prevented me from running perfcollect in pid mode and getting usable results.
- These scripts install perf tools and lttng on your node.  Be warned.
- These scripts leave a perfmap in `/tmp`.  You should probably clean that up.
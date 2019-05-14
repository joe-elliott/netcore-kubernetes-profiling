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
- name: COMPlus_ZapDisable
  value: "1"
```

**COMPlus_PerfMapEnabled**
Creates a perf map in `/tmp` that perf can read to symbolicate stack traces.  `./setup.sh` copies them from the container to the host system.

**COMPlus_ZapDisable**
Will force netcore runtime to be JITted.  This is normally not desirable, but it will cause the netcore runtime dll symbols to be included in the perf maps.  This will allow perf to gather symbols for both the runtime as well as your application.

There are other ways to do this if you are interested. https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/linux-performance-tracing.md#resolving-framework-symbols

### 2. Run ./setup.sh
SSH to the node and run [`./setup.sh <pid on host>`](./setup.sh) with the pid of the process you want to profile as root.  This script will

- Move map files out of the container's `/tmp` directory to the host so perf can pick them up.
- Download and run `perfcollect install`
- Download [Flamegraph Utilities](https://github.com/brendangregg/FlameGraph) to `./FlameGraph`

### 3. Profile!

**perf**

You can generate an interactable flamegraph svg by running the following:
```
perf record -g -p <pid>
<Ctrl+C>
perf script | FlameGraph/stackcollapse-perf.pl | FlameGraph/flamegraph.pl > flamegraph.svg
```

## Traps

Profiling for long periods of time can often generate too much data to be worthwhile.  Often you only want to start tracing during certain events when a service is misbehaving.  See [`./trap.sh`](./trap.sh) script for an example.

This script uses docker stats to only trigger profiling when the CPU usage dips below a threshold.  This is useful if you have a netcore application that is experiencing thread starvation and causing the service to stall out.

## Weirdness

- These scripts leave a perfmap in `/tmp`.  You should probably clean that up.
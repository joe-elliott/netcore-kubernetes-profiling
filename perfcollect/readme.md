# perfcollect

[perfcollect](https://aka.ms/perfcollect) and [Perfview](https://github.com/Microsoft/perfview/blob/master/documentation/Downloading.md) are a collection of tools provided by Microsoft to analyze the behavior of running netcore processes.

The following guide will walk you through using these tools to gather events and perform cpu profiling on a live container running in Kubernetes.  Note that we will be performing our data collection from the node that the container is running on.

Check out these guides on [cpu profiling](../cpu-profiling/readme.md) and [static-tracepoints](../cpu-profiling/readme.md) without using PerfView.

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
Instructs netcore to produce LTTng events. 

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

### 3. Profile!

The perfcollect script itself will collect both stack traces and events at the same time.  The below will collect for 5 seconds.  If you leave the `collectsec` argument off you will need to Ctrl+C to interrupt `perfcollect`

`./perfcollect collect sample -collectsec 5`

This will create a `sample.trace.zip` file which can then be viewed with [PerfView](https://github.com/Microsoft/perfview/blob/master/documentation/Downloading.md)

I don't have as much experience with this tool as I do with just looking at flamegraphs, but seems to be a rich tool with a lot of options for analysis.

## Weirdness

- Lttng events are registered for pid 1, but perf will be running against a different pid.  Unsure if this has negative impacts on Perfview.  This has prevented me from running perfcollect in pid mode and getting usable results.
- These scripts install perf tools and lttng on your node.  Be warned.
- These scripts leave a perfmap in `/tmp`.  You should probably clean that up.
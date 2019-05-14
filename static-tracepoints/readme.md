# static-tracepoints

Recording static tracepoints produced by the netcore framework is actually quite easy.   Netcore is already instrumented to produce framework level events such as garbage collection or thread creation.

If you are interested in both profiling and recording LTTng events see [perfcollect](../perfcollect/readme.md).  This documentation will walk you through generating data for the PerfView utility.

### 1. Run your netcore app in K8s
Start a new pod that you want to profile with the following env vars set.

```
env:
- name: COMPlus_EnableEventLog
  value: "1"
```

**COMPlus_EnableEventLog**
Instructs netcore to produce LTTng events. 

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

### 2. Install LTTng
SSH to the node and install LTTng.  An easy way to do this would be to use `perfcollect`.  Be warned this installs a handful of tools related to linux tracing and debugging.

```
curl -OL https://aka.ms/perfcollect
chmod +x perfcollect
./perfcollect install
```

### 3. Collect Events

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

## Weirdness

- These scripts install perf tools and lttng on your node.  Be warned.

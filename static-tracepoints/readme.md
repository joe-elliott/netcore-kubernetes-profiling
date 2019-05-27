# static-tracepoints

Recording static tracepoints produced by the netcore framework is actually quite easy.   Netcore is already instrumented to produce framework level events such as garbage collection and thread creation.

If you are interested in both profiling and recording LTTng events see [perfcollect](../perfcollect).  This documentation will walk you through generating data for the PerfView utility.

## Run your netcore app in K8s
Create your pod with a [debugging sidecar](https://hub.docker.com/r/joeelliott/netcore-debugging-tools).  The rest of this guide will use [static-tracepoints.yaml](./static-tracepoints.yaml) which runs a sidecar next to a simple [sample app](https://github.com/joe-elliott/sample-netcore-app).


#### Environment Variables
Set the following environment variables for your main process.

```
env:
- name: COMPlus_EnableEventLog
  value: "1"
```

`COMPlus_EnableEventLog`  Instructs netcore to produce LTTng events. 

#### Mount /var/run/lttng
LTTng uses a number of files in this folder to communicate with the running process.  Sharing this folder between containers allows your sidecar to pick up events produced by your netcore app.

#### shareProcessNamespace
Setting `shareProcessNamespace` to true allows the sidecar to easily access the process you want to debug.

## Collect Events!

Exec into the sidecar and discover the pid of the dotnet process you want to profile.  You will use it in the below examples.

```
kubectl exec -it -c profile-sidecar sample-netcore-app bash
# ps aux | grep dotnet
root         7  0.4  3.9 11797376 80500 ?      SLsl 00:55   0:01 dotnet /app/sample-netcore-app.dll
```

Start an LTTng session and collect events.

```
lttng create session --output=./lttng-events
lttng enable-event --userspace --all
lttng track --pid=<pid> -u
lttng start
# events are being recored now
lttng stop
lttng destroy
```

Dump them to the terminal.

```
babeltrace ./lttng-events

...
[01:00:37.588459510] (+0.000000481) sample-netcore-app DotNETRuntime:GCSampledObjectAllocationHigh: { cpu_id = 0 }, { Address = 139897548412480, TypeID = 139906679802464, ObjectCountForTypeSample = 1, TotalSizeForTypeSample = 122, ClrInstanceID = 0 }
[01:00:37.588460717] (+0.000001207) sample-netcore-app DotNETRuntime:EventSource: { cpu_id = 0 }, { EventID = 25, EventName = "SetActivityId", EventSourceName = "System.Threading.Tasks.TplEventSource", Payload = "{\"NewId\":00000000-0000-0000-0000-000000000000}" }
[01:00:37.588523375] (+0.000062658) sample-netcore-app DotNETRuntime:ThreadPoolWorkerThreadWait: { cpu_id = 0 }, { ActiveWorkerThreadCount = 2, RetiredWorkerThreadCount = 0, ClrInstanceID = 0 }
[01:00:37.588524339] (+0.000000964) sample-netcore-app DotNETRuntime:ThreadPoolWorkerThreadWait: { cpu_id = 0 }, { ActiveWorkerThreadCount = 2, RetiredWorkerThreadCount = 0, ClrInstanceID = 0 }
[01:00:38.586440792] (+0.997916453) sample-netcore-app DotNETRuntime:GCSampledObjectAllocationHigh: { cpu_id = 0 }, { Address = 139897548412608, TypeID = 139906670816858, ObjectCountForTypeSample = 1, TotalSizeForTypeSample = 48, ClrInstanceID = 0 }
[01:00:38.586445343] (+0.000004551) sample-netcore-app DotNETRuntime:GCSampledObjectAllocationHigh: { cpu_id = 0 }, { Address = 139897548412656, TypeID = 139906679813328, ObjectCountForTypeSample = 1, TotalSizeForTypeSample = 24, ClrInstanceID = 0 }
...
```
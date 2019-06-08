# coredumps

This guide will walk you through capturing a coredump of a netcore application running in Kubernetes cluster.  The tools are designed to run in a sidecar next to the pod you want to debug.

Most information pulled from:

https://github.com/dotnet/coreclr/blob/master/Documentation/botr/xplat-minidump-generation.md

## Run your netcore app in K8s
Create your pod with a [debugging sidecar](https://hub.docker.com/r/joeelliott/netcore-debugging-tools).  The rest of this guide will use [coredumps.yaml](./coredumps.yaml) which runs a sidecar next to a simple [sample app](https://github.com/joe-elliott/sample-netcore-app).

#### Environment Variables
Set the following environment variables for your main process.

```
env:
- name: COMPlus_DbgEnableMiniDump
    value: "1"
- name: COMPlus_DbgMiniDumpName
    value: "/tmp/coredump.%d"
```

`COMPlus_DbgEnableMiniDump` creates a perf map in `/tmp` that perf can read to symbolicate stack traces.  

`COMPlus_DbgMiniDumpName` will force netcore runtime to be JITted.  This is normally not desirable, but it will cause the netcore runtime dll symbols to be included in the perf maps.  This will allow perf to gather symbols for both the runtime as well as your application.

Another variable you could consider setting is `COMPlus_DbgMiniDumpType`.  `COMPlus_DbgMiniDumpType` allows you to change the information that is captured in the coredump.  See [here](https://github.com/dotnet/coreclr/blob/master/Documentation/botr/xplat-minidump-generation.md#configurationpolicy) for more information.  The default value of `MiniDumpWithPrivateReadWriteMemory ` has been sufficient to view threads, stack traces and explore the heap.

#### shareProcessNamespace
Setting `shareProcessNamespace` to true allows the sidecar to easily access the process you want to debug.

## Generate dump

#### 
COMPlus_DbgEnableMiniDump=1
COMPlus_DbgMiniDumpName='/tmp/coredump.%d'
SIGKILL?

#### On Demand
```
    kubectl exec -it -c profile-sidecar sample-netcore-app bash
    cd /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5
    ./createdump 141
```

#### On crash
```
   Environment.FailFast()
```

### Parsing
```
apt-get update
apt-get install lldb
```

```
lldb /usr/bin/dotnet --core /tmp/coredump.6
plugin load /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/libsosplugin.so
setclrpath /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5
```

### Basic commands
```
sos Threads
```
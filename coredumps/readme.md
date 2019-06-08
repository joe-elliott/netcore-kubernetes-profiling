# coredumps

https://github.com/dotnet/coreclr/blob/master/Documentation/botr/xplat-minidump-generation.md
https://stackoverflow.com/questions/42070270/how-to-dump-a-net-core-application-on-linux
https://github.com/dotnet/coreclr/issues/1321

## Run your netcore app in K8s
Create your pod with a [debugging sidecar](https://hub.docker.com/r/joeelliott/netcore-debugging-tools).  The rest of this guide will use [coredumps.yaml](./coredumps.yaml) which runs a sidecar next to a simple [sample app](https://github.com/joe-elliott/sample-netcore-app).

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
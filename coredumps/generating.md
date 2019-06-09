# Generating Core Dumps

This guide will walk you through capturing a core dump of a netcore application running in Kubernetes cluster.  The tools are designed to run in a sidecar next to the pod you want to debug.

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

`COMPlus_DbgEnableMiniDump` tells the netcore runtime to generate a core dump if the process exits unexpectedly.

`COMPlus_DbgMiniDumpName` indicates the file to place the core dump in when the process exits unexpectedly.  We are placing it in `/tmp` so it is accessible in the sidecar.

Another variable you could consider setting is `COMPlus_DbgMiniDumpType`.  `COMPlus_DbgMiniDumpType` allows you to change the information that is captured in the core dump.  See [here](https://github.com/dotnet/coreclr/blob/master/Documentation/botr/xplat-minidump-generation.md#configurationpolicy) for more information.  The default value of `MiniDumpWithPrivateReadWriteMemory ` has been sufficient to view threads, stack traces and explore the heap.

#### shareProcessNamespace
Setting `shareProcessNamespace` to true allows the sidecar to easily access the process you want to debug.

#### Mount /tmp
By sharing /tmp as an empty directory the debugging sidecar can easily access core dumps created when the application exits unexpectedly.

## Generate dump

There are two different scenarios in which you'd generally like to generate a core dump.  See below for details on generating a dump on demand or when an application crashes.

To begin exploring both cases exec into the sidecar.

```
kubectl exec -it -c profile-sidecar sample-netcore-app bash
```

#### On Demand

On demand core dumps are useful when your application enters states you need to better understand that do not cause the application to crash.  E.g.

- Your application is deadlocking and you want to see the stack traces of all threads.
- Your application is consuming an unbounded amount of memory and you want to investigate the heap.

To generate a core dump on demand we will use the `createdump` utility provided by Microsoft.  This application is located in `/usr/share/dotnet/shared/Microsoft.NETCore.App/<dotnet framework version>`.  Note that you will need the pid of the dotnet process.

```
# ps aux | grep dotnet
root       832  0.7  3.8 11927716 77536 ?      SLsl 13:26   0:00 dotnet /app/sample-netcore-app.dll

# /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/createdump 151
Writing minidump with heap to file /tmp/coredump.832
Written 168390656 bytes (41111 pages) to core file

# ls -al /tmp/coredump*
-rw-r--r-- 1 root root 168591360 Jun  8 13:29 /tmp/coredump.832
```

#### On Unexpected Exception

If your application is crashing due to an unexpected exception then coredumps will be generated automtically due to the environment variables set above `COMPlus_DbgEnableMiniDump` and `COMPlus_DbgMiniDumpName`  The [sample application](https://github.com/joe-elliott/sample-netcore-app) has an endpoint that calls [`Environment.FailFast()`](https://docs.microsoft.com/en-us/dotnet/api/system.environment.failfast?view=netcore-2.2) to force just such an unexpected exit.

After connecting to the sidecar:

```
# ps aux | grep dotnet
root       151  0.1  4.0 11796900 83064 ?      SLsl 13:02   0:01 dotnet /app/sample-netcore-app.dll

# curl http://localhost:8080/api/fail
curl: (52) Empty reply from server

# ls -al /tmp/coredump*
-rw-r--r-- 1 root root 171085824 Jun  8 13:26 /tmp/coredump.151
```

## Next Steps

Now that you have generated a dump check out [this guide](./analyzing.md) for more information on analyzing it.
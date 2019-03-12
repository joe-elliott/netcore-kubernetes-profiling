# dynamic-tracing

WIP documentation and scripts for dynamic tracing of netcore apps.  Most information pulled from:

- [Using CrossGen to Create Native Images](https://github.com/dotnet/coreclr/blob/master/Documentation/building/crossgen.md)
- [Dynamic Tracing of .NET Core Methods](https://blogs.microsoft.co.il/sasha/2018/02/08/dynamic-tracing-of-net-core-methods/)
- [perf Examples](http://www.brendangregg.com/perf.html)

The below very rough notes are an outline of how I have successfully traced netcore applications running on Linux.  I am currently working on expanding this to be a drop in method for dynamic tracing of methods of any Kubernetes application.

### make a dotnet thing
```
./dotnet new console
./dotnet publish . -o ./bin --self-contained --runtime linux-x64
```

### generate native images using crossgen
Crossgen is weirdly hard to find.  After running a publish I was able to find it in `/root/.nuget/packages/runtime.linux-x64.microsoft.netcore.app/2.2.2/tools/crossgen`.  

The first command generates the native image.  The second generates a map file that we will use to determine the address at which to place a probe.

```
./crossgen /JITPath bin/libclrjit.so /Platform_Assemblies_Paths bin bin/app.dll
./crossgen /Platform_Assemblies_Paths bin /CreatePerfMap /tmp bin/app.ni.exe
```

Do the above for every dll you want to place probes on.

### Find the address to trace

Follow the instructions [here](https://blogs.microsoft.co.il/sasha/2018/02/08/dynamic-tracing-of-net-core-methods/) to calculate the address to place a probe at.  You will use the the native image perf maps in `/tmp` and the process memory map located at `/proc/<pid>/maps`.

### Add a probe, trace it, view it and remove

```
perf probe -x ./bin/app.ni.exe --add 0x<address from above>  
perf record -e probe_app:* -ag -- sleep 10
perf script
perf probe --del=*
```

### runNative.sh

This [script](./runNative.sh) takes a single parameter which is the path to a netcore CLR application dll.  It will then:

- Pull crossgen
- Generate the native image
- Generate the perf map of the native image
- Run the native image

There is a lot of work to be done to support different container environments but these are the basic steps to start dynamically tracing netcore applications.  The idea is that this script would be injected into a container via configmap and run instead of the netcore application.  This script will then generate the native image and run it allowing for dynamic tracing of the process.

### open questions/todo
- create an automatic way to generate the native images and maps without recompiling code
- find a way to get application and framework symbols
- find and document ways to get arguments and return vals
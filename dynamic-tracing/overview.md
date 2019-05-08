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
Crossgen is available in the appropriate runtime netcore nuget package.  For instance if you have a 2.2.2 netcore app running on the `linux-musl-x64` runtime then you would download the following package.  Unzip the package and look in the `./tools` directory to find crossgen.

https://www.nuget.org/packages/runtime.linux-musl-x64.Microsoft.NETCore.App/2.2.2

After you get a hold of the appropriate crossgen run the following commands. The first command generates the native image.  The second generates a map file that we will use to determine the address at which to place a probe.

```
./crossgen /JITPath bin/libclrjit.so /Platform_Assemblies_Paths bin bin/app.dll
./crossgen /Platform_Assemblies_Paths bin /CreatePerfMap /tmp bin/app.ni.exe
```

Do the above for every dll you want to place probes on.

### Find the address to trace

Follow the instructions [here](https://blogs.microsoft.co.il/sasha/2018/02/08/dynamic-tracing-of-net-core-methods/) to calculate the address to place a probe at.  You will use the the native image perf maps in `/tmp` and the process memory map located at `/proc/<pid>/maps`.

The helper script [calc-offsets.py](./calc-offsets.py) is also provided.

### Add a probe, trace it, view it and remove

```
perf probe -x ./bin/app.ni.exe --add 0x<address from above>  
perf record -e probe_app:* -ag -- sleep 10
perf script
perf probe --del=*
```

### next steps

See [probes](./probes.md) for more information about the kinds of probes you can place.
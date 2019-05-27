# dynamic-tracing

Information about dynamically tracing netcore applications is sparse and sometimes incorrect.  There is definitely still work to be done, but the below steps are a very good start.  Most of the information contained in this document was pulled from:

- [Using CrossGen to Create Native Images](https://github.com/dotnet/coreclr/blob/master/Documentation/building/crossgen.md)
- [Dynamic Tracing of .NET Core Methods](https://blogs.microsoft.co.il/sasha/2018/02/08/dynamic-tracing-of-net-core-methods/)
- [perf Examples](http://www.brendangregg.com/perf.html)

The below notes review generally how to dynamically trace a netcore application.  See [this guide](./kubernetes.md) for a drop in method of dynamically tracing in Kubernetes from a sidecar.

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

Do the above for every dll you want to place probes on.  Presumably you can place probes on other dlls, but so far I have only done this with the primary dll or exe.

### Find the address to trace

These [instructions](https://blogs.microsoft.co.il/sasha/2018/02/08/dynamic-tracing-of-net-core-methods/) to calculate the address to place a probe at.  You will use the the native image perf maps in `/tmp` and the process memory map located at `/proc/<pid>/maps`.

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
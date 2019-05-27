# dynamic-tracing

Information about dynamically tracing netcore applications is sparse and sometimes incorrect.  There is definitely still work to be done, but the below steps are a very good start.  Most of the information contained in this document was pulled from:

- [Using CrossGen to Create Native Images](https://github.com/dotnet/coreclr/blob/master/Documentation/building/crossgen.md)
- [Dynamic Tracing of .NET Core Methods](https://blogs.microsoft.co.il/sasha/2018/02/08/dynamic-tracing-of-net-core-methods/)
- [perf Examples](http://www.brendangregg.com/perf.html)
- [proc maps](https://stackoverflow.com/questions/1401359/understanding-linux-proc-id-maps)

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

To place a probe we have to find the offset into the native image.  You will use the the native image perf maps in `/tmp` and the process memory map located at `/proc/<pid>/maps`.

Get the process id.
```
root@sample-netcore-app:~# ps aux | grep dotnet
root       112  0.0  3.8 11804944 77704 ?      SLl  11:14   0:03 dotnet /app-profile/sample-netcore-app.ni.exe
```

Note the location of the method you want to trace.
```
root@sample-netcore-app:~# cat /tmp/sample-netcore-app.ni.\{e46f1077-89cb-4add-94fd-a6ae91a035fc\}.map | grep calculateEcho     
0000000000021900 9 instance string [sample-netcore-app] sample_netcore_app.Providers.EchoProvider::calculateEchoValue(string)
```

Note the mmap'ed sections of the native image in the process memory map.
```
root@sample-netcore-app:~# cat /proc/112/maps | grep sample
7ff03c8a0000-7ff03c8a1000 r--p 00000000 08:01 8410243                    /app-profile/sample-netcore-app.ni.exe
7ff03c8b0000-7ff03c8b1000 rw-p 00000000 08:01 8410243                    /app-profile/sample-netcore-app.ni.exe
7ff03c8c0000-7ff03c8c3000 r-xp 00000000 08:01 8410243                    /app-profile/sample-netcore-app.ni.exe
7ff03c8d2000-7ff03c8d3000 r--p 00002000 08:01 8410243                    /app-profile/sample-netcore-app.ni.exe
```

Choose the appropriate section from the above four.  The correct section will both be executable and will also contain the address we discovered above (0x21900 in our case).

The first section is not executable and contains offsets 0x00000->0x10000.
The second section is not executable and contains offsets 0x10000->0x20000.
The third section is executable and contains offsets 0x20000->0x30000.  This is the correct section!
The fourth section is not executable and contains offsets 0x30000->0x40000 (See Notes below).  

Once you have all of the above values you can caluclate the offset using the following calculation:
```
MethodAddress - (ExeSectionStartAddress - FirstSectionStartAddress) + SectionOffset
```
In our case
```
0x21900 - (0x7ff03c8c0000 - 0x7ff03c8a0000) + 0x0000 = 0x1900
```

*Note*:  I'm honestly not sure how the SectionOffset works into the above calculations.  The third column is an offset into the file (SectionOffset) that was passed when mmap was called.  I've never had this land on the same section as the executable to really test how they impact calculating the offset for dynamic tracing.  [calc-offsets.py](../images/calc-offsets.py) uses the original calculations provided by Sasha Goldstein.

### Add a probe, trace it, view it and remove

```
perf probe -x ./bin/app.ni.exe --add 0x1900
perf record -e probe_app:* -ag -- sleep 10
perf script
perf probe --del=*
```

### Next Steps

See [probes](./probes.md) for more information about the kinds of probes you can place.  This document has examples of using both perf and bcc to place dynamic probes on [this app](https://github.com/joe-elliott/sample-netcore-app)

### calc-offsets.py

The helper script [calc-offsets.py](../images/calc-offsets.py) is provided to perform the above calculations automatically.

```
root@sample-netcore-app:~# python calc-offsets.py 112 sample-netcore-app.ni.exe
offset: 17e0 : void [sample-netcore-app] sample_netcore_app.Program::Main(string[])
offset: 1820 : class [Microsoft.AspNetCore.Hosting.Abstractions]Microsoft.AspNetCore.Hosting.IWebHostBuilder [sample-netcore-app] sample_netcore_app.Program::CreateWebHostBuilder(string[])
offset: 1840 : instance void [sample-netcore-app] sample_netcore_app.Program::.ctor()
offset: 1850 : instance void [sample-netcore-app] sample_netcore_app.Startup::.ctor(class [Microsoft.Extensions.Configuration.Abstractions]Microsoft.Extensions.Configuration.IConfiguration)
offset: 1870 : instance class [Microsoft.Extensions.Configuration.Abstractions]Microsoft.Extensions.Configuration.IConfiguration [sample-netcore-app] sample_netcore_app.Startup::get_Configuration()
offset: 1880 : instance void [sample-netcore-app] sample_netcore_app.Startup::ConfigureServices(class [Microsoft.Extensions.DependencyInjection.Abstractions]Microsoft.Extensions.DependencyInjection.IServiceCollection)
offset: 18d0 : instance void [sample-netcore-app] sample_netcore_app.Startup::Configure(class [Microsoft.AspNetCore.Http.Abstractions]Microsoft.AspNetCore.Builder.IApplicationBuilder,class [Microsoft.AspNetCore.Hosting.Abstractions]Microsoft.AspNetCore.Hosting.IHostingEnvironment)
offset: 18f0 : instance void [sample-netcore-app] sample_netcore_app.Providers.EchoProvider::.ctor()
offset: 1900 : instance string [sample-netcore-app] sample_netcore_app.Providers.EchoProvider::calculateEchoValue(string)
offset: 1910 : instance void [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::.ctor()
offset: 1920 : instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValue(int32)
offset: 1950 : instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValueRecursive(int32,int32,int32,int32)
offset: 1980 : instance void [sample-netcore-app] sample_netcore_app.Controllers.EchoController::.ctor(class sample_netcore_app.Providers.IEchoProvider)
offset: 19c0 : instance class [Microsoft.AspNetCore.Mvc.Core]Microsoft.AspNetCore.Mvc.ActionResult`1<string> [sample-netcore-app] sample_netcore_app.Controllers.EchoController::Get(string)
offset: 1a00 : instance void [sample-netcore-app] sample_netcore_app.Controllers.FibonacciController::.ctor(class sample_netcore_app.Providers.IFibonacciProvider)
offset: 1a40 : instance class [Microsoft.AspNetCore.Mvc.Core]Microsoft.AspNetCore.Mvc.ActionResult`1<int32> [sample-netcore-app] sample_netcore_app.Controllers.FibonacciController::Get(int32)
```
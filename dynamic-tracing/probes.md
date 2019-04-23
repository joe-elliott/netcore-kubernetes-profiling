# probes

### Run Application

Create the [dynamic-tracing.yaml](./dynamic-tracing.yaml) Kubernetes specs in your cluster and ssh to the appropriate node.  This will run a simple web service in your cluster:  https://github.com/number101010/sample-netcore-app.

Copy map and files from the `/tmp` directory in the container to the root.  Use [mapgen.py](./mapgen.py) to merge the native image perf map with the standard perf map.  Adapted from: https://gist.github.com/goldshtn/fe3f7c3b10ec7e5511ae755abaf52172

### Simple uprobes

- Obtain exe offset:
```
# cat /proc/31012/maps | grep ni.exe
7f784ee80000-7f784ee81000 r-xp 00000000 ca:02 8388617                    /app-profile/sample-netcore-app.ni.exe
7f784ee90000-7f784ee91000 rwxp 00000000 ca:02 8388617                    /app-profile/sample-netcore-app.ni.exe
7f784eea0000-7f784eea3000 r-xp 00000000 ca:02 8388617                    /app-profile/sample-netcore-app.ni.exe
7f784eeb2000-7f784eeb3000 r-xp 00002000 ca:02 8388617                    /app-profile/sample-netcore-app.ni.exe
```

```
# cat /tmp/sample-netcore-app.ni.\{d2e97439-0da1-4364-a46e-21d41f3d9078\}.map
...
0000000000021920 2b instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValue(int32)
...
```

- Add the probe:
```
# perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1920'
```

- Record
```
# perf record -e probe_sample:* -ag -- sleep 10
```

- Exercise
```
$ curl https://sample-netcore-app/api/fibonacci?pos=3
3
```

- Dump Results
```
# perf script
Failed to open /app-profile/sample-netcore-app.ni.exe, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.3/Microsoft.AspNetCore.Mvc.Core.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.3/Microsoft.AspNetCore.Routing.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.3/Microsoft.AspNetCore.HostFiltering.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.3/Microsoft.AspNetCore.Hosting.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.3/System.Private.CoreLib.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.3/libcoreclr.so, continuing without symbols
Failed to open /lib/ld-musl-x86_64.so.1, continuing without symbols
dotnet 17273 [000] 1761930.225777: probe_sample:abs_1920: (7f784eea1920)
                    1920 [unknown] (/app-profile/sample-netcore-app.ni.exe)
                  1239e3 [unknown] (/usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.3/Microsoft.AspNetCore.Mvc.Core.dll)
                  132f12 [unknown] (/usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.3/Microsoft.AspNetCore.Mvc.Core.dll)
            7f7854aa5c6b [unknown] (/tmp/perf-31012.map)
            7f7854aa5bf9 [unknown] (/tmp/perf-31012.map)
...
```
The call stack is currently quite bad.  We might be able to improve this by running crossgen on dependent dlls and using mapgen to merge them into the perfmap. 

### Integer Parameters
Parameters can be recorded by understanding which registers are used to pass various parameter types.  See System V AMD64 ABI in https://en.wikipedia.org/wiki/X86_calling_conventions.  

Also, even though it's for kprobes, this (https://www.kernel.org/doc/Documentation/trace/kprobetrace.txt) is the best document I can find which shows how to request and format registers and memory locations.

```
# perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1920 pos=%si:s32'
```

```
$ curl https://sample-netcore-app/api/fibonacci?pos=3
3
```

Note the named parameter "pos" is formatted as a signed 32 bit integer:
```
# perf script
Failed to open /app-profile/sample-netcore-app.ni.exe, continuing without symbols
          dotnet 22154 [000] 1762703.370019: probe_sample:abs_1920: (7f784eea1920) pos=3
```

### Return Values (uretprobes)

```
# perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1920%return ret=$retval:s32'
```

```
$ curl https://profile.internal.qsrpolarisdev.net/api/fibonacci?pos=10
89
```

Note that the return value of `89` is successfully recorded and displayed:
```
# perf script
dotnet 22346 [000] 1762828.667743: probe_sample:abs_1920: (7f784eea1920 <- 7f78528413d5) ret=89
```

### String Parameters
???
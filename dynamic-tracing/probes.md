# probes

### Run Application

Create the [dynamic-tracing.yaml](./dynamic-tracing.yaml) Kubernetes specs in your cluster and ssh to the appropriate node.  This will run a simple web service in your cluster:  https://github.com/number101010/sample-netcore-app.

Copy map and files from the `/tmp` directory in the container to the root.  Use [mapgen.py](./mapgen.py) to merge the native image perf map with the standard perf map.  Adapted from: https://gist.github.com/goldshtn/fe3f7c3b10ec7e5511ae755abaf52172.  At this point I mostly think that mapgen doesn't work.  There is a lot of work still to be done on building good stack traces in perf while dynamic tracing.

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
# cat /tmp/sample-netcore-app.ni.\{d2e97439-0da1-4364-a46e-21d41f3d9078\}.map | grep calculateFibonacciValue
0000000000021920 2b instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValue(int32)
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
$ curl http://sample-netcore-app/api/fibonacci?pos=3
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
$ curl http://sample-netcore-app/api/fibonacci?pos=3
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
$ curl http://sample-netcore-app/api/fibonacci?pos=10
89
```

Note that the return value of `89` is successfully recorded and displayed:
```
# perf script
dotnet 22346 [000] 1762828.667743: probe_sample:abs_1920: (7f784eea1920 <- 7f78528413d5) ret=89
```

### String Parameters

Identify the function to profile
```
# cat /tmp/sample-netcore-app.ni.\{d2e97439-0da1-4364-a46e-21d41f3d9078\}.map | grep calculateEcho
0000000000021900 9 instance string [sample-netcore-app] sample_netcore_app.Providers.EchoProvider::calculateEchoValue(string)
```

Through trial and error I have found that the netcore string's length is a 32 bit int stored 8 bytes offset from the string pointer.  Note that we are using `(%si)` to dereference the value in RSI because this is a string type.  We are also pulling 128 bits of the string itself in two 64 bit chunks.

Note that perf supports a string type directly.  However, this requires a null terminated string. 

```
perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1900 len=+8(%si):u32 str=+12(%si):x64 str2=+20(%si)'
```

Exercise
```
$ curl http://sample-netcore-app/api/echo?echo=abc
abc
$ curl http://sample-netcore-app/api/echo?echo=abcdef
abcdef
$ curl http://sample-netcore-app/api/echo?echo=abcdefghi
abcdefghi
$ curl http://sample-netcore-app/api/echo?echo=abcdefghijkl
abcdefghijkl
$ curl http://sample-netcore-app/api/echo?echo=abcdefghijklmno
abcdefghijklmno
```

Note that `str` and `str2`'s bytes are actually in reverse order.  I am unsure why this is.
```
# perf script
Failed to open /app-profile/sample-netcore-app.ni.exe, continuing without symbols
dotnet 24162 [000] 33591.658838: probe_sample:abs_1900: (7fc028bd1900) len=3 str=0x6300620061 str2=0x0
dotnet 24162 [000] 33593.727911: probe_sample:abs_1900: (7fc028bd1900) len=6 str=0x64006300620061 str2=0x660065
dotnet 24162 [000] 33595.926689: probe_sample:abs_1900: (7fc028bd1900) len=9 str=0x64006300620061 str2=0x68006700660065
dotnet 24162 [000] 33598.230186: probe_sample:abs_1900: (7fc028bd1900) len=12 str=0x64006300620061 str2=0x68006700660065
dotnet 24162 [000] 33600.630045: probe_sample:abs_1900: (7fc028bd1900) len=15 str=0x64006300620061 str2=0x68006700660065
```
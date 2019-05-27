# perf

This document shows step by step examples on using both perf to dynamically trace [this application](https://github.com/joe-elliott/sample-netcore-app) in your cluster with [the sidecar](https://hub.docker.com/r/joeelliott/netcore-debugging-tools) generated from this repo.

See [probes](../probes.md) for more information on setup.

#### Add the probe
```
# perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1920'
```

#### Record
```
# perf record -e probe_sample:* -ag -- sleep 10
```

#### Exercise
```
$ curl http://sample-netcore-app/api/fibonacci?pos=3
3
```

#### Dump Results
```
# perf script
Failed to open /app-profile/sample-netcore-app.ni.exe, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Routing.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.HostFiltering.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Hosting.dll, continuing without symbols
Failed to open /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/System.Private.CoreLib.dll, continuing without symbols
Failed to open /lib/x86_64-linux-gnu/libpthread-2.24.so, continuing without symbols
dotnet 29638 [000] 930393.538484: probe_sample:abs_1920: (7f8ccc5a1920)
                    1920 [unknown] (/app-profile/sample-netcore-app.ni.exe)
                  123c93 [unknown] (/usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll)
                  1331c2 [unknown] (/usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll)
            7f8cd21d0bbb void [System.Private.CoreLib] System.Runtime.CompilerServices.AsyncMethodBuilderCore::Start(!!0&)+0x3b (/tmp/perf-247.map)
            7f8cd21d0b49 instance class [netstandard]System.Threading.Tasks.Task [Microsoft.AspNetCore.Mvc.Core] Microsoft.AspNetCore.Mvc.Internal.ControllerActionInvoker::Invoke
                   f11f2 [unknown] (/usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll)
                  132c64 [unknown] (/usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll)
...
```
The call stack is currently quite bad.  We might be able to improve this by running crossgen on dependent dlls and using mapgen to merge them into the perfmap.  There is definitely [work to be done](../../todo) in this area.

#### Integer Parameters
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
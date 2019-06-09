### Analyzing

```
lldb /usr/bin/dotnet --core /tmp/coredump.6
```

Load the sos plugin and point it at the CLR.  This provides a set of commands that allow you to analyze the state of the managed application.  The rest of the guide will use the commands enabled by this plugin.
```
plugin load /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/libsosplugin.so
setclrpath /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5
```

### Basic commands
```
soshelp
```

- install lldb-3.9?
- eestack hangs?

# find stuff on heap and inspect?
DumpHeap -type Provider
GCRoot <address>

(lldb) sos GCRoot 00007f2dc83fa388
Found 0 unique roots (run 'gcroot -all' to see all roots).
(lldb) sos GCRoot -all 00007f2dc83fa388
Found 0 roots.

(lldb) sos DumpObj 00007f2dc83fa388
Name:        sample_netcore_app.Controllers.FibonacciController
MethodTable: 00007f2ef2130048
EEClass:     00007f2ef2099720
Size:        64(0x40) bytes
File:        /app/sample-netcore-app.dll
Fields:
              MT    Field   Offset                 Type VT     Attr            Value Name
Unable to display fields
00007f2eeeec6c30  4000003       30 ...FibonacciProvider  0 instance 00007f2cc80e3648 _provider
Unable to display fields

# find thrown exception
sos Threads
thread select 17
sos PrintException
sos ClrStack

# find locked threads?

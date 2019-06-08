### Analyzing

```
lldb /usr/bin/dotnet --core /tmp/coredump.6
plugin load /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/libsosplugin.so
setclrpath /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5
```

### Basic commands
```
sos Threads
```
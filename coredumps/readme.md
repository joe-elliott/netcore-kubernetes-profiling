# core dumps

Taking a core dump allows analysis of the state of the application at the time the dump was taken.  This is useful to investigate the number and state of your application threads, viewing last thrown exceptions, exploring the objects on the heap and more.

The following guides show how to generate and analyze the core dump of an application running in Kubernetes from a sidecar.

- [Generating](./generating.md)
  - Guide on how to generate a coredump in multiple scenarios.
- [Analyzing](./analyzing.md)
  - Information about using lldb to analyze the captured dump.

### Alternative Methods

The above guides are dependent on being able to install lldb 3.9 in container.  If this is not possible then Microsoft has provided a dotnet dump tool that does not rely on a native debugger.

https://github.com/dotnet/diagnostics/blob/master/documentation/dotnet-dump-instructions.md


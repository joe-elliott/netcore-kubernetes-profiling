# coredumps

Taking a core dump allows analysis of the state of the application at the time the dump was taken.  This is useful to investigate the number and state of your application threads, viewing last thrown exceptions, exploring the objects on the heap and more.

The following guides show how to generate and analyze the core dump of an application running in Kubernetes from a sidecar.

- [Generating](./generating.md)
  - Guide on how to generate a coredump in multiple scenarios.
- [Analyzing](./analyzing.md)
  - Information about using lldb to analyze the captured dump.
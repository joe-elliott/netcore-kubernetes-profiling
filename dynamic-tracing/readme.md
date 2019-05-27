# dynamic-tracing

Dynamic tracing allows instrumentation of code without recompiling.  This includes the ability to not only record when specific methods are being called but also dump parameters or return values from methods.  It can give you incredible insight into the behavior of a live application without any changes to the codebase.

The following guides show how to generally perform dynamic tracing with netcore as well as specific details of how to trace an application running in Kubernetes from a sidecar.

- [Overview](./overview.md)
  - General guide on how to perform dynamic tracing with netcore.
- [In Kubernetes](./kubernetes.md)
  - Specialized scripts and techniques for dynamic tracing netcore apps in Kubernetes.
- [Probes](./probes.md)
  - Different kinds of probes that can be placed once a the address of a function is determined.  If you want to skip the details and get right to the live examples click here!
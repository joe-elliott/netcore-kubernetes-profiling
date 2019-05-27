# dynamic-tracing

Dynamic tracing allows instrumentation of code without recompiling.  The following guides show how to generally perform dynamic tracing with netcore as well as specific details of how to trace an application running in Kubernetes from a sidecar.

- [Overview](./overview.md)
  General guide on how to perform dynamic tracing with netcore.
- [In Kubernetes](./kubernetes.md)
  Specialized scripts and techniques for dynamic tracing netcore apps in Kubernetes.
- [Probes](./probes.md)
  Different kinds of probes that can be placed once a the address of a function is determined
# netcore-kubernetes-profiling

This is my personal collection of notes, scripts and techniques developed to help debug live netcore applications running in Kubernetes.  I am not an expert on these subjects and attempt to credit my sources and inspirations as much as possible.  Feel free to ask questions, make corrections or even submit pull requests.

- [images](./images)
  - A collection of Dockerfiles to build sidecar profiling containers.
- [cpu profiling](cpu-profiling)
- [static tracepoints](static-tracepoints/readme.md)
- [perfcollect](perfcollect/readme.md)
  - Static Tracepoints and CPU Profiling
- [dynamic tracing](dynamic-tracing/readme.md)
  - Includes guides on using both perf events and bcc

Originally the repo was focused on running profiling tools on the node on which the pod was running.   Currently I am rewriting all of the guides to use a sidecar instead.  This approach should be signicantly more flexible and clean then the previous method.  

Previously this repo was focused on executing these techniques from the node the application was running on.  If you are interested in that approach you can check it out [here](https://github.com/joe-elliott/netcore-kubernetes-profiling/tree/54bacfeecb33de6bbc590768af9c276efd1b4e4c).

## todo

- cpu profile
  - add sample app example
  - switch to sidecar
- static tracepoints
  - add sample app example
  - switch to sidecar
- perfcollect
  - add sample app example
  - switch to sidecar
- dynamic tracing
   - documentation cleanup
   - switch to sidecar
   - improve call stacks
     - https://github.com/dotnet/ILMerge
     - Perf can't use perf maps for dlls?  bcc can?
       - http://blogs.microsoft.co.il/sasha/2017/02/27/profiling-a-net-core-application-on-linux/
     - review mapgen.py.  make sure we can get stack traces
   - bcc/bpf
      - add sample app example
      - flesh out instructions on installing and show examples
      - switch to sidecar
- core dumps
- add notes regarding the interaction between the kernel and the debugging tools in container.  
  - test techniques on multiple kernels

## to read

- https://jvns.ca/blog/2017/07/05/linux-tracing-systems/
- http://man7.org/linux/man-pages/man1/perf-probe.1.html
- https://linux.die.net/man/1/perf-probe
- https://www.kernel.org/doc/Documentation/trace/kprobetrace.txt
- http://www.brendangregg.com/blog/2018-10-08/dtrace-for-linux-2018.html
- http://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html
- https://www.joyfulbikeshedding.com/blog/2019-01-31-full-system-dynamic-tracing-on-linux-using-ebpf-and-bpftrace.html

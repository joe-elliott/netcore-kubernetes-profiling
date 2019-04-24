# netcore-kubernetes-profiling

This is my personal collection of notes, scripts and techniques developed to help debug live netcore applications running in Kubernetes.  I am not an expert on these subjects and attempt to credit my sources and inspirations as much as possible.  Feel free to ask questions, make corrections or even submit pull requests.

- [cpu profiling](cpu-profiling/readme.md)
- [dynamic tracing](dynamic-tracing/readme.md)

Generally these scripts are designed to be run on the Kubernetes node outside of the container as root.  The developers I support have latitude to build containers mostly how they would like and the container environment is unreliable.

## todo

- cpu profile
  - add sample app example
- dynamic tracing
   - figure out strings.  muck with offset?
   - documentation cleanup
   - improve call stacks
     - https://github.com/dotnet/ILMerge
   - create script to pull perf maps, place them in /tmp and display all traceable methods with their native image offset
- separate lttng events from cpu profiling
- core dumps
- bcc/bpf

## to read

- https://jvns.ca/blog/2017/07/05/linux-tracing-systems/
- http://man7.org/linux/man-pages/man1/perf-probe.1.html
- https://linux.die.net/man/1/perf-probe
- https://www.kernel.org/doc/Documentation/trace/kprobetrace.txt
- http://www.brendangregg.com/blog/2018-10-08/dtrace-for-linux-2018.html
- http://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html

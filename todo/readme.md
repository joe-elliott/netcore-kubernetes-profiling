## todo

- Review external links
  - Sasha Goldstein's work is all 404ing?
- add animated console thing
- include info on the main page about natively profiling
- dynamic tracing
   - improve call stacks
     - https://github.com/dotnet/ILMerge
     - Perf can't use perf maps for dlls?  bcc can?
       - http://blogs.microsoft.co.il/sasha/2017/02/27/profiling-a-net-core-application-on-linux/
     - review mapgen.py.  make sure we can get stack traces
   - bcc/bpf
      - improve and consolidate scripts to dump params/rets
      - add sample app example
      - flesh out instructions on installing and show examples
- core dumps
- test these examples on other linux distros and kernel versions
- build sidecars for other netcore versions 

## to read

- https://jvns.ca/blog/2017/07/05/linux-tracing-systems/
- http://man7.org/linux/man-pages/man1/perf-probe.1.html
- https://linux.die.net/man/1/perf-probe
- https://www.kernel.org/doc/Documentation/trace/kprobetrace.txt
- http://www.brendangregg.com/blog/2018-10-08/dtrace-for-linux-2018.html
- http://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html
- https://www.joyfulbikeshedding.com/blog/2019-01-31-full-system-dynamic-tracing-on-linux-using-ebpf-and-bpftrace.html

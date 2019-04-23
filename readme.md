# netcore-kubernetes-profiling

This is my personal collection of notes, scripts and techniques developed to help debug live netcore applications running in Kubernetes.  I am not an expert on these subjects and attempt to credit my sources and inspirations as much as possible.  Feel free to ask questions, make corrections or even submit pull requests.

- [cpu profiling](cpu-profiling/readme.md)
- [dynamic tracing](dynamic-tracing/readme.md)

Generally these scripts are designed to be run on the Kubernetes node outside of the container as root.  The developers I support have latitude to build containers mostly how they would like and the container environment is unreliable.

## todo

- dynamic tracing
  - document getting retvals
     perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1920%return ret=$retval'
     perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1900%return ret=$retval'
       'myfunc%return +0($retval):string
   - Get params?
     perf probe -x /app-profile/sample-netcore-app.ni.exe --add '0x1920 pos=%rdi'
   - figure out strings.  muck with offset?
- separate lttng events from cpu profiling
- core dumps
- bcc/bpf
- give step by step instructions with the sample app

## to read

https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention?view=vs-2017
https://jvns.ca/blog/2017/07/05/linux-tracing-systems/
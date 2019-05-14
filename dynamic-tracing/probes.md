# probes

### Run Application

Create the [dynamic-tracing.yaml](./dynamic-tracing.yaml) Kubernetes specs in your cluster and ssh to the appropriate node.  This will run a simple web service in your cluster:  https://github.com/number101010/sample-netcore-app.

Copy map and files from the `/tmp` directory in the container to the root.  Use [mapgen.py](./mapgen.py) to merge the native image perf map with the standard perf map.  Adapted from: https://gist.github.com/goldshtn/fe3f7c3b10ec7e5511ae755abaf52172.  At this point I mostly think that mapgen doesn't work.  There is a lot of work still to be done on building good stack traces in perf while dynamic tracing.

### Simple uprobes

- Use [calc-offsets.py](./calc-offsets.py) to see method offsets for use in probing
```
# python calc-offsets.py 31012 sample-netcore-app.ni.exe
...
offset: 1920 : instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValue(int32)
...
```

### Examples
After calculating the appropriate offset dynamic tracing can be accomplished with a number of tools.  

- [perf](./perf/readme.md)
- [bcc](./bcc/readme.md)

In all cases we will be dumping registers in order to inspect method parameters.  See System V AMD64 ABI in https://en.wikipedia.org/wiki/X86_calling_conventions.  

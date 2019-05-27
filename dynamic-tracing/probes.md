# probes

This document shows step by step examples on using both perf and bcc to dynamically trace [this application](https://github.com/joe-elliott/sample-netcore-app) in your cluster with [the sidecar](https://hub.docker.com/r/joeelliott/netcore-debugging-tools) generated from this repo.

#### Run Application

Create [dynamic-tracing.yaml](./dynamic-tracing.yaml) Kubernetes specs in your cluster.   Exec into the sidecar and run `./setup.sh`.  The tools we are using are very tightly coupled with the kernel version you want to debug.  Because of this we can't install all of the tools we need directly in the container.  They must be installed once the container is running and the kernel version is known.  `./setup.sh` will attempt to install the rest.  If you are having issues refer to the notes on [kernel interactions](../kernel-interactions) with the container.

```
kubectl exec -it -c profile-sidecar sample-netcore-app bash
# ./setup.sh
```

~Use [mapgen.py](./mapgen.py) to merge the native image perf map with the standard perf map.  Adapted from this [script](https://gist.github.com/goldshtn/fe3f7c3b10ec7e5511ae755abaf52172).~  At this point I mostly think that mapgen doesn't work.  There is a lot of work still [to be done](../todo) on building good stack traces in perf while dynamic tracing.

#### Dump offsets

Use [calc-offsets.py](../images/calc-offsets.py) to see method offsets for use in probing.  Record these offsets for both the perf and bcc guides below.

```
root@sample-netcore-app:~# python calc-offsets.py 112 sample-netcore-app.ni.exe
offset: 17e0 : void [sample-netcore-app] sample_netcore_app.Program::Main(string[])
offset: 1820 : class [Microsoft.AspNetCore.Hosting.Abstractions]Microsoft.AspNetCore.Hosting.IWebHostBuilder [sample-netcore-app] sample_netcore_app.Program::CreateWebHostBuilder(string[])
offset: 1840 : instance void [sample-netcore-app] sample_netcore_app.Program::.ctor()
offset: 1850 : instance void [sample-netcore-app] sample_netcore_app.Startup::.ctor(class [Microsoft.Extensions.Configuration.Abstractions]Microsoft.Extensions.Configuration.IConfiguration)
offset: 1870 : instance class [Microsoft.Extensions.Configuration.Abstractions]Microsoft.Extensions.Configuration.IConfiguration [sample-netcore-app] sample_netcore_app.Startup::get_Configuration()
offset: 1880 : instance void [sample-netcore-app] sample_netcore_app.Startup::ConfigureServices(class [Microsoft.Extensions.DependencyInjection.Abstractions]Microsoft.Extensions.DependencyInjection.IServiceCollection)
offset: 18d0 : instance void [sample-netcore-app] sample_netcore_app.Startup::Configure(class [Microsoft.AspNetCore.Http.Abstractions]Microsoft.AspNetCore.Builder.IApplicationBuilder,class [Microsoft.AspNetCore.Hosting.Abstractions]Microsoft.AspNetCore.Hosting.IHostingEnvironment)
offset: 18f0 : instance void [sample-netcore-app] sample_netcore_app.Providers.EchoProvider::.ctor()
offset: 1900 : instance string [sample-netcore-app] sample_netcore_app.Providers.EchoProvider::calculateEchoValue(string)
offset: 1910 : instance void [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::.ctor()
offset: 1920 : instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValue(int32)
offset: 1950 : instance int32 [sample-netcore-app] sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValueRecursive(int32,int32,int32,int32)
offset: 1980 : instance void [sample-netcore-app] sample_netcore_app.Controllers.EchoController::.ctor(class sample_netcore_app.Providers.IEchoProvider)
offset: 19c0 : instance class [Microsoft.AspNetCore.Mvc.Core]Microsoft.AspNetCore.Mvc.ActionResult`1<string> [sample-netcore-app] sample_netcore_app.Controllers.EchoController::Get(string)
offset: 1a00 : instance void [sample-netcore-app] sample_netcore_app.Controllers.FibonacciController::.ctor(class sample_netcore_app.Providers.IFibonacciProvider)
offset: 1a40 : instance class [Microsoft.AspNetCore.Mvc.Core]Microsoft.AspNetCore.Mvc.ActionResult`1<int32> [sample-netcore-app] sample_netcore_app.Controllers.FibonacciController::Get(int32)
```

## Examples
After calculating the appropriate offset dynamic tracing can be accomplished with a number of tools.  

- [perf](./perf)
- [bcc](./bcc)

In both cases we will be dumping registers in order to inspect method parameters.  See System V AMD64 ABI in https://en.wikipedia.org/wiki/X86_calling_conventions.  

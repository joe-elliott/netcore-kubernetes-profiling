# Coredumps in Alpine

This guide is meant to complement the [generating](./generating.md) and [analyzing](./analyzing.md) guides already available.  These instructions are specific to Alpine and have been tested using [coredumps.alpine.yaml](./coredumps.alpine.yaml)

Unfortunately the `createdump` utility is broken in Alpine containers.  See the below thread for details.  Due to this bug we will be forced to generate a full coredump.

https://github.com/dotnet/coreclr/issues/24599

## Alpine coredumps

Using the .NET Core pid run `createdump` in full mode.  Note how large these dumps are.  If you are running against using .NET Core 3.0+ then you should be able to use `dotnet dump` itself to generate the dump.

```
# /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/createdump --full 7
Writing full dump to file /tmp/coredump.7
Written 11171069952 bytes (2727312 pages) to core file

# ls -al /tmp
...
-rw-r--r--    1 root     root     11171229696 Jun 23 12:25 coredump.7
```

Use `dotnet dump` to analyze.  See the [official documentation](https://github.com/dotnet/diagnostics/blob/master/documentation/dotnet-dump-instructions.md) for help.

Below you will see some examples of some instructions run against  dump taken from the [sample app](https://github.com/joe-elliott/sample-netcore-app).

```
/ # dotnet dump analyze /tmp/coredump.7

> clrstack
OS Thread Id: 0x7 (0)
        Child SP               IP Call Site
00007FFF276AE3C0 00007f38c66463ad [GCFrame: 00007fff276ae3c0]
00007FFF276AE4A0 00007f38c66463ad [HelperMethodFrame_1OBJ: 00007fff276ae4a0] System.Threading.Monitor.ObjWait(Boolean, Int32, System.Object)
00007FFF276AE5D0 00007F384C0CD4A2 System.Threading.ManualResetEventSlim.Wait(Int32, System.Threading.CancellationToken)
00007FFF276AE660 00007F384C0989E9 System.Threading.Tasks.Task.SpinThenBlockingWait(Int32, System.Threading.CancellationToken) [/root/coreclr/src/mscorlib/src/System/Threading/Tasks/Task.cs @ 2959]
00007FFF276AE6C0 00007F384C098879 System.Threading.Tasks.Task.InternalWaitCore(Int32, System.Threading.CancellationToken) [/root/coreclr/src/mscorlib/src/System/Threading/Tasks/Task.cs @ 2898]
00007FFF276AE720 00007F384C0B96B6 System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(System.Threading.Tasks.Task) [/root/coreclr/src/mscorlib/src/System/Runtime/CompilerServices/TaskAwaiter.cs @ 146]
00007FFF276AE740 00007F384C765527 Microsoft.AspNetCore.Hosting.WebHostExtensions.Run(Microsoft.AspNetCore.Hosting.IWebHost) [/_/src/Microsoft.AspNetCore.Hosting/WebHostExtensions.cs @ 66]
00007FFF276AE760 00007F384C5B1B6E sample_netcore_app.Program.Main(System.String[])
00007FFF276AEA48 00007f38c575cfcf [GCFrame: 00007fff276aea48]
00007FFF276AEF10 00007f38c575cfcf [GCFrame: 00007fff276aef10]

> clrthreads
ThreadCount:      10
UnstartedThread:  0
BackgroundThread: 7
PendingThread:    0
DeadThread:       2
Hosted Runtime:   no
                                                                                                        Lock
 DBG   ID OSID ThreadOBJ           State GC Mode     GC Alloc Context                  Domain           Count Apt Exception
   0    1    7 000055F9D46F0D20  2020020 Preemptive  00007F362BDD6E28:00007F362BDD7FD0 000055F9D46D1F60 0     Ukn
   8    2   15 000055F9D4865C60    21220 Preemptive  0000000000000000:0000000000000000 000055F9D46D1F60 0     Ukn (Finalizer)
   9    3   16 000055F9D487A580  1020220 Preemptive  0000000000000000:0000000000000000 000055F9D46D1F60 0     Ukn (Threadpool Worker)
  10    4   17 000055F9D48EA400    21220 Preemptive  00007F372B8ED1D8:00007F372B8EDFD0 000055F9D46D1F60 0     Ukn
XXXX    5    0 000055F9D48F3760  1031820 Preemptive  0000000000000000:0000000000000000 000055F9D46D1F60 0     Ukn (Threadpool Worker)
  11    6   1a 000055F9D48F67E0  1021220 Preemptive  00007F372B903EE0:00007F372B903FD0 000055F9D46D1F60 0     Ukn (Threadpool Worker)
  12    7   1b 000055F9D49A7C00  2021220 Preemptive  00007F362BC76408:00007F362BC77FD0 000055F9D46D1F60 0     Ukn
XXXX    8    0 000055F9D4A99FE0  1031820 Preemptive  0000000000000000:0000000000000000 000055F9D46D1F60 0     Ukn (Threadpool Worker)
  14    9   1e 000055F9D4A9BC80    21220 Preemptive  00007F362BDD80D0:00007F362BDD9FD0 000055F9D46D1F60 0     Ukn
  15   10   87 000055F9D48F5E40  1021220 Preemptive  00007F362BDDCDC0:00007F362BDDDFD0 000055F9D46D1F60 0     Ukn (Threadpool Worker)

> dumpheap -type FibonacciProvider
         Address               MT     Size
00007f372b950038 00007f384e086cd0       24

Statistics:
              MT    Count    TotalSize Class Name
00007f384e086cd0        1           24 sample_netcore_app.Providers.FibonacciProvider

> gcroot 00007f372b950038

Thread 7:
    00007FFF276AE660 00007F384C0989E9 System.Threading.Tasks.Task.SpinThenBlockingWait(Int32, System.Threading.CancellationToken) [/root/coreclr/src/mscorlib/src/System/Threading/Tasks/Task.cs @ 2959]
        rbp-38: 00007fff276ae678
            ->  00007F362BDD6D58 System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1+AsyncStateMachineBox`1[[System.Threading.Tasks.VoidTaskResult, System.Private.CoreLib],[Microsoft.AspNetCore.Hosting.WebHostExtensions+<RunAsync>d__4, Microsoft.AspNetCore.Hosting]]
            ->  00007F362B961BA8 Microsoft.AspNetCore.Hosting.Internal.WebHost
            ->  00007F362B95FD60 Microsoft.Extensions.DependencyInjection.ServiceCollection
            ->  00007F362B95FD78 System.Collections.Generic.List`1[[Microsoft.Extensions.DependencyInjection.ServiceDescriptor, Microsoft.Extensions.DependencyInjection.Abstractions]]
            ->  00007F362BC28DC0 Microsoft.Extensions.DependencyInjection.ServiceDescriptor[]
            ->  00007F362B93FF38 Microsoft.Extensions.DependencyInjection.ServiceDescriptor
            ->  00007F362B93CA30 Microsoft.AspNetCore.Hosting.WebHostBuilderContext
            ->  00007F362B948C70 Microsoft.Extensions.Configuration.ConfigurationRoot
            ->  00007F362B948C90 Microsoft.Extensions.Configuration.ConfigurationReloadToken
            ->  00007F362B948CA8 System.Threading.CancellationTokenSource
            ->  00007F362BC3AFB8 System.Threading.CancellationTokenSource+CallbackPartition[]
            ->  00007F362BC3AFE0 System.Threading.CancellationTokenSource+CallbackPartition
            ->  00007F362BDCA070 System.Threading.CancellationTokenSource+CallbackNode
            ->  00007F362BDCA030 System.Action`1[[System.Object, System.Private.CoreLib]]
            ->  00007F362BDCA008 Microsoft.Extensions.Primitives.ChangeToken+<>c__DisplayClass1_0`1[[System.String, System.Private.CoreLib]]
            ->  00007F362BDC9FC8 System.Action`1[[System.String, System.Private.CoreLib]]
            ->  00007F362BDC9F20 Microsoft.Extensions.Options.OptionsMonitor`1[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering]]
            ->  00007F362BDCA4F8 System.Action`2[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering],[System.String, System.Private.CoreLib]]
            ->  00007F362BDCA4D8 Microsoft.Extensions.Options.OptionsMonitor`1+ChangeTrackerDisposable[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering]]
            ->  00007F362BDCA498 System.Action`2[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering],[System.String, System.Private.CoreLib]]
            ->  00007F362BDCA480 Microsoft.Extensions.Options.OptionsMonitorExtensions+<>c__DisplayClass0_0`1[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering]]
            ->  00007F362BDCA440 System.Action`1[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering]]
            ->  00007F362BDCA110 Microsoft.AspNetCore.HostFiltering.HostFilteringMiddleware
            ->  00007F362BDC6588 Microsoft.AspNetCore.Http.RequestDelegate
            ->  00007F362BDC6550 Microsoft.AspNetCore.Routing.EndpointRoutingMiddleware
            ->  00007F362BDC38D8 Microsoft.AspNetCore.Routing.Matching.DfaMatcherFactory
            ->  00007F362BC29F10 Microsoft.Extensions.DependencyInjection.ServiceLookup.ServiceProviderEngineScope
            ->  00007F362BC3FB10 System.Collections.Generic.List`1[[System.IDisposable, System.Private.CoreLib]]
            ->  00007F362BC4F670 System.IDisposable[]
            ->  00007F362BC4DF88 Microsoft.AspNetCore.Server.Kestrel.Core.KestrelServer
            ->  00007F362BC4F168 System.Collections.Generic.List`1[[Microsoft.AspNetCore.Server.Kestrel.Transport.Abstractions.Internal.ITransport, Microsoft.AspNetCore.Server.Kestrel.Transport.Abstractions]]
            ->  00007F362BDD46A8 Microsoft.AspNetCore.Server.Kestrel.Transport.Abstractions.Internal.ITransport[]
            ->  00007F362BDD3738 Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.SocketTransport
            ->  00007F362BDD3080 Microsoft.AspNetCore.Server.Kestrel.Core.AnyIPListenOptions
            ->  00007F362BDD32D0 System.Collections.Generic.List`1[[System.Func`2[[Microsoft.AspNetCore.Connections.ConnectionDelegate, Microsoft.AspNetCore.Connections.Abstractions],[Microsoft.AspNetCore.Connections.ConnectionDelegate, Microsoft.AspNetCore.Connections.Abstractions]], System.Private.CoreLib]]
            ->  00007F362BDD3648 System.Func`2[[Microsoft.AspNetCore.Connections.ConnectionDelegate, Microsoft.AspNetCore.Connections.Abstractions],[Microsoft.AspNetCore.Connections.ConnectionDelegate, Microsoft.AspNetCore.Connections.Abstractions]][]
            ->  00007F362BDD3608 System.Func`2[[Microsoft.AspNetCore.Connections.ConnectionDelegate, Microsoft.AspNetCore.Connections.Abstractions],[Microsoft.AspNetCore.Connections.ConnectionDelegate, Microsoft.AspNetCore.Connections.Abstractions]]
            ->  00007F362BDD35C0 Microsoft.AspNetCore.Server.Kestrel.Core.Internal.HttpConnectionBuilderExtensions+<>c__DisplayClass1_0`1[[Microsoft.AspNetCore.Hosting.Internal.HostingApplication+Context, Microsoft.AspNetCore.Hosting]]
            ->  00007F362BDD35D8 Microsoft.AspNetCore.Server.Kestrel.Core.Internal.HttpConnectionMiddleware`1[[Microsoft.AspNetCore.Hosting.Internal.HostingApplication+Context, Microsoft.AspNetCore.Hosting]]
            ->  00007F362BDCE760 Microsoft.AspNetCore.Hosting.Internal.HostingApplication
            ->  00007F362BDCB2D8 Microsoft.AspNetCore.Http.RequestDelegate
            ->  00007F362BDCB2B8 Microsoft.AspNetCore.Hosting.Internal.RequestServicesContainerMiddleware
            ->  00007F362BC29E80 Microsoft.Extensions.DependencyInjection.ServiceLookup.DynamicServiceProviderEngine
            ->  00007F362BC32010 System.Collections.Concurrent.ConcurrentDictionary`2[[System.Type, System.Private.CoreLib],[System.Func`2[[Microsoft.Extensions.DependencyInjection.ServiceLookup.ServiceProviderEngineScope, Microsoft.Extensions.DependencyInjection],[System.Object, System.Private.CoreLib]], System.Private.CoreLib]]
            ->  00007F362BDBEDB0 System.Collections.Concurrent.ConcurrentDictionary`2+Tables[[System.Type, System.Private.CoreLib],[System.Func`2[[Microsoft.Extensions.DependencyInjection.ServiceLookup.ServiceProviderEngineScope, Microsoft.Extensions.DependencyInjection],[System.Object, System.Private.CoreLib]], System.Private.CoreLib]]
            ->  00007F362BDBE5B8 System.Collections.Concurrent.ConcurrentDictionary`2+Node[[System.Type, System.Private.CoreLib],[System.Func`2[[Microsoft.Extensions.DependencyInjection.ServiceLookup.ServiceProviderEngineScope, Microsoft.Extensions.DependencyInjection],[System.Object, System.Private.CoreLib]], System.Private.CoreLib]][]
            ->  00007F372B950008 System.Collections.Concurrent.ConcurrentDictionary`2+Node[[System.Type, System.Private.CoreLib],[System.Func`2[[Microsoft.Extensions.DependencyInjection.ServiceLookup.ServiceProviderEngineScope, Microsoft.Extensions.DependencyInjection],[System.Object, System.Private.CoreLib]], System.Private.CoreLib]]
            ->  00007F372B9822D8 System.Func`2[[Microsoft.Extensions.DependencyInjection.ServiceLookup.ServiceProviderEngineScope, Microsoft.Extensions.DependencyInjection],[System.Object, System.Private.CoreLib]]
            ->  00007F372B9822C0 Microsoft.Extensions.DependencyInjection.ServiceLookup.ExpressionResolverBuilder+<>c__DisplayClass17_1
            ->  00007F372B950038 sample_netcore_app.Providers.FibonacciProvider
```
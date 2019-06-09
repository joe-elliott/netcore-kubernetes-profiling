# Analyzing Core Dumps

This guide will cover the basics of loading a netcore core dump in lldb and analyzing it.  It presumes you've followed [this guide](./generating.md).  The below commands are all run in the sidecar from the previous guide after a dump has been generated.


## Loading the Dump
If you follow [the previous guide](./generating.md) then you have a core dump in your `/tmp` directory generated one way or another.

```
# ls /tmp/coredump*
/tmp/coredump.6
# lldb /usr/bin/dotnet --core /tmp/coredump.6
```

After you are in lldb, load the sos plugin and point it at the CLR.  The sos plugin provides a set of commands that allow you to analyze the state of the managed application.  The rest of the guide will use commands enabled by this plugin.  Note that the location of libsosplugin.so and the CLR are framework version dependent.

```
(lldb) plugin load /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5/libsosplugin.so
(lldb) setclrpath /usr/share/dotnet/shared/Microsoft.NETCore.App/2.2.5
```

#### Getting help
The sos plugin provides some basic help by running the `soshelp` command.  Help is always a good place to start.  After you have run `soshelp` and reviewed the available commands see below for some basic guides on performing other tasks.

#### Finding a Thrown Exception
An unhandled exception is a common way for a application to unexpectedly crash.  In our case we forced the application to crash by calling [Environment.FailFast()](https://github.com/joe-elliott/sample-netcore-app/blob/master/Controllers/FailController.cs#L15).  Let's discover the exception that was thrown and inspect the call stack.

First, let's just check out all of our CLR threads.

```
(lldb) sos Threads
ThreadCount:      9
UnstartedThread:  0
BackgroundThread: 8
PendingThread:    0
DeadThread:       0
Hosted Runtime:   no
                                                                                                        Lock  
       ID OSID ThreadOBJ           State GC Mode     GC Alloc Context                  Domain           Count Apt Exception
   1    1    6 0000000002715340  2020020 Preemptive  0000000000000000:0000000000000000 00000000026C6FD0 0     Ukn 
   9    2   1a 00000000027BC340    21220 Preemptive  0000000000000000:0000000000000000 00000000026C6FD0 0     Ukn (Finalizer) 
  10    3   1b 00007FC6F00009F0  1020220 Preemptive  0000000000000000:0000000000000000 00000000026C6FD0 0     Ukn (Threadpool Worker) 
  11    4   1c 0000000002856A80    21220 Preemptive  0000000000000000:0000000000000000 00000000026C6FD0 0     Ukn 
  12    7   20 00000000028BC3D0  2021220 Preemptive  0000000000000000:0000000000000000 00000000026C6FD0 0     Ukn 
  14    9   23 00007FC6E4009B30    21220 Preemptive  00007FC7083BEE50:00007FC7083C0140 00000000026C6FD0 0     Ukn 
  15   12   e3 00007FC6D400E050  1021220 Preemptive  00007FC8085D0748:00007FC8085D1520 00000000026C6FD0 0     Ukn (Threadpool Worker) System.ExecutionEngineException 00007fc7081a71e0
  16   13   e4 00007FC6D400F230  1021220 Preemptive  00007FC8085D7730:00007FC8085D9520 00000000026C6FD0 0     Ukn (Threadpool Worker) 
  17   16   e7 00007FC6D4011840  1021220 Preemptive  00007FC70843C5B0:00007FC70843E140 00000000026C6FD0 0     Ukn (Threadpool Worker) 
```

Note that thread 15 has an unhandled exception.  Let's switch to that thread and view the exception in detail.

```
(lldb) thread select 15
* thread #15, stop reason = signal SIGABRT
    frame #0: 0x00007fc9a378db5a libpthread.so.0`__new_sem_wait_slow + 106
libpthread.so.0`__new_sem_wait_slow:
->  0x7fc9a378db5a <+106>: cmpq   $-0x1000, %rax            ; imm = 0xF000 
    0x7fc9a378db60 <+112>: ja     0x7fc9a378db7b            ; <+139>
    0x7fc9a378db62 <+114>: movl   %r8d, %edi
    0x7fc9a378db65 <+117>: movl   %eax, 0xc(%rsp)
(lldb) sos PrintException
Exception object: 00007fc7081a71e0
Exception type:   System.ExecutionEngineException
Message:          <none>
InnerException:   <none>
StackTrace (generated):
<none>
StackTraceString: <none>
HResult: 80131506
```

Finally, view the current callstack on the thread.  This should give us information about where the exception was called from.  In this case it clearly calls out the exception was called from `FailController::Get` as expected.

```
(lldb) sos ClrStack
OS Thread Id: 0xe3 (15)
        Child SP               IP Call Site
00007FC98A919548 00007fc9a378db5a [GCFrame: 00007fc98a919548] 
00007FC98A919628 00007fc9a378db5a [HelperMethodFrame_2OBJ: 00007fc98a919628] System.Environment.FailFast(System.String, System.Exception)
00007FC98A919760 00007FC92EB305EF sample_netcore_app.Controllers.FailController.Get()
00007FC98A919780 00007FC92C921C0D SOS Warning: Loading symbols for dynamic assemblies is not yet supported
DynamicClass.lambda_method
00007FC98A919790 00007FC929CE3C93 /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll!Unknown
00007FC98A9197A0 00007FC929CF1483 /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll!Unknown
00007FC98A9197F0 00007FC929CF31C2 /usr/share/dotnet/shared/Microsoft.AspNetCore.App/2.2.5/Microsoft.AspNetCore.Mvc.Core.dll!Unknown
...
```

#### Inspecting Objects on the Heap
Another common task is to inspect the heap to diagnose a memory leak.  Here are some basic commands to inspect objects on the heap. 

First, let's find an object we are interested in and dump some basic information.
```
(lldb) sos DumpHeap -type FibonacciProvider
         Address               MT     Size
00007fc808277940 00007fc92a956cd0       24     

Statistics:
              MT    Count    TotalSize Class Name
00007fc92a956cd0        1           24 sample_netcore_app.Providers.FibonacciProvider
Total 1 objects
```

```
(lldb) sos DumpObj 00007fc808277940
Name:        sample_netcore_app.Providers.FibonacciProvider
MethodTable: 00007fc92a956cd0
EEClass:     00007fc92a962db8
Size:        24(0x18) bytes
File:        /app/sample-netcore-app.dll
Fields:
None
```

```
(lldb) sos DumpMT -md 00007fc92a956cd0
EEClass:         00007FC92A962DB8
Module:          00007FC9281F43C8
Name:            sample_netcore_app.Providers.FibonacciProvider
mdToken:         0000000002000005
File:            /app/sample-netcore-app.dll
BaseSize:        0x18
ComponentSize:   0x0
Slots in VTable: 7
Number of IFaces in IFaceMap: 1
--------------------------------------
MethodDesc Table
           Entry       MethodDesc    JIT Name
00007FC9288979A0 00007FC9284352F0 PreJIT System.Object.ToString()
00007FC9288979C0 00007FC9284352F8 PreJIT System.Object.Equals(System.Object)
00007FC928897A10 00007FC928435320 PreJIT System.Object.GetHashCode()
00007FC928897A20 00007FC928435340 PreJIT System.Object.Finalize()
00007FC92EB28CC0 00007FC92A956CB8    JIT sample_netcore_app.Providers.FibonacciProvider.calculateFibonacciValue(Int32)
00007FC92EB28CA0 00007FC92A956CB0    JIT sample_netcore_app.Providers.FibonacciProvider..ctor()
00007FC92EB28D00 00007FC92A956CC0    JIT sample_netcore_app.Providers.FibonacciProvider.calculateFibonacciValueRecursive(Int32, Int32, Int32, Int32)
```

You can even dump the IL code if you're so inclined.

```
(lldb) sos DumpIL 00007FC92A956CC0
ilAddr = 00007FC9A3BF02D3
IL_0000: ldarg.3 
IL_0001: ldarg.s VAR OR ARG 4
IL_0003: bgt.s IL_0015
IL_0005: ldarg.0 
IL_0006: ldarg.2 
IL_0007: ldarg.1 
IL_0008: ldarg.2 
IL_0009: add 
IL_000a: ldarg.3 
IL_000b: ldc.i4.1 
IL_000c: add 
IL_000d: ldarg.s VAR OR ARG 4
IL_000f: call sample_netcore_app.Providers.FibonacciProvider::calculateFibonacciValueRecursive
IL_0014: ret 
IL_0015: ldarg.2 
IL_0016: ret 
```

However, the most likely thing you're looking for is a path to a GCRoot.  This will give you information about why the object is still in memory which will help you diagnose memory leaks.  At this point I am unsure why some of the object names are `<error>` and how to correct this.

```
(lldb) sos GCRoot -all -nostacks 00007fc808277940
HandleTable:
    00007FC9A3DA1140 (strong handle)
    -> 00007FC7081F2B48 System.Object[]
    -> 00007FC7081E6B20 System.Threading.Tasks.Task
    ...
    -> 00007FC80825EBA0 System.Action`1[[System.String, System.Private.CoreLib]]
    -> 00007FC80825EB18 <error>
    -> 00007FC80825EF18 System.Action`2[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering],[System.String, System.Private.CoreLib]]
    -> 00007FC80825EEF8 <error>
    -> 00007FC80825EEB8 System.Action`2[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering],[System.String, System.Private.CoreLib]]
    -> 00007FC80825EEA0 <error>
    -> 00007FC80825EE60 System.Action`1[[Microsoft.AspNetCore.HostFiltering.HostFilteringOptions, Microsoft.AspNetCore.HostFiltering]]
    -> 00007FC80825ECB0 Microsoft.AspNetCore.HostFiltering.HostFilteringMiddleware
    ...
    -> 00007FC808277940 sample_netcore_app.Providers.FibonacciProvider
```
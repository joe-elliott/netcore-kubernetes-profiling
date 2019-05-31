# bcc

This document shows step by step examples on using bcc to dynamically trace [this application](https://github.com/joe-elliott/sample-netcore-app) in your cluster with [the sidecar](https://hub.docker.com/r/joeelliott/netcore-debugging-tools) generated from this repo.

See [probes](../probes.md) for more information on setup.  After you have followed the steps there come back to learn how to use bcc.

#### netcore-bcc-trace.py

bcc is mostly amazing.  It allows for bpf programs to be run when dynamic tracepoints are hit.  [netcore-bcc-trace.py](../../images/netcore-bcc-trace.py) is a utility I built to easily trace parameter and return values of functions.

Tracing `calculateFibonacciValue`:
```
root@sample-netcore-app:~# python netcore-bcc-trace.py /app-profile/sample-netcore-app.ni.exe 0x1920 int
          dotnet-3438  [001] .... 903863.831439: : val 10
          dotnet-3438  [000] .... 903895.395103: : val 20
          dotnet-3740  [001] .... 903899.770254: : val 30
```

[netcore-bcc-trace.py](../../images/netcore-bcc-trace.py) dynamically prints out the values passed into the traced method as it is being called.  In the above example the application was curled passing in the three values shown.

Tracing `calculateEchoValue`:
```
root@sample-netcore-app:~# python netcore-bcc-trace.py /app-profile/sample-netcore-app.ni.exe 0x1900 str
          dotnet-5408  [001] .... 904117.897441: : len 11 : hello world
```
In this example the echo endpoint was called passing in "hello world".

It should be noted that the string tracing does some hacky things to extract a string parameter value and display it as it's being traced.  I'm just ditching the first byte of every character and displaying the second.  I don't actually know what netcore's internal character encoding is and this just happens to work if all of your characters are 8-bit ASCII.

#### trace-hist.py
[trace-hist.py](../../images/trace-hist.py)
This basic example traces `calculateFibonacciValue` and draws a histogram of the values that were passed to this function.  Eventually I intend on rolling histogram functionality into the above script.

Because bcc uses bpf to attach arbitrary code to dynamic tracepoints it can do so much more than the above!  See some examples here: https://github.com/iovisor/bcc/tree/master/examples.

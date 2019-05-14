# bcc

The following perf examples are being generated using a sample application.  See [probes](../probes.md) for more information.

bcc is mostly amazing.  It allows for bpf programs to be run when dynamic tracepoints are hit.  See below for some pything examples.

[trace-hist.py](./trace-hist.py)
Basic histogram example tracing `calculateFibonacciValue`.

[trace-int.py](./trace-int.py)
Basic example dumping an integer parameter.  Tracing `calculateFibonacciValue`.

[trace-string.py](./trace-string.py)
Basic example dumping a netcore string parameter.  Tracing `calculateEchoValue`.  This example does some hacky things to extract a string parameter value and display it as it's being traced.

Note that I'm just ditching the first byte of every character and displaying the second.  I don't actually know what netcore's internal character encoding is and this just happens to work if all of your characters are 8-bit ASCII.
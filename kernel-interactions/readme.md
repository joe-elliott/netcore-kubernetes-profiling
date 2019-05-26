# kernel-interactions

When you run [setup.sh](../images/setup.sh) it pulls tools to help with the various debugging methods.  Often these tools are compiled and packaged for a single kernel version.  Unfortunately, the debian repos that the runtime containers are pointed at can be missing packages for the kernel you happen to be running on.  At least kernel versions 4.19 and 4.9 appear to work out of the box.

This document contains information about how to get the debug tooling working on kernels that do not immediately work.  Some of these techniques may be dangerous or provide inconsistent results.

## Kernel 4.15

A [setup script](../images/setup.4.15.sh) has been provided for 4.15.  Note that it uses a snapshot of the unstable repo from 2018 to find 4.15 tooling and linux headers.

```
echo deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20180222 sid main contrib >> /etc/apt/sources.list
```

Using this technique everything except bcc will work.
#! /bin/sh

#
# Sometimes after running this you'll still get errors like:
#
#    /usr/bin/perf: line 13: exec: perf_4.15: not found
#    E: linux-perf-4.15 is not installed.
#
# This is because the version of perf installed does not match the kernel version reported by
#  `uname -r`.  See /usr/bin/perf for more info.  In the past I have had success finding the version
#  of perf I do have installed and doing horribleness like:
#
#    ln -s /usr/bin/perf_4.19 /usr/bin/perf_4.15
#
#  I have gotten this to work.  I have also seen this cause perf to segfault.  I imagine you're rolling the 
#  dice if you force perf to run against a kernel it was not compiled for.
#
./perfcollect install

#
# this might not work depending on the host operating system, kernel version, and packages
#   available to the container.  if it doesn't work another option to host mount /lib/modules and install
#   headers on the host OS
#
apt-get install linux-headers-`uname -r`


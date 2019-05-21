#! /bin/sh

#
# certain tools need to be installed after the container is running so that they are the appropriate
#   packages for the host kernel
#

./perfcollect.sh install

#
# this might not work depending on the host operating system, kernel version, and packages
#   available to the container.  if it doesn't work another option to host mount /lib/modules and install
#   headers on the host OS
#
apt-get install linux-headers-`uname -r`
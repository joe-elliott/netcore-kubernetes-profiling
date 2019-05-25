#! /bin/sh
apt-get update

./perfcollect install
apt-get install -y linux-headers-`uname -r`


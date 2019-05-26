#! /bin/sh

echo deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20180222 sid main contrib >> /etc/apt/sources.list

apt-get update

./perfcollect install

apt-get install -y --allow-downgrades \
                linux-headers-4.15 \
                linux-perf=4.15+90


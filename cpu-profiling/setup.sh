#
# ./setup.sh <pid>
#    given a pid sets up the host for profiling it
#

pid=$1

cp /proc/$1/root/tmp/perf-1.map /tmp/perf-$pid.map
cp /proc/$1/root/tmp/perfinfo-1.map /tmp/perfinfo-$pid.map

# better test for perf tools installed?
echo -- Checking For perfcollect
if [ ! -f ./perfcollect ]; then
   echo -- Installing perfcollect

   curl -OL https://aka.ms/perfcollect
   chmod +x perfcollect
   ./perfcollect install
fi

echo -- Checking for FlameGraph
if [ ! -d ./FlameGraph ]; then
   echo -- Installing FlameGraph

   git clone --depth=1 https://github.com/BrendanGregg/FlameGraph
fi

#
# if you need libcoreclr.so and other runtime symbols the below will need to be investigated
#
#   install dotnet runtime symbols? https://github.com/dotnet/coreclr/blob/master/Documentation/project-docs/linux-performance-tracing.md#getting-symbols-for-the-native-runtime
#

#netcore_dir=./netcoretmp
#ASPNETCORE_VERSION=$(cat /proc/$pid/environ | tr \\0 \\n | grep ASPNETCORE_VERSION | cut -d'=' -f2)

#echo -- Checking for netcore version $ASPNETCORE_VERSION
#if [ ! -d $netcore_dir/shared/Microsoft.NETCore.App/$ASPNETCORE_VERSION ]; then
#  echo -- Installing netcore version $ASPNETCORE_VERSION

#  wget https://dotnetcli.blob.core.windows.net/dotnet/aspnetcore/Runtime/$ASPNETCORE_VERSION/aspnetcore-runtime-$ASPNETCORE_VERSION-linux-x64.tar.gz
#  mv aspnetcore-runtime-$ASPNETCORE_VERSION-linux-x64.tar.gz  aspnetcore.tar.gz
#  mkdir -p $netcore_dir
#  tar -zxf aspnetcore.tar.gz -C $netcore_dir
#  rm aspnetcore.tar.gz
#fi
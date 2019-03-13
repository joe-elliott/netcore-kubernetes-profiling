#! /bin/sh
#
# genNative.sh <app dll> <sdk version>
#    ./genNative /app/app.dll
#

APP_DLL=$1
APP_DIR=$(dirname "$APP_DLL")
DOTNET_VERSION=$(dotnet --info | grep Version | cut -f2 -d":" | xargs)
DOTNET_FRAMEWORK_PATH=/usr/share/dotnet/shared/Microsoft.NETCore.App/$DOTNET_VERSION
#todo:  dynamically generate this with dotnet --list-runtimes
ADDITIONAL_PATHS=/usr/share/dotnet/shared/Microsoft.AspNetCore.All/$DOTNET_VERSION:/usr/share/dotnet/shared/Microsoft.AspNetCore.App/$DOTNET_VERSION

# using the shell name to guess the runtime id.  can't find a better way to do this
#  bash => linux-x64
#   ash => linux-musl-x64
if [ -f /bin/bash ]; then
  RUNTIME_ID=linux-x64
else
  RUNTIME_ID=linux-musl-x64
fi

# get dotnet sdk
echo -- Grabbing netcore sdk $DOTNET_VERSION for runtime $RUNTIME_ID

# alpine containers have wget.  standard have curl
if which curl; then
  curl -L -o runtime.zip https://www.nuget.org/api/v2/package/runtime.$RUNTIME_ID.Microsoft.NETCore.App/$DOTNET_VERSION
elif which wget; then
  wget -O runtime.zip https://www.nuget.org/api/v2/package/runtime.$RUNTIME_ID.Microsoft.NETCore.App/$DOTNET_VERSION
else
  echo "Unable to pull runtime"
  exit 1
fi

# install unzip if necessary
#  alpine containers have unzip.  others don't.  use apt-get to bring it in.
which unzip || { apt-get update && apt-get install unzip -y; }

mkdir -p ./runtime
unzip runtime.zip -d ./runtime
cp ./runtime/tools/crossgen .
chmod 744 ./crossgen
rm -rf ./runtime

# find libjitclr.so
if [ -f $APP_DIR/libcrljit.so ]; then
  JIT_PATH=$APP_DIR/libcrljit.so
elif [ -f $DOTNET_FRAMEWORK_PATH/libclrjit.so ]; then
  JIT_PATH=$DOTNET_FRAMEWORK_PATH/libclrjit.so
else
  # look in other places?  use find?
  echo "Unable to find libclrjit.so"
  exit 1
fi

# generate native image and perf map
APP_NATIVE_IMAGE=${APP_DLL%.*}.ni.exe
./crossgen /JITPath $JIT_PATH \
           /Platform_Assemblies_Paths $DOTNET_FRAMEWORK_PATH:$APP_DIR:$ADDITIONAL_PATHS \
           $APP_DLL
./crossgen /Platform_Assemblies_Paths $DOTNET_FRAMEWORK_PATH:$APP_DIR:$ADDITIONAL_PATHS \
           /CreatePerfMap /tmp \
           $APP_NATIVE_IMAGE

# run native image
dotnet $APP_NATIVE_IMAGE
#! /bin/sh
#
# genNative.sh <app dll> <sdk version>
#    ./genNative /app/app.dll
#

APP_DLL=$1
APP_DIR=$(dirname "$APP_DLL")
DOTNET_VERSION=$(dotnet --info | grep Version | cut -f2 -d":" | xargs)
DOTNET_FRAMEWORK_PATH=/usr/share/dotnet/shared/Microsoft.NETCore.App/$DOTNET_VERSION
# todo: choose runtime version based on env
RUNTIME_ID=linux-musl-x64  # or linux-x64

# get dotnet sdk
echo -- Grabbing netcore sdk $DOTNET_VERSION

# todo: support curl
wget -O runtime.zip https://www.nuget.org/api/v2/package/runtime.$RUNTIME_ID.Microsoft.NETCore.App/$DOTNET_VERSION

# todo: some containers don't have unzip
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
APP_NATIVE_IMAGE=$APP_DLL.ni.dll
./crossgen /JITPath $JIT_PATH /Platform_Assemblies_Paths $DOTNET_FRAMEWORK_PATH:$APP_DIR /out $APP_NATIVE_IMAGE $APP_DLL
./crossgen /Platform_Assemblies_Paths $DOTNET_FRAMEWORK_PATH:$APP_DIR /CreatePerfMap /tmp $APP_NATIVE_IMAGE

# run native image
dotnet $APP_NATIVE_IMAGE
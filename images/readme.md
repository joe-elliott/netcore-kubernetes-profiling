# images

A collection of Dockerfiles to build sidecar containers from which to profile a netcore application.  These images will contain tooling necessary to profile using all the techniques discussed in this repo.

Currently these images are only 2.2.5 which purposefully matches the runtime builds for the sample application: https://github.com/joe-elliott/sample-netcore-app.  With additional work this could be extended to cover other netcore versions.

#### ./Dockerfile.alpine

The alpine image lacks bcc and lttng so any examples using those tools will not work.
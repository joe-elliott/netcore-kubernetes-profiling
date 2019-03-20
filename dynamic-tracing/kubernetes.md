# dynamic-tracing-kubernetes

WIP

### Adjust deployment
- To generate perfmap:

  ```
  env:
  - name: COMPlus_PerfMapEnabled
    value: "1"
  ```
- The startup script will take awhile to pull and run crossgen.  Add a long delay to your liveness probe so k8s doesn't kill your pods.

  ```
  livenessProbe:
    initialDelaySeconds: 600
  ```
- Adjust the command to run [runNative.sh](./runNative.sh) instead of the actual app.  [runNative.sh](./runNative.sh) will generate a native image of the app dll and then run the native image.

   ```
   command: ["/run-native/runNative.sh"]
   args: ["/app/app.dll"]
   ```
- Mount [runNative.sh](./runNative.sh) as a configmap.

  ```
  - mountPath: /run-native
    name: run-native-volume
  ...
  - configMap:
      defaultMode: 0740
      name: run-native
    name: run-native-volume
  ```
- Mount `/app-profile` on the host.  [runNative.sh](./runNative.sh) will copy the entire app over to this folder after generating native images.  This allows for dynamic probing from the host.

  ``` 
  - mountPath: /app-profile
    name: host-app
  ...
  - hostPath:
      path: /app-profile
      type: DirectoryOrCreate
    name: host-app
  ```
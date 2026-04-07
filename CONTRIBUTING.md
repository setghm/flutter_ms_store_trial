## Development notes

> [!NOTE]
> I recommend always build the plugin using either the Developer Command Prompt or Developer Powershell
> to avoid any issue.

> [!NOTE]
> After updating the CMakeLists.txt file, re-run `flutter build windows`.
> A Visual Studio restart will be needed too if you have the IDE opened.

### Commands

To generate the Pigeon sources:

```shell
dart run pigeon --input=pigeons/ms_store_api.dart
```

To build and test the example:

```powershell
cd example

dart run msix:build # Just build, don't pack, we need the manifest

cd build\windows\x64\runner\Debug

Add-AppxPackage -Register AppxManifest.xml
```

### Debugging the MSIX package

Open Visual Studio, go to **_Debug_ > _Other Debug Targets_ > _Debug Installed App Package..._**

Wait until packages are loaded if you have a slow computer.

In code type select **Native only**.

Click on Run.

The **Output** window will show the native logs printed with the `OutputDebugString` function.

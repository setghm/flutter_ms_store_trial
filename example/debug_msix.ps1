# Debug configuration to test MSIX package

dart run msix:build

if ($?) {
    pushd .
    cd build\windows\x64\runner\Debug

    Add-AppxPackage -Register AppxManifest.xml

    popd
}

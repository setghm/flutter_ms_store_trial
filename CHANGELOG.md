## 1.0.2
  
- Decrease Dart SDK to 3.9.0 to ensure better compatibility.
- Add screenshots

## 1.0.1

- Added a note about unpacked MSIX apps receiving an activated full version
  license by default, with an empty `skuStoreId`, and how to filter these out.

## 1.0.0

Provide an API to integrate a trial of a Flutter app on Windows using Microsoft Store.

Main features:

* Restore the user license
* Listen to license updates through a stream
* Request the license purchase from the app
* Get the package family name of the app

import 'dart:async';
import 'dart:convert';

import 'src/ms_store_api.g.dart';

part 'src/ms_store_trial.implementation.dart';

part 'src/ms_store_trial.models.dart';

/// Access Microsoft Store API on Windows.
abstract class MsStoreTrial {
  static final _instance = _PluginImplementation();

  /// Use the plugin through this field.
  static MsStoreTrial get instance => _instance;

  /// Delivers changes on the current app license.
  ///
  /// You should subscribe this stream before you call `restoreLicense()`.
  ///
  /// Note: unpacked MSIX apps will receive an activated full version license
  /// by default, with an empty [skuStoreId]. In production, you may want to
  /// filter these out:
  ///
  /// ```dart
  /// MsStoreTrial.instance.licenseStream
  ///   .where((license) => license.skuStoreId.isNotEmpty)
  ///   .listen((license) {
  ///     // Update your app state or UI
  ///   });
  /// ```
  ///
  /// For a more exhaustive check, you can also compare [skuStoreId] against
  /// your known app store product ID.
  ///
  /// The [skuStoreId] has the format: <product Store ID>/<SKU Store ID>
  ///
  /// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storesku.storeid
  Stream<MsStoreAppLicense> get licenseStream;

  /// Returns the Microsoft Store product information associated with this app.
  Future<MsStoreProductResponse> getProduct();

  /// Shows the Microsoft Store purchase dialog to the user.
  ///
  /// If the product purchase is successful, you'll receive an event in
  /// `licenseStream` with the new license details.
  Future<MsStorePurchaseResponse> requestPurchase();

  /// Restore the app product license.
  ///
  /// You might want call this method every time your app starts before the UI is loaded.
  ///
  /// Results will be sent through `licenseStream`.
  Future<void> restoreLicense();

  /// Returns the package family name of the current Windows app.
  ///
  /// If the app is not properly packed as an MSIX file,
  /// an empty string will be returned.
  Future<String> getPackageFamilyName();
}

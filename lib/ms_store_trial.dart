import 'dart:async';

import 'ms_store_api.g.dart';

export 'ms_store_api.g.dart'
    show
        MsStoreProduct,
        MsStoreProductResponse,
        MsStorePurchaseStatus,
        MsStorePurchaseResponse,
        MsStoreAppLicense;

/// Access Microsoft Store API on Windows.
abstract class MsStoreTrial {
  static final _instance = _PluginImplementation();

  /// Use the plugin through this field.
  static MsStoreTrial get instance => _instance;

  /// Delivers changes on the current app license.
  ///
  /// You should subscribe this stream before you call `restoreLicense()`.
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
}

class _PluginImplementation implements MsStoreTrial, MsStoreFlutterApi {
  _PluginImplementation() {
    MsStoreFlutterApi.setUp(this);
  }

  final _api = MsStoreHostApi();
  final _licenseStream = StreamController<MsStoreAppLicense>.broadcast();

  @override
  Stream<MsStoreAppLicense> get licenseStream => _licenseStream.stream;

  @override
  Future<MsStoreProductResponse> getProduct() =>
      _api.getStoreProductForCurrentApp();

  @override
  Future<MsStorePurchaseResponse> requestPurchase() =>
      _api.requestCurrentAppPurchase();

  @override
  Future<void> restoreLicense() => _api.restoreCurrentAppLicense();

  @override
  void onLicenseChanged(MsStoreAppLicense license) =>
      _licenseStream.add(license);
}

extension MsStoreAppLicenseExtension on MsStoreAppLicense {
  /// Returns true if you configured your app's trial version as time-limited.
  /// If the full version has already been purchased false will be returned.
  bool get isTimeLimited => expirationTimestamp != 0 && trialTimeRemaining != 0;

  /// The expiration date of the trial version of your app.
  /// If the full version has already been purchased a DateTime(0) object will be returned.
  DateTime get expirationDate =>
      DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);

  /// Trial time remaining duration.
  /// If the full version has alrady been purchased a Duration.zero object will be returned.
  Duration get trialTimeRemainingDuration =>
      Duration(milliseconds: trialTimeRemaining);
}

extension MsStoreProductResponseExtension on MsStoreProductResponse {
  /// Check if the app is an
  /// [associated store product](https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials#testing).
  ///
  /// You should check this value as a not associated app will always receive a non-trial, activated license.
  ///
  /// In order to correctly associate your app with a Microsoft Store Product
  /// you need to pack it as MSIX and it deploy in your system.
  ///
  bool get isStoreAssociated => extendedError.toUnsigned(32) != 0x803F6107;
}

extension MsStoreProductExtension on MsStoreProduct {
  /// Returns true if the product is free or has a price of 0.
  bool get isFree => price.isEmpty;
}

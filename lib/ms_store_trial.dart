import 'dart:async';

import 'ms_store_api.g.dart';

export 'ms_store_api.g.dart' show
    MsStoreProduct,
    MsStoreProductResponse,
    MsStorePurchaseStatus,
    MsStorePurchaseResponse,
    MsStoreLicense;

abstract class MsStoreTrial {
  static final _instance = _PluginImplementation();
  static MsStoreTrial get instance => _instance;

  /// Updates on this app license.
  Stream<MsStoreLicense> get licenseStream;

  /// Returns the Microsoft Store product associated with this app.
  Future<MsStoreProductResponse> getProduct();

  /// Requests the purchase of this product through Microsoft Store.
  Future<MsStorePurchaseResponse> requestPurchase();

  /// Restore the product license.
  ///
  /// Results will be sent through licenseStream.
  Future<void> restoreLicense();
}

class _PluginImplementation implements MsStoreTrial, MsStoreFlutterApi {
  _PluginImplementation() {
    MsStoreFlutterApi.setUp(this);
  }

  final _api = MsStoreHostApi();
  final _licenseStream = StreamController<MsStoreLicense>.broadcast();

  @override
  Stream<MsStoreLicense> get licenseStream => _licenseStream.stream;

  @override
  Future<MsStoreProductResponse> getProduct() => _api.getStoreProductForCurrentApp();

  @override
  Future<MsStorePurchaseResponse> requestPurchase() => _api.requestCurrentAppPurchase();

  @override
  Future<void> restoreLicense() => _api.restoreCurrentAppLicense();

  @override
  void onLicenseChanged(MsStoreLicense license) => _licenseStream.add(license);
}

extension MsStoreLicenseTime on MsStoreLicense {
  bool get isTimeLimited => expirationTimestamp != 0 && trialTimeRemaining != 0;

  DateTime get expirationDate => DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);

  Duration get trialTimeRemainingDuration => Duration(milliseconds: trialTimeRemaining);
}

extension MsStoreProductChecking on MsStoreProductResponse {
  /// Check if the app has an associated store product.
  ///
  /// https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials#testing
  bool get isStoreAssociated => extendedError.toUnsigned(32) != 0x803F6107;
}

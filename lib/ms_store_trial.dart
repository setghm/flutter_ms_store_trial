import 'dart:async';

import 'ms_store_api.g.dart';

export 'ms_store_api.g.dart' show
    MsStoreProduct,
    MsStoreProductResponse,
    MsStorePurchaseStatus,
    MsStorePurchaseResponse,
    MsStoreLicense;

class MsStoreTrial implements MsStoreFlutterApi {
  static final _instance = MsStoreTrial._();
  static MsStoreTrial get instance => _instance;

  MsStoreTrial._() {
    MsStoreFlutterApi.setUp(this);
  }

  final _api = MsStoreHostApi();
  final _licenseStream = StreamController<MsStoreLicense>.broadcast();

  Stream<MsStoreLicense> get licenseStream => _licenseStream.stream;

  Future<MsStoreProductResponse> getProduct() => _api.getStoreProductForCurrentApp();

  Future<MsStorePurchaseResponse> requestPurchase() => _api.requestCurrentAppPurchase();

  Future<void> restoreLicense() => _api.restoreCurrentAppLicense();

  @override
  void onLicenseChanged(MsStoreLicense license) => _licenseStream.add(license);
}

extension MsStoreLicenseExpiration on MsStoreLicense {
  DateTime? get expirationDate => expirationTimestamp != null
    ? DateTime.fromMillisecondsSinceEpoch(expirationTimestamp!)
    : null;
}

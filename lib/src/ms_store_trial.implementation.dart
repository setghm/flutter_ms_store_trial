part of '../ms_store_trial.dart';

class _PluginImplementation implements MsStoreTrial, MsStoreFlutterApi {
  _PluginImplementation() {
    MsStoreFlutterApi.setUp(this);
  }

  final _api = MsStoreHostApi();
  final _licenseStream = StreamController<MsStoreAppLicense>.broadcast();

  @override
  Stream<MsStoreAppLicense> get licenseStream => _licenseStream.stream;

  @override
  Future<MsStoreProductResponse> getProduct() async {
    final struct = await _api.getStoreProductForCurrentApp();
    return MsStoreProductResponse._fromStruct(struct);
  }

  @override
  Future<MsStorePurchaseResponse> requestPurchase() async {
    final struct = await _api.requestCurrentAppPurchase();
    return MsStorePurchaseResponse._fromStruct(struct);
  }

  @override
  Future<void> restoreLicense() => _api.restoreCurrentAppLicense();

  @override
  Future<String> getPackageFamilyName() => _api.getPackageFamilyName();

  @override
  void onLicenseChanged(AppLicenseStruct struct) {
    final license = MsStoreAppLicense._fromStruct(struct);
    _licenseStream.add(license);
  }
}

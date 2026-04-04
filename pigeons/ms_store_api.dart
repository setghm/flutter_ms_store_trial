import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/ms_store_api.g.dart',
    cppHeaderOut: 'windows/ms_store_api.g.h',
    cppSourceOut: 'windows/ms_store_api.g.cpp',
    cppOptions: CppOptions(namespace: 'ms_store_trial'),
  )
)

@HostApi()
abstract class MsStoreHostApi {
  @async
  MsStoreProductResponse getStoreProductForCurrentApp();

  @async
  MsStorePurchaseResponse requestCurrentAppPurchase();

  void restoreCurrentAppLicense();
}

@FlutterApi()
abstract class MsStoreFlutterApi {
  void onLicenseChanged(MsStoreLicense license);
}

class MsStoreLicense {
  final bool isActive;
  final bool isTrial;
  final bool isTrialOwnedByThisUser;
  final int? expirationTimestamp;

  const MsStoreLicense({
    required this.isActive,
    required this.isTrial,
    required this.isTrialOwnedByThisUser,
    required this.expirationTimestamp,
  });
}

class MsStoreProduct {
  final String storeId;
  final String description;
  final String price;

  const MsStoreProduct({
    required this.storeId,
    required this.description,
    required this.price,
  });
}

class MsStoreProductResponse {
  final MsStoreProduct? product;
  final int extendedError;

  const MsStoreProductResponse({
    required this.product,
    required this.extendedError,
  });
}

enum MsStorePurchaseStatus {
  succeed,
  alreadyPurchased,
  notPurchased,
  networkError,
  serverError,
}

class MsStorePurchaseResponse {
  final MsStorePurchaseStatus status;
  final int extendedError;

  const MsStorePurchaseResponse({
    required this.status,
    required this.extendedError,
  });
}

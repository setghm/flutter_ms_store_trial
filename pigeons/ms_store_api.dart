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

/// Provides license info for the current app.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeapplicense
class MsStoreLicense {
  final bool isActive;
  final bool isTrial;
  final bool isTrialOwnedByThisUser;
  final int trialTimeRemaining;
  final int expirationTimestamp;
  final String skuStoreId;
  final String extendedJsonData;
  final String trialUniqueId;

  const MsStoreLicense({
    required this.isActive,
    required this.isTrial,
    required this.isTrialOwnedByThisUser,
    required this.expirationTimestamp,
    required this.trialTimeRemaining,
    required this.skuStoreId,
    required this.extendedJsonData,
    required this.trialUniqueId,
  });
}

/// Represents a product that is available in the Microsoft Store.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeproduct
class MsStoreProduct {
  final String storeId;
  final String title;
  final String description;
  final String price;
  final String priceCurrencyCode;
  final String formattedPrice;
  final String productKind;
  final String extendedJsonData;

  const MsStoreProduct({
    required this.storeId,
    required this.title,
    required this.description,
    required this.price,
    required this.priceCurrencyCode,
    required this.formattedPrice,
    required this.productKind,
    required this.extendedJsonData,
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

/// Defines values that represent the status of a request to purchase an app or add-on.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storepurchasestatus
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

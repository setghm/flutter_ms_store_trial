import 'package:pigeon/pigeon.dart';

// NOTE: declare nested classes before using them.

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/ms_store_api.g.dart',
    cppHeaderOut: 'windows/ms_store_api.g.h',
    cppSourceOut: 'windows/ms_store_api.g.cpp',
    cppOptions: CppOptions(namespace: 'ms_store_trial'),
  ),
)

@HostApi()
abstract class MsStoreHostApi {
  @async
  String getPackageFamilyName();

  @async
  ProductResponseStruct getStoreProductForCurrentApp();

  @async
  PurchaseResponseStruct requestCurrentAppPurchase();

  void restoreCurrentAppLicense();
}

@FlutterApi()
abstract class MsStoreFlutterApi {
  void onLicenseChanged(AppLicenseStruct license);
}

class AppLicenseStruct {
  bool? isActive;
  bool? isTrial;
  bool? isTrialOwnedByThisUser;
  int? trialTimeRemaining;
  int? expirationTimestamp;
  String? skuStoreId;
  String? trialUniqueId;
  String? extendedJsonData;
}

class ProductPriceStruct {
  String? formattedPrice;
  String? currencyCode;
  String? unformattedPrice;
}

class ProductStruct {
  String? storeId;
  String? title;
  String? description;
  String? productKind;
  ProductPriceStruct? price;
  String? extendedJsonData;
}

class ProductResponseStruct {
  ProductStruct? product;
  int? extendededError;
}

class PurchaseResponseStruct {
  int? status;
  int? extendedError;
}

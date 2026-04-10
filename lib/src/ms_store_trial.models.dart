part of '../ms_store_trial.dart';

/// Provides license info for the current app.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeapplicense
class MsStoreAppLicense {
  /// Indicates whether the license is valid and provides
  /// the current user an entitlement to use the app.
  final bool isActive;

  /// Indicates whether the license is a trial license.
  final bool isTrial;

  /// Indicates whether the current user has an entitlement for the usage-limited
  /// trial that is associated with this app license.
  final bool isTrialOwnedByThisUser;

  /// The remaining time for the usage-limited trial that is associated
  /// with this app license.
  ///
  /// When the value of this field has not been defined it will default to zero.
  /// You can use the `hasTrialPeriod` getter.
  final Duration trialTimeRemaining;

  /// The expiration date and time for the app license.
  ///
  /// When the value of this field has not been defined it will default to zero.
  /// You can use the `hasExpirationDate` getter.
  final DateTime expirationDate;

  /// The Store ID of the licensed app SKU from the Microsoft Store catalog.
  final String skuStoreId;

  /// A unique ID that identifies the combination of the current user
  /// and the usage-limited trial that is associated with this app license.
  final String trialUniqueId;

  /// Complete license data in JSON format.
  final String extendedJsonData;

  const MsStoreAppLicense({
    required this.isActive,
    required this.isTrial,
    required this.isTrialOwnedByThisUser,
    required this.expirationDate,
    required this.trialTimeRemaining,
    required this.skuStoreId,
    required this.trialUniqueId,
    required this.extendedJsonData,
  });

  factory MsStoreAppLicense._fromStruct(AppLicenseStruct struct) =>
    MsStoreAppLicense(
      isActive: struct.isActive!,
      isTrial: struct.isTrial!,
      isTrialOwnedByThisUser: struct.isTrialOwnedByThisUser!,
      trialTimeRemaining: Duration(microseconds: struct.trialTimeRemaining!),
      expirationDate: DateTime.fromMicrosecondsSinceEpoch(struct.expirationTimestamp!),
      skuStoreId: struct.skuStoreId!,
      trialUniqueId: struct.trialUniqueId!,
      extendedJsonData: struct.extendedJsonData!,
    );

  /// Parses the extendedJsonData field and returns the result.
  Map<String, dynamic> get extendedJson => jsonDecode(extendedJsonData);

  /// Indicates whether the full version is purchased and active.
  bool get isFullVersionActive => !isTrial && isActive;

  /// Indicates whether the trial version is currently active (not expired).
  bool get isTrialVersionActive => isTrial && isActive;

  /// Indicates whether the trial period has expired.
  bool get isTrialVersionExpired => isTrial && !isActive;

  /// Indicates whether the product was configured to offer a trial period time
  /// instead of an unlimited trial.
  bool get hasTrialPeriod => trialTimeRemaining != Duration.zero;

  /// Indicates whether the product has a valid expiration date.
  bool get hasExpirationDate => expirationDate.microsecondsSinceEpoch != 0;

  @override
  String toString() {
    return 'MsStoreAppLicense{'
    'isActive: $isActive, '
    'isTrial: $isTrial, '
    'isTrialOwnedByThisUser: $isTrialOwnedByThisUser, '
    'trialTimeRemaining: $trialTimeRemaining, '
    'expirationDate: $expirationDate, '
    'skuStoreId: "$skuStoreId", '
    'trialUniqueId: "$trialUniqueId", '
    'extendedJsonData: $extendedJsonData '
    '}';
  }
}

/// Represents a product that is available in the Microsoft Store.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeproduct
class MsStoreProduct {
  /// The Store ID for this product.
  final String storeId;

  /// The product title from the Microsoft Store listing.
  final String title;

  /// The product description from the Microsoft Store listing.
  final String description;

  /// The type of the product.
  ///
  /// According to Microsoft documentation, these are the currently supported values:
  /// - Application
  /// - Game
  /// - Consumable
  /// - UnmanagedConsumable
  /// - Durable
  ///
  /// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeproduct.productkind#windows-services-store-storeproduct-productkind
  final String productKind;

  /// The price for the default SKU and availability for the product.
  final MsStoreProductPrice? price;

  // Complete data for the product from the Store in JSON format.
  final String extendedJsonData;

  const MsStoreProduct({
    required this.storeId,
    required this.title,
    required this.description,
    required this.productKind,
    required this.price,
    required this.extendedJsonData,
  });

  factory MsStoreProduct._fromStruct(ProductStruct struct) =>
    MsStoreProduct(
      storeId: struct.storeId!,
      title: struct.title!,
      description: struct.description!,
      price: struct.price != null
        ? MsStoreProductPrice._fromStruct(struct.price!)
        : null,
      productKind: struct.productKind!,
      extendedJsonData: struct.extendedJsonData!,
    );

  /// Returns true if the product has an established price.
  bool get hasPrice => price != null && !(price!.isEmpty);

  /// Parses the extendedJsonData field and returns the result.
  Map<String, dynamic> get extendedJson => jsonDecode(extendedJsonData);

  @override
  String toString() {
    return 'MsStoreProduct{'
    'storeId: "$storeId", '
    'title: "$title", '
    'description: "$description", '
    'productKind: "$productKind", '
    'price: $price, '
    'extendedJsonData: $extendedJsonData'
    '}';
  }
}

/// Contains pricing info for a product listing in the Microsoft Store.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeprice
class MsStoreProductPrice {
  /// The ISO 4217 currency code for the market of the current user.
  ///
  /// https://en.wikipedia.org/wiki/ISO_4217#List_of_ISO_4217_currency_codes
  final String currencyCode;

  /// The base price for the product with the appropriate formatting
  /// for the market of the current user.
  final String formattedPrice;

  /// The base price for the product without any formatting.
  final String unformattedPrice;

  const MsStoreProductPrice({
    required this.currencyCode,
    required this.formattedPrice,
    required this.unformattedPrice,
  });

  factory MsStoreProductPrice._fromStruct(ProductPriceStruct struct) =>
    MsStoreProductPrice(
      currencyCode: struct.currencyCode ?? '',
      formattedPrice: struct.formattedPrice ?? '',
      unformattedPrice: struct.unformattedPrice ?? '',
    );

  /// Indicates whether all fields are empty strings or not.
  bool get isEmpty =>
    currencyCode.isEmpty && formattedPrice.isEmpty && unformattedPrice.isEmpty;

  @override
  String toString() {
    return 'MsStoreProductPrice{'
    'currencyCode: "$currencyCode", '
    'formattedPrice: "$formattedPrice", '
    'unformattedPrice: "$unformattedPrice"'
    '}';
  }
}

/// Provides response data for a request to retrieve details about the current app
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storeproductresult
class MsStoreProductResponse {
  /// Info about the current app.
  final MsStoreProduct? product;

  /// The error code for the request, if the operation encountered an error.
  final int extendedError;

  const MsStoreProductResponse({
    required this.product,
    required this.extendedError,
  });

  factory MsStoreProductResponse._fromStruct(ProductResponseStruct struct) =>
    MsStoreProductResponse(
      product: struct.product != null
        ? MsStoreProduct._fromStruct(struct.product!)
        : null,
      extendedError: struct.extendededError!,
    );

  /// True if the product info is present, false otherwise.
  ///
  /// When false, check the extendedError value.
  bool get hasProduct => product != null;

  /// True if the operation encountered an error.
  bool get hasError => extendedError != 0;

  /// True if the returned error is related to a store association error
  /// indicating that there's a configuration issue with the packaging.
  ///
  /// https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials#testing
  bool get hasStoreAssociationError => extendedError.toUnsigned(32) == 0x803F6107;

  @override
  String toString() {
    return 'MsStoreProductResponse{'
    'product: $product, '
    'extendedError: $extendedError'
    '}';
  }
}

/// Defines values that represent the status of a request to purchase an app or add-on.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storepurchasestatus
enum MsStorePurchaseStatus {
  /// The purchase request succeeded.
  succeed,

  /// The current user has already purchased the specified app or add-on.
  alreadyPurchased,

  /// The purchase request did not succeed.
  notPurchased,

  /// The purchase request did not succeed because of a network
  /// connectivity error.
  networkError,

  /// The purchase request did not succeed because of a server error
  /// returned by the Microsoft Store.
  serverError,
}

/// Provides response data for a request to purchase an app or product
/// that is offered by the app.
///
/// https://learn.microsoft.com/en-us/uwp/api/windows.services.store.storepurchaseresult
class MsStorePurchaseResponse {
  /// The status of the purchase request.
  final MsStorePurchaseStatus status;

  /// The error code for the purchase request, if the operation encountered an error.
  final int extendedError;

  const MsStorePurchaseResponse({
    required this.status,
    required this.extendedError,
  });

  factory MsStorePurchaseResponse._fromStruct(PurchaseResponseStruct struct) =>
    MsStorePurchaseResponse(
      status: MsStorePurchaseStatus.values[struct.status!],
      extendedError: struct.extendedError!,
    );

  @override
  String toString() {
    return 'MsStorePurchaseResponse{'
    'status: $status, '
    'extendedError: $extendedError'
    '}';
  }
}

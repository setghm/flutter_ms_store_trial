import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ms_store_trial/ms_store_trial.dart';

/// This apps helps to test all the related functionalities in one place.
///
/// Great for debugging and testing new features of the plugin.
class DevelopmentApp extends StatefulWidget {
  const DevelopmentApp({super.key});

  @override
  State<DevelopmentApp> createState() => _DevelopmentAppState();
}

class _DevelopmentAppState extends State<DevelopmentApp> {
  MsStoreProductResponse? _productResponse;
  MsStorePurchaseResponse? _purchaseResponse;
  MsStoreAppLicense? _license;
  String? _packageFamilyName;

  late final StreamSubscription<MsStoreAppLicense> _licenseUpdates;

  final _logsController = TextEditingController(text: '');
  final _extendedLicenseJsonController = TextEditingController(text: '');
  final _extendedProductJsonController = TextEditingController(text: '');
  final _logsScrollController = ScrollController();
  final _jsonEncoder = const JsonEncoder.withIndent('  ');

  bool get _isValidProduct => _productResponse?.product != null;

  bool get _isFullVersion => _license != null ? !(_license!.isTrial) : false;

  @override
  void initState() {
    super.initState();

    MsStoreTrial.instance.getProduct().then((value) {
      _productResponse = value;

      if (mounted) {
        if (_productResponse!.product == null) {
          _log('Unable to retrieve the store product for the current app');
        } else {
          _log('Got product response: $_productResponse');

          _extendedProductJsonController.text =
            _jsonEncoder.convert(_productResponse!.product!.extendedJson);
        }

        setState(() {
          // Update
        });
      }
    });

    _licenseUpdates = MsStoreTrial.instance.licenseStream.listen((event) {
      _license = event;

      if (mounted) {
        _log('License update received: $_license');

        _extendedLicenseJsonController.text =
          _jsonEncoder.convert(_license!.extendedJson);

        setState(() {
          // Update
        });
      }
    });

    MsStoreTrial.instance.getPackageFamilyName().then((value) {
      _packageFamilyName = value;
      if (mounted) {
        setState(() {
          // Update
        });
      }
    });

    MsStoreTrial.instance.restoreLicense();
  }

  @override
  void dispose() {
    _logsController.dispose();
    _extendedLicenseJsonController.dispose();
    _extendedProductJsonController.dispose();
    _logsScrollController.dispose();
    _licenseUpdates.cancel();
    super.dispose();
  }

  void _purchase() async {
    _log('Requesting purchase...');

    _purchaseResponse = await MsStoreTrial.instance.requestPurchase();

    if (mounted) {
      _log('Purchase response received: $_purchaseResponse');
      setState(() {
        // Update
      });
    }
  }

  void _log(String text) {
    debugPrint(text);

    _logsController.text += '$text\n';

    if (_logsScrollController.hasClients) {
      _logsScrollController.animateTo(
        _logsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Microsoft Store trial example')),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            spacing: 10,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 5,
                                children: [
                                  Text(
                                    'Product information',
                                    style: TextTheme.of(context).titleLarge
                                  ),
                                  Divider(),

                                  if (_productResponse != null) ...[
                                    _buildProductInfo(context),
                                    const Divider(height: 5),
                                  ],

                                  if (_packageFamilyName != null)
                                    _buildPackagingStatus(context),
                                ],
                              ),
                            ),
                            Card(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 5,
                                children: [
                                  Text(
                                    'License information',
                                    style: TextTheme.of(context).titleLarge
                                  ),
                                  Divider(),

                                  if (_isValidProduct && _license != null) ...[
                                    _buildLicenseInfo(context),
                                    const Divider(height: 5),
                                  ],

                                  _buildBuyButton(context),

                                  if (_purchaseResponse != null) ...[
                                    const Divider(height: 5),
                                    _buildPurchaseInfo(context),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Text('Extended product JSON'),
                            Divider(height: 5),
                            Expanded(
                              child: TextField(
                                controller: _extendedProductJsonController,
                                maxLines: null,
                                minLines: null,
                                expands: true,
                                readOnly: true,
                                keyboardType: TextInputType.multiline,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Text('Extended license JSON'),
                            Divider(height: 5),
                            Expanded(
                              child: TextField(
                                controller: _extendedLicenseJsonController,
                                maxLines: null,
                                minLines: null,
                                expands: true,
                                readOnly: true,
                                keyboardType: TextInputType.multiline,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Card(
                  child: Column(
                    children: [
                      Text('Logs'),
                      Divider(height: 5),
                      Expanded(
                        child: TextField(
                          controller: _logsController,
                          scrollController: _logsScrollController,
                          maxLines: null,
                          minLines: null,
                          expands: true,
                          readOnly: true,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    if (_productResponse!.product != null) {
      final isPaid = _productResponse!.product!.hasPrice;
      final formattedPrice = _productResponse!.product!.price?.formattedPrice;
      final currencyCode = _productResponse!.product!.price?.currencyCode;

      return Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('StoreId: ${_productResponse!.product!.storeId}'),
          Text('Description: ${_productResponse!.product!.description}'),
          Text(
            isPaid
                ? 'Price: $formattedPrice $currencyCode'
                : 'App is free',
          ),
        ],
      );
    }
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          'Error: ${_formatError(_productResponse!.extendedError)}',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        _productResponse!.hasStoreAssociationError
          ? Text(
            'Not associated with a store product',
            style: const TextStyle(color: Colors.red),
          )
          : Text(
            'Microsoft Store Product',
            style: const TextStyle(color: Colors.green),
          ),
      ],
    );
  }

  Widget _buildLicenseInfo(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _license!.isTrial ? 'Trial version' : 'Full version',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          _license!.isActive ? 'Activated' : 'Not activated',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _license!.isActive ? Colors.blue : Colors.red,
          ),
        ),

        if (_license!.hasExpirationDate)
          Text('Expires on: ${_license!.trialTimeRemaining.toString()}'),

        Text('SKU store ID: ${_license!.skuStoreId}'),
        Text('Trial unique ID: ${_license!.trialUniqueId}'),
      ],
    );
  }

  Widget _buildBuyButton(BuildContext context) => OutlinedButton.icon(
    onPressed: _isValidProduct ? _purchase : null,
    icon: Icon(Icons.shopping_cart),
    label: Text(
      _isFullVersion
          ? 'Buy again'
          : _isValidProduct
          ? 'Buy full version'
          : 'Not available',
    ),
  );

  Widget _buildPurchaseInfo(BuildContext context) => Column(
    spacing: 5,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(switch (_purchaseResponse!.status) {
        .succeed => 'The purchase was successful.',
        .alreadyPurchased => 'The user has already purchased the product.',
        .notPurchased => 'The purchase did not complete.',
        .networkError =>
          'The purchase was unsuccessful due to a network error.',
        .serverError => 'The purchase was unsuccessful due to a server error.',
      }, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),

      if (_purchaseResponse!.extendedError != 0)
        SelectableText(
          'Purchase error: ${_formatError(_purchaseResponse!.extendedError)}',
        ),
    ],
  );

  Widget _buildPackagingStatus(BuildContext context) => Column(
    spacing: 5,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_packageFamilyName!.isEmpty)
        Text(
          'Not packed',
          textAlign: TextAlign.start,
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
      if (_packageFamilyName!.isNotEmpty)
        Text(
          'Package family name: $_packageFamilyName',
          textAlign: TextAlign.start,
          style: const TextStyle(color: Colors.indigo)
        ),
    ],
  );

  String _formatError(int error) {
    final number = error
        .toUnsigned(32)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');

    return '0x$number';
  }
}

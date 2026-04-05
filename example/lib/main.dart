import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ms_store_trial/ms_store_trial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MsStoreProductResponse? _productResponse;
  MsStorePurchaseResponse? _purchaseResponse;
  MsStoreLicense? _license;

  late final StreamSubscription<MsStoreLicense> _licenseUpdates;

  final _logsController = TextEditingController(text: '');
  final _extendedLicenseJsonController = TextEditingController(text: '');
  final _extendedProductJsonController = TextEditingController(text: '');
  final _logsScrollController = ScrollController();

  bool get _isValidProduct => _productResponse?.product != null;

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

          _extendedProductJsonController.text = _productResponse!.product!.extendedJsonData;
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

        _extendedLicenseJsonController.text = _license!.extendedJsonData;

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
        // Úpdate
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
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_productResponse != null)
                                _buildProductInfo(context),

                              if (_isValidProduct && _license != null)
                                _buildLicenseInfo(context),

                              _buildBuyButton(context),

                              if (_purchaseResponse != null)
                                _buildPurchaseInfo(context),
                            ],
                          ),
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
                                decoration: const InputDecoration(border: InputBorder.none),
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
                                decoration: const InputDecoration(border: InputBorder.none),
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
                          decoration: const InputDecoration(border: InputBorder.none),
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
      return Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('StoreId: ${_productResponse!.product!.storeId}'),
          Text('Description: ${_productResponse!.product!.description}'),
          Text('Price: ${_productResponse!.product!.price}'),
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
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        _productResponse!.isStoreAssociated
          ? Text(
            'Microsoft Store Product',
            style: const TextStyle(color: Colors.green)
          )
          : Text(
            'Not associated with a store product',
            style: const TextStyle(color: Colors.red)
          ),
      ],
    );
  }

  Widget _buildLicenseInfo(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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

        if (_license!.isTimeLimited)
          Text('Expires on: ${_license!.expirationDate.toString()}'),

        Text('SKU store ID: ${_license!.skuStoreId}'),
        Text('Trial unique ID: ${_license!.trialUniqueId}'),
      ],
    );
  }

  Widget _buildBuyButton(BuildContext context) {
    final isAlreadyPurchased = _license?.isTrial ?? false;

    return OutlinedButton.icon(
      onPressed: _isValidProduct ? _purchase : null,
      icon: Icon(Icons.shopping_cart),
      label: Text(isAlreadyPurchased
        ? 'Buy again'
        : _isValidProduct
        ? 'Buy full version'
        : 'Not available'
      ),
    );
  }

  Widget _buildPurchaseInfo(BuildContext context) => Column(
    spacing: 5,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        switch (_purchaseResponse!.status) {
          .succeed => 'The purchase was successful.',
          .alreadyPurchased => 'The user has already purchased the product.',
          .notPurchased => 'The purchase did not complete.',
          .networkError => 'The purchase was unsuccessful due to a network error.',
          .serverError => 'The purchase was unsuccessful due to a server error.',
        },
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),

      if (_purchaseResponse!.extendedError != 0)
        SelectableText('Purchase error: ${_formatError(_purchaseResponse!.extendedError)}'),
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

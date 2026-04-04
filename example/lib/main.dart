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

  final _logsController = TextEditingController(text: '');
  final _logsScrollController = ScrollController();

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
        }

        setState(() {
          // Update
        });
      }
    });
  }

  @override
  void dispose() {
    _logsController.dispose();
    _logsScrollController.dispose();
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
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  child: Column(
                    spacing: 10,
                    children: [
                      if (_productResponse != null)
                        _buildProductInfo(context),

                      _buildBuyButton(context),

                      if (_purchaseResponse != null)
                        _buildPurchaseInfo(context),
                    ],
                  ),
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
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: null,
                          expands: true,
                          controller: _logsController,
                          scrollController: _logsScrollController,
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

    return SelectableText('Error: ${_formatError(_productResponse!.extendedError)}');
  }

  Widget _buildBuyButton(BuildContext context) {
    final isValidProduct = _productResponse!.product != null;

    return OutlinedButton.icon(
      onPressed: isValidProduct ? _purchase : null,
      icon: Icon(Icons.shopping_cart),
      label: Text(isValidProduct ? 'Buy full version' : 'Not available'),
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

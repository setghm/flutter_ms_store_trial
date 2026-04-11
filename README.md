# ms_store_trial

Use Microsoft Store to offer a trial version of your Flutter app on Windows.

This plugin is intended to enable a **one-time purchase** of your app license.

![ms_store_trial_example](https://github.com/user-attachments/assets/467ebc8a-e5bd-4e0c-8eb7-e925c723f203)

## Instructions

Before starting make sure you have a [Microsoft Partner account](https://partner.microsoft.com/).

### Part 1. Associate your app with a Microsoft Store Product

#### Part 1.1. Create a Microsoft Store product

Open your [Microsoft Partner dashboard](https://partner.microsoft.com/dashboard), go to **Apps and
games**, click on **New product** and select **MSIX or PWA app**. Enter the name of your app and
click **Reserve product name** to create your product.

Once your product is created, complete your app submission: Pricing and availability, Properties,
Age ratings, etc. Leave the Packages section pending for now.

This doesn't need to be a public submission, so you may want to:

- Set the visibility to private.
- Add your own account to test the app.
- Configure the trial pricing and time limit.

#### Part 1.2. Configure MSIX packaging

For an easier configuration use the [msix package](https://pub.dev/packages/msix).
(Although you can use tools
like [winapp](https://learn.microsoft.com/en-us/windows/apps/dev-tools/winapp-cli/guides/flutter)
or [msstore](https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/overview) its
usage won't be covered by this guide).

Open your [Microsoft Partner dashboard](https://partner.microsoft.com/dashboard), go to **Apps and
games**, click on your app
to open the **Application overview**, once there in the side panel go to **Product Identity** under
the **Product management** section, note these values:

- Package/Identity/Name
- Package/Identity/Publisher
- Package/Properties/PublisherDisplayName

Add the [msix package](https://pub.dev/packages/msix) as a development dependency:

```shell
flutter pub add dev:msix
```

Create a configuration section in your `pubspec.yaml` file for the msix packaging:

```yaml
msix_config:
  display_name: # Your reserved app name
  identity_name: # Package/Identity/Name value
  publisher: # Package/Identity/Publisher value
  publisher_display_name: # Package/Properties/PublisherDisplayName value
  store: true
  msix_version: 1.0.0.0
  debug: true # You can change this
  icon: windows/runner/resources/app_icon.ico # You can change this
  # You can configure more settings if you need, see msix package reference:
  # https://pub.dev/packages/msix
```

Pack your app:

```shell
dart run msix:create
```

Now you can complete your app submission by attaching the `.msix` file in the Packages section.

Once your app is published you need to download it from the Microsoft Store on your development
machine and open it once, so the license can be downloaded.

### Part 2. Integrate a trial in your app

Add this plugin as a dependency:

```shell
flutter pub add ms_store_trial
```

Subscribe to license changes at app startup. The following snippet shows a general usage example:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ms_store_trial/ms_store_trial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MsStoreAppLicense? _license;
  late final StreamSubscription<MsStoreAppLicense> _licenseUpdates;

  @override
  void initState() {
    super.initState();

    // Subscribe to license updates first.
    _licenseUpdates = MsStoreTrial.instance.licenseStream.listen((event) {
      _license = event;
      if (mounted) {
        setState(() {
          // Update UI.
        });
      }
    });

    // IMPORTANT: Restore user app license.
    MsStoreTrial.instance.restoreLicense();
  }

  @override
  void dispose() {
    _licenseUpdates.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullVersion = _license?.isFullVersionActive ?? false;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: Column(
            children: [
              if (_license != null)
                Text('Is full version: $isFullVersion'),

              if (!isFullVersion)
                OutlinedButton(
                  onPressed: () async {
                    final response = await MsStoreTrial.instance.requestPurchase();
                    debugPrint(
                        'Purchase status: ${response.status}, error: ${response.extendedError}');
                    // If success, license update will be delivered through the license stream.
                  },
                  child: Text('Purchase full version'),
                ),
            ]
        ),
      ),
    );
  }
}
```

### Part 3. Testing trial integration

You can test the plugin integration in your app when you're developing it. However, running your app
normally, such as with `flutter run -d windows` won't work as it must be packed as MSIX, and it must
also be installed.

Run the package command, but this time you'll need the unpacked files:

```shell
dart run msix:build --debug
```

Now, install your app on your development Windows machine using the `Add-AppxPackage` CmdLet:

```powershell
cd build\windows\x64\runner\Debug

Add-AppxPackage -Register AppxManifest.xml
```

Once your app is installed you'll be able to test the trial integration.

Also, you can debug the installed MSIX app using Visual Studio as shown
in [this guide](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-debug).

## API summary

Listen license changes:

```dart
MsStoreTrial.instance.licenseStream.listen((license) {
  // Update your app state or UI
});
```

Restore the user's app license:

```dart
MsStoreTrial.instance.restoreLicense();
// Subscribe to licenseStream to get the results.
```

Show a special Microsoft Store window to purchase your app:

```dart
MsStorePurchaseResponse response = await MsStoreTrial.instance.requestPurchase();

// Possible statues. 
final message = switch (response.status) {
  MsStorePurchaseStatus.succeed => 'Purchase was successful',
  MsStorePurchaseStatus.alreadyPurchased => 'Already purchased',
  MsStorePurchaseStatus.notPurchased => 'Cancelled by the user',
  MsStorePurchaseStatus.networkError => 'Network error: ${response.extendedError}',
  MsStorePurchaseStatus.serverError => 'Server error: ${response.extendedError}',
};
```

Get Microsoft Store details of this app (title, product price, store ID, etc.):

```dart
MsStoreProductResponse response = await MsStoreTrial.instance.getProduct();

if (response.hasProduct) {
  // Read product info.
  debugPrint(response.product!.title);
  // ...
}
```

Get package family name, useful to check if the app was properly packed:

```dart
String name = await MsStoreTrial.instance.getPackageFamilyName();

if(name.isEmpty) {
  debugPrint('Not a valid MSIX package');
}
```

## Notes

> [!IMPORTANT]
> When releasing to Microsoft Store don't forget to pack in release mode, otherwise
> your users will get missing DLL files errors.

> [!NOTE]
> Methods to purchase your own app includes:
> - Create promo codes and redeem at https://account.microsoft.com/billing/redeem
> - Set your app price to zero, free trial will still appear if configured

> [!NOTE]
> I didn't find a method to perform a re-purchase, although you can try with multiple
> Microsoft accounts or different app submissions.

## External references

- [Implement a trial version of your app](https://learn.microsoft.com/en-us/windows/uwp/monetize/implement-a-trial-version-of-your-app)
- [Testing In-app purchases and trials](https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials#testing)
- [Enable in-app purchases of apps and add-ons](https://learn.microsoft.com/en-us/windows/uwp/monetize/enable-in-app-purchases-of-apps-and-add-ons)
- [Set pricing and availability for MSIX app](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/price-and-availability?pivots=store-installer-msix#free-trial)
- [Run, debug, and test an MSIX package](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-debug)

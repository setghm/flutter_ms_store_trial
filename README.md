# ms_store_trial

Offer a trial version of your Flutter app in Windows using the Microsoft Store API.

## Instructions

Before using any functionality of this plugin you must create a Microsoft Partner account, upload
your app to Microsoft Store and configure the MSIX packaging.

Before starting make sure you already have
a [Microsoft Partner account](https://partner.microsoft.com/).

### Part 1. Associate your app with a Microsoft Store Product

Open your [Microsoft Partner dashboard](https://partner.microsoft.com/dashboard), go to **Apps and
games**, click on **New product** and select **MSIX or PWA app**. Write the name of your app and
click **Reserve product name** to create your product.

Once your product is created, complete your app submission (Pricing and availability, Properties,
Age ratings, Packages, etc.).

This step is needed in order to get the published status and shouldn't be a public submission, so you may want to do this:

- Set the visibility to private.
- Add your own account to test the app.
- Configure the trial pricing and time limit.

#### Part 1.1. Configure MSIX packaging

For an easier configuration use the [msix package](https://pub.dev/packages/msix).
(Although you can use tools like [winapp](https://learn.microsoft.com/en-us/windows/apps/dev-tools/winapp-cli/guides/flutter) or [msstore](https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/overview) its usage won't be covered by this guide).

Open your [Microsoft Partner dashboard](https://partner.microsoft.com/dashboard) go to **Apps and
games**, click on your app to open the **Aplication overview**, once there in the lateral panel go to **Product Identity** under the **Product management** section, take down these values:

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

Then attach the generated `.msix` file to your submissions.

Once your app is published you need to download it from the Microsoft Store on your development machine and open it once, so the license can be downloaded.

### Part 2. Integrate the trial version of your app

Add this plugin as a dependency:

```shell
flutter pub add ms_store_trial
```

Subscribe to license changes at your app startup, the following snippet shows a general example usage:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ms_store_trial/ms_store_trial.dart';

int main() {
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
        final isFullVersion = !(_license?.isTrial) ?? false;

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
                                    debugPrint('Purchase status: ${response.status}, error: ${response.extendedError}');
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

You can test the plugin integration in your app as you add or remove features. However running your app normally as with `flutter run -d windows` won't work as it must be packed as MSIX and installed.

Run the package command, but this time you'll need the unpacked files:

```shell
dart run msix:build --debug
```

Now, install your app in your development Windows machine using the `Add-AppxPackage` CmdLet:

```powershell
cd build\windows\x64\runner\Debug

Add-AppxPackage -Register AppxManifest.xml
```

Now your app will be installed and you'll be able to test the full version in-app purchase.

Also you can debug it using Visual Studio as shown in [this guide](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-debug).

> [!NOTE]
> You can create promo codes to purchase your app license.

## External references

- [Implement a trial version of your app](https://learn.microsoft.com/en-us/windows/uwp/monetize/implement-a-trial-version-of-your-app)
- [Testing In-app purchases and trials](https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials#testing)
- [Enable in-app purchases of apps and add-ons](https://learn.microsoft.com/en-us/windows/uwp/monetize/enable-in-app-purchases-of-apps-and-add-ons)
- [Set pricing and availability for MSIX app](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/price-and-availability?pivots=store-installer-msix#free-trial)
- [Run, debug, and test an MSIX package](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-debug)

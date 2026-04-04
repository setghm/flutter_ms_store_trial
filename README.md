# ms_store_trial

Offer a trial version of your Flutter app in Windows using the Microsoft Store API.

## Instructions

Before using any functionality of this plugin you must create a Microsoft Partner account, upload
your app to Microsoft Store and associate your app with a product.

### Step 1. Set up your app as a Microsoft Store product

Before starting make sure you already have
a [Microsoft Partner account](https://partner.microsoft.com/).

Open your [Microsoft Partner dashboard](https://partner.microsoft.com/dashboard), go to **Apps and
games**, Click on **New product** and select **MSIX or PWA app**. Write the name of your app and
click **Reserve product name** to create your product.

Once your product is created, complete your app submission (Pricing and availability, Properties,
Age ratings, Packages, etc.).

However, this won't be your release submission, but this step is needed in order to get the
published status and start integrating the purchase functionalities, so you may want to do this:

- Set the visibility to private.
- Add your own account to test the app.
- Configure the trial.

Pack your app
as [MSIX](https://docs.flutter.dev/platform-integration/windows/building#msix-packaging) and upload
it.

Once your app is published you need to download it on your development computer and open it once, so
the license can be downloaded.

### Step 2. Use this plugin in your app

Install this plugin:

```shell
flutter pub add microsoft_store_trial
```

### Step 3. Testing Microsoft Store trial integration



### External references

- [In-app purchases and trials](https://learn.microsoft.com/en-us/windows/uwp/monetize/in-app-purchases-and-trials#testing)
- [Implement a trial version of your app](https://learn.microsoft.com/en-us/windows/uwp/monetize/implement-a-trial-version-of-your-app)
- [Enable in-app purchases of apps and add-ons](https://learn.microsoft.com/en-us/windows/uwp/monetize/enable-in-app-purchases-of-apps-and-add-ons)
- [Set pricing and availability for MSIX app](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/price-and-availability?pivots=store-installer-msix#free-trial)
- [Run, debug, and test an MSIX package](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-debug)

## Developing this plugin

> [!NOTE]
> In development it is needed to either build the plugin using the Developer Command Prompt for
> VS or adding the Visual Studio tools to your PATH, otherwise build won't be successfull.

> [!NOTE]
> After updating the CMakeLists.txt file, re-run `flutter build windows`.

#include "ms_store_trial_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <sstream>
#include <inttypes.h>
#include <string>

#include <winrt/windows.foundation.h>
#include <winrt/windows.services.store.h>
#include <ShObjIdl_core.h>
#include <appmodel.h>

#include "ms_store_api.g.h"
#include "foreground_dispatcher.hpp"

using namespace winrt::Windows::Services::Store;
using namespace winrt::Windows::Foundation;

namespace ms_store_trial {

// static
void MsStoreTrialPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {

#if !defined(FLUTTER_RELEASE)
    // In debug mode, get the logs to check if the app was properly packaged as MSIX.
    (void)GetPackageFamilyName();
#endif

    auto context = InitStoreContext(registrar);

    auto messenger = registrar->messenger();

    auto plugin = std::make_unique<MsStoreTrialPlugin>(context);

    plugin->flutter_api_ = std::make_unique<MsStoreFlutterApi>(messenger);

    MsStoreHostApi::SetUp(messenger, plugin.get());

    registrar->AddPlugin(std::move(plugin));
}

// static
std::wstring MsStoreTrialPlugin::GetPackageFamilyName() {
    UINT32 length = 0;
    LONG result = GetCurrentPackageFamilyName(&length, nullptr);

    if (result == ERROR_INSUFFICIENT_BUFFER) {
        std::wstring familyName;
        familyName.resize(length);

        result = GetCurrentPackageFamilyName(&length, familyName.data());

        if (result == ERROR_SUCCESS) {
            OutputDebugString((L"[INFO] Package family name found: " + winrt::to_hstring(familyName.c_str()) + L"\n").c_str());
            return familyName;
        }
        else {
            OutputDebugString((L"[ERROR] Unable to retrieve Package Family Name: " + winrt::to_hstring((int32_t)result) + L"\n").c_str());
        }
    }
    else {
        OutputDebugString(L"[ERROR] Application is not packed\n");
    }

    return L"";
}

// static
StoreContext MsStoreTrialPlugin::InitStoreContext(flutter::PluginRegistrarWindows* registrar) {
    auto context = StoreContext::GetDefault();

    auto hwnd = registrar->GetView()->GetNativeWindow();

    auto interop = context.try_as<IInitializeWithWindow>();

    if (interop) {
        HRESULT hr = interop->Initialize(hwnd);

        if (FAILED(hr)) {
            auto e = winrt::hresult_error(hr);
            OutputDebugString((L"[ERROR] Unable to associate StoreContext with the current window: " + e.message() + L"\n").c_str());
        }
        else {
            OutputDebugString(L"[INFO] Store context initialized successfully!\n");
        }
    }
    else {
        OutputDebugString(L"[ERROR] StoreContext does not support IInitializeWithWindow. Check package identity.\n");
    }

    return context;
}

MsStoreTrialPlugin::MsStoreTrialPlugin(StoreContext context) : context_(context) {
    foreground_ = std::make_unique<ForegroundDispatcher>();

    license_changed_token_ = context_.OfflineLicensesChanged(
        [this](auto, auto) {
            this->FireCurrentAppLicenseAsync();
        });
}

MsStoreTrialPlugin::~MsStoreTrialPlugin() {
    if (context_) {
        context_.OfflineLicensesChanged(license_changed_token_);
    }
}

winrt::fire_and_forget MsStoreTrialPlugin::GetStoreProductForCurrentAppAsync(
    std::function<void(ErrorOr<ProductResponseStruct>)> result) {
    try {
        StoreProductResult res = co_await context_.GetStoreProductForCurrentAppAsync();
        ProductResponseStruct response;

        if (res.ExtendedError()) {
            response.set_extendeded_error(static_cast<int>(res.ExtendedError().value));
            result(response);
            co_return;
        }

        auto storeProduct = res.Product();
        ProductStruct product;

        auto storePrice = storeProduct.Price();
        ProductPriceStruct price;

        // Access the unformatted price might throw an exception.
        try {
            price.set_unformatted_price(winrt::to_string(storePrice.UnformattedBasePrice()));
        }
        catch (...) {
            OutputDebugString(L"[LOG] Unable to get the unformatted price\n");
        }

        price.set_currency_code(winrt::to_string(storePrice.CurrencyCode()));
        price.set_formatted_price(winrt::to_string(storePrice.FormattedBasePrice()));

        product.set_price(price);

        product.set_store_id(winrt::to_string(storeProduct.StoreId()));
        product.set_title(winrt::to_string(storeProduct.Title()));
        product.set_description(winrt::to_string(storeProduct.Description()));
        product.set_product_kind(winrt::to_string(storeProduct.ProductKind()));
        product.set_extended_json_data(winrt::to_string(storeProduct.ExtendedJsonData()));

        response.set_extendeded_error(0LL);
        response.set_product(product);

        result(response);
    }
    catch (winrt::hresult_error const& e) {
        result(FlutterError("WINRT_EXCEPTION", winrt::to_string(e.message())));
    }
    catch (const std::exception& e) {
        result(FlutterError("EXCEPTION", e.what()));
    }
}

winrt::fire_and_forget MsStoreTrialPlugin::RequestCurrentAppPurchaseAsync(
    std::function<void(ErrorOr<PurchaseResponseStruct> reply)> result) {
    try {
        StoreProductResult productRes = co_await context_.GetStoreProductForCurrentAppAsync();

        if (productRes.ExtendedError()) {
            result(FlutterError("PRODUCT_ERROR", "Unable to retrieve the store product for the current app"));
            co_return;
        }

        auto storeId = productRes.Product().StoreId();
        StorePurchaseResult purchaseRes = co_await context_.RequestPurchaseAsync(storeId);

        PurchaseResponseStruct response;

        response.set_extended_error(purchaseRes.ExtendedError().value);
        response.set_status(static_cast<int>(purchaseRes.Status()));

        result(response);
    }
    catch (winrt::hresult_error const& e) {
        result(FlutterError("WINRT_EXCEPTION", winrt::to_string(e.message())));
    }
    catch (const std::exception& e) {
        result(FlutterError("EXCEPTION", e.what()));
    }
}

void MsStoreTrialPlugin::GetPackageFamilyName(
    std::function<void(ErrorOr<std::string> reply)> result) {
    std::wstring wstr = MsStoreTrialPlugin::GetPackageFamilyName();

    if (wstr.empty()) {
        result(std::string());
        return;
    }

    int size = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string str(size, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &str[0], size, NULL, NULL);

    result(str);
}

winrt::fire_and_forget MsStoreTrialPlugin::FireCurrentAppLicenseAsync(void) {
    StoreAppLicense res = co_await context_.GetAppLicenseAsync();

    AppLicenseStruct license;

    license.set_is_active(static_cast<bool>(res.IsActive()));
    license.set_is_trial(static_cast<bool>(res.IsTrial()));
    license.set_is_trial_owned_by_this_user(static_cast<bool>(res.IsTrialOwnedByThisUser()));

    license.set_sku_store_id(winrt::to_string(res.SkuStoreId()));
    license.set_trial_unique_id(winrt::to_string(res.TrialUniqueId()));
    license.set_extended_json_data(winrt::to_string(res.ExtendedJsonData()));

    constexpr int64_t NO_DEFINED_TIME = 0x7FFFFFFFFFFFFFFF;

    /**
    * Check if has expiration date.
    */
    int64_t expirationDate = static_cast<int64_t>(winrt::clock::to_time_t(res.ExpirationDate()));
    bool hasNoExpirationDate = expirationDate == NO_DEFINED_TIME;

    license.set_expiration_timestamp(hasNoExpirationDate ? 0LL : expirationDate);

    /**
    * Check if we should pass a 0 value trial time remaining instead.
    */
    int64_t trialTimeRemaining = static_cast<int64_t>(res.TrialTimeRemaining().count());
    bool hasNoTrialTime = trialTimeRemaining == NO_DEFINED_TIME;

    license.set_trial_time_remaining(hasNoTrialTime ? 0LL : trialTimeRemaining);

    /**
    * CRITICAL: We can only call Flutter API on platform thread.
    */
    foreground_->post([license = std::move(license), this]() {
        flutter_api_->OnLicenseChanged(license, []() {}, [](auto) {});
    });
}

}  // namespace ms_store_trial

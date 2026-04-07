#include "ms_store_trial_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <sstream>
#include <chrono>
#include <inttypes.h>

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

    (void)GetPackageFamilyName();

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
    std::function<void(ErrorOr<MsStoreProductResponse>)> result) {
    try {
        StoreProductResult res = co_await context_.GetStoreProductForCurrentAppAsync();

        if (res.ExtendedError()) {
            MsStoreProductResponse response{
                static_cast<int>(res.ExtendedError().value)
            };
            result(response);
            co_return;
        }

        auto storeProduct = res.Product();

        std::string unformattedPrice = "";

        /**
        * Accessing the unformatted price when it is zero will raise an exception.
        * Keep in separated blocks to ensure available data is gathered regardless any possible issue.
        */
        try {
            unformattedPrice = winrt::to_string(storeProduct.Price().UnformattedBasePrice());
        }
        catch (...) {
            OutputDebugString(L"[LOG] Unable to get the unformatted base price\n");
        }

        MsStoreProduct product{
            winrt::to_string(storeProduct.StoreId()),
            winrt::to_string(storeProduct.Title()),
            winrt::to_string(storeProduct.Description()),
            unformattedPrice,
            winrt::to_string(storeProduct.Price().CurrencyCode()),
            winrt::to_string(storeProduct.Price().FormattedBasePrice()),
            winrt::to_string(storeProduct.ProductKind()),
            winrt::to_string(storeProduct.ExtendedJsonData())
        };
        MsStoreProductResponse response{
            &product,
            static_cast<int>(res.ExtendedError().value)
        };

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
    std::function<void(ErrorOr<MsStorePurchaseResponse> reply)> result) {
    try {
        StoreProductResult productRes = co_await context_.GetStoreProductForCurrentAppAsync();

        if (productRes.ExtendedError()) {
            result(FlutterError("PRODUCT_ERROR", "Unable to retrieve the store product for the current app"));
            co_return;
        }

        auto storeId = productRes.Product().StoreId();
        StorePurchaseResult purchaseRes = co_await context_.RequestPurchaseAsync(storeId);

        MsStorePurchaseResponse response{
            static_cast<MsStorePurchaseStatus>(static_cast<int>(purchaseRes.Status())),
            static_cast<int>(purchaseRes.ExtendedError().value),
        };

        result(response);
    }
    catch (winrt::hresult_error const& e) {
        result(FlutterError("WINRT_EXCEPTION", winrt::to_string(e.message())));
    }
    catch (const std::exception& e) {
        result(FlutterError("EXCEPTION", e.what()));
    }
}

winrt::fire_and_forget MsStoreTrialPlugin::FireCurrentAppLicenseAsync(void) {
    StoreAppLicense res = co_await context_.GetAppLicenseAsync();

    /**
    * CRITICAL: We only call Flutter API on platform thread.
    */
    foreground_->post([res = std::move(res), this]() {
        int64_t expirationDate = winrt::clock::to_time_t(res.ExpirationDate()) / 1000;
        int64_t trialTimeRemaining = std::chrono::duration_cast<std::chrono::milliseconds>(res.TrialTimeRemaining()).count();

        MsStoreAppLicense license{
            static_cast<bool>(res.IsActive()),
            static_cast<bool>(res.IsTrial()),
            static_cast<bool>(res.IsTrialOwnedByThisUser()),
            trialTimeRemaining,
            expirationDate,
            winrt::to_string(res.SkuStoreId()),
            winrt::to_string(res.ExtendedJsonData()),
            winrt::to_string(res.TrialUniqueId()),
        };

        flutter_api_->OnLicenseChanged(license, []() {}, [](auto) {});
    });
}

}  // namespace ms_store_trial

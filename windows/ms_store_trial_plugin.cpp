#include "ms_store_trial_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <sstream>

#include <winrt/windows.foundation.h>
#include <winrt/windows.services.store.h>

#include "ms_store_api.g.h"

using namespace winrt::Windows::Services::Store;
using namespace winrt::Windows::Foundation;

namespace ms_store_trial {

// static
void MsStoreTrialPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {

    auto messenger = registrar->messenger();

    auto plugin = std::make_unique<MsStoreTrialPlugin>();

    plugin->flutter_api_ = std::make_unique<MsStoreFlutterApi>(messenger);

    MsStoreHostApi::SetUp(messenger, plugin.get());

    registrar->AddPlugin(std::move(plugin));
}

MsStoreTrialPlugin::MsStoreTrialPlugin() {
    context_ = StoreContext::GetDefault();

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

        MsStoreProduct product{
            winrt::to_string(res.Product().StoreId()),
            winrt::to_string(res.Product().Description()),
            winrt::to_string(res.Product().Price().FormattedPrice())
        };
        MsStoreProductResponse response{
            &product,
            static_cast<int>(res.ExtendedError().value)
        };

        result(response);
    }
    catch (const std::exception& e) {
        result(FlutterError("EXCEPTION", e.what(), nullptr));
    }
}

winrt::fire_and_forget MsStoreTrialPlugin::RequestCurrentAppPurchaseAsync(
    std::function<void(ErrorOr<MsStorePurchaseResponse> reply)> result) {
    try {
        StoreProductResult productRes = co_await context_.GetStoreProductForCurrentAppAsync();

        if (productRes.ExtendedError()) {
            result(FlutterError("PRODUCT_ERROR", "Unable to retrieve the store product for the current app", nullptr));
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
    catch (const std::exception& e) {
        result(FlutterError("EXCEPTION", e.what(), nullptr));
    }
}

winrt::fire_and_forget MsStoreTrialPlugin::FireCurrentAppLicenseAsync(void) {
    StoreAppLicense res = co_await context_.GetAppLicenseAsync();

    time_t expirationDate = winrt::clock::to_time_t(res.ExpirationDate());

    MsStoreLicense license {
       static_cast<bool>(res.IsActive()),
       static_cast<bool>(res.IsTrial()),
       static_cast<bool>(res.IsTrialOwnedByThisUser()),
       &expirationDate,
    };

    flutter_api_->OnLicenseChanged(license, []() {}, [](auto) {});
}

}  // namespace ms_store_trial

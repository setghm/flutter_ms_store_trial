#ifndef FLUTTER_PLUGIN_MS_STORE_TRIAL_PLUGIN_H_
#define FLUTTER_PLUGIN_MS_STORE_TRIAL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include <winrt/windows.foundation.h>
#include <winrt/windows.services.store.h>

#include "ms_store_api.g.h"
#include "foreground_dispatcher.hpp"

namespace ms_store_trial {

class MsStoreTrialPlugin : public MsStoreHostApi, public flutter::Plugin {
private:
  winrt::Windows::Services::Store::StoreContext context_{ nullptr };
  winrt::event_token license_changed_token_;
  std::unique_ptr<MsStoreFlutterApi> flutter_api_;
  std::unique_ptr<ForegroundDispatcher> foreground_;
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MsStoreTrialPlugin(winrt::Windows::Services::Store::StoreContext context);

  virtual ~MsStoreTrialPlugin();

  // Disallow copy and assign.
  MsStoreTrialPlugin(const MsStoreTrialPlugin&) = delete;
  MsStoreTrialPlugin& operator=(const MsStoreTrialPlugin&) = delete;

  std::optional<FlutterError> RestoreCurrentAppLicense() override {
      FireCurrentAppLicenseAsync();
      return std::nullopt;
  }

  void GetStoreProductForCurrentApp(
      std::function<void(ErrorOr<ProductResponseStruct>)> result) override {
      GetStoreProductForCurrentAppAsync(result);
  }

  void RequestCurrentAppPurchase(
      std::function<void(ErrorOr<PurchaseResponseStruct> reply)> result) override {
      RequestCurrentAppPurchaseAsync(result);
  }

  void GetPackageFamilyName(
      std::function<void(ErrorOr<std::string> reply)> result) override;
private:
    static std::wstring GetPackageFamilyName(void);

    static winrt::Windows::Services::Store::StoreContext
        InitStoreContext(flutter::PluginRegistrarWindows *registrar);

    winrt::fire_and_forget GetStoreProductForCurrentAppAsync(
        std::function<void(ErrorOr<ProductResponseStruct>)> result);

    winrt::fire_and_forget RequestCurrentAppPurchaseAsync(
        std::function<void(ErrorOr<PurchaseResponseStruct> reply)> result);

    winrt::fire_and_forget FireCurrentAppLicenseAsync(void);
};

}  // namespace ms_store_trial

#endif  // FLUTTER_PLUGIN_MS_STORE_TRIAL_PLUGIN_H_

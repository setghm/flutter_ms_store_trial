#include "include/ms_store_trial/ms_store_trial_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ms_store_trial_plugin.h"

void MsStoreTrialPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ms_store_trial::MsStoreTrialPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

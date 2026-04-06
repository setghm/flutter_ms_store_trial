#include "foreground_dispatcher.hpp"

#include <winrt/windows.foundation.h>

#define WM_RUN_ON_UI_THREAD (WM_USER + 100)

LRESULT ForegroundDispatcher::Procedure(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    ForegroundDispatcher* self = nullptr;

    if (msg == WM_NCCREATE) {
        auto* create = reinterpret_cast<CREATESTRUCT*>(lParam);
        self = static_cast<ForegroundDispatcher*>(create->lpCreateParams);
        SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    }
    else {
        self = reinterpret_cast<ForegroundDispatcher*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    }

    if (self != nullptr && msg == WM_RUN_ON_UI_THREAD) {
        OutputDebugString(L"[INFO] Running tasks...\n");

        std::queue<std::function<void()>> local_tasks;

        {
            std::lock_guard<std::mutex> lock(self->mutex_);
            std::swap(local_tasks, self->tasks_);
        }

        while (!local_tasks.empty()) {
            OutputDebugString((L"[INFO] Running task " + winrt::to_hstring(local_tasks.size()) + L"...\n").c_str());
            auto& task = local_tasks.front();
            if (task) task();
            local_tasks.pop();
        }

        return 0;
    }
    else if (self == nullptr && msg == WM_RUN_ON_UI_THREAD) {
        OutputDebugString(L"[INFO] Unable to get self pointer\n");
    }

    return DefWindowProc(hwnd, msg, wParam, lParam);
}

ForegroundDispatcher::ForegroundDispatcher() {
    const wchar_t CLASS_NAME[] = L"com.setghm.ms_store_trial.ForegroundDispatcher";

    WNDCLASSEX wx{0};
    wx.cbSize = sizeof(WNDCLASSEX);
    wx.lpfnWndProc = ForegroundDispatcher::Procedure;
    wx.hInstance = GetModuleHandle(nullptr);
    wx.lpszClassName = CLASS_NAME;

    RegisterClassEx(&wx);

    /*
    * Message-only window
    * 
    * https://devblogs.microsoft.com/oldnewthing/20171218-00/?p=97595
    */
    message_hwnd_ = CreateWindowEx(0, CLASS_NAME, 0, 0, 0, 0, 0, 0, HWND_MESSAGE, 0, wx.hInstance, this);
}

ForegroundDispatcher::~ForegroundDispatcher() {
    if (message_hwnd_) {
        DestroyWindow(message_hwnd_);
        message_hwnd_ = nullptr;
    }
}

void ForegroundDispatcher::post(std::function<void()> fn) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        tasks_.push(std::move(fn));
    }
    OutputDebugString(L"[INFO] Posting task...\n");
    PostMessage(message_hwnd_, WM_RUN_ON_UI_THREAD, 0, 0);
}

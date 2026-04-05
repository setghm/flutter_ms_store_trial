#pragma once

#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <functional>
#include <memory>
#include <mutex>
#include <queue>

/**
 * Temporary solution until a built-in method to post tasks to the main thread exists.
 * 
 * Internally a message-only window is created in order to signal the main thread to handle the
 * queued tasks.
 */
class ForegroundDispatcher {
private:
    static LRESULT Procedure(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
public:
    explicit ForegroundDispatcher();

    ~ForegroundDispatcher();

    /**
     * Execute the given lambda on the main thread.
     */
    void post(std::function<void()> fn);

private:
    HWND message_hwnd_ = nullptr;

    std::mutex mutex_;
    std::queue<std::function<void()>> tasks_;
};
